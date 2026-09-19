import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/cafe/cafe_screen.dart';

void main() {
  late LearningDb db;
  setUp(() => db = LearningDb.forTesting());
  tearDown(() async {
    // Image.asset lädt asynchron; ohne Leeren spricht der imageCache
    // zwischen Tests über (flaky) — wie in PR #46.
    imageCache.clear();
    imageCache.clearLiveImages();
    await db.close();
  });

  // Eine Miniatur trägt seit D1 (Final-Review 19.9.) ein `cacheWidth` und
  // damit einen ResizeImage-Provider statt eines nackten AssetImage —
  // durchgreifen auf den zugrundeliegenden Provider.
  String assetOf(WidgetTester tester, String key) {
    final p = tester.widget<Image>(find.byKey(ValueKey(key))).image;
    final a = p is ResizeImage ? p.imageProvider : p;
    return (a as AssetImage).assetName;
  }

  testWidgets('nothing due → the café is calmly empty, with no count or '
      '"0 due" message', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-guest-list')), findsNothing);
    // Nothing that reads like a due count leaks into the empty state.
    expect(find.textContaining('0'), findsNothing);
    expect(find.textContaining('fällig'), findsNothing);
  });

  testWidgets('due items at rung 1 and 3 → only the Wirtin and Schulkind '
      'are present', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_a', rung: 1);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_b', rung: 3);

    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-empty')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-guest-wirtin')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-guest-schulkind')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-guest-vielredner')), findsNothing);
    expect(
        find.byKey(const ValueKey('cafe-guest-gleichaltrige')), findsNothing);
  });

  testWidgets('occupancy is computed once on entry (stable for the session)',
      (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_a', rung: 3);
    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-guest-schulkind')), findsOneWidget);

    // Adding more due items after entry does NOT change this session's café.
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_b', rung: 5);
    // Force build() to run again on the SAME State (same widget config →
    // Element/State reused, no re-init). Occupancy is cached from initState,
    // so a rebuild must NOT surface the newly-due rung-5 item.
    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('cafe-guest-gleichaltrige')), findsNothing);
  });

  testWidgets('tapping a present guest opens that guest\'s turn screen',
      (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_x', rung: 3);

    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cafe-guest-schulkind')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-turn-screen')), findsOneWidget);
  });

  testWidgets('leer: die Wirtin am Tresen im Licht der Stunde', (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: CafeScreen(db: db, light: CafeLight.abend)));
    await tester.pumpAndSettle();
    expect(assetOf(tester, 'cafe-scene-empty'),
        sceneAsset(CafeMotif.wirtinTresen, CafeLight.abend));
    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);
  });

  testWidgets('belegt: der Raum als Kopfbild, je Gast sein Stammplatz als '
      'Miniatur', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_a', rung: 1);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_b', rung: 3);
    await tester.pumpWidget(
        MaterialApp(home: CafeScreen(db: db, light: CafeLight.nacht)));
    await tester.pumpAndSettle();
    expect(assetOf(tester, 'cafe-scene-room'),
        sceneAsset(CafeMotif.leer, CafeLight.nacht));
    expect(assetOf(tester, 'cafe-scene-guest-wirtin'),
        sceneAsset(stammplatzOf(CafeGuest.wirtin), CafeLight.nacht));
    expect(assetOf(tester, 'cafe-scene-guest-schulkind'),
        sceneAsset(stammplatzOf(CafeGuest.schulkind), CafeLight.nacht));
    expect(find.byKey(const ValueKey('cafe-scene-guest-vielredner')),
        findsNothing);
  });
}
