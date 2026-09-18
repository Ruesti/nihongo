import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/dictionary.dart';
import 'package:nihongo_app/features/story/diegetic_speak_sheet.dart'
    show kDiegeticSuccessAutoClose;
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:nihongo_app/features/story/trace_evaluator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/story/folge_01_dictionary_fixture.dart';
import '../../fixtures/story/pilot_01_regen_fixture.dart';

Map<String, dynamic> _twoPanelEpisodeJson() => {
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
    };

Episode _twoPanelEpisode() => Episode.fromJson(_twoPanelEpisodeJson());

/// Three panels so a mid-episode position (index 1) is genuinely a resume
/// point, distinct from the last panel — reaching the LAST panel always
/// marks the episode completed (Reader-Erleben §2.7), which would otherwise
/// make a "position persists across remounts" test collide with the
/// "a completed episode reopens on the title card" behaviour.
Episode _threePanelEpisode() => Episode.fromJson({
      'id': 'ep_test_reader_mid',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Test Episode Mid',
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
                {'speakerId': 'narrator', 'text': 'First panel text', 'tokens': []},
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 2,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {'speakerId': 'narrator', 'text': 'Second panel text', 'tokens': []},
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 3,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {'speakerId': 'narrator', 'text': 'Third panel text', 'tokens': []},
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

Map<String, dynamic> _episodeWithDiegeticSpeakOnSecondPanelJson() => {
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
    };

Episode _episodeWithDiegeticSpeakOnSecondPanel() =>
    Episode.fromJson(_episodeWithDiegeticSpeakOnSecondPanelJson());

Map<String, dynamic> _episodeWithDiegeticTraceOnSecondPanelJson() => {
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
                  'tokens': [
                    {'surface': 'メモ', 'itemId': null},
                  ],
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
    };

Episode _episodeWithDiegeticTraceOnSecondPanel() =>
    Episode.fromJson(_episodeWithDiegeticTraceOnSecondPanelJson());

Episode _episodeWithHitAreaBubble() => Episode.fromJson({
      'id': 'ep_hit', 'seasonId': 's', 'orderIndex': 1, 'title': 'Hit',
      'locale': 'ja', 'era': 'e',
      'budget': {
        'items': [
          {'refType': 'lexeme', 'id': 'lex_ja_sumimasen'},
        ],
        'maxNew': 1,
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'protagonist',
                  'text': 'すみません',
                  'hitArea': [
                    {'x': 0.1, 'y': 0.1},
                    {'x': 0.6, 'y': 0.1},
                    {'x': 0.6, 'y': 0.3},
                    {'x': 0.1, 'y': 0.3},
                  ],
                  'tokens': [
                    {'surface': 'すみません', 'itemId': 'lex_ja_sumimasen'},
                  ],
                },
              ],
              'thoughts': [
                {'text': 'Ich hätte anrufen sollen.'},
              ],
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

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

  testWidgets(
      'tapping the last panel again opens the end card instead of advancing '
      'further', (tester) async {
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pump();
    expect(find.text('Second panel text'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pump();

    expect(find.byKey(const ValueKey('story-end-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-reader-panel')), findsNothing);
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
    await tester.pumpAndSettle();

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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

    // Folge01 V2 has 10 panels (9 taps after the title card). No
    // speak/traceEvaluator is wired into this screen, and V2 has no
    // `dictionary` interaction anywhere (that was P09-specific in V1) —
    // the dismiss-check below is a harmless no-op kept for parity with
    // other read-through tests.
    for (var i = 0; i < 9; i++) {
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();

      if (find.byKey(const ValueKey('dictionary-sheet')).evaluate().isNotEmpty) {
        await tester.tapAt(const Offset(400, 50));
        await tester.pumpAndSettle();
      }
    }

    // Panel 10 (the last panel) carries the Endkarten-Haken narration.
    expect(
      find.text(
        'Auf dem Zettel standen einmal drei Zeilen. Mira kennt jetzt: ein '
        'Zeichen und vier Wörter. Hinter dieser Tür fängt der Rest an.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'persists the position after advancing, so a fresh widget instance resumes there',
      (tester) async {
    final store = await _freshStore();
    // Three panels: advancing to the middle one (index 1) leaves the
    // episode un-completed, so the remount below hits the resumeMidway
    // path, not the "completed episode → title card" path.
    final episode = _threePanelEpisode();

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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

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

    // Resumes directly on the saved position — no title card, since the
    // episode isn't completed (resumeMidway path).
    expect(find.byKey(const ValueKey('story-title-card')), findsNothing);
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

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
      'reading the real Folge 01 fixture: tapping a bubble opens the '
      'dictionary with nothing resolvable yet (V2 hat keine automatische '
      'Dictionary-Interaktion mehr — die gab es nur in V1 bei P09)',
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dictionary-sheet')), findsNothing);

    // Panel 1's signage bubble (みなみまち) carries a hitArea — tapping
    // any bubble opens the dictionary, regardless of a dedicated
    // `dictionary` interaction (that mechanic is gone in V2).
    await tester.tap(find.byKey(const ValueKey('story-bubble-hit-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dictionary-sheet')), findsOneWidget);

    await tester.tap(find.text('さ行'));
    await tester.pump();

    expect(find.text('すみません'), findsOneWidget);
    expect(find.text('Entschuldigung / Verzeihung'), findsNothing);
  });

  testWidgets(
      'reading the real Folge 01 fixture: closing a dictionary opened via '
      'bubble tap and continuing reveals the next panel',
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('story-bubble-hit-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dictionary-sheet')), findsOneWidget);

    // Close the book and read on — the next panel carries the story on.
    await tester.tapAt(const Offset(400, 50));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();

    // Position advances from Panel 1 (index 0) to Panel 2 (index 1), whose
    // Erzählkasten carries the story on.
    expect(find.text('Der Regen war schneller als sie.'), findsOneWidget);
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

    // Not on the speak panel yet.
    expect(find.byKey(const ValueKey('diegetic-speak-sheet')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-diegetic-prompt')));
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-diegetic-prompt')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pumpAndSettle();

    expect(received, ['lex_ja_sumimasen']);

    // The sheet auto-closes 900ms after success; flush that pending timer
    // so it doesn't leak past this test.
    await tester.pump(kDiegeticSuccessAutoClose);
    await tester.pumpAndSettle();
  });

  testWidgets('nach erfolgreichem Sprechen reagiert das Panel: '
      'Reaktionsbild + Erzaehlzeile', (tester) async {
    final json = _episodeWithDiegeticSpeakOnSecondPanelJson();
    // Reaktion an die speak-Interaktion des zweiten Panels haengen:
    final panel = ((json['pages'] as List).first
        as Map<String, dynamic>)['panels'][1] as Map<String, dynamic>;
    (panel['interactions'] as List)[0] = {
      'type': 'speak', 'diegetic': true,
      'reactionAsset': 'assets/comic/placeholder_page.png',
      'reactionCaption': 'Sie hat dich gehört.',
    };
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: Episode.fromJson(json),
        progressStore: await _freshStore(),
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        speakEvaluator: _FakeSpeakEvaluator(0.9),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-diegetic-prompt')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-reaction-caption')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pumpAndSettle();
    // Wie in den bestehenden Erfolgs-Tests (Task 3): pumpAndSettle() allein
    // erkennt den ausstehenden Future.delayed(900ms) nicht als "laufenden
    // Frame" — ohne laufende Animation bleibt hasScheduledFrame nach dem
    // ersten Rebuild false. Den Auto-Close-Timer explizit verstreichen
    // lassen, dann den Crossfade fertig einschwingen lassen.
    await tester.pump(kDiegeticSuccessAutoClose);
    await tester.pumpAndSettle(); // Auto-Close + Crossfade
    expect(find.byKey(const ValueKey('diegetic-speak-sheet')), findsNothing);
    expect(find.byKey(const ValueKey('story-reaction-caption')), findsOneWidget);
    expect(find.text('Sie hat dich gehört.'), findsOneWidget);
  });

  testWidgets('Skip statt erfolgreichem Sprechen: keine Reaktion, Original '
      'bleibt (INV-1)', (tester) async {
    final json = _episodeWithDiegeticSpeakOnSecondPanelJson();
    final panel = ((json['pages'] as List).first
        as Map<String, dynamic>)['panels'][1] as Map<String, dynamic>;
    (panel['interactions'] as List)[0] = {
      'type': 'speak', 'diegetic': true,
      'reactionAsset': 'assets/comic/placeholder_page.png',
      'reactionCaption': 'Sie hat dich gehört.',
    };
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: Episode.fromJson(json),
        progressStore: await _freshStore(),
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        speakEvaluator: _FakeSpeakEvaluator(0.9),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-diegetic-prompt')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diegetic-speak-sheet')), findsNothing);
    expect(find.byKey(const ValueKey('story-reaction-caption')), findsNothing);
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diegetic-trace-sheet')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-diegetic-prompt')));
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diegetic-trace-sheet')), findsNothing);
  });

  testWidgets('a trace interaction with diegetic:false never opens the sheet '
      '(INV-6 boundary)', (tester) async {
    final store = await _freshStore();
    final episode = Episode.fromJson({
      'id': 'ep_trace_nondiegetic',
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
                  'speakerId': 'buch',
                  'text': 'あめ',
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [
                {'type': 'trace', 'diegetic': false},
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
        traceEvaluator: _FakeTraceEvaluator(true),
        onDiegeticTraceSuccess: (_) async {},
      ),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
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
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-diegetic-prompt')));
    await tester.pumpAndSettle();

    await tester.drag(
        find.byKey(const ValueKey('diegetic-trace-canvas')), const Offset(60, 40));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('diegetic-trace-done')));
    await tester.pumpAndSettle();

    expect(received, ['lex_ja_ame']);

    // The sheet auto-closes 900ms after success; flush that pending timer
    // so it doesn't leak past this test.
    await tester.pump(kDiegeticSuccessAutoClose);
    await tester.pumpAndSettle();
  });

  testWidgets('eine Bubble mit hitArea wird Tippflaeche im Bild: '
      'kein Dialogtext unter dem Panel, Tap spricht und oeffnet das Woerterbuch',
      (tester) async {
    final spoken = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episodeWithHitAreaBubble(),
        progressStore: await _freshStore(),
        speak: (t) async => spoken.add(t),
        dictionaryEntries: const [
          DictionaryEntry(id: 'lex_ja_sumimasen', headword: 'すみません',
              meaning: 'Entschuldigung'),
        ],
        knownIds: const {},
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-bubble-hit-0')), findsOneWidget);
    // Kein Fallback-Text unter dem Bild:
    expect(find.text('すみません'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-bubble-hit-0')));
    await tester.pumpAndSettle();
    expect(spoken, ['すみません']);
    expect(find.byKey(const ValueKey('dictionary-sheet')), findsOneWidget);
  });

  testWidgets('thoughts erscheinen als Erzaehlkasten-Overlay', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episodeWithHitAreaBubble(),
        progressStore: await _freshStore(),
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    final box = find.byKey(const ValueKey('story-thought-box'));
    expect(box, findsOneWidget);
    expect(find.descendant(of: box,
        matching: find.text('Ich hätte anrufen sollen.')), findsOneWidget);
  });

  testWidgets('Erstoeffnung zeigt die Titelkarte mit Titel und Anmoderation; '
      'Tap startet das Lesen', (tester) async {
    final episode = Episode.fromJson({
      ...pilot01RegenJson,
      'intro': 'Eine junge Frau steigt allein aus dem Zug.',
    });
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: await _freshStore(),
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-title-card')), findsOneWidget);
    // Der Titel-String entspricht dem 'title'-Feld in
    // lib/features/story/episodes/folge_01_regen.dart ('Regen') — dort
    // steht nicht "Folge 1 — Regen", die Titelkarte zeigt episode.title
    // unverändert.
    expect(find.text('Regen'), findsOneWidget);
    expect(find.text('Eine junge Frau steigt allein aus dem Zug.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('story-reader-panel')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-reader-panel')), findsOneWidget);
  });

  testWidgets('Tap auf dem letzten Panel oeffnet die Endkarte; '
      'ihr Knopf verlaesst den Reader', (tester) async {
    final episode = Episode.fromJson({
      ..._twoPanelEpisodeJson(),
      'outro': 'Der Name kommt ihr bekannt vor …',
    });
    final store = await _freshStore();
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel'))); // → Panel 2 (letztes)
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel'))); // → Endkarte
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-end-card')), findsOneWidget);
    expect(find.text('Der Name kommt ihr bekannt vor …'), findsOneWidget);
    expect(await store.isCompleted(episode.id), isTrue);
  });

  testWidgets('eine abgeschlossene Folge startet beim Wiederoeffnen auf der '
      'Titelkarte — nicht auf dem letzten Panel mit offenem Sheet',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = StoryProgressStore(prefs);
    final episode = Episode.fromJson(pilot01RegenJson);
    await store.savePosition(episode.id, 9); // letztes Panel (V2: 10 Panels)
    await store.markCompleted(episode.id);

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        traceEvaluator: _FakeTraceEvaluator(true),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-title-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('diegetic-trace-sheet')), findsNothing);
  });

  testWidgets('eine Bubble OHNE hitArea rendert wie bisher unter dem Bild '
      '(Uebergangs-Fallback)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _twoPanelEpisode(),
        progressStore: await _freshStore(),
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-bubble-hit-0')), findsNothing);
  });

  testWidgets('speak-Interaktion mit target/promptText/targetItemIds nutzt '
      'genau diese statt der Bubble-Ableitung', (tester) async {
    final json = _episodeWithDiegeticSpeakOnSecondPanelJson();
    final panel = ((json['pages'] as List).first
        as Map<String, dynamic>)['panels'][1] as Map<String, dynamic>;
    (panel['interactions'] as List)[0] = {
      'type': 'speak', 'diegetic': true,
      'promptText': 'Mira braucht Hilfe.',
      'target': 'すみません',
      'targetItemIds': ['lex_ja_sumimasen'],
    };
    final received = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: Episode.fromJson(json),
        progressStore: await _freshStore(),
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        speakEvaluator: _FakeSpeakEvaluator(0.9),
        onDiegeticSpeakSuccess: (ids) async => received.addAll(ids),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-diegetic-prompt')));
    await tester.pumpAndSettle();
    // Der Prompt steht als Hinweis auf dem Panel UND im Blatt — geprueft wird das Blatt.
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('diegetic-speak-sheet')),
            matching: find.text('Mira braucht Hilfe.')),
        findsOneWidget);
    expect(find.text('すみません'), findsWidgets); // das Ziel, nicht der Bubble-Text
    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pump(kDiegeticSuccessAutoClose);
    await tester.pumpAndSettle();
    expect(received, ['lex_ja_sumimasen']);
  });

  testWidgets('trace mit target und leeren targetItemIds: Aufgabe erscheint, '
      'Erfolg reagiert, aber bucht nichts', (tester) async {
    final json = _episodeWithDiegeticTraceOnSecondPanelJson();
    final panel = ((json['pages'] as List).first
        as Map<String, dynamic>)['panels'][1] as Map<String, dynamic>;
    (panel['interactions'] as List)[0] = {
      'type': 'trace', 'diegetic': true,
      'promptText': 'Rette das Zeichen: め.',
      'target': 'め',
      'targetItemIds': <dynamic>[],
      'reactionCaption': 'Jetzt gehört es ihr.',
    };
    final received = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: Episode.fromJson(json),
        progressStore: await _freshStore(),
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        traceEvaluator: _FakeTraceEvaluator(true),
        onDiegeticTraceSuccess: (ids) async => received.addAll(ids),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-diegetic-prompt')));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('diegetic-trace-sheet')),
            matching: find.text('Rette das Zeichen: め.')),
        findsOneWidget);
    await tester.drag(find.byKey(const ValueKey('diegetic-trace-canvas')),
        const Offset(30, 30));
    await tester.tap(find.byKey(const ValueKey('diegetic-trace-done')));
    await tester.pump(kDiegeticSuccessAutoClose);
    await tester.pumpAndSettle();
    expect(received, isEmpty);
    expect(find.byKey(const ValueKey('story-reaction-caption')), findsOneWidget);
  });
}
