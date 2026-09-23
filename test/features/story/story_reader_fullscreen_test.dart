import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/reader_system_ui.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingSystemUi implements ReaderSystemUi {
  final List<String> calls = [];
  @override
  Future<void> enterImmersive() async => calls.add('enter');
  @override
  Future<void> exitImmersive() async => calls.add('exit');
}

Future<StoryProgressStore> freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return StoryProgressStore(await SharedPreferences.getInstance());
}

Future<void> noopSpeak(String text) async {}

/// Zwei Panels; Panel 1 hat Quer- und Hochbild und eine Blase mit beiden
/// Tippflächen, Panel 2 hat nur ein Querbild (Übergangsfall).
Episode twoFormatEpisode({String? cover, String? coverPortrait, String? titleJa}) =>
    Episode.fromJson({
      'id': 'ep_fullscreen',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Regen',
      'locale': 'ja',
      'era': '1996',
      if (cover != null) 'cover': cover,
      if (coverPortrait != null) 'coverPortrait': coverPortrait,
      if (titleJa != null) 'titleJa': titleJa,
      'budget': {'items': [], 'glyphs': []},
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'assets/story/p01.jpg',
              'assetPortrait': 'assets/story/p01_hoch.jpg',
              'bubbles': [
                {
                  'speakerId': 'signage',
                  'text': 'みなみまち駅',
                  'hitArea': [
                    {'x': 0.06, 'y': 0.05},
                    {'x': 0.48, 'y': 0.05},
                    {'x': 0.48, 'y': 0.18},
                    {'x': 0.06, 'y': 0.18},
                  ],
                  'hitAreaPortrait': [
                    {'x': 0.10, 'y': 0.10},
                    {'x': 0.50, 'y': 0.10},
                    {'x': 0.50, 'y': 0.30},
                    {'x': 0.10, 'y': 0.30},
                  ],
                  'tokens': [
                    {'surface': '駅', 'reading': 'えき', 'itemId': 'lex_ja_eki'},
                  ],
                },
              ],
              'thoughts': [
                {'text': 'Das ist Mira.'},
              ],
              'interactions': [],
            },
            {
              'index': 1,
              'asset': 'assets/story/p02.jpg',
              'bubbles': [
                {'speakerId': 'narrator', 'text': 'Zweites Panel', 'tokens': []},
              ],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    });

Future<void> pumpReader(WidgetTester tester, Episode episode,
    {required StoryProgressStore store, RecordingSystemUi? ui}) async {
  await tester.pumpWidget(MaterialApp(
    home: StoryReaderScreen(
      episode: episode,
      progressStore: store,
      speak: noopSpeak,
      dictionaryEntries: const [],
      knownIds: const {},
      systemUi: ui ?? RecordingSystemUi(),
    ),
  ));
  await tester.pump();
}

/// Schirm in logischen Pixeln setzen (S23 = 1080×2340 physisch, hier /2).
void setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Vollbild-Adapter (Spec §7.1)', () {
    testWidgets('Lesephase schaltet Vollbild ein, Endkarte wieder aus',
        (tester) async {
      final ui = RecordingSystemUi();
      await pumpReader(tester, twoFormatEpisode(), store: await freshStore(), ui: ui);
      expect(ui.calls, isEmpty, reason: 'Titelkarte zeigt die Leisten noch');

      await tester.tap(find.byKey(const ValueKey('story-title-card')));
      await tester.pumpAndSettle();
      expect(ui.calls, ['enter']);

      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('story-end-card')), findsOneWidget);
      expect(ui.calls, ['enter', 'exit']);
    });

    testWidgets('Reader verlassen mitten in der Folge stellt die Leisten wieder her',
        (tester) async {
      final ui = RecordingSystemUi();
      await pumpReader(tester, twoFormatEpisode(), store: await freshStore(), ui: ui);
      await tester.tap(find.byKey(const ValueKey('story-title-card')));
      await tester.pumpAndSettle();
      expect(ui.calls, ['enter']);

      await tester.pumpWidget(const SizedBox()); // Route weg → dispose
      await tester.pump();
      expect(ui.calls, ['enter', 'exit']);
    });

    testWidgets('Wiedereinstieg mitten in der Folge schaltet sofort Vollbild ein',
        (tester) async {
      final store = await freshStore();
      await store.savePosition('ep_fullscreen', 1);
      final ui = RecordingSystemUi();
      await pumpReader(tester, twoFormatEpisode(), store: store, ui: ui);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('story-title-card')), findsNothing);
      expect(ui.calls, ['enter']);
    });
  });

  group('Lesephase als Vollbild (Spec §7.1/§7.2)', () {
    Future<void> startReading(WidgetTester tester, {RecordingSystemUi? ui}) async {
      await pumpReader(tester, twoFormatEpisode(), store: await freshStore(), ui: ui);
      await tester.tap(find.byKey(const ValueKey('story-title-card')));
      await tester.pumpAndSettle();
    }

    String shownAsset(WidgetTester tester) {
      final img = tester.widget<Image>(find.byKey(const ValueKey('story-panel-image')));
      return (img.image as AssetImage).assetName;
    }

    testWidgets('hochkant zeigt das Hochbild, quer das Querbild', (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      expect(shownAsset(tester), 'assets/story/p01_hoch.jpg');

      setScreen(tester, const Size(1170, 540));
      await tester.pumpAndSettle();
      expect(shownAsset(tester), 'assets/story/p01.jpg');
    });

    testWidgets('Panel ohne Hochbild zeigt hochkant das Querbild', (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      expect(shownAsset(tester), 'assets/story/p02.jpg');
      expect(find.byKey(const ValueKey('story-bubble-footer')), findsOneWidget);
      expect(find.text('Zweites Panel'), findsOneWidget);
    });

    testWidgets('das Bild füllt den Schirm (Cover-Rechteck), nicht nur die Breite',
        (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      final rect = tester.getRect(find.byKey(const ValueKey('story-panel-image')));
      expect(rect.height, closeTo(1170, 0.5));
      expect(rect.width, closeTo(1170 * (1080 / 1936), 0.5));
      expect(rect.left, closeTo((540 - rect.width) / 2, 0.5));
    });

    testWidgets('Tippfläche liegt relativ zum beschnittenen Bild, hochkant aus hitAreaPortrait',
        (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      final imageW = 1170 * (1080 / 1936);
      final imageLeft = (540 - imageW) / 2;
      final hit = tester.getRect(find.byKey(const ValueKey('story-bubble-hit-0')));
      expect(hit.left, closeTo(imageLeft + 0.10 * imageW, 0.5));
      expect(hit.top, closeTo(0.10 * 1170, 0.5));
      expect(hit.width, closeTo(0.40 * imageW, 0.5));
      expect(hit.height, closeTo(0.20 * 1170, 0.5));
    });

    testWidgets('quer: Tippfläche aus hitArea, mit negativem Versatz oben', (tester) async {
      setScreen(tester, const Size(1170, 540));
      await startReading(tester);
      final imageH = 1170 / (1920 / 1072);
      final imageTop = (540 - imageH) / 2; // negativ
      final hit = tester.getRect(find.byKey(const ValueKey('story-bubble-hit-0')));
      expect(hit.left, closeTo(0.06 * 1170, 0.5));
      expect(hit.top, closeTo(imageTop + 0.05 * imageH, 0.5));
      expect(hit.width, closeTo(0.42 * 1170, 0.5));
    });

    testWidgets('Tipp auf die Tippfläche öffnet weiterhin das Wörterbuch', (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      await tester.tap(find.byKey(const ValueKey('story-bubble-hit-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dictionary-sheet')), findsOneWidget);
    });

    testWidgets('Drehen mitten in der Folge behält die Position', (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      expect(shownAsset(tester), 'assets/story/p02.jpg');

      setScreen(tester, const Size(1170, 540));
      await tester.pumpAndSettle();
      expect(shownAsset(tester), 'assets/story/p02.jpg');
      expect(find.text('Zweites Panel'), findsOneWidget);
    });

    testWidgets('Gedanken-Kasten und Zurück-Chip liegen im Bild, keine AppBar mehr',
        (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const ValueKey('story-thought-box')), findsOneWidget);
      expect(find.text('Das ist Mira.'), findsOneWidget);
      final back = tester.widget<IconButton>(find.byKey(const ValueKey('story-reader-back')));
      expect(back.onPressed, isNull, reason: 'auf Panel 1 gesperrt');
    });
  });
}
