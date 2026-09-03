import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_rain', glossKey: 'rain', partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ame', languageId: 'lang_ja', conceptId: 'concept_rain',
        writtenForm: 'あめ', reading: 'あめ'));
  });
  tearDown(() async => db.close());

  Future<int> reviewLogCount() async =>
      (await db.select(db.reviewLog).get()).length;

  testWidgets('the Schulkind poses a rung-3 production turn; a correct answer '
      'grades it (a review is logged) and a followUp appears', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame',
        rung: 3);

    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(db: db, guest: CafeGuest.schulkind),
    ));
    await tester.pumpAndSettle();

    // The prompt is the meaning; the learner types the word.
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsOneWidget);
    expect(await reviewLogCount(), 0);

    await tester.enterText(
        find.byKey(const ValueKey('cafe-turn-input')), 'あめ');
    await tester.tap(find.byKey(const ValueKey('cafe-turn-submit')));
    await tester.pumpAndSettle();

    // A grade was submitted to the ladder, and the guest reacted.
    expect(await reviewLogCount(), 1);
    expect(find.byKey(const ValueKey('cafe-turn-followup')), findsOneWidget);
  });

  testWidgets('using the meaning hint dodges — still graded, and the guest '
      'reacts to a hinted turn', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame',
        rung: 3);

    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(db: db, guest: CafeGuest.schulkind),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cafe-turn-hint')));
    await tester.pumpAndSettle();
    // After a hint the word is revealed; typing it is still a dodge.
    await tester.enterText(
        find.byKey(const ValueKey('cafe-turn-input')), 'あめ');
    await tester.tap(find.byKey(const ValueKey('cafe-turn-submit')));
    await tester.pumpAndSettle();

    expect(await reviewLogCount(), 1);
    expect(find.byKey(const ValueKey('cafe-turn-followup')), findsOneWidget);
  });

  testWidgets('a guest with no due items shows the done/empty state',
      (tester) async {
    // Nothing seeded as due → the Schulkind has nobody to talk to.
    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(db: db, guest: CafeGuest.schulkind),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-turn-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsNothing);
  });
}
