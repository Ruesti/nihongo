import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';

void main() {
  late LearningDb db;
  late List<LearnItem> items;
  const words = ['あめ', 'かさ', 'えき', 'みせ'];

  setUp(() async {
    db = LearningDb.forTesting();
    items = [];
    for (var i = 0; i < words.length; i++) {
      await db.into(db.concepts).insert(ConceptsCompanion.insert(
          id: 'concept_$i', glossKey: 'gloss_$i', partOfSpeech: 'noun',
          defaultAssetType: const Value('image')));
      await db.into(db.lexemes).insert(LexemesCompanion.insert(
          id: 'lex_ja_$i', languageId: 'lang_ja', conceptId: 'concept_$i',
          writtenForm: words[i], reading: words[i]));
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_$i', rung: 1);
      items.add((await db.getLearnItem('lang_ja:lexeme:lex_ja_$i'))!);
    }
  });
  tearDown(() async {
    imageCache.clear();
    imageCache.clearLiveImages();
    await db.close();
  });

  String assetOf(WidgetTester tester, String key) =>
      (tester.widget<Image>(find.byKey(ValueKey(key))).image as AssetImage)
          .assetName;

  Future<void> answerKnown(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
    await tester.pumpAndSettle();
  }

  Widget screen({List<CafeGuest>? speakers}) => MaterialApp(
        home: CafeTurnScreen(
          db: db,
          guest: CafeGuest.wirtin,
          initialQueue: items,
          speakers: speakers,
          light: CafeLight.abend,
        ),
      );

  testWidgets('die Szene gehört dem Sprecher des Blocks und wechselt mit ihm',
      (tester) async {
    await tester.pumpWidget(screen(speakers: const [
      CafeGuest.wirtin, CafeGuest.wirtin, CafeGuest.wirtin, CafeGuest.schulkind,
    ]));
    await tester.pumpAndSettle();
    expect(assetOf(tester, 'cafe-turn-scene'),
        turnScene(CafeGuest.wirtin, CafeLight.abend, 0));
    await answerKnown(tester);
    // Innerhalb des Blocks bleibt das Bild (ein Bild pro Block, §3.3).
    expect(assetOf(tester, 'cafe-turn-scene'),
        turnScene(CafeGuest.wirtin, CafeLight.abend, 0));
    await answerKnown(tester);
    await answerKnown(tester);
    expect(assetOf(tester, 'cafe-turn-scene'),
        turnScene(CafeGuest.schulkind, CafeLight.abend, 0));
    // Steuerung bleibt ohne Scrollen erreichbar.
    expect(find.byKey(const ValueKey('cafe-turn-known')), findsOneWidget);
  });

  testWidgets('zweiter Block desselben Sprechers → nächster Moment',
      (tester) async {
    await tester.pumpWidget(screen()); // Wirtin überall → Blöcke 0 und 1
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await answerKnown(tester);
    }
    expect(assetOf(tester, 'cafe-turn-scene'),
        turnScene(CafeGuest.wirtin, CafeLight.abend, 1));
  });

  testWidgets('bei offener Tastatur klappt die Szene auf ein Band',
      (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('cafe-turn-scene'))).height,
        200);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('cafe-turn-scene'))).height,
        72);
  });
}
