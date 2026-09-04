import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/pipeline/fsrs_knowledge_source.dart';
import 'package:nihongo_app/core/pipeline/knowledge_bridge.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart'
    show Knowledge;
import 'package:nihongo_app/features/story/diegetic_encounter.dart';

/// Mirrors `cafe_bridge_test.dart`'s `_knows` exactly: reads through
/// `FsrsKnowledgeSource.load`, the same canonical read path
/// `ReviewScreen`-parity code uses, filtered by mining's BCP-47
/// `languageCode`. This proves the diegetic encounter's projection lands
/// in the SAME bucket the rest of the app reads from — not just that some
/// row landed somewhere.
Future<Knowledge> _knows(MiningDb db, String lemma,
        {required String languageCode}) async =>
    (await FsrsKnowledgeSource.load(db, languageCode: languageCode))
        .call(lemma);

void main() {
  test('a diegetic encounter projects the item into mining under "ja", not '
      '"lang_ja"', () async {
    final learning = LearningDb.forTesting();
    final mining = MiningDb.forTesting();
    addTearDown(() async {
      await learning.close();
      await mining.close();
    });
    await learning.into(learning.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_rain',
        glossKey: 'rain',
        partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await learning.into(learning.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ame',
        languageId: 'lang_ja',
        conceptId: 'concept_rain',
        writtenForm: 'あめ',
        reading: 'あめ'));

    // Before: mining knows nothing about あめ under the canonical 'ja'
    // bucket.
    expect(await _knows(mining, 'あめ', languageCode: 'ja'), Knowledge.unknown);

    final enc = DiegeticEncounter(
      ladder: LadderReview(learning, bridge: KnowledgeBridge(mining)),
      languageId: 'lang_ja',
    );
    await enc.encounter(RefType.lexeme, 'lex_ja_ame');

    // markEncountered → rung 1 → Knowledge.learning, projected under 'ja'.
    expect(
        await _knows(mining, 'あめ', languageCode: 'ja'), Knowledge.learning);

    // Negative: nothing landed in the dead 'lang_ja' bucket (the on-ramp
    // pack id, not the BCP-47 mining code).
    final wrongBucket = await mining.select(mining.vocabItems).get()
      ..retainWhere((v) => v.languageCode == 'lang_ja');
    expect(wrongBucket, isEmpty);
    expect(await _knows(mining, 'あめ', languageCode: 'lang_ja'),
        Knowledge.unknown);
  });
}
