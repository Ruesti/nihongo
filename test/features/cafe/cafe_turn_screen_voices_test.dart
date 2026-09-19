import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_guest_script.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_prompts.dart';
import 'package:nihongo_app/features/cafe/cafe_turn.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';

void main() {
  late LearningDb db;
  late List<LearnItem> items;

  const words = ['あめ', 'かさ', 'えき', 'みせ'];

  setUp(() async {
    db = LearningDb.forTesting();
    items = [];
    for (var i = 0; i < words.length; i++) {
      final concept = 'concept_$i';
      final lexeme = 'lex_ja_$i';
      await db.into(db.concepts).insert(ConceptsCompanion.insert(
          id: concept,
          glossKey: 'gloss_$i',
          partOfSpeech: 'noun',
          defaultAssetType: const Value('image')));
      await db.into(db.lexemes).insert(LexemesCompanion.insert(
          id: lexeme,
          languageId: 'lang_ja',
          conceptId: concept,
          writtenForm: words[i],
          reading: words[i]));
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, lexeme, rung: 1);
      items.add((await db.getLearnItem('lang_ja:lexeme:$lexeme'))!);
    }
  });
  tearDown(() async => db.close());

  Widget screen({List<CafeGuest>? speakers}) => MaterialApp(
        home: CafeTurnScreen(
          db: db,
          guest: CafeGuest.wirtin,
          initialQueue: items,
          speakers: speakers,
          doneLine: 'Ende.',
        ),
      );

  Future<void> answerKnown(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(ValueKey(key))).data!;

  testWidgets('ohne speakers: die Wirtin durchgehend — Stimm-Zeile über dem '
      'Wort, kein Sprecherwechsel, Reaktion von ihr', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsOneWidget);
    expect(textOf(tester, 'cafe-turn-voice'),
        scriptFor(CafeGuest.wirtin).voiceLine(CafeExerciseKind.recognition, 0));
    expect(find.byKey(const ValueKey('cafe-turn-handover')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-turn-entry')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    expect(textOf(tester, 'cafe-turn-followup'),
        scriptFor(CafeGuest.wirtin).followUp(CafeOutcome.correct, 0));

    // Auch der vierte Turn bleibt bei der Wirtin.
    await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await answerKnown(tester);
    }
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-handover')), findsNothing);
  });

  testWidgets('mit speakers [W,W,W,S]: ab Turn 4 fragt das Schulkind — '
      'Titel, Übergabe, Einstieg, eigene Stimme und Reaktion; am Ende wieder '
      'die Wirtin', (tester) async {
    await tester.pumpWidget(screen(speakers: const [
      CafeGuest.wirtin,
      CafeGuest.wirtin,
      CafeGuest.wirtin,
      CafeGuest.schulkind,
    ]));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(const ValueKey('cafe-turn-handover')), findsNothing);
      await answerKnown(tester);
    }

    expect(find.widgetWithText(AppBar, 'Das Schulkind'), findsOneWidget);
    expect(textOf(tester, 'cafe-turn-handover'), wirtinHandoverLine(1));
    expect(textOf(tester, 'cafe-turn-entry'),
        scriptFor(CafeGuest.schulkind).entry(0));
    expect(textOf(tester, 'cafe-turn-voice'),
        scriptFor(CafeGuest.schulkind)
            .voiceLine(CafeExerciseKind.recognition, 3));
    // Die Übungsform ist die der Sprosse (Erkennen), nicht die des
    // Schulkinds (Schreiben): Erkennen-Knöpfe, kein Eingabefeld.
    expect(find.byKey(const ValueKey('cafe-turn-known')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-input')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    expect(textOf(tester, 'cafe-turn-followup'),
        scriptFor(CafeGuest.schulkind).followUp(CafeOutcome.correct, 3));

    await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-turn-done-line')), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    expect(await db.select(db.reviewLog).get(), hasLength(4));
  });

  testWidgets('ein Plan falscher Länge wird ignoriert — Wirtin überall',
      (tester) async {
    await tester.pumpWidget(screen(speakers: const [CafeGuest.schulkind]));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    await answerKnown(tester);
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-handover')), findsNothing);
  });

  testWidgets('Wechsel zwischen zwei Gästen ohne Wirtin: Einstieg, aber keine '
      'Übergabe-Zeile', (tester) async {
    await tester.pumpWidget(screen(speakers: const [
      CafeGuest.vielredner,
      CafeGuest.vielredner,
      CafeGuest.vielredner,
      CafeGuest.gleichaltrige,
    ]));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Der Vielredner'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await answerKnown(tester);
    }
    expect(find.widgetWithText(AppBar, 'Die Gleichaltrige'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-handover')), findsNothing);
    expect(textOf(tester, 'cafe-turn-entry'),
        scriptFor(CafeGuest.gleichaltrige).entry(0));
  });

  testWidgets('Sprosse 2 (Lesen): die Stimm-Zeile der Lese-Form steht über '
      'dem Wort, das Eingabefeld bleibt', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_0', rung: 2);
    final item = (await db.getLearnItem('lang_ja:lexeme:lex_ja_0'))!;
    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(
          db: db, guest: CafeGuest.wirtin, initialQueue: [item]),
    ));
    await tester.pumpAndSettle();
    expect(textOf(tester, 'cafe-turn-voice'),
        scriptFor(CafeGuest.wirtin).voiceLine(CafeExerciseKind.readingInput, 0));
    expect(find.byKey(const ValueKey('cafe-turn-input')), findsOneWidget);
  });
}
