import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/story/diegetic_encounter.dart';

void main() {
  late LearningDb learning;
  late DiegeticEncounter enc;

  setUp(() {
    learning = LearningDb.forTesting();
    enc = DiegeticEncounter(
      ladder: LadderReview(learning),
      languageId: 'lang_ja',
    );
  });

  tearDown(() async => learning.close());

  Future<LearnItem?> itemFor(String refId) =>
      (learning.select(learning.learnItems)..where((t) => t.refId.equals(refId)))
          .getSingleOrNull();

  test('a first diegetic encounter introduces the item and reaches rung 1',
      () async {
    await enc.encounter(RefType.lexeme, 'lex_ja_sumimasen');

    final item = await itemFor('lex_ja_sumimasen');
    expect(item, isNotNull);
    expect(item!.masteryRung, 1);
    expect(item.languageId, 'lang_ja');
  });

  test('encountering the same item twice stays at rung 1, no duplicate',
      () async {
    await enc.encounter(RefType.lexeme, 'lex_ja_sumimasen');
    await enc.encounter(RefType.lexeme, 'lex_ja_sumimasen');

    final rows = await (learning.select(learning.learnItems)
          ..where((t) => t.refId.equals('lex_ja_sumimasen')))
        .get();
    expect(rows, hasLength(1));
    expect(rows.single.masteryRung, 1);
  });

  test('an item already advanced beyond rung 0 is never demoted (INV-6)',
      () async {
    await learning.addLearnItemAtRung(
        'lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 4);

    await enc.encounter(RefType.lexeme, 'lex_ja_ame');

    final item = await itemFor('lex_ja_ame');
    expect(item!.masteryRung, 4);
  });
}
