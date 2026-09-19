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

  Widget screen({List<CafeGuest>? speakers, int lineOffset = 0}) => MaterialApp(
        home: CafeTurnScreen(
          db: db,
          guest: CafeGuest.wirtin,
          initialQueue: items,
          speakers: speakers,
          lineOffset: lineOffset,
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

  testWidgets('lineOffset rotiert Übergabe, Einstieg und Stimm-Zeile '
      '(Final-Review F2); 0 verhält sich wie bisher', (tester) async {
    await tester.pumpWidget(screen(
        speakers: const [
          CafeGuest.wirtin,
          CafeGuest.wirtin,
          CafeGuest.wirtin,
          CafeGuest.schulkind,
        ],
        lineOffset: 1));
    await tester.pumpAndSettle();

    expect(textOf(tester, 'cafe-turn-voice'),
        scriptFor(CafeGuest.wirtin).voiceLine(CafeExerciseKind.recognition, 1));

    for (var i = 0; i < 3; i++) {
      await answerKnown(tester);
    }

    expect(textOf(tester, 'cafe-turn-handover'), wirtinHandoverLine(2));
    expect(textOf(tester, 'cafe-turn-entry'),
        scriptFor(CafeGuest.schulkind).entry(1));
  });

  testWidgets('ein übersprungenes Item (fehlende Lexem-Zeile) verschluckt '
      'den Blockwechsel nicht (Final-Review F4)', (tester) async {
    // Ghost-Item wie in cafe_debrief_screen_test „ohne Lexem-Zeile wird
    // übersprungen": ein Karteikasten-Eintrag ohne passende Lexem-Zeile.
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ghost',
        rung: 1);
    final ghost = (await db.getLearnItem('lang_ja:lexeme:lex_ja_ghost'))!;

    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_4',
        glossKey: 'gloss_4',
        partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_4',
        languageId: 'lang_ja',
        conceptId: 'concept_4',
        writtenForm: 'そら',
        reading: 'そら'));
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_4',
        rung: 1);
    final fifth = (await db.getLearnItem('lang_ja:lexeme:lex_ja_4'))!;

    final queue = [...items.sublist(0, 3), ghost, fifth];

    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(
        db: db,
        guest: CafeGuest.wirtin,
        initialQueue: queue,
        speakers: const [
          CafeGuest.wirtin,
          CafeGuest.wirtin,
          CafeGuest.wirtin,
          CafeGuest.schulkind,
          CafeGuest.schulkind,
        ],
        doneLine: 'Ende.',
      ),
    ));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await answerKnown(tester);
    }
    // Item 4 (Index 3) fehlt die Lexem-Zeile und wird übersprungen — Item 5
    // (Index 4, Schulkind) muss trotzdem Übergabe und Einstieg zeigen; der
    // übersprungene Turn darf den Wechsel nicht verschlucken.
    expect(find.widgetWithText(AppBar, 'Das Schulkind'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-handover')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-entry')), findsOneWidget);
  });

  testWidgets('Turn-Körper mit Übergabe, Einstieg und aufgedeckter Antwort '
      'passt auf einen kleinen Schirm — Scroll statt Overflow (Final-Review '
      'F5)', (tester) async {
    await tester.pumpWidget(screen(speakers: const [
      CafeGuest.wirtin,
      CafeGuest.wirtin,
      CafeGuest.wirtin,
      CafeGuest.schulkind,
    ]));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await answerKnown(tester);
    }
    // Jetzt zeigt der Schirm den ersten Schulkind-Turn (Übergabe + Einstieg
    // + eigene Stimme) auf der großzügigen Test-Fläche — erst jetzt auf
    // Telefongröße schrumpfen, damit die unauffälligen Turns davor nicht
    // mit hineinspielen.
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-turn-handover')), findsOneWidget);
    // Der Körper ist jetzt tatsächlich länger als der Schirm — sonst prüft
    // der Test darunter gar nichts (kein Absturz durch bloßes Fehlen).
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scroll.position.maxScrollExtent, greaterThan(0));

    // Aufgedeckte Antwort macht den Körper noch etwas länger.
    await tester.ensureVisible(find.byKey(const ValueKey('cafe-turn-reveal')));
    await tester.tap(find.byKey(const ValueKey('cafe-turn-reveal')));
    await tester.pumpAndSettle();

    // Der Knopf ist erreichbar (scrollen statt Overflow) und tippbar.
    await tester.ensureVisible(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-turn-followup')), findsOneWidget);
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
