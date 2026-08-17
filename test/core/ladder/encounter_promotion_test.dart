import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';

void main() {
  late LearningDb db;
  setUp(() => db = LearningDb.forTesting());
  tearDown(() => db.close());

  test('introduce() inserts a new item at rung 0', () async {
    await LadderReview(db).introduce('lang_ja', RefType.character, 'char_a');
    final item = (await db.select(db.learnItems).get()).single;
    expect(item.masteryRung, 0);
  });

  test('markEncountered promotes rung 0 → 1 and schedules a future due', () async {
    await LadderReview(db).introduce('lang_ja', RefType.character, 'char_a');
    final before = (await db.select(db.learnItems).get()).single;
    expect(before.masteryRung, 0);

    await LadderReview(db).markEncountered(before);

    final after =
        await db.getLearnItem('lang_ja:character:char_a');
    expect(after, isNotNull);
    expect(after!.masteryRung, 1);
    // scheduled into the future — not immediately due again as a cold test
    expect(after.dueAt.isAfter(DateTime.now()), isTrue);
  });

  test('markEncountered writes no review_log row (it is ungraded)', () async {
    await LadderReview(db).introduce('lang_ja', RefType.character, 'char_a');
    final item = (await db.select(db.learnItems).get()).single;
    await LadderReview(db).markEncountered(item);
    final logs = await db.select(db.reviewLog).get();
    expect(logs, isEmpty);
  });
}
