# Story-Engine P4b — P09 Dictionary Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the P4a dictionary into the panel reader so that reaching a panel carrying a `dictionary` interaction — Folge 01's P09 — automatically opens it, dismissibly, showing entries with whatever the reader currently knows (nothing, this early in the story) — completing `docs/story/BRIEF_STORY_ENGINE.md` phase P4 ("Wörterbuch: Kana-Blättern, Kosten, Handschrift-Bestand").

**Architecture:** A single, additive change to `StoryReaderScreen` (phases P2/P3, already merged): it starts consuming `StoryPanel.interactions` for the first time (previously rendered but never read) to detect the `dictionary` interaction type, and presents the already-built `DictionarySheet` (phase P4a) as a dismissible `showModalBottomSheet`. No new files, no new mechanics beyond wiring two already-complete pieces together. The "cost" mechanic from brief §3.4 (visible time passing, the conversation partner walking away) needs no new engine code at all — it's already fully represented in Folge 01's own content: P10 (the panel immediately after P09) already depicts her gone, and the existing tap-to-advance carries the reader there exactly as it does between any two panels. "Nichts zu finden" (§3.4/P09) falls out of P4a's own `knownIds`-gating for free: this early in the story nothing is known yet, so every dictionary entry the reader browses to shows only its headword, never a meaning.

**Tech Stack:** Dart 3.11 / Flutter, `flutter_test`. No new packages.

## Global Constraints

- Base branch: `origin/main` — now includes phases P1–P4a (merged via PR #28/#29/#30/#31): the `Episode` schema and Folge 01 fixture (P1), `StoryReaderScreen`/`StoryProgressStore` (P2), per-token tap-for-audio (P3), and `DictionaryEntry`/`dictionaryGroups`/`DictionarySheet`/the Folge 01 dictionary fixture (P4a). This plan does not modify any P1/P4a file — only `story_reader_screen.dart` and its test.
- `StoryReaderScreen` gains two new **required** constructor parameters — `List<DictionaryEntry> dictionaryEntries` and `Set<String> knownIds` — following the same explicit-injection convention already established for `progressStore`/`speak`. No DB/SRS lookup inside the widget; `knownIds` stays a plain injected value, same deferral rationale as P4a (real SRS integration is the brief's own later phase P5).
- No new "auto-advance" or "auto-close" logic for the dictionary sheet. Dismissing it (tap outside, drag down — `showModalBottomSheet`'s own default behavior) simply returns to the panel underneath; the reader continues exactly as before via the existing tap-to-advance gesture. The brief's own P10 content already carries the "time passed, she's gone" consequence — this plan must not duplicate or simulate that in code.
- The dictionary check re-runs on every position change (forward or backward), not just once ever — revisiting P09 (e.g. navigating back to it) re-opens the sheet. No new persistence field (e.g. "has the reader already seen this prompt") is introduced; that would be scope creep beyond what this phase needs.
- This plan does not attempt to mechanically prove the brief's own P4 acceptance line ("P09 fühlt sich richtig an") — that is an experiential judgment for a human/device pass, not a `flutter test` assertion. This plan proves the *mechanics* are correct and in place for that judgment to be made against.
- Run tests with `flutter test <path>` from the repo root.

---

### Task 1: Auto-open the dictionary on reaching a `dictionary`-interaction panel

**Files:**
- Modify: `lib/features/story/story_reader_screen.dart` (full replacement below)
- Modify: `test/features/story/story_reader_screen_test.dart` (full replacement below)

**Interfaces:**
- Consumes: `DictionaryEntry`, `DictionarySheet` from `lib/features/story/dictionary.dart` / `dictionary_sheet.dart` (P4a, already merged); `folge01DictionaryEntries` from `test/fixtures/story/folge_01_dictionary_fixture.dart` (P4a, test-only use); `InteractionType` from `lib/features/story/episode.dart` (P1, already merged — `enum InteractionType { reveal, listen, speak, trace, dictionary }`).
- Produces: `StoryReaderScreen` constructor grows to `{required Episode episode, required StoryProgressStore progressStore, required Future<void> Function(String) speak, required List<DictionaryEntry> dictionaryEntries, required Set<String> knownIds}`. New widget key: `ValueKey('dictionary-sheet')` on the presented sheet's root, for tests to detect it.

- [ ] **Step 1: Replace the test file with the updated version (existing tests adapted + 4 new tests)**

Replace the full contents of `test/features/story/story_reader_screen_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/dictionary.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
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

    await tester.tap(find.byType(ModalBarrier).last);
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
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/story/story_reader_screen_test.dart`
Expected: FAIL — compile error, `StoryReaderScreen` does not have `dictionaryEntries`/`knownIds` named parameters yet.

- [ ] **Step 3: Replace the implementation file with the updated version**

Replace the full contents of `lib/features/story/story_reader_screen.dart` with:

```dart
import 'package:flutter/material.dart';

import 'dictionary.dart';
import 'dictionary_sheet.dart';
import 'episode.dart';
import 'story_progress_store.dart';

/// Default panel aspect ratio (width / height) — matches the default used
/// for the earlier comic-page model (`comic_pack.dart`). Real per-panel
/// dimensions don't exist yet; every panel currently renders the shared
/// placeholder image.
const double _panelAspectRatio = 0.7;

/// Reads an [Episode] panel by panel, tap to advance. Tapping a lookupable
/// token plays its audio and shows its reading (INV-2: audio + kana, never
/// meaning). Tokens marked `lookupable: false` render as inert text — no
/// tap handler, no visual hint, no lock indicator (INV-7). Resumes from the
/// last panel the reader reached, persisted via [progressStore]. A panel
/// carrying a `dictionary` interaction (e.g. Folge 01's P09) automatically
/// opens [DictionarySheet] as a dismissible sheet — no gate, no forced
/// resolution (INV-1): the reader can dismiss it and keep reading exactly
/// as with any other panel.
class StoryReaderScreen extends StatefulWidget {
  final Episode episode;
  final StoryProgressStore progressStore;
  final Future<void> Function(String text) speak;
  final List<DictionaryEntry> dictionaryEntries;
  final Set<String> knownIds;

  const StoryReaderScreen({
    super.key,
    required this.episode,
    required this.progressStore,
    required this.speak,
    required this.dictionaryEntries,
    required this.knownIds,
  });

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  late final List<StoryPanel> _panels = widget.episode.allPanels.toList();
  int? _position;

  @override
  void initState() {
    super.initState();
    _restorePosition();
  }

  Future<void> _restorePosition() async {
    final saved = await widget.progressStore.lastPosition(widget.episode.id);
    if (!mounted) return;
    final clamped = saved == null ? 0 : saved.clamp(0, _panels.length - 1);
    setState(() => _position = clamped);
    _maybeShowDictionary(clamped);
  }

  void _advance() {
    final current = _position;
    if (current == null || current >= _panels.length - 1) return;
    _goTo(current + 1);
  }

  void _goBack() {
    final current = _position;
    if (current == null || current <= 0) return;
    _goTo(current - 1);
  }

  void _goTo(int position) {
    setState(() => _position = position);
    widget.progressStore.savePosition(widget.episode.id, position);
    _maybeShowDictionary(position);
  }

  void _maybeShowDictionary(int position) {
    final panel = _panels[position];
    final hasDictionaryInteraction =
        panel.interactions.any((i) => i.type == InteractionType.dictionary);
    if (!hasDictionaryInteraction) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SizedBox(
          key: const ValueKey('dictionary-sheet'),
          height: MediaQuery.of(sheetContext).size.height * 0.7,
          child: DictionarySheet(
            entries: widget.dictionaryEntries,
            knownIds: widget.knownIds,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    if (position == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final panel = _panels[position];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.episode.title),
        leading: IconButton(
          key: const ValueKey('story-reader-back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: position > 0 ? _goBack : null,
        ),
      ),
      body: GestureDetector(
        key: const ValueKey('story-reader-panel'),
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: SingleChildScrollView(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: _panelAspectRatio,
                child: Image.asset(
                  panel.asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: const Color(0xFFEDEDED)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final thought in panel.thoughts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          thought.text,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    for (final bubble in panel.bubbles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BubbleContent(
                          bubble: bubble,
                          speak: widget.speak,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders one bubble's content. A bubble with no tokens (e.g. an
/// environmental note with nothing tappable in it) renders as plain text,
/// unchanged from phase P2. Otherwise each token renders individually:
/// lookupable tokens are tappable and play audio (INV-2); non-lookupable
/// tokens render as inert text with no gesture handler at all (INV-7 — not
/// merely disabled, but genuinely absent as an interactive element, so a
/// tap on one falls through to the panel's own advance gesture, same as
/// tapping empty space). Text between/after tokens is reconstructed from
/// `bubble.text` so punctuation isn't lost (phase P3 fix).
class _BubbleContent extends StatelessWidget {
  final StoryBubble bubble;
  final Future<void> Function(String text) speak;

  const _BubbleContent({required this.bubble, required this.speak});

  @override
  Widget build(BuildContext context) {
    if (bubble.tokens.isEmpty) {
      return Text(bubble.text);
    }
    final spans = <Widget>[];
    var cursor = 0;
    for (final token in bubble.tokens) {
      final start = bubble.text.indexOf(token.surface, cursor);
      if (start >= 0) {
        if (start > cursor) {
          spans.add(Text(bubble.text.substring(cursor, start)));
        }
        cursor = start + token.surface.length;
      }
      spans.add(_tokenWidget(context, token));
    }
    if (cursor < bubble.text.length) {
      spans.add(Text(bubble.text.substring(cursor)));
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: spans,
    );
  }

  Widget _tokenWidget(BuildContext context, StoryToken token) {
    final content = token.reading == null
        ? Text(token.surface)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                token.reading!,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(token.surface),
            ],
          );

    if (!token.lookupable) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => speak(token.surface),
      child: content,
    );
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/story/story_reader_screen_test.dart`
Expected: PASS (all 14 tests: 10 carried over from P2/P3 unchanged, plus 4 new — auto-opens on a dictionary interaction, stays closed without one, dismiss-then-continue, and the real Folge 01/P09 scenario).

- [ ] **Step 5: Run the full story-feature test suite together**

Run: `flutter test test/features/story/ test/fixtures/story/`
Expected: PASS (all tests across P1–P4a and this plan — 40 total).

- [ ] **Step 6: Commit**

```bash
git add lib/features/story/story_reader_screen.dart test/features/story/story_reader_screen_test.dart
git commit -m "feat(story): open the dictionary automatically at P09 (P4b — dictionary integration)"
```
