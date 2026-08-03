import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/passage_snapshot.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart' show Knowledge;

Token _tok(String lemma) =>
    Token(surface: lemma, lemma: lemma, pos: 'n', charStart: 0, charEnd: 1);

Future<void> _seedWork(MiningDb db) => db.into(db.works).insert(
      WorksCompanion.insert(
        id: 'w1',
        title: 'W',
        medium: 'epub',
        languageCode: 'ja',
        addedAt: DateTime.now().toUtc(),
      ),
    );

void main() {
  late MiningDb db;
  setUp(() async {
    db = MiningDb.forTesting();
    await _seedWork(db);
  });
  tearDown(() => db.close());

  group('computeUnknownRatio', () {
    test('is the fraction of content tokens that are unknown', () {
      final tokens = [_tok('本'), _tok('猫'), _tok('犬'), _tok('鳥')];
      // 本 known, the rest unknown → 3/4.
      Knowledge k(String l) => l == '本' ? Knowledge.known : Knowledge.unknown;

      expect(computeUnknownRatio(tokens, k), 0.75);
    });

    test('excludes punctuation from the denominator', () {
      final tokens = [_tok('本'), _tok('。'), _tok('猫')];
      Knowledge k(String l) => l == '本' ? Knowledge.known : Knowledge.unknown;

      // Only 本 and 猫 count; 。 excluded → 1 unknown / 2 content = 0.5.
      expect(computeUnknownRatio(tokens, k), 0.5);
    });

    test('a passage of only punctuation has ratio 0.0, not NaN', () {
      expect(computeUnknownRatio([_tok('。'), _tok('、')], (_) => Knowledge.unknown),
          0.0);
    });
  });

  group('recordPassageSnapshot', () {
    test('appends an immutable snapshot row with the computed ratio',
        () async {
      final snap = await recordPassageSnapshot(
        db,
        workId: 'w1',
        passageRef: 'p1',
        tokens: [_tok('本'), _tok('猫')],
        knowledgeOf: (l) => l == '本' ? Knowledge.known : Knowledge.unknown,
        metrics: const PassageMetrics(dwellMs: 90000, lookupCount: 3),
        ts: DateTime.utc(2026, 1, 1),
      );

      expect(snap.unknownRatio, 0.5);
      expect(snap.dwellMs, 90000);
      expect(snap.lookupCount, 3);
    });

    test('reading the same passage twice appends two rows (append-only)',
        () async {
      await recordPassageSnapshot(db,
          workId: 'w1', passageRef: 'p1', tokens: [_tok('本')],
          knowledgeOf: (_) => Knowledge.unknown, ts: DateTime.utc(2026, 1, 1));
      await recordPassageSnapshot(db,
          workId: 'w1', passageRef: 'p1', tokens: [_tok('本')],
          knowledgeOf: (_) => Knowledge.known, ts: DateTime.utc(2026, 2, 1));

      expect((await db.select(db.passageSnapshots).get()), hasLength(2));
    });
  });

  group('PassageDelta / latestPassageDelta', () {
    Future<void> read(String ref, double _, DateTime ts,
        {required bool known}) async {
      await recordPassageSnapshot(db,
          workId: 'w1',
          passageRef: ref,
          tokens: [_tok('本'), _tok('猫')],
          knowledgeOf: (l) =>
              known ? Knowledge.known : Knowledge.unknown,
          ts: ts);
    }

    test('returns null until a passage has been read twice', () async {
      await read('p1', 1.0, DateTime.utc(2026, 1, 1), known: false);

      expect(
        await latestPassageDelta(db, workId: 'w1', passageRef: 'p1'),
        isNull,
      );
    });

    test('reports an improvement when the unknown ratio drops', () async {
      await read('p1', 1.0, DateTime.utc(2026, 1, 1), known: false); // 100%
      await read('p1', 0.0, DateTime.utc(2026, 2, 1), known: true); // 0%

      final delta =
          await latestPassageDelta(db, workId: 'w1', passageRef: 'p1');

      expect(delta, isNotNull);
      expect(delta!.isImprovement, isTrue);
      expect(delta.isRegression, isFalse);
      expect(delta.before.unknownRatio, 1.0);
      expect(delta.after.unknownRatio, 0.0);
    });

    test('reports a REGRESSION honestly when the passage got harder',
        () async {
      // Read it while known first, then after forgetting.
      await read('p1', 0.0, DateTime.utc(2026, 1, 1), known: true); // 0%
      await read('p1', 1.0, DateTime.utc(2026, 6, 1), known: false); // 100%

      final delta =
          await latestPassageDelta(db, workId: 'w1', passageRef: 'p1');

      expect(delta!.isRegression, isTrue);
      expect(delta.isImprovement, isFalse);
      expect(delta.unknownRatioChange, greaterThan(0)); // harder now
    });

    test('uses the two MOST RECENT readings, not the first two', () async {
      await read('p1', 1.0, DateTime.utc(2026, 1, 1), known: false);
      await read('p1', 1.0, DateTime.utc(2026, 2, 1), known: false);
      await read('p1', 0.0, DateTime.utc(2026, 3, 1), known: true); // latest

      final delta =
          await latestPassageDelta(db, workId: 'w1', passageRef: 'p1');

      // after = the March reading (known), before = the Feb reading.
      expect(delta!.after.unknownRatio, 0.0);
      expect(delta.before.unknownRatio, 1.0);
      expect(delta.after.ts.isAfter(delta.before.ts), isTrue);
    });
  });
}
