# Story-Engine P3 — Bubble Tap (Audio + Kana) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make speech-bubble tokens tappable in the panel reader: tapping a lookupable token plays its audio and shows its reading; tapping a locked (non-lookupable) token does nothing at all — matching `docs/story/BRIEF_STORY_ENGINE.md` phase P3 ("Bubble-Tap: Audio + Kana. INV-2, INV-7") with acceptance bar "Tap auf Kanji tut nachweislich nichts."

**Architecture:** Modifies the two files phase P2 built (`lib/features/story/story_reader_screen.dart` and its test) — no new files. Bubble text, currently rendered as one flat `Text(bubble.text)` block, is restructured to render per-token when a bubble has tokens: each lookupable token becomes an individually tappable span (audio via an injected `speak` callback, reading shown statically above the surface when present); each non-lookupable token renders with no gesture handler at all — not disabled-looking, genuinely absent as an interactive element, so a tap on it falls through to whatever is underneath (the whole-panel advance gesture from P2), exactly as if it were part of the background art. Bubbles with no tokens keep P2's original plain-text fallback unchanged.

**Tech Stack:** Dart 3.11 / Flutter, `flutter_test`. No new packages — `speak` is injected as a plain `Future<void> Function(String)` callback (matching `lib/core/tts_service.dart`'s `TtsService.speak` signature exactly), not a new abstraction; production wiring to the real `TtsService.instance.speak` happens whenever the reader is wired into navigation (still deferred, see Global Constraints).

## Global Constraints

- Base branch: `origin/main` — now includes phases P1 and P2 (merged via PR #28 and PR #29): `lib/features/story/episode.dart` (`Episode`, `StoryPanel`, `StoryBubble`, `StoryToken` with `surface`, `reading`, `itemId`, `lookupable` fields), `lib/features/story/story_progress_store.dart`, `lib/features/story/story_reader_screen.dart`, and the Folge 01 "Regen" fixture at `test/fixtures/story/pilot_01_regen_fixture.dart`.
- `speak` is a **required** constructor parameter on `StoryReaderScreen`, following the same explicit-dependency-injection convention already established for `progressStore` in P2 — no static-singleton default. This is a deliberate, necessary choice: the codebase's existing `TtsService` (`lib/core/tts_service.dart`) is a concrete singleton (`TtsService.instance`) with no test seam, and P3's own acceptance bar requires *proving* that tapping a locked token never triggers audio — that's only testable if the reader depends on an injectable function rather than calling the singleton directly. This mirrors, but does not replace, the existing `TtsService`/`AudioButton` pattern used elsewhere in the app (`lib/widgets/audio_button.dart`) — those are untouched.
- Reading display is **static**, not reveal-on-tap: if `StoryToken.reading != null`, it is always shown (small text above the surface) — tapping only triggers audio. This matches the pre-existing rendering convention in `lib/features/comic/spatial_reader.dart`'s `_BubbleWidget._l2Content` (`if (t.reading != null) Text(t.reading!, ...)` unconditionally) and avoids inventing new per-token "revealed" state that neither this phase's brief text nor its acceptance bar requires.
- Meaning/dictionary display remains explicitly out of scope (INV-2: audio + kana, never meaning) — that begins in a later phase (the brief's P4).
- No app-navigation changes: `lib/app.dart` stays untouched, same as P2.
- Run tests with `flutter test <path>` from the repo root.

---

### Task 1: Per-token bubble rendering — tap plays audio, locked tokens are inert

**Files:**
- Modify: `lib/features/story/story_reader_screen.dart` (full replacement below)
- Modify: `test/features/story/story_reader_screen_test.dart` (full replacement below)

**Interfaces:**
- Consumes: `Episode`, `StoryPanel`, `StoryBubble`, `StoryToken` (with `surface: String`, `reading: String?`, `lookupable: bool`) from `lib/features/story/episode.dart` (P1, unchanged); `StoryProgressStore` from `lib/features/story/story_progress_store.dart` (P2, unchanged).
- Produces: `StoryReaderScreen` constructor gains a fourth required field: `final Future<void> Function(String text) speak;`. All other public interface (`episode`, `progressStore`, widget keys `'story-reader-panel'` / `'story-reader-back'`) unchanged from P2.

- [ ] **Step 1: Replace the test file with the updated version (existing tests adapted + 3 new tests)**

Replace the full contents of `test/features/story/story_reader_screen_test.dart` with:

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

    await tester.tap(find.text('すみません'));
    await tester.pump();

    expect(speakCalls, ['すみません']);
    expect(find.text('すみません'), findsOneWidget);
    expect(find.text('Second panel text'), findsNothing);
  });

  testWidgets('tapping a non-lookupable token plays no audio (INV-7)',
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

    await tester.tap(find.text('駅'));
    await tester.pump();

    expect(speakCalls, isEmpty);
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/story/story_reader_screen_test.dart`
Expected: FAIL — compile error, `StoryReaderScreen` does not have a `speak` named parameter yet.

- [ ] **Step 3: Replace the implementation file with the updated version**

Replace the full contents of `lib/features/story/story_reader_screen.dart` with:

```dart
import 'package:flutter/material.dart';

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
/// last panel the reader reached, persisted via [progressStore].
class StoryReaderScreen extends StatefulWidget {
  final Episode episode;
  final StoryProgressStore progressStore;
  final Future<void> Function(String text) speak;

  const StoryReaderScreen({
    super.key,
    required this.episode,
    required this.progressStore,
    required this.speak,
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
/// tapping empty space).
class _BubbleContent extends StatelessWidget {
  final StoryBubble bubble;
  final Future<void> Function(String text) speak;

  const _BubbleContent({required this.bubble, required this.speak});

  @override
  Widget build(BuildContext context) {
    if (bubble.tokens.isEmpty) {
      return Text(bubble.text);
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final token in bubble.tokens) _tokenWidget(context, token),
      ],
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
Expected: PASS (all 9 tests: 6 carried over from P2, 3 new).

- [ ] **Step 5: Run the full story-feature test suite together**

Run: `flutter test test/features/story/ test/fixtures/story/`
Expected: PASS (all tests across P1, P2, and P3 — 22 total).

- [ ] **Step 6: Commit**

```bash
git add lib/features/story/story_reader_screen.dart test/features/story/story_reader_screen_test.dart
git commit -m "feat(story): make bubble tokens tappable — audio+kana, locked tokens inert (P3)"
```
