import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' show Rating;

import '../../core/datum/datum_registry.dart';
import '../../core/datum/datum_voice.dart';
import '../../core/db/mining_db.dart';
import '../../core/language_pack/language_pack.dart' show Token;
import '../../core/pipeline/due_in_reading.dart';
import '../../core/pipeline/fsrs_knowledge_source.dart';
import '../../core/pipeline/passage_snapshot.dart';
import '../../core/pipeline/review_scheduler.dart';
import '../../core/text_track/word_tap.dart';
import '../opening/opening_state.dart';
import 'slice_pack.dart';

/// The vertical slice's one seam onto the real mining engine. It seeds a
/// [MiningDb] from the prebaked [SlicePack] and exposes exactly the
/// operations the slice's two screens need — every one of them delegated
/// to the *real* pipeline component (no slice-local reimplementations):
///
///  - due-in-view      → [DueInReading]        (§7)
///  - grade a card     → [ReviewScheduler]     (§7, real FSRS write)
///  - tap a word       → [WordTapHandler]      (§5)
///  - finish a passage → [recordPassageSnapshot] (§7, immutable)
///  - opening proof    → [loadOpeningState] + [DatumVoice] (§8, §6.3)
///
/// The screens hold no pipeline logic; this repository is the only place
/// the slice touches the engine, which is what keeps it a *wiring* layer.
class SliceRepository {
  final MiningDb db;
  final SlicePack pack;

  late final String workId = 'work:slice:${pack.languageCode}';
  late final _tap = WordTapHandler(pack.dictionary);
  late final _due = DueInReading(db);
  late final _scheduler = ReviewScheduler(db);
  final _datum = DatumVoice(registry: DatumRegistry.forLocale('de'));

  SliceRepository({required this.db, required this.pack});

  /// Idempotent: safe to call on every launch. Content is re-asserted
  /// (insert-or-update).
  ///
  /// [includeDemoKnowledge] seeds a small "returning reader already saw
  /// these" set of due cards — right for the standalone demo entry
  /// (`main_mining.dart`), but WRONG in the unified app, where the
  /// on-ramp is the real knowledge source and must not be polluted with
  /// demo "known" words. The in-app reading tab passes `false`.
  Future<void> seed({bool includeDemoKnowledge = true, DateTime? now}) async {
    await _seedContent();
    if (includeDemoKnowledge) await _seedDemoKnowledge(now: now);
  }

  Future<void> _seedContent() async {
    final ts = DateTime.now().toUtc();
    await db.into(db.works).insertOnConflictUpdate(WorksCompanion.insert(
          id: workId,
          title: pack.workTitle,
          medium: 'epub',
          languageCode: pack.languageCode,
          addedAt: ts,
        ));
    final sourceId = 'src:$workId';
    await db.into(db.sources).insertOnConflictUpdate(SourcesCompanion.insert(
          id: sourceId,
          workId: workId,
          kind: 'epub',
          path: 'bundled:rashomon_slice',
          importedAt: ts,
        ));
    for (var i = 0; i < pack.passages.length; i++) {
      final p = pack.passages[i];
      await db.into(db.textSpans).insertOnConflictUpdate(
            TextSpansCompanion.insert(
              id: 'span:$workId:${p.passageRef}',
              workId: workId,
              sourceId: sourceId,
              ordinal: i,
              content: p.content,
              anchorType: 'flow',
              charStart: Value(0),
              charEnd: Value(p.content.length),
            ),
          );
    }
  }

  Future<void> _seedDemoKnowledge({DateTime? now}) async {
    final existing = await (db.select(db.cards)..limit(1)).get();
    if (existing.isNotEmpty) return; // preserve real progress across launches

    // Seeded as "seen but due now" (due yesterday) so the inline review
    // in the reader has real items to surface. Labelled demo seed, not a
    // measurement — see [SlicePack.demoKnownLemmas].
    final asOf = (now ?? DateTime.now()).toUtc();
    final yesterday = asOf.subtract(const Duration(days: 1));
    for (final lemma in pack.demoKnownLemmas) {
      final vocabId = 'vocab:${pack.languageCode}:$lemma';
      await db.into(db.vocabItems).insertOnConflictUpdate(
            VocabItemsCompanion.insert(
              id: vocabId,
              languageCode: pack.languageCode,
              lemma: lemma,
              pos: '',
              createdAt: yesterday,
            ),
          );
      await db.into(db.cards).insertOnConflictUpdate(CardsCompanion.insert(
            id: 'card:$vocabId',
            vocabItemId: vocabId,
            state: const Value('review'),
            stability: const Value(2.0),
            due: yesterday,
            lastReview: yesterday.subtract(const Duration(days: 2)),
          ));
    }
  }

  /// Due review items whose lemma is present in [passage] — the reader's
  /// current text is the queue (§7).
  Future<List<DueCardInView>> dueInView(SlicePassage passage,
          {DateTime? now}) =>
      _due.dueInView(
          languageCode: pack.languageCode, tokens: passage.tokens, now: now);

  /// Grade a surfaced card in the reading flow (real FSRS write, §7).
  Future<void> grade(String cardId, Rating rating, {DateTime? now}) =>
      _scheduler.grade(cardId, rating, now: now);

  /// The dictionary lookup behind a word tap (§5).
  WordTapResult tap(Token token) => _tap.onTap(token);

  /// Append an immutable snapshot of one reading of [passage] (§7). The
  /// unknown ratio is computed against the reader's *real* current
  /// knowledge (FSRS state), so re-reading later yields a true delta.
  Future<void> finishReading(
    SlicePassage passage, {
    int lookupCount = 0,
    int? dwellMs,
    DateTime? now,
  }) async {
    final knowledge =
        await FsrsKnowledgeSource.load(db, languageCode: pack.languageCode);
    await recordPassageSnapshot(
      db,
      workId: workId,
      passageRef: passage.passageRef,
      tokens: passage.tokens,
      knowledgeOf: knowledge.call,
      metrics: PassageMetrics(lookupCount: lookupCount, dwellMs: dwellMs),
      ts: now,
    );
  }

  /// The opening-screen proof state (§8), from real snapshot history.
  Future<OpeningState> openingState() => loadOpeningState(db);

  /// Datum's line for an opening state, or null for silence (§6.3). A
  /// blank slate has no observation and thus no line — never a
  /// fabricated one.
  String? openingDatumLine(OpeningState state) {
    final observation = openingDatumObservation(state);
    if (observation == null) return null;
    return _datum.say(observation);
  }
}
