import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/story/pilot_01_regen_fixture.dart';

Episode _twoPanelEpisode() => Episode.fromJson({
      'id': 'ep_test_reader',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Test Episode',
      'locale': 'ja',
      'era': '1996',
      'budget': {'items': [], 'glyphs': []},
      'pages': [
        {
          'index': 1,
          'panels': [
            {
              'index': 1,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'narrator',
                  'text': 'First panel text',
                  'tokens': [],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 2,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'narrator',
                  'text': 'Second panel text',
                  'tokens': [],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    });

Future<StoryProgressStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return StoryProgressStore(await SharedPreferences.getInstance());
}

Future<void> _noopSpeak(String text) async {}

void main() {
  testWidgets('shows the first panel and advances to the next on tap',
      (tester) async {
    final store = await _freshStore();

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _twoPanelEpisode(),
        progressStore: store,
        speak: _noopSpeak,
      ),
    ));
    await tester.pump();

    expect(find.text('First panel text'), findsOneWidget);
    expect(find.text('Second panel text'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pump();

    expect(find.text('First panel text'), findsNothing);
    expect(find.text('Second panel text'), findsOneWidget);
  });

  testWidgets(
      'back button is disabled on the first panel, enabled after advancing',
      (tester) async {
    final store = await _freshStore();

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _twoPanelEpisode(),
        progressStore: store,
        speak: _noopSpeak,
      ),
    ));
    await tester.pump();

    final backButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('story-reader-back')),
    );
    expect(backButton.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pump();

    final backButtonAfter = tester.widget<IconButton>(
      find.byKey(const ValueKey('story-reader-back')),
    );
    expect(backButtonAfter.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('story-reader-back')));
    await tester.pump();

    expect(find.text('First panel text'), findsOneWidget);
  });

  testWidgets('does not advance past the last panel', (tester) async {
    final store = await _freshStore();

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _twoPanelEpisode(),
        progressStore: store,
        speak: _noopSpeak,
      ),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pump();
    expect(find.text('Second panel text'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pump();

    expect(find.text('Second panel text'), findsOneWidget);
  });

  testWidgets('resumes from a previously saved position', (tester) async {
    final store = await _freshStore();
    final episode = _twoPanelEpisode();
    await store.savePosition(episode.id, 1);

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: _noopSpeak,
      ),
    ));
    await tester.pump();

    expect(find.text('Second panel text'), findsOneWidget);
    expect(find.text('First panel text'), findsNothing);
  });

  testWidgets('reads Folge 01 "Regen" from the first panel to the last',
      (tester) async {
    final store = await _freshStore();
    final episode = Episode.fromJson(pilot01RegenJson);

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: _noopSpeak,
      ),
    ));
    await tester.pump();

    for (var i = 0; i < 23; i++) {
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pump();
    }

    expect(
      find.text('(unleserliche Randnotiz, Kanji und Datum)'),
      findsOneWidget,
    );
  });

  testWidgets(
      'persists the position after advancing, so a fresh widget instance resumes there',
      (tester) async {
    final store = await _freshStore();
    final episode = _twoPanelEpisode();

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: _noopSpeak,
      ),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pump();
    expect(find.text('Second panel text'), findsOneWidget);

    expect(await store.lastPosition(episode.id), 1);

    // Unmount completely so the next pump forces a genuinely fresh State —
    // pumping the same widget type/key again would let Flutter reuse the
    // existing State instead of re-running initState/_restorePosition.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: _noopSpeak,
      ),
    ));
    await tester.pump();

    expect(find.text('Second panel text'), findsOneWidget);
    expect(find.text('First panel text'), findsNothing);
  });

  testWidgets(
      'tapping a lookupable token plays its audio and does not advance the panel',
      (tester) async {
    final store = await _freshStore();
    final speakCalls = <String>[];
    final episode = Episode.fromJson({
      'id': 'ep_test_tap',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Tap Test',
      'locale': 'ja',
      'era': '1996',
      'budget': {'items': [], 'glyphs': []},
      'pages': [
        {
          'index': 1,
          'panels': [
            {
              'index': 1,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'protagonist',
                  'text': 'すみません',
                  'tokens': [
                    {'surface': 'すみません', 'lookupable': true},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 2,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'narrator',
                  'text': 'Second panel text',
                  'tokens': [],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    });

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: (text) async => speakCalls.add(text),
      ),
    ));
    await tester.pump();

    await tester.ensureVisible(find.text('すみません'));
    await tester.tap(find.text('すみません'));
    await tester.pump();

    expect(speakCalls, ['すみません']);
    expect(find.text('すみません'), findsOneWidget);
    expect(find.text('Second panel text'), findsNothing);
  });

  testWidgets(
      'tapping a non-lookupable token plays no audio and falls through to advance (INV-7)',
      (tester) async {
    final store = await _freshStore();
    final speakCalls = <String>[];
    final episode = Episode.fromJson({
      'id': 'ep_test_locked',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Locked Test',
      'locale': 'ja',
      'era': '1996',
      'budget': {'items': [], 'glyphs': []},
      'pages': [
        {
          'index': 1,
          'panels': [
            {
              'index': 1,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'signage',
                  'text': '駅',
                  'tokens': [
                    {'surface': '駅', 'lookupable': false},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 2,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'narrator',
                  'text': 'Second panel text',
                  'tokens': [],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    });

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: (text) async => speakCalls.add(text),
      ),
    ));
    await tester.pump();

    await tester.ensureVisible(find.text('駅'));
    await tester.tap(find.text('駅'));
    await tester.pump();

    expect(speakCalls, isEmpty);
    expect(find.text('Second panel text'), findsOneWidget);
  });

  testWidgets(
      'a multi-token bubble preserves punctuation between tokens and taps only the tapped token',
      (tester) async {
    final store = await _freshStore();
    final speakCalls = <String>[];
    final episode = Episode.fromJson({
      'id': 'ep_test_multi_token',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Multi Token Test',
      'locale': 'ja',
      'era': '1996',
      'budget': {'items': [], 'glyphs': []},
      'pages': [
        {
          'index': 1,
          'panels': [
            {
              'index': 1,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'ladenbesitzer',
                  'text': 'これ、こわれた',
                  'tokens': [
                    {'surface': 'これ', 'lookupable': true},
                    {'surface': 'こわれた', 'lookupable': false},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    });

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: (text) async => speakCalls.add(text),
      ),
    ));
    await tester.pump();

    expect(find.text('これ'), findsOneWidget);
    expect(find.text('、'), findsOneWidget);
    expect(find.text('こわれた'), findsOneWidget);

    await tester.ensureVisible(find.text('これ'));
    await tester.tap(find.text('これ'));
    await tester.pump();

    expect(speakCalls, ['これ']);
  });

  testWidgets('a token with a reading displays it above the surface',
      (tester) async {
    final store = await _freshStore();
    final episode = Episode.fromJson({
      'id': 'ep_test_reading',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Reading Test',
      'locale': 'ja',
      'era': '1996',
      'budget': {'items': [], 'glyphs': []},
      'pages': [
        {
          'index': 1,
          'panels': [
            {
              'index': 1,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'signage',
                  'text': '駅',
                  'tokens': [
                    {'surface': '駅', 'reading': 'えき', 'lookupable': true},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    });

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: _noopSpeak,
      ),
    ));
    await tester.pump();

    expect(find.text('駅'), findsOneWidget);
    expect(find.text('えき'), findsOneWidget);
  });
}
