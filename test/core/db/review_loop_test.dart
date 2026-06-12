import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_service.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/srs/scheduler.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedJaPack(db);
    await db.addLearnItem('lang_ja', RefType.lexeme, 'lex_ja_dog');
  });

  tearDown(() async => db.close());

  test('new item is immediately due at rung 1', () async {
    final due = await db.getDueItems('lang_ja');
    expect(due.length, 1);
    expect(due.first.masteryRung, 1);
    expect(due.first.consecutiveCorrect, 0);
    expect(due.first.refType, 'lexeme');
    expect(due.first.refId, 'lex_ja_dog');
  });

  test('3 good results promote item from rung 1 to rung 2', () async {
    for (int i = 0; i < promotionThreshold; i++) {
      final item = (await db.select(db.learnItems).get()).first;
      final result = processResult(
        currentRung: item.masteryRung,
        consecutiveCorrect: item.consecutiveCorrect,
        scheduleInput: ScheduleInput(
          ease: item.ease,
          intervalDays: item.intervalDays,
          reps: item.reps,
        ),
        result: ReviewResult.good,
      );
      await db.applyReviewResult(item, result, ReviewResult.good);
    }

    final promoted = (await db.select(db.learnItems).get()).first;
    expect(promoted.masteryRung, 2);
    expect(promoted.consecutiveCorrect, 0);
  });

  test('again on rung 3 item demotes to rung 2 and increments lapses', () async {
    await db.addLearnItemAtRung(
      'lang_ja', RefType.character, 'char_ja_a',
      rung: 3,
    );

    final items = await db.select(db.learnItems).get();
    final item = items.firstWhere((i) => i.masteryRung == 3);

    final result = processResult(
      currentRung: item.masteryRung,
      consecutiveCorrect: item.consecutiveCorrect,
      scheduleInput: ScheduleInput(
        ease: item.ease,
        intervalDays: item.intervalDays,
        reps: item.reps,
      ),
      result: ReviewResult.again,
    );
    await db.applyReviewResult(item, result, ReviewResult.again);

    final updated = await (db.select(db.learnItems)
          ..where((t) => t.id.equals(item.id)))
        .getSingle();
    expect(updated.masteryRung, 2);
    expect(updated.lapses, 1);
    expect(updated.consecutiveCorrect, 0);
  });

  test('review_log records rung-before-result and result string', () async {
    final item = (await db.select(db.learnItems).get()).first;
    final result = processResult(
      currentRung: item.masteryRung,
      consecutiveCorrect: item.consecutiveCorrect,
      scheduleInput: ScheduleInput(
        ease: item.ease,
        intervalDays: item.intervalDays,
        reps: item.reps,
      ),
      result: ReviewResult.good,
    );
    await db.applyReviewResult(item, result, ReviewResult.good);

    final logs = await db.select(db.reviewLog).get();
    expect(logs.length, 1);
    expect(logs.first.result, 'good');
    expect(logs.first.rung, 1); // rung BEFORE update
    expect(logs.first.learnItemId, item.id);
  });

  test('item is not due after good review (interval=1 day)', () async {
    final item = (await db.select(db.learnItems).get()).first;
    final result = processResult(
      currentRung: item.masteryRung,
      consecutiveCorrect: item.consecutiveCorrect,
      scheduleInput: ScheduleInput(
        ease: item.ease,
        intervalDays: item.intervalDays,
        reps: item.reps,
      ),
      result: ReviewResult.good,
    );
    await db.applyReviewResult(item, result, ReviewResult.good);

    final due = await db.getDueItems('lang_ja');
    expect(due, isEmpty);
  });

  test('item is due again soon after again result', () async {
    final item = (await db.select(db.learnItems).get()).first;
    final result = processResult(
      currentRung: item.masteryRung,
      consecutiveCorrect: item.consecutiveCorrect,
      scheduleInput: ScheduleInput(
        ease: item.ease,
        intervalDays: item.intervalDays,
        reps: item.reps,
      ),
      result: ReviewResult.again,
    );
    await db.applyReviewResult(item, result, ReviewResult.again);

    // dueAt = now + 1 minute — still in the near future
    final updated = (await db.select(db.learnItems).get()).first;
    final minutesUntilDue =
        updated.dueAt.difference(DateTime.now()).inMinutes;
    expect(minutesUntilDue, lessThanOrEqualTo(2));
    expect(minutesUntilDue, greaterThanOrEqualTo(0));
  });
}
