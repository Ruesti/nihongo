import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/pipeline/fsrs_knowledge_source.dart';
import 'package:nihongo_app/core/pipeline/knowledge_bridge.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';
import 'package:nihongo_app/core/srs/scheduler.dart';

Future<void> _seedLexeme(LearningDb db,
    {required String id,
    required String written,
    required int rung,
    int consecutive = 0}) async {
  await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex:$id',
        languageId: 'ja',
        conceptId: 'c:$id',
        writtenForm: written,
        reading: written,
      ));
  await db.into(db.learnItems).insert(LearnItemsCompanion.insert(
        id: 'li:$id',
        languageId: 'ja',
        refType: 'lexeme',
        refId: 'lex:$id',
        masteryRung: Value(rung),
        consecutiveCorrect: Value(consecutive),
        dueAt: DateTime.utc(2026, 8, 6),
      ));
}

Future<LearnItem> _byId(LearningDb db, String id) =>
    (db.select(db.learnItems)..where((t) => t.id.equals(id))).getSingle();

Future<Knowledge> _knows(MiningDb db, String lemma) async =>
    (await FsrsKnowledgeSource.load(db, languageCode: 'ja')).call(lemma);

void main() {
  late LearningDb learning;
  late MiningDb mining;
  late LadderReview review;

  setUp(() {
    learning = LearningDb.forTesting();
    mining = MiningDb.forTesting();
    review = LadderReview(learning, bridge: KnowledgeBridge(mining));
  });

  tearDown(() async {
    await learning.close();
    await mining.close();
  });

  test('promotion to a production rung projects the lexeme as known',
      () async {
    await _seedLexeme(learning, id: 'neko', written: '猫', rung: 3, consecutive: 2);
    await review.submit(await _byId(learning, 'li:neko'), ReviewResult.good);

    expect((await _byId(learning, 'li:neko')).masteryRung, 4); // promoted
    expect(await _knows(mining, '猫'), Knowledge.known);
  });

  test('demotion below production re-projects the lexeme as learning',
      () async {
    await _seedLexeme(learning, id: 'neko', written: '猫', rung: 3);
    await review.submit(await _byId(learning, 'li:neko'), ReviewResult.again);

    expect((await _byId(learning, 'li:neko')).masteryRung, 2); // demoted
    expect(await _knows(mining, '猫'), Knowledge.learning);
  });

  test('a mastered character does not project (not a lemma)', () async {
    await learning.into(learning.learnItems).insert(LearnItemsCompanion.insert(
          id: 'li:char',
          languageId: 'ja',
          refType: 'character',
          refId: 'chr:x',
          masteryRung: Value(3),
          consecutiveCorrect: Value(2),
          dueAt: DateTime.utc(2026, 8, 6),
        ));
    await review.submit(await _byId(learning, 'li:char'), ReviewResult.good);
    expect(await mining.select(mining.vocabItems).get(), isEmpty);
  });

  test('introduce creates a rung-1 item and projects it as learning',
      () async {
    await learning.into(learning.lexemes).insert(LexemesCompanion.insert(
          id: 'lex:inu',
          languageId: 'ja',
          conceptId: 'c:inu',
          writtenForm: '犬',
          reading: '犬',
        ));
    await review.introduce('ja', RefType.lexeme, 'lex:inu');

    final item = await (learning.select(learning.learnItems)
          ..where((t) => t.refId.equals('lex:inu')))
        .getSingle();
    expect(item.masteryRung, 1);
    expect(await _knows(mining, '犬'), Knowledge.learning);
  });

  test('without a bridge, applying a review leaves mining untouched',
      () async {
    final noBridge = LadderReview(learning); // bridge null → dormant seam
    await _seedLexeme(learning, id: 'neko', written: '猫', rung: 3, consecutive: 2);
    await noBridge.submit(await _byId(learning, 'li:neko'), ReviewResult.good);
    expect(await mining.select(mining.vocabItems).get(), isEmpty);
  });
}
