# Story-Engine P5b — Episode-complete → SRS handoff Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When the reader finishes an episode, hand every budgeted vocabulary item to the real SRS ladder **once**, as one batch — creating a `learn_item` at rung 0 for each (`LadderReview.introduce`), never at a productive rung. This is the second and final slice of the brief's phase P5 ("Auslauf + SRS-Übergabe", `docs/story/BRIEF_STORY_ENGINE.md` §5); P5a already seeded those items as real lexemes. Introducing only at completion, only at the lowest rung, satisfies **INV-5 ("kein produktiver Rung vor Lesende")** by construction: nothing enters the SRS until the reader reaches the last panel, and even then only at rung 0. Idempotency (`introduce` skips any item that already has a `learn_item`) satisfies **INV-6**: re-reading an episode never duplicates a row nor demotes an item the learner has already advanced.

**Architecture:** Two decoupled pieces plus one integration test.
- The reader stays a pure UI widget: it gains one **optional** lifecycle callback `onEpisodeComplete`, fired exactly once the first time it reaches the final panel. It does **not** know about the SRS — nothing about reading depends on the callback firing, preserving **INV-1** (no gate; the episode is fully readable standalone).
- A separate, independently-testable `EpisodeSrsHandoff` performs the batch introduce given a `LadderReview` + a `languageId`. It uses **only** `LadderReview.introduce` (rung 0), which does not touch the `KnowledgeBridge` — so the handoff needs only a `LearningDb`, no `MiningDb`.
- App wiring (connecting `onEpisodeComplete` to a real handoff on a real route) is **deferred**: `StoryReaderScreen` is not routed into the app yet (it is constructed only in tests). P5b delivers the mechanism and proves the whole P5a-seed → P5b-handoff chain with a widget integration test; wiring it into a live screen is a later phase's job.

**Tech Stack:** Dart 3.11 / Flutter, Drift/SQLite (`LearningDb.forTesting()`), `flutter_test`, `shared_preferences`. No new packages.

## Global Constraints

- Base branch: `origin/main` — now includes P4b (the reader's P09 dictionary auto-open + its `dictionaryEntries`/`knownIds` constructor params) and P5a (the 8 Folge 01 lexemes seeded under `languageId = 'lang_ja'`). This plan builds on that reader.
- **Introduce only, rung 0.** The handoff calls `LadderReview.introduce(languageId, refType, refId)` per budgeted item — nothing else. `introduce` creates a `learn_item` at `masteryRung: 0` and, by design, does **not** call the `KnowledgeBridge` (an unmet item is not projected as knowledge). Do **not** call `markEncountered`/`submit` — that would promote items to rung 1+, violating INV-5.
- **Handoff needs only `LearningDb`.** `LadderReview(learning)` with no `bridge` argument is correct and sufficient. Do not construct a `MiningDb` or `KnowledgeBridge` for the handoff or its tests.
- **`languageId` is the pack id `'lang_ja'`, NOT `Episode.locale` (`'ja'`).** The handoff takes `languageId` as an explicit constructor parameter. Mapping an episode's locale to a pack's languageId is the caller's (future app-wiring) responsibility, deliberately kept out of the handoff so it stays pack-agnostic. `'lang_ja'` is exactly what P5a seeded and what ties these `learn_items` to the real lexemes.
- **`onEpisodeComplete` is optional (nullable).** The reader is fully functional without it (INV-1). Existing `StoryReaderScreen(...)` call sites (all in `test/features/story/story_reader_screen_test.dart`) must remain valid unchanged — do not make the parameter required.
- **Fire exactly once.** Guard with a `bool _completionFired` state flag so back-then-forward navigation, rebuilds, or resuming directly at the last panel never fire it twice within a widget's lifetime. (The handoff is idempotent, so a re-fire across a *fresh* widget instance is harmless too — but the in-widget guard is still required.)
- **Fire-and-forget.** `onEpisodeComplete?.call()` returns a `Future` the reader does **not** await — a slow handoff must never block reading (INV-1). Tests that need to observe the handoff's DB writes capture that `Future` and await it explicitly.
- Widget keys already in the reader: `story-reader-panel` (the tap-to-advance surface), `story-reader-back`, `dictionary-sheet`. Reuse them; add none for this feature.
- Run tests with `flutter test <path>` from the repo root; the full suite with `flutter test`. The suite has 8 pre-existing environmental failures in `test/mining_packs/ja/` (missing native tokenizer `.so`) that are unrelated to this work — "green" here means those 8 and no others.

---

### Task 1: `EpisodeSrsHandoff` — batch introduce at rung 0

**Files:**
- Create: `lib/features/story/episode_srs_handoff.dart`
- Test: `test/features/story/episode_srs_handoff_test.dart`

**Interfaces:**
- Produces (used by Task 3): `class EpisodeSrsHandoff { const EpisodeSrsHandoff({required LadderReview ladder, required String languageId}); Future<void> introduceEpisode(Episode episode); }`.
- Consumes: `LadderReview` (`lib/core/ladder/ladder_review.dart`), `Episode`/`EpisodeBudget`/`ItemRef` (`lib/features/story/episode.dart`), `RefType` (`lib/core/ladder/rung_defs.dart`).

- [ ] **Step 1: Write the failing test**

Create `test/features/story/episode_srs_handoff_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episode_srs_handoff.dart';

import '../../fixtures/story/pilot_01_regen_fixture.dart';

void main() {
  late LearningDb learning;
  late EpisodeSrsHandoff handoff;
  late Episode episode;

  setUp(() {
    learning = LearningDb.forTesting();
    handoff = EpisodeSrsHandoff(
      ladder: LadderReview(learning),
      languageId: 'lang_ja',
    );
    episode = Episode.fromJson(pilot01RegenJson);
  });

  tearDown(() async => learning.close());

  Future<LearnItem?> itemFor(String refId) =>
      (learning.select(learning.learnItems)..where((t) => t.refId.equals(refId)))
          .getSingleOrNull();

  test('introduces every budgeted item as a rung-0 learn_item', () async {
    await handoff.introduceEpisode(episode);

    expect(episode.budget.items, isNotEmpty);
    for (final ref in episode.budget.items) {
      final item = await itemFor(ref.id);
      expect(item, isNotNull, reason: '${ref.id} was not introduced');
      expect(item!.masteryRung, 0);
      expect(item.refType, ref.refType.name);
      expect(item.languageId, 'lang_ja');
    }
  });

  test('is idempotent — re-running does not duplicate any item', () async {
    await handoff.introduceEpisode(episode);
    await handoff.introduceEpisode(episode);

    for (final ref in episode.budget.items) {
      final rows = await (learning.select(learning.learnItems)
            ..where((t) => t.refId.equals(ref.id)))
          .get();
      expect(rows, hasLength(1), reason: '${ref.id} duplicated on re-run');
    }
  });

  test('never disturbs an item already advanced beyond rung 0 (INV-6)',
      () async {
    final ref = episode.budget.items.first;
    // The learner already mastered this item in a prior episode.
    await learning.addLearnItemAtRung('lang_ja', ref.refType, ref.id, rung: 4);

    await handoff.introduceEpisode(episode);

    final item = await itemFor(ref.id);
    expect(item!.masteryRung, 4, reason: 'handoff demoted a mastered item');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/story/episode_srs_handoff_test.dart`
Expected: FAIL — `episode_srs_handoff.dart` does not exist yet (import error).

- [ ] **Step 3: Write the implementation**

Create `lib/features/story/episode_srs_handoff.dart`:

```dart
import '../../core/ladder/ladder_review.dart';
import 'episode.dart';

/// Hands an episode's budgeted vocabulary to the SRS ladder once, at the
/// moment the reader finishes the episode (P5b). Every budgeted item is
/// *introduced* — created as a `learn_item` at rung 0 via
/// [LadderReview.introduce] — and never promoted to a productive rung, which
/// is how "kein produktiver Rung vor Lesende" (INV-5) holds by construction:
/// items enter the SRS only when reading ends, and only at the lowest rung.
///
/// Idempotent by construction: [LadderReview.introduce] skips any item that
/// already has a `learn_item`, so re-reading the episode never duplicates a
/// row nor disturbs an item the learner has already advanced beyond rung 0
/// (INV-6).
///
/// [languageId] is the pack's language id (e.g. `'lang_ja'`) — NOT an
/// episode's `locale`. Mapping a locale to a pack languageId is the caller's
/// concern; keeping it a parameter here leaves the handoff pack-agnostic.
class EpisodeSrsHandoff {
  final LadderReview ladder;
  final String languageId;

  const EpisodeSrsHandoff({required this.ladder, required this.languageId});

  Future<void> introduceEpisode(Episode episode) async {
    for (final item in episode.budget.items) {
      await ladder.introduce(languageId, item.refType, item.id);
    }
  }
}
```

Note: every budgeted item is introduced, including `singleton` items — `singleton` exempts an item from the ≥2-panel repetition rule (INV-4), it does not exempt it from being learned.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/story/episode_srs_handoff_test.dart`
Expected: PASS (all 3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/episode_srs_handoff.dart test/features/story/episode_srs_handoff_test.dart
git commit -m "feat(story): add EpisodeSrsHandoff — batch-introduce budgeted items at rung 0 (P5b)"
```

---

### Task 2: Reader `onEpisodeComplete` callback (fires once at the last panel)

**Files:**
- Modify: `lib/features/story/story_reader_screen.dart`
- Modify: `test/features/story/story_reader_screen_test.dart` (add tests only; do not change existing tests or call sites)

**Interfaces:**
- `StoryReaderScreen` gains one optional constructor param: `final Future<void> Function()? onEpisodeComplete;` (nullable, no default needed). All existing call sites remain valid because it is optional.

- [ ] **Step 1: Write the failing tests**

Add these two `testWidgets` to `test/features/story/story_reader_screen_test.dart` (reuse the file's existing `_twoPanelEpisode()`, `_freshStore()`, `_noopSpeak`, and the `story-reader-panel` / `story-reader-back` keys). `_twoPanelEpisode()` has id `'ep_test_reader'`, an empty budget, and two panels (last index 1).

```dart
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/story/story_reader_screen_test.dart`
Expected: FAIL to compile — `No named parameter with the name 'onEpisodeComplete'`.

- [ ] **Step 3: Write the implementation**

In `lib/features/story/story_reader_screen.dart`:

(a) Add the field after `final Set<String> knownIds;` (line 28):
```dart

  /// Fired exactly once, the first time the reader reaches the final panel of
  /// the episode (P5b — hand the episode's vocabulary to the SRS ladder).
  /// Optional: the reader is fully functional without it (INV-1, no gate) —
  /// nothing about reading depends on this firing. Fire-and-forget: the
  /// returned Future is not awaited, so a slow handoff never blocks reading.
  final Future<void> Function()? onEpisodeComplete;
```

(b) Add to the constructor parameter list (after `required this.knownIds,`):
```dart
    this.onEpisodeComplete,
```

(c) Add the guard field to `_StoryReaderScreenState`, next to `int? _position;`:
```dart
  bool _completionFired = false;
```

(d) Add the completion helper (place it right after `_maybeShowDictionary`):
```dart
  void _maybeFireCompletion(int position) {
    if (position < _panels.length - 1 || _completionFired) return;
    _completionFired = true;
    widget.onEpisodeComplete?.call();
  }
```

(e) Call it wherever `_position` is set — right after each existing `_maybeShowDictionary(...)` call:
- In `_restorePosition()`, after `_maybeShowDictionary(clamped);` add `_maybeFireCompletion(clamped);`
- In `_goTo(int position)`, after `_maybeShowDictionary(position);` add `_maybeFireCompletion(position);`

Update the class docstring's INV list is optional; do not remove existing doc lines.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/story/story_reader_screen_test.dart`
Expected: PASS — the two new tests plus every pre-existing reader test (the optional param leaves them untouched).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/story_reader_screen.dart test/features/story/story_reader_screen_test.dart
git commit -m "feat(story): fire onEpisodeComplete once when the reader reaches the last panel (P5b)"
```

---

### Task 3: End-to-end integration — reading Folge 01 hands its vocabulary to the ladder

**Files:**
- Create: `test/features/story/story_reader_srs_handoff_test.dart`

**Interfaces:** consumes Task 1's `EpisodeSrsHandoff` and Task 2's `onEpisodeComplete`; wires a real `LadderReview` over a real seeded `LearningDb` as the reader's completion callback. No new library code.

- [ ] **Step 1: Write the failing test**

Create `test/features/story/story_reader_srs_handoff_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episode_srs_handoff.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/story/folge_01_dictionary_fixture.dart';
import '../../fixtures/story/pilot_01_regen_fixture.dart';

Future<StoryProgressStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return StoryProgressStore(await SharedPreferences.getInstance());
}

void main() {
  testWidgets(
      'reading Folge 01 to the end hands every budgeted word to the SRS '
      'ladder at rung 0 (P5a seed + P5b handoff, end to end)', (tester) async {
    final learning = LearningDb.forTesting();
    addTearDown(() async => learning.close());
    await seedJaPack(learning);

    final handoff = EpisodeSrsHandoff(
      ladder: LadderReview(learning),
      languageId: 'lang_ja',
    );
    final episode = Episode.fromJson(pilot01RegenJson);
    final store = await _freshStore();

    Future<void>? handoffDone;
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: (_) async {},
        dictionaryEntries: folge01DictionaryEntries,
        knownIds: const {},
        onEpisodeComplete: () async {
          handoffDone = handoff.introduceEpisode(episode);
          await handoffDone;
        },
      ),
    ));
    await tester.pump();

    // Nothing has entered the SRS before the episode is finished (INV-5).
    expect(await learning.select(learning.learnItems).get(), isEmpty);

    // Read to the last panel. P09 auto-opens the dictionary; dismiss it by
    // tapping above the sheet, exactly as the existing read-through test does.
    for (var i = 0; i < 23; i++) {
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      if (find.byKey(const ValueKey('dictionary-sheet')).evaluate().isNotEmpty) {
        await tester.tapAt(const Offset(400, 50));
        await tester.pumpAndSettle();
      }
    }
    await handoffDone; // await the fire-and-forget batch introduce

    // Every budgeted item now has a rung-0 learn_item referencing the real
    // lexeme P5a seeded.
    expect(episode.budget.items, isNotEmpty);
    for (final ref in episode.budget.items) {
      final item = await (learning.select(learning.learnItems)
            ..where((t) => t.refId.equals(ref.id)))
          .getSingleOrNull();
      expect(item, isNotNull, reason: '${ref.id} not handed to the ladder');
      expect(item!.masteryRung, 0);
    }
  });
}
```

- [ ] **Step 2: Run the test to verify it fails, then passes**

Run: `flutter test test/features/story/story_reader_srs_handoff_test.dart`
Expected before Tasks 1–2 exist: compile failure. With Tasks 1–2 done: PASS. If `handoffDone` is still null at `await handoffDone`, the completion never fired — check that the loop actually reaches panel index 23 (24 panels, 23 advances) and that `_maybeFireCompletion` is wired into `_goTo`.

- [ ] **Step 3: Run the full story-feature suite together**

Run: `flutter test test/features/story/`
Expected: PASS across all story tests (Task 1 unit, Task 2 reader tests, this integration test, and every pre-existing P1–P4b story test).

- [ ] **Step 4: Commit**

```bash
git add test/features/story/story_reader_srs_handoff_test.dart
git commit -m "test(story): end-to-end — reading Folge 01 introduces its vocabulary to the ladder (P5b)"
```
