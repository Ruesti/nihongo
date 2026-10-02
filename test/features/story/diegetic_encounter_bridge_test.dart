import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/pipeline/fsrs_knowledge_source.dart';
import 'package:nihongo_app/core/pipeline/knowledge_bridge.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart' show Knowledge;
import 'package:nihongo_app/features/story/diegetic_encounter.dart';

Future<Knowledge> _knows(MiningDb db, String lemma,
        {required String languageCode}) async =>
    (await FsrsKnowledgeSource.load(db, languageCode: languageCode))
        .call(lemma);

void main() {
  test('ein diegetischer Encounter mit Bridge projiziert unter BCP-47 ja, '
      'nicht unter der Pack-ID lang_ja', () async {
    final learning = LearningDb.forTesting();
    final mining = MiningDb.forTesting();
    addTearDown(() async {
      await learning.close();
      await mining.close();
    });
    await learning.into(learning.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_dog',
        glossKey: 'dog',
        partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await learning.into(learning.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_dog',
        languageId: 'lang_ja',
        conceptId: 'concept_dog',
        writtenForm: '犬',
        reading: 'いぬ'));

    final encounter = DiegeticEncounter(
      ladder: LadderReview(learning, bridge: KnowledgeBridge(mining)),
      languageId: 'lang_ja',
      languageCode: 'ja',
    );
    await encounter.encounter(RefType.lexeme, 'lex_ja_dog');

    // Rung 1 → learning, im kanonischen 'ja'-Bucket …
    expect(await _knows(mining, '犬', languageCode: 'ja'), Knowledge.learning);
    // … und NICHTS im toten 'lang_ja'-Bucket.
    expect(await _knows(mining, '犬', languageCode: 'lang_ja'),
        Knowledge.unknown);
  });
}
