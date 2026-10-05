import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'story_reader_fullscreen_test.dart' show RecordingSystemUi;

const _hitA = [
  {'x': 0.1, 'y': 0.1},
  {'x': 0.3, 'y': 0.1},
  {'x': 0.3, 'y': 0.2},
  {'x': 0.1, 'y': 0.2},
];
const _hitB = [
  {'x': 0.6, 'y': 0.6},
  {'x': 0.8, 'y': 0.6},
  {'x': 0.8, 'y': 0.7},
  {'x': 0.6, 'y': 0.7},
];

/// Schutz-Test: Seit 5.10. (Spec Mira schweigt §4) lehnt der Validator
/// tokenlose Mira-Blasen ab, Folgen haben keine „…“-Blase mehr. Der Reader
/// hält eine solche Blase trotzdem inert — die Fixture wird bewusst nicht
/// validiert.
Episode _silenceEpisode({required bool withHitAreas}) => Episode.fromJson({
      'id': 'ep_silence',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Stille',
      'locale': 'ja',
      'era': '1996',
      'budget': {
        'items': [
          {'id': 'lex_a', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [
        {
          'index': 1,
          'panels': [
            {
              'index': 1,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'passant',
                  'text': 'あ、あ',
                  'hitArea': withHitAreas ? _hitA : [],
                  'tokens': [
                    {'surface': 'あ', 'itemId': 'lex_a'},
                    {'surface': 'あ', 'itemId': 'lex_a'},
                  ],
                },
                {
                  'speakerId': 'protagonist',
                  'text': '…',
                  'hitArea': withHitAreas ? _hitB : [],
                  'tokens': [],
                },
              ],
              'thoughts': [],
              'interactions': [
                {
                  'type': 'silent',
                  'diegetic': true,
                  'target': 'あ',
                  'targetItemIds': ['lex_a'],
                },
              ],
            },
            {
              'index': 2,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    });

Future<List<String>> _openReading(WidgetTester tester, Episode episode) async {
  SharedPreferences.setMockInitialValues({});
  final store = StoryProgressStore(await SharedPreferences.getInstance());
  final spoken = <String>[];
  await tester.pumpWidget(MaterialApp(
    home: StoryReaderScreen(
      episode: episode,
      progressStore: store,
      speak: (t) async => spoken.add(t),
      dictionaryEntries: const [],
      knownIds: const {},
      systemUi: RecordingSystemUi(),
    ),
  ));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('story-title-card')));
  await tester.pumpAndSettle();
  return spoken;
}

void main() {
  testWidgets('die „…“-Blase hat keine Tippfläche und liest nichts vor',
      (tester) async {
    final spoken =
        await _openReading(tester, _silenceEpisode(withHitAreas: true));

    expect(find.byKey(const ValueKey('story-bubble-hit-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-bubble-hit-1')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-bubble-hit-0')));
    await tester.pump();
    expect(spoken, ['あ、あ']);
  });

  testWidgets('die „…“-Blase landet nicht in der Fußzeile', (tester) async {
    await _openReading(tester, _silenceEpisode(withHitAreas: false));
    // Die gehörte Blase ohne Tippfläche steht in der Fußzeile, die „…“ nicht.
    expect(find.byKey(const ValueKey('story-bubble-footer')), findsOneWidget);
    expect(
      find.descendant(
          of: find.byKey(const ValueKey('story-bubble-footer')),
          matching: find.text('…')),
      findsNothing,
    );
  });
}
