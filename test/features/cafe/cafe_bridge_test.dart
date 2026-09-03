import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/pipeline/fsrs_knowledge_source.dart';
import 'package:nihongo_app/core/pipeline/knowledge_bridge.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart'
    show Knowledge;
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';

/// Mirrors `ladder_review_test.dart`'s `_knows` exactly: reads through
/// `FsrsKnowledgeSource.load`, the same canonical read path
/// `ReviewScreen`-parity code uses, filtered by mining's BCP-47
/// `languageCode`. This proves the café's projection lands in the SAME
/// bucket the rest of the app reads from — not just that some row landed
/// somewhere.
Future<Knowledge> _knows(MiningDb db, String lemma,
        {required String languageCode}) async =>
    (await FsrsKnowledgeSource.load(db, languageCode: languageCode))
        .call(lemma);

void main() {
  testWidgets('a café turn with a bridge projects the reviewed lexeme into '
      'the shared mining store', (tester) async {
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
    await learning.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog',
        rung: 3);

    // Before: mining knows nothing about 犬 under the canonical 'ja' bucket.
    expect(await _knows(mining, '犬', languageCode: 'ja'), Knowledge.unknown);

    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(
        db: learning,
        guest: CafeGuest.schulkind, // rung 3 → productionInput
        bridge: KnowledgeBridge(mining),
      ),
    ));
    await tester.pumpAndSettle();

    // Produce the word (rung-3 prompt is the meaning; answer is the form).
    await tester.enterText(
        find.byKey(const ValueKey('cafe-turn-input')), '犬');
    await tester.tap(find.byKey(const ValueKey('cafe-turn-submit')));
    await tester.pumpAndSettle();

    // After: the graded review projected into mining under 'ja' — the same
    // bucket ReviewScreen and the KnowledgeBoot backfill use (rung 3 → known).
    expect(await _knows(mining, '犬', languageCode: 'ja'), Knowledge.known);

    // Negative: nothing landed in the dead 'lang_ja' bucket (the on-ramp
    // pack id, not the BCP-47 mining code). If this fails, the café is
    // still projecting to the wrong bucket.
    final wrongBucket = await mining.select(mining.vocabItems).get()
      ..retainWhere((v) => v.languageCode == 'lang_ja');
    expect(wrongBucket, isEmpty);
    expect(await _knows(mining, '犬', languageCode: 'lang_ja'),
        Knowledge.unknown);
  });
}
