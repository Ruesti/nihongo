# Story-Engine P2 — Panel Reader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a panel-by-panel reader that can read Folge 01 ("Regen") from its first panel to its last, tap-to-advance, with no graded interaction of any kind — matching `docs/story/BRIEF_STORY_ENGINE.md` phase P2 ("Panel-Reader. Durchlesen ohne jede Interaktion. Folge 01 von P01–P24 lesbar").

**Architecture:** Two additive Dart files under `lib/features/story/`, building directly on the `Episode`/`StoryPanel`/`StoryBubble`/`StoryThought` schema merged in phase P1 (`lib/features/story/episode.dart`). A small persistence wrapper (`StoryProgressStore`) records which panel a reader last reached, following the existing `SharedPreferences`-backed-class pattern already used in this codebase (see `lib/features/onboarding/onboarding_prefs.dart`). The reader widget (`StoryReaderScreen`) takes an already-parsed `Episode` — loading one from a bundled asset, and wiring a navigation route to reach it, are explicitly out of scope (see Global Constraints).

**Tech Stack:** Dart 3.11 / Flutter, `flutter_test`, `shared_preferences` (already a pubspec dependency, no new packages).

## Global Constraints

- Base branch: `origin/main` — it now includes phase P1 (merged via PR #28): `lib/features/story/episode.dart` with `Episode`, `StoryPage`, `StoryPanel`, `StoryBubble`, `StoryThought`, `StoryToken`, `EpisodeBudget`, `ItemRef`, `GlyphRef`, and `Episode.allPanels`. Do not redefine any of these — import them.
- `test/fixtures/story/pilot_01_regen_fixture.dart` (also merged in P1) exports `const Map<String, dynamic> pilot01RegenJson` — the full 24-panel Folge 01 fixture. Use it as-is for the acceptance test; do not modify it.
- No app-navigation changes in this phase: do not touch `lib/app.dart` or add a `GoRoute`. `StoryReaderScreen` is built and fully tested as a standalone widget (constructed directly with an `Episode` it's given); wiring it into the app's navigation is deferred to a later phase, once the reader is ready to actually ship rather than still being proven out.
- No bubble/thought tap handling, no TTS playback, no dictionary lookup in this phase. `StoryBubble.hitArea` is empty for every panel in the current fixture (no real artwork exists yet to trace hit-areas against) — render bubble and thought text as a plain, non-interactive list below the panel image, not positioned by coordinates. Interaction begins in a later phase (the brief's P3, "Bubble-Tap: Audio + Kana. INV-2, INV-7").
- Persistence follows the established pattern in this codebase: a small class wrapping an injected `SharedPreferences` instance (constructor-injected, not a static singleton) — see `lib/features/onboarding/onboarding_prefs.dart`. Tests mock it with `SharedPreferences.setMockInitialValues({})` in `setUp`, then `await SharedPreferences.getInstance()` — see `test/features/onboarding/onboarding_flow_test.dart`.
- Run tests with `flutter test <path>` from the repo root.

---

### Task 1: Story progress store

**Files:**
- Create: `lib/features/story/story_progress_store.dart`
- Test: `test/features/story/story_progress_store_test.dart`

**Interfaces:**
- Consumes: `SharedPreferences` (package `shared_preferences`, already a dependency).
- Produces (used by Task 2): `class StoryProgressStore { const StoryProgressStore(SharedPreferences prefs); Future<int?> lastPosition(String episodeId); Future<void> savePosition(String episodeId, int position); }`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/story/story_progress_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('returns null when no position has been saved for an episode', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = StoryProgressStore(prefs);

    expect(await store.lastPosition('ep_ja_shotengai_01'), isNull);
  });

  test('saves and retrieves a position for an episode', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = StoryProgressStore(prefs);

    await store.savePosition('ep_ja_shotengai_01', 7);

    expect(await store.lastPosition('ep_ja_shotengai_01'), 7);
  });

  test('tracks positions independently per episode', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = StoryProgressStore(prefs);

    await store.savePosition('ep_a', 3);
    await store.savePosition('ep_b', 9);

    expect(await store.lastPosition('ep_a'), 3);
    expect(await store.lastPosition('ep_b'), 9);
  });

  test('overwrites a previously saved position for the same episode', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = StoryProgressStore(prefs);

    await store.savePosition('ep_ja_shotengai_01', 2);
    await store.savePosition('ep_ja_shotengai_01', 5);

    expect(await store.lastPosition('ep_ja_shotengai_01'), 5);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/story/story_progress_store_test.dart`
Expected: FAIL — `lib/features/story/story_progress_store.dart` does not exist yet (import error).

- [ ] **Step 3: Write the implementation**

Create `lib/features/story/story_progress_store.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which panel a reader last reached in an episode, keyed by
/// [Episode.id]. One integer per episode — the position is an index into
/// [Episode.allPanels], not a [StoryPanel.index] value.
class StoryProgressStore {
  static const _keyPrefix = 'story_progress_';

  final SharedPreferences _prefs;
  const StoryProgressStore(this._prefs);

  Future<int?> lastPosition(String episodeId) async {
    return _prefs.getInt('$_keyPrefix$episodeId');
  }

  Future<void> savePosition(String episodeId, int position) async {
    await _prefs.setInt('$_keyPrefix$episodeId', position);
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/story/story_progress_store_test.dart`
Expected: PASS (all 4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/story_progress_store.dart test/features/story/story_progress_store_test.dart
git commit -m "feat(story): add StoryProgressStore for per-episode panel position"
```

---

### Task 2: Panel-by-panel reader screen

**Files:**
- Create: `lib/features/story/story_reader_screen.dart`
- Test: `test/features/story/story_reader_screen_test.dart`

**Interfaces:**
- Consumes: `Episode`, `StoryPanel` from `lib/features/story/episode.dart` (P1, already merged); `StoryProgressStore` from Task 1; `pilot01RegenJson` from `test/fixtures/story/pilot_01_regen_fixture.dart` (P1, already merged — test-only use).
- Produces: `class StoryReaderScreen extends StatefulWidget { const StoryReaderScreen({required Episode episode, required StoryProgressStore progressStore}); }`. Widget keys used by tests and available for later phases to build on: `ValueKey('story-reader-panel')` (the tap-to-advance surface) and `ValueKey('story-reader-back')` (the back button).

- [ ] **Step 1: Write the failing tests**

Create `test/features/story/story_reader_screen_test.dart`:

```dart
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

void main() {
  testWidgets('shows the first panel and advances to the next on tap',
      (tester) async {
    final store = await _freshStore();

    await tester.pumpWidget(MaterialApp(
      home:
          StoryReaderScreen(episode: _twoPanelEpisode(), progressStore: store),
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
      home:
          StoryReaderScreen(episode: _twoPanelEpisode(), progressStore: store),
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
      home:
          StoryReaderScreen(episode: _twoPanelEpisode(), progressStore: store),
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
      home: StoryReaderScreen(episode: episode, progressStore: store),
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
      home: StoryReaderScreen(episode: episode, progressStore: store),
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
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/story/story_reader_screen_test.dart`
Expected: FAIL — `lib/features/story/story_reader_screen.dart` does not exist yet (import error).

- [ ] **Step 3: Write the implementation**

Create `lib/features/story/story_reader_screen.dart`:

```dart
import 'package:flutter/material.dart';

import 'episode.dart';
import 'story_progress_store.dart';

/// Default panel aspect ratio (width / height) — matches the default used
/// for the earlier comic-page model (`comic_pack.dart`). Real per-panel
/// dimensions don't exist yet; every panel currently renders the shared
/// placeholder image.
const double _panelAspectRatio = 0.7;

/// Reads an [Episode] panel by panel, tap to advance. No bubble or thought
/// is interactive yet (INV-1: the whole episode must be readable without
/// solving anything) — that begins in a later phase. Resumes from the last
/// panel the reader reached, persisted via [progressStore].
class StoryReaderScreen extends StatefulWidget {
  final Episode episode;
  final StoryProgressStore progressStore;

  const StoryReaderScreen({
    super.key,
    required this.episode,
    required this.progressStore,
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
    setState(() => _position = saved ?? 0);
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
                        child: Text(bubble.text),
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
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/story/story_reader_screen_test.dart`
Expected: PASS (all 5 tests, including the 24-panel Folge 01 read-through).

- [ ] **Step 5: Run the full story-feature test suite together**

Run: `flutter test test/features/story/ test/fixtures/story/`
Expected: PASS (all tests across P1 and P2).

- [ ] **Step 6: Commit**

```bash
git add lib/features/story/story_reader_screen.dart test/features/story/story_reader_screen_test.dart
git commit -m "feat(story): add panel-by-panel reader screen (P2 — Durchlesen ohne Interaktion)"
```
