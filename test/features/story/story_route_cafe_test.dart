import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';
import 'package:nihongo_app/features/story/story_route.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('„Ins Café" von der Endkarte landet in der Nachbesprechung, '
      'und jedes Budget-Wort liegt vorher im Karteikasten', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final learning = LearningDb.forTesting();
    await seedJaPack(learning);
    addTearDown(() async => learning.close());

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWithValue(learning)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StoryRoute(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

    // Folge 01 V3: 10 Panels → 9 Taps bis zum letzten, ein 10. auf die
    // Endkarte. Die Route hängt immer Speak-/Trace-Evaluatoren ein; jedes
    // Sheet wird per Tap oberhalb geschlossen (Muster story_route_test).
    const sheetKeys = [
      ValueKey('dictionary-sheet'),
      ValueKey('diegetic-speak-sheet'),
      ValueKey('diegetic-trace-sheet'),
    ];
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      for (final key in sheetKeys) {
        if (find.byKey(key).evaluate().isNotEmpty) {
          await tester.tapAt(const Offset(400, 50));
          await tester.pumpAndSettle();
        }
      }
    }
    expect(find.byKey(const ValueKey('story-end-cafe')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('story-end-cafe')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-card')), findsOneWidget);
    final episode = loadFolge01();
    for (final ref in episode.budget.items) {
      final item = await learning
          .getLearnItem('lang_ja:${ref.refType.name}:${ref.id}');
      expect(item, isNotNull, reason: '${ref.id} lag nicht im Karteikasten');
    }
  });
}
