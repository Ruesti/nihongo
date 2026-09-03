import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/pipeline/knowledge_bridge.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart'
    show Knowledge;
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';

/// Mirrors `ladder_review_test.dart`'s `_knows`, but reads FSRS card state
/// directly instead of going through `FsrsKnowledgeSource.load` (which
/// filters by `languageCode`). `VocabItems` has no `masteryRung` column
/// (that's an on-ramp-only field, per `KnowledgeBridge`'s doc comment) —
/// mining's own knowledge signal is the joined `Cards` row's FSRS
/// `state`/`stability`. This helper deliberately does not filter by
/// `languageCode`: proving the reviewed lemma projected is the point of
/// this test, not pinning `CafeTurnScreen`'s existing (pre-Task-1)
/// `languageCode: widget.languageId` passthrough to the bridge.
Future<Knowledge> _knows(MiningDb db, String lemma) async {
  final query = db.select(db.vocabItems).join([
    innerJoin(db.cards, db.cards.vocabItemId.equalsExp(db.vocabItems.id)),
  ])
    ..where(db.vocabItems.lemma.equals(lemma));
  final rows = await query.get();
  if (rows.isEmpty) return Knowledge.unknown;
  final card = rows.first.readTable(db.cards);
  return (card.state == 'review' && card.stability >= 5.0)
      ? Knowledge.known
      : Knowledge.learning;
}

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

    // Before: mining knows nothing about 犬.
    expect(await _knows(mining, '犬'), Knowledge.unknown);

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

    // After: the graded review projected into mining (rung 3 → known).
    expect(await _knows(mining, '犬'), Knowledge.known);
  });
}
