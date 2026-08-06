import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/fsrs_knowledge_source.dart';
import 'package:nihongo_app/core/pipeline/knowledge_bridge.dart';
import 'package:nihongo_app/core/pipeline/passage_snapshot.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';

Token _tok(String lemma) => Token(
    surface: lemma, lemma: lemma, pos: 'n', charStart: 0, charEnd: lemma.length);

/// Seed one on-ramp lexeme + its learn_item at [rung] (FK enforcement is
/// off in the test DB, so the parent Language/Concept rows aren't needed).
Future<void> _seedLexeme(LearningDb db,
    {required String id, required String written, required int rung}) async {
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
        dueAt: DateTime.utc(2026, 8, 6),
      ));
}

void main() {
  test('knowledgeForRung: production rungs known, intro rungs learning', () {
    expect(KnowledgeBridge.knowledgeForRung(5), Knowledge.known);
    expect(KnowledgeBridge.knowledgeForRung(3), Knowledge.known);
    expect(KnowledgeBridge.knowledgeForRung(2), Knowledge.learning);
    expect(KnowledgeBridge.knowledgeForRung(1), Knowledge.learning);
  });

  group('backfill: on-ramp mastery → shared knowledge state (arch C)', () {
    late LearningDb learning;
    late MiningDb mining;
    late KnowledgeBridge bridge;

    setUp(() async {
      learning = LearningDb.forTesting();
      mining = MiningDb.forTesting();
      bridge = KnowledgeBridge(mining);
      await _seedLexeme(learning, id: 'neko', written: '猫', rung: 4); // mastered
      await _seedLexeme(learning, id: 'inu', written: '犬', rung: 2); // learning
      // A mastered CHARACTER must NOT bridge — it isn't a lemma.
      await learning.into(learning.learnItems).insert(LearnItemsCompanion.insert(
            id: 'li:char',
            languageId: 'ja',
            refType: 'character',
            refId: 'chr:x',
            masteryRung: Value(5),
            dueAt: DateTime.utc(2026, 8, 6),
          ));
    });

    tearDown(() async {
      await learning.close();
      await mining.close();
    });

    test('only lexemes project; rung maps to known/learning', () async {
      final r =
          await bridge.backfill(learning, languageId: 'ja', languageCode: 'ja');
      expect(r.lexemesProjected, 2); // the mastered character is ignored
      expect(r.knownCount, 1);
      expect(r.learningCount, 1);

      final knowledge = await FsrsKnowledgeSource.load(mining, languageCode: 'ja');
      expect(knowledge.call('猫'), Knowledge.known);
      expect(knowledge.call('犬'), Knowledge.learning);
      expect(knowledge.call('未知'), Knowledge.unknown); // never taught
    });

    test('mining unknownRatio drops once the on-ramp base is bridged', () async {
      final tokens = [_tok('猫'), _tok('犬'), _tok('未知')];

      final before = await FsrsKnowledgeSource.load(mining, languageCode: 'ja');
      expect(computeUnknownRatio(tokens, before.call), 1.0); // nothing known yet

      await bridge.backfill(learning, languageId: 'ja', languageCode: 'ja');

      final after = await FsrsKnowledgeSource.load(mining, languageCode: 'ja');
      // 猫 known + 犬 learning (both not-unknown), 未知 unknown → 1/3.
      expect(computeUnknownRatio(tokens, after.call), closeTo(1 / 3, 1e-9));
    });

    test('idempotent: re-running backfill does not duplicate rows', () async {
      await bridge.backfill(learning, languageId: 'ja', languageCode: 'ja');
      await bridge.backfill(learning, languageId: 'ja', languageCode: 'ja');
      expect(await mining.select(mining.cards).get(), hasLength(2));
      expect(await mining.select(mining.vocabItems).get(), hasLength(2));
    });
  });
}
