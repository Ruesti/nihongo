import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/dictionary.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:nihongo_app/features/story/trace_evaluator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/story/folge_01_dictionary_fixture.dart';
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

Episode _episodeWithDictionaryOnSecondPanel() => Episode.fromJson({
      'id': 'ep_test_dictionary',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Dictionary Test',
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
              'interactions': [
                {'type': 'dictionary', 'diegetic': true},
              ],
            },
          ],
        },
      ],
    });

Episode _episodeWithDiegeticSpeakOnSecondPanel() => Episode.fromJson({
      'id': 'ep_speak_test',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Speak Test',
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
                {'speakerId': 'narrator', 'text': 'First', 'tokens': []},
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 2,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'her',
                  'text': 'すみません',
                  'tokens': [
                    {
                      'surface': 'すみません',
                      'itemId': 'lex_ja_sumimasen',
                      'lookupable': true,
                    },
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [
                {'type': 'speak', 'diegetic': true},
              ],
            },
          ],
        },
      ],
    });

Episode _episodeWithDiegeticTraceOnSecondPanel() => Episode.fromJson({
      'id': 'ep_trace_test',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Trace Test',
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
                {'speakerId': 'n', 'text': 'First', 'tokens': []},
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 2,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'buch',
                  'text': 'あめ',
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                  ],
                },
                {
                  'speakerId': 'notiz',
                  'text': '(unleserliche Randnotiz)',
                  'tokens': [],
                },
              ],
              'thoughts': [],
              'interactions': [
                {'type': 'trace', 'diegetic': true},
              ],
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

class _FakeSpeakEvaluator implements SpeakEvaluator {
  final double score;
  _FakeSpeakEvaluator(this.score);
  @override
  Future<double> evaluate(String target) async => score;
}

class _FakeTraceEvaluator implements TraceEvaluator {
  final bool ok;
  _FakeTraceEvaluator(this.ok);
  @override
  Future<bool> evaluate(String target, List<List<Offset>> userStrokes) async =>
      ok;
}

void main() {
  testWidgets('shows the first panel and advances to the next on tap',
      (tester) async {
    final store = await _freshStore();

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _twoPanelEpisode(),
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
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
        dictionaryEntries: const [],
        knownIds: const {},
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
        dictionaryEntries: const [],
        knownIds: const {},
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
        dictionaryEntries: const [],
        knownIds: const {},
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
        dictionaryEntries: folge01DictionaryEntries,
        knownIds: const {},
      ),
    ));
    await tester.pump();

    for (var i = 0; i < 23; i++) {
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();

      // Panel 9 (P09, reached after the 8th tap) carries a dictionary
      // interaction and auto-opens the dictionary sheet — dismiss it by
      // tapping a point clearly above the sheet (which covers the bottom
      // 70% of the screen) so the remaining taps keep advancing the story.
      if (find.byKey(const ValueKey('dictionary-sheet')).evaluate().isNotEmpty) {
        await tester.tapAt(const Offset(400, 50));
        await tester.pumpAndSettle();
      }
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
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pump();
    expect(find.text('Second panel text'), findsOneWidget);

    expect(await store.lastPosition(episode.id), 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
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
        dictionaryEntries: const [],
        knownIds: const {},
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
        dictionaryEntries: const [],
        knownIds: const {},
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
        dictionaryEntries: const [],
        knownIds: const {},
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
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pump();

    expect(find.text('駅'), findsOneWidget);
    expect(find.text('えき'), findsOneWidget);
  });

  testWidgets(
      'reaching a panel with a dictionary interaction opens the dictionary sheet automatically',
      (tester) async {
    final store = await _freshStore();

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episodeWithDictionaryOnSecondPanel(),
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pump();

    expect(find.byKey(const ValueKey('dictionary-sheet')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dictionary-sheet')), findsOneWidget);
  });

  testWidgets('a panel without a dictionary interaction does not open the sheet',
      (tester) async {
    final store = await _freshStore();

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _twoPanelEpisode(),
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dictionary-sheet')), findsNothing);
  });

  testWidgets(
      'the dictionary sheet can be dismissed and reading continues normally',
      (tester) async {
    final store = await _freshStore();

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episodeWithDictionaryOnSecondPanel(),
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dictionary-sheet')), findsOneWidget);

    // Tap a point clearly above the sheet (which covers the bottom 70% of
    // the screen) to hit the exposed modal barrier and dismiss it.
    await tester.tapAt(const Offset(400, 50));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dictionary-sheet')), findsNothing);

    expect(find.text('Second panel text'), findsOneWidget);
  });

  testWidgets(
      'reading the real Folge 01 fixture: reaching P09 opens the dictionary with nothing resolvable yet',
      (tester) async {
    final store = await _freshStore();
    final episode = Episode.fromJson(pilot01RegenJson);

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: folge01DictionaryEntries,
        knownIds: const {},
      ),
    ));
    await tester.pump();

    for (var i = 0; i < 7; i++) {
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pump();
    }
    // The 8th tap lands on P09 (position index 8), which carries the
    // dictionary interaction in the real fixture.
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dictionary-sheet')), findsOneWidget);

    await tester.tap(find.text('さ行'));
    await tester.pump();

    expect(find.text('すみません'), findsOneWidget);
    expect(find.text('Entschuldigung / Verzeihung'), findsNothing);
  });

  testWidgets(
      'reading the real Folge 01 fixture: P10 shows the visible consequence after P09',
      (tester) async {
    final store = await _freshStore();
    final episode = Episode.fromJson(pilot01RegenJson);

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: folge01DictionaryEntries,
        knownIds: const {},
      ),
    ));
    await tester.pump();

    // Advance to P09 (position index 8), which auto-opens the dictionary.
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('dictionary-sheet')), findsOneWidget);

    // Close the book and read on — the next panel carries the consequence.
    await tester.tapAt(const Offset(400, 50));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();

    expect(find.text('Weg.'), findsOneWidget);
  });

  testWidgets('fires onEpisodeComplete once when the last panel is reached',
      (tester) async {
    final store = await _freshStore();
    var completeCount = 0;

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _twoPanelEpisode(),
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        onEpisodeComplete: () async => completeCount++,
      ),
    ));
    await tester.pump();

    // On the first panel — episode not finished yet.
    expect(completeCount, 0);

    // Advance to the last (second) panel — fires exactly once.
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(completeCount, 1);

    // Going back and forward again must NOT fire a second time.
    await tester.tap(find.byKey(const ValueKey('story-reader-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(completeCount, 1);
  });

  testWidgets('fires onEpisodeComplete once when resuming directly at the last '
      'panel', (tester) async {
    final store = await _freshStore();
    await store.savePosition('ep_test_reader', 1); // last panel of _twoPanelEpisode
    var completeCount = 0;

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _twoPanelEpisode(),
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        onEpisodeComplete: () async => completeCount++,
      ),
    ));
    await tester.pumpAndSettle();

    expect(completeCount, 1);
  });

  testWidgets('a diegetic-speak panel opens the speak sheet when an evaluator '
      'is injected', (tester) async {
    final store = await _freshStore();
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episodeWithDiegeticSpeakOnSecondPanel(),
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        speakEvaluator: _FakeSpeakEvaluator(0.9),
        onDiegeticSpeakSuccess: (_) async {},
      ),
    ));
    await tester.pump();

    // Not on the speak panel yet.
    expect(find.byKey(const ValueKey('diegetic-speak-sheet')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diegetic-speak-sheet')), findsOneWidget);

    // Skippable, no gate: dismissing keeps reading available.
    await tester.tap(find.byKey(const ValueKey('diegetic-speak-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diegetic-speak-sheet')), findsNothing);
    expect(find.byKey(const ValueKey('story-reader-panel')), findsOneWidget);
  });

  testWidgets('no evaluator injected → no speak sheet even on a diegetic-speak '
      'panel (INV-1 standalone)', (tester) async {
    final store = await _freshStore();
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episodeWithDiegeticSpeakOnSecondPanel(),
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diegetic-speak-sheet')), findsNothing);
  });

  testWidgets('a non-diegetic panel never opens the speak sheet (INV-6)',
      (tester) async {
    final store = await _freshStore();
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _twoPanelEpisode(), // no speak interaction anywhere
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        speakEvaluator: _FakeSpeakEvaluator(0.9),
        onDiegeticSpeakSuccess: (_) async {},
      ),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diegetic-speak-sheet')), findsNothing);
  });

  testWidgets('a successful speak fires onDiegeticSpeakSuccess with the '
      "panel's item ids", (tester) async {
    final store = await _freshStore();
    List<String>? received;
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episodeWithDiegeticSpeakOnSecondPanel(),
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        speakEvaluator: _FakeSpeakEvaluator(0.9),
        onDiegeticSpeakSuccess: (ids) async => received = ids,
      ),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pumpAndSettle();

    expect(received, ['lex_ja_sumimasen']);
  });

  testWidgets('a speak interaction with diegetic:false never opens the sheet '
      '(INV-6 boundary)', (tester) async {
    final store = await _freshStore();
    final episode = Episode.fromJson({
      'id': 'ep_speak_nondiegetic',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
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
                {'speakerId': 'n', 'text': 'First', 'tokens': []},
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 2,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'her',
                  'text': 'すみません',
                  'tokens': [
                    {
                      'surface': 'すみません',
                      'itemId': 'lex_ja_sumimasen',
                      'lookupable': true,
                    },
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [
                {'type': 'speak', 'diegetic': false},
              ],
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
        dictionaryEntries: const [],
        knownIds: const {},
        speakEvaluator: _FakeSpeakEvaluator(0.9),
        onDiegeticSpeakSuccess: (_) async {},
      ),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diegetic-speak-sheet')), findsNothing);
  });

  testWidgets('a diegetic-trace panel opens the trace sheet when an evaluator '
      'is injected, and is skippable', (tester) async {
    final store = await _freshStore();
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episodeWithDiegeticTraceOnSecondPanel(),
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        traceEvaluator: _FakeTraceEvaluator(true),
        onDiegeticTraceSuccess: (_) async {},
      ),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('diegetic-trace-sheet')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diegetic-trace-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('diegetic-trace-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diegetic-trace-sheet')), findsNothing);
    expect(find.byKey(const ValueKey('story-reader-panel')), findsOneWidget);
  });

  testWidgets('no evaluator → no trace sheet on a diegetic-trace panel (INV-1)',
      (tester) async {
    final store = await _freshStore();
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episodeWithDiegeticTraceOnSecondPanel(),
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diegetic-trace-sheet')), findsNothing);
  });

  testWidgets('a non-diegetic panel never opens the trace sheet (INV-6)',
      (tester) async {
    final store = await _freshStore();
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _twoPanelEpisode(),
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        traceEvaluator: _FakeTraceEvaluator(true),
        onDiegeticTraceSuccess: (_) async {},
      ),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diegetic-trace-sheet')), findsNothing);
  });

  testWidgets('a successful trace fires onDiegeticTraceSuccess with only the '
      'token bubble ids (the inert note bubble is excluded)', (tester) async {
    final store = await _freshStore();
    List<String>? received;
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episodeWithDiegeticTraceOnSecondPanel(),
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        traceEvaluator: _FakeTraceEvaluator(true),
        onDiegeticTraceSuccess: (ids) async => received = ids,
      ),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();

    await tester.drag(
        find.byKey(const ValueKey('diegetic-trace-canvas')), const Offset(60, 40));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('diegetic-trace-done')));
    await tester.pumpAndSettle();

    expect(received, ['lex_ja_ame']);
  });
}
