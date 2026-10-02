import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Episode _twoPanels() => Episode.fromJson({
      'id': 'ep_end',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'outro': 'Hinter dieser Tür fängt der Rest an.',
      'budget': {'items': [], 'glyphs': []},
      'pages': [
        {
          'index': 0,
          'panels': [
            for (var i = 0; i < 2; i++)
              {
                'index': i,
                'asset': 'assets/comic/placeholder_page.png',
                'bubbles': [],
                'thoughts': [],
                'interactions': [],
              },
          ],
        },
      ],
    });

void main() {
  late StoryProgressStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = StoryProgressStore(await SharedPreferences.getInstance());
  });

  Widget reader({Future<void> Function()? onEnterCafe}) => MaterialApp(
        home: StoryReaderScreen(
          episode: _twoPanels(),
          progressStore: store,
          speak: (_) async {},
          dictionaryEntries: const [],
          knownIds: const {},
          onEnterCafe: onEnterCafe,
        ),
      );

  Future<void> readToEnd(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-end-card')), findsOneWidget);
  }

  testWidgets('mit onEnterCafe: „Ins Café" (ruft den Weg) und „Später"',
      (tester) async {
    var entered = false;
    await tester.pumpWidget(reader(onEnterCafe: () async => entered = true));
    await readToEnd(tester);
    expect(find.byKey(const ValueKey('story-end-cafe')), findsOneWidget);
    expect(find.text('Ins Café'), findsOneWidget);
    expect(find.byKey(const ValueKey('story-end-done')), findsOneWidget);
    expect(find.text('Später'), findsOneWidget);
    // Kein Gate: die Folge gilt schon als gelesen, egal was jetzt kommt.
    expect(await store.isCompleted('ep_end'), isTrue);
    await tester.tap(find.byKey(const ValueKey('story-end-cafe')));
    await tester.pump();
    expect(entered, isTrue);
  });

  testWidgets('ohne onEnterCafe bleibt „Zurück zum Lesen"', (tester) async {
    await tester.pumpWidget(reader());
    await readToEnd(tester);
    expect(find.byKey(const ValueKey('story-end-cafe')), findsNothing);
    expect(find.text('Zurück zum Lesen'), findsOneWidget);
  });
}
