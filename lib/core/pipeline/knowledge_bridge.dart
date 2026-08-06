import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../db/learning_db.dart';
import '../db/mining_db.dart';
import 'fsrs_bootstrap_import.dart' show simulateWellKnownCard;
import 'fsrs_mapping.dart';
import 'sentence_scoring.dart' show Knowledge;

/// The result of a [KnowledgeBridge.backfill] — how much on-ramp mastery
/// was projected into the shared knowledge state.
class KnowledgeBridgeResult {
  final int lexemesProjected;
  final int knownCount;
  final int learningCount;

  const KnowledgeBridgeResult({
    required this.lexemesProjected,
    required this.knownCount,
    required this.learningCount,
  });
}

/// The on-ramp → mining knowledge bridge (DESIGN_ONRAMP_BRIDGE.md,
/// architecture **C**). `MiningDb`'s `VocabItems`+`Cards` is the single
/// source of truth for "is this lemma known"; the on-ramp (LearningDb's
/// recall ladder) keeps its own SM-2 scheduling but PROJECTS each
/// lexeme's mastery into that shared state through this bridge. So mining
/// treats already-learned words as known and only mines genuinely new
/// ones — two schedulers, one knowledge truth.
///
/// Only **lexeme** mastery bridges: mining's knowledge unit is the lemma
/// (word). Character mastery (a kanji glyph) and grammar mastery are not
/// lemmas and deliberately do not project here (see the design's mapping
/// table).
class KnowledgeBridge {
  final MiningDb mining;

  const KnowledgeBridge(this.mining);

  /// The design's rung → knowledge mapping: rungs 3–5 are production
  /// (the learner can *produce* the word, so certainly knows it for
  /// reading) → [Knowledge.known]; rungs 1–2 are introduced-but-not-yet-
  /// mastered → [Knowledge.learning]. A lexeme absent from the on-ramp
  /// never reaches this function, so it stays `unknown` in mining.
  static Knowledge knowledgeForRung(int masteryRung) =>
      masteryRung >= 3 ? Knowledge.known : Knowledge.learning;

  /// Project one lexeme's current mastery into the shared knowledge
  /// state. Called on every on-ramp promotion/demotion (and by
  /// [backfill]); last-write-wins per the shared-substrate rule.
  ///
  /// SM-2 numbers are NOT converted to FSRS (different algorithms, no
  /// honest mapping). Instead a genuinely FSRS-earned trajectory is
  /// simulated forward — `known` via [simulateWellKnownCard], `learning`
  /// via a single `good` review — the same discipline the frequency
  /// bootstrap already uses.
  Future<void> projectLexeme({
    required String languageCode,
    required String lemma,
    required int masteryRung,
    DateTime? now,
  }) async {
    final card = _cardFor(knowledgeForRung(masteryRung), now: now);
    final vocabId = 'vocab:$languageCode:$lemma';
    await mining.transaction(() async {
      await mining.into(mining.vocabItems).insertOnConflictUpdate(
            VocabItemsCompanion.insert(
              id: vocabId,
              languageCode: languageCode,
              lemma: lemma,
              pos: '',
              createdAt: (now ?? DateTime.now()).toUtc(),
            ),
          );
      await mining.into(mining.cards).insertOnConflictUpdate(
            FsrsMapping.toCompanion(card).copyWith(
              id: Value('card:$vocabId'),
              vocabItemId: Value(vocabId),
            ),
          );
    });
  }

  /// Backfill the shared knowledge state from every mastered lexeme the
  /// on-ramp already holds — the initial hand-off. Idempotent (re-running
  /// re-projects the same rows). Only `refType == 'lexeme'` items are
  /// read; each is joined to its [Lexemes] row for the `writtenForm`,
  /// which is the lemma mining keys on.
  ///
  /// Form-matching caveat (design): `writtenForm` must equal the Lindera
  /// lemma. For curated A1/A2 vocab it does; any mismatch simply fails to
  /// mark the word known → mining over-mines it, never falsely claims it.
  Future<KnowledgeBridgeResult> backfill(
    LearningDb learning, {
    required String languageId,
    required String languageCode,
    DateTime? now,
  }) async {
    final query = learning.select(learning.learnItems).join([
      innerJoin(
        learning.lexemes,
        learning.lexemes.id.equalsExp(learning.learnItems.refId),
      ),
    ])
      ..where(learning.learnItems.languageId.equals(languageId) &
          learning.learnItems.refType.equals('lexeme'));

    final rows = await query.get();
    var known = 0;
    var learningCount = 0;
    for (final row in rows) {
      final item = row.readTable(learning.learnItems);
      final lexeme = row.readTable(learning.lexemes);
      await projectLexeme(
        languageCode: languageCode,
        lemma: lexeme.writtenForm,
        masteryRung: item.masteryRung,
        now: now,
      );
      if (item.masteryRung >= 3) {
        known++;
      } else {
        learningCount++;
      }
    }
    return KnowledgeBridgeResult(
      lexemesProjected: rows.length,
      knownCount: known,
      learningCount: learningCount,
    );
  }

  fsrs.Card _cardFor(Knowledge knowledge, {DateTime? now}) {
    final scheduler = fsrs.FSRS();
    if (knowledge == Knowledge.known) return simulateWellKnownCard(scheduler);
    // learning: one good review → a real 'learning' FSRS state with low
    // stability, which `FsrsKnowledgeSource` reads as learning (not known,
    // not unknown).
    final t = (now ?? DateTime.now()).toUtc();
    return scheduler.repeat(fsrs.Card(), t)[fsrs.Rating.good]!.card;
  }
}
