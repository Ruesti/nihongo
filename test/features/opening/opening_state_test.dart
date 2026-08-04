import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/datum/observation.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/passage_snapshot.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart' show Knowledge;
import 'package:nihongo_app/features/opening/opening_state.dart';

Token _tok(String lemma) =>
    Token(surface: lemma, lemma: lemma, pos: 'n', charStart: 0, charEnd: 1);

Future<void> _read(
  MiningDb db, {
  required String work,
  required String passage,
  required bool known,
  required DateTime ts,
}) async {
  await db.into(db.works).insertOnConflictUpdate(WorksCompanion.insert(
        id: work, title: work, medium: 'epub', languageCode: 'ja',
        addedAt: ts,
      ));
  await recordPassageSnapshot(db,
      workId: work,
      passageRef: passage,
      tokens: [_tok('本'), _tok('猫')],
      knowledgeOf: (_) => known ? Knowledge.known : Knowledge.unknown,
      ts: ts);
}

void main() {
  late MiningDb db;
  setUp(() => db = MiningDb.forTesting());
  tearDown(() => db.close());

  group('loadOpeningState', () {
    test('a fresh user with no history → BlankSlate', () async {
      expect(await loadOpeningState(db), isA<BlankSlateState>());
    });

    test('a passage read once → FirstReading (graceful empty state)',
        () async {
      await _read(db, work: 'w1', passage: 'p1', known: false,
          ts: DateTime.utc(2026, 1, 1));

      final state = await loadOpeningState(db);

      expect(state, isA<FirstReadingState>());
      expect((state as FirstReadingState).lastReading.unknownRatio, 1.0);
    });

    test('a passage read twice → RePresentation with a delta', () async {
      await _read(db, work: 'w1', passage: 'p1', known: false,
          ts: DateTime.utc(2026, 1, 1));
      await _read(db, work: 'w1', passage: 'p1', known: true,
          ts: DateTime.utc(2026, 2, 1));

      final state = await loadOpeningState(db);

      expect(state, isA<RePresentationState>());
      final delta = (state as RePresentationState).delta;
      expect(delta.before.unknownRatio, 1.0);
      expect(delta.after.unknownRatio, 0.0);
    });

    test('picks the MOST RECENTLY read passage across works', () async {
      await _read(db, work: 'w1', passage: 'old', known: false,
          ts: DateTime.utc(2026, 1, 1));
      await _read(db, work: 'w2', passage: 'recent', known: false,
          ts: DateTime.utc(2026, 5, 1)); // newer, different work

      final state = await loadOpeningState(db);

      // Only 'recent' was read once → FirstReading on that passage.
      expect(state, isA<FirstReadingState>());
      expect((state as FirstReadingState).lastReading.passageRef, 'recent');
    });
  });

  group('openingDatumObservation', () {
    test('a delta state yields a deltaMeasured observation with measured facts',
        () async {
      await _read(db, work: 'w1', passage: 'Kapitel 2', known: false,
          ts: DateTime.utc(2026, 1, 1));
      await _read(db, work: 'w1', passage: 'Kapitel 2', known: true,
          ts: DateTime.utc(2026, 2, 12));

      final obs = openingDatumObservation(await loadOpeningState(db))!;

      expect(obs.kind, ObservationKind.deltaMeasured);
      expect(obs.facts['unknown_before'], 100);
      expect(obs.facts['unknown_after'], 0);
      expect(obs.facts['chapter'], 'Kapitel 2');
    });

    test('a first-reading state yields a firstReading observation', () async {
      await _read(db, work: 'w1', passage: 'Kapitel 2', known: false,
          ts: DateTime.utc(2026, 1, 1));

      final obs = openingDatumObservation(await loadOpeningState(db))!;

      expect(obs.kind, ObservationKind.firstReading);
      expect(obs.facts['chapter'], 'Kapitel 2');
    });

    test('a blank slate yields no observation', () async {
      expect(openingDatumObservation(const BlankSlateState()), isNull);
    });
  });
}
