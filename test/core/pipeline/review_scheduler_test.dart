import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/pipeline/review_scheduler.dart';

Future<void> _seedNewCard(MiningDb db, {required String cardId}) async {
  final vocabId = 'vocab:$cardId';
  final now = DateTime.now().toUtc();
  await db.into(db.vocabItems).insert(VocabItemsCompanion.insert(
        id: vocabId,
        languageCode: 'ja',
        lemma: '本',
        pos: 'n',
        createdAt: now,
      ));
  await db.into(db.cards).insert(CardsCompanion.insert(
        id: cardId,
        vocabItemId: vocabId,
        due: now,
        lastReview: now,
      ));
}

void main() {
  late MiningDb db;
  late ReviewScheduler scheduler;

  setUp(() {
    db = MiningDb.forTesting();
    scheduler = ReviewScheduler(db);
  });
  tearDown(() => db.close());

  group('ReviewScheduler.grade', () {
    test('a "good" review pushes the due date into the future', () async {
      await _seedNewCard(db, cardId: 'c1');
      final now = DateTime.utc(2026, 1, 1);

      final outcome = await scheduler.grade('c1', fsrs.Rating.good, now: now);

      expect(outcome.newDue.isAfter(now), isTrue);
    });

    test('grading persists the updated scheduling state to the card row',
        () async {
      await _seedNewCard(db, cardId: 'c1');
      final now = DateTime.utc(2026, 1, 1);

      await scheduler.grade('c1', fsrs.Rating.easy, now: now);

      final row =
          await (db.select(db.cards)..where((c) => c.id.equals('c1'))).getSingle();
      expect(row.state, isNot('newState')); // advanced past new
      expect(row.reps, greaterThan(0));
      expect(row.stability, greaterThan(0));
    });

    test('grading appends an immutable review-log row', () async {
      await _seedNewCard(db, cardId: 'c1');
      final now = DateTime.utc(2026, 1, 1);

      await scheduler.grade('c1', fsrs.Rating.good, now: now);

      final logs = await db.select(db.reviewLogs).get();
      expect(logs, hasLength(1));
      expect(logs.single.cardId, 'c1');
      expect(logs.single.rating, 'good');
      expect(logs.single.stabilityBefore, isNotNull);
      expect(logs.single.stabilityAfter, isNotNull);
    });

    test('the review log records stability before and after the review',
        () async {
      await _seedNewCard(db, cardId: 'c1');
      final now = DateTime.utc(2026, 1, 1);

      final outcome = await scheduler.grade('c1', fsrs.Rating.good, now: now);
      final log = (await db.select(db.reviewLogs).get()).single;

      expect(log.stabilityBefore, outcome.stabilityBefore);
      expect(log.stabilityAfter, outcome.stabilityAfter);
    });

    test('two reviews append two log rows (history accumulates)', () async {
      await _seedNewCard(db, cardId: 'c1');

      await scheduler.grade('c1', fsrs.Rating.good,
          now: DateTime.utc(2026, 1, 1));
      await scheduler.grade('c1', fsrs.Rating.good,
          now: DateTime.utc(2026, 1, 5));

      expect((await db.select(db.reviewLogs).get()), hasLength(2));
    });

    test('an "again" review keeps the item due soon (short interval)',
        () async {
      // Advance the card to a review state first so "again" is a lapse.
      await _seedNewCard(db, cardId: 'c1');
      await scheduler.grade('c1', fsrs.Rating.easy,
          now: DateTime.utc(2026, 1, 1));

      final againOutcome = await scheduler.grade('c1', fsrs.Rating.again,
          now: DateTime.utc(2026, 6, 1));

      // Due again within days, not the long easy interval.
      final daysUntilDue =
          againOutcome.newDue.difference(DateTime.utc(2026, 6, 1)).inDays;
      expect(daysUntilDue, lessThan(2));
    });
  });
}
