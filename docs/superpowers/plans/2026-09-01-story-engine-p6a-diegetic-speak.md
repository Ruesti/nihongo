# Story-Engine P6a — Diegetic speak moments (P07/P22) + SRS effect Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the diegetic **speaking** moments of the brief's phase P6 (Folge 01 panels P07 and P22), the first slice of P6 (P6b covers the P24 tracing moment). At a panel carrying a `speak` interaction marked `diegetic: true`, the reader offers an in-fiction speak-along: it can play the word (TTS), let the reader say it into the mic, score the attempt (`SttService.similarity`), and give gentle feedback. A **successful** attempt feeds the SRS — the spoken item reaches **rung 1** (encountered) — while the whole moment stays **skippable without losing progress**. This is the brief's INV-6 exception ("Sprechübungen laufen nicht im Story-Modus. Ausnahme: explizit als `diegetic: true` markierte Panels"): the productive speaking activity is allowed only here, and its SRS effect is capped at rung 1, which is not a productive rung (3–5) and stays ≤ rung 2 (INV-5).

**Architecture:** Decoupled, mirroring P5b. Three pieces:
- `DiegeticEncounter` — a small, independently-testable SRS unit: given a `LadderReview` + `languageId`, `encounter(refType, refId)` introduces the item if needed and, only if it is still at rung 0, marks it encountered (rung 1). Idempotent and non-demoting (a word already advanced beyond rung 0 is left untouched) — so it composes safely with P5b's episode-end batch introduce.
- `SpeakEvaluator` (interface) + `DiegeticSpeakSheet` (widget) — the skippable speak overlay. The sheet depends on the `SpeakEvaluator` **interface**, so tests inject a fake (no real mic); the real implementation wraps `SttService`.
- Reader integration — `StoryReaderScreen` gains two **optional** injected deps (`speakEvaluator`, `onDiegeticSpeakSuccess`) and a `_maybeShowSpeak` hook beside the existing `_maybeShowDictionary`. With nothing injected the reader is unchanged (INV-1: fully readable standalone; existing call sites keep working). The reader fires `onDiegeticSpeakSuccess(itemIds)` on a successful attempt; wiring that callback to `DiegeticEncounter` (over a real DB) is what the integration test does, and what a future app-wiring phase will do on a live route.

**Tech Stack:** Dart 3.11 / Flutter, Drift/SQLite (`LearningDb.forTesting()`), `flutter_test`. Reuses `SttService` (`lib/core/stt_service.dart`, real `speech_to_text`) and `LadderReview` (`lib/core/ladder/ladder_review.dart`). No new packages.

## Global Constraints

- Base branch: `origin/main` (`1d74fcc`) — includes P4b (reader dictionary), P5a (seeded ja lexemes), P5b (`EpisodeSrsHandoff`, reader `onEpisodeComplete`). This plan builds on that reader.
- **The fixture and the `episode.dart` model need NO changes.** `test/fixtures/story/pilot_01_regen_fixture.dart` already marks P07 (`index: 7`) and P22 (`index: 22`) with `{'type': 'speak', 'diegetic': true}`; `InteractionType` already has `speak`; `StoryInteraction` already parses `diegetic`/`optional`. Do not modify any of these.
- **SRS effect capped at rung 1.** A successful diegetic speak calls `DiegeticEncounter.encounter`, which introduces (rung 0) then `markEncountered` (rung 1) — and only promotes an item that is *currently at rung 0*. Never call `submit` or otherwise push toward a productive rung (3–5): that would violate INV-6. Rung 1 ≤ 2 keeps INV-5 intact for a not-yet-finished episode.
- **Idempotent / non-demoting.** `encounter` on an item already at rung ≥ 1 is a no-op (introduce skips existing rows; `markEncountered` is only called when the current rung is 0). A word spoken at both P07 and P22, or spoken then read-to-completion (P5b), never regresses.
- **`languageId` is the pack id `'lang_ja'`**, not `Episode.locale`. `DiegeticEncounter` takes it as a constructor param (same rationale as P5b's `EpisodeSrsHandoff`).
- **Everything optional / skippable (INV-1).** `speakEvaluator` and `onDiegeticSpeakSuccess` are nullable reader params. The speak sheet opens only when a diegetic-speak panel is reached AND a `speakEvaluator` is injected; it is always dismissible (a skip control), and dismissing it loses no reading progress and triggers no SRS effect. No path gates navigation.
- **Speak items are lexemes.** The reader resolves a diegetic-speak panel's target from its bubbles: target text = the panel's bubble texts joined; item ids = the non-null `itemId`s of those bubbles' tokens. The success callback passes those ids; wiring calls `encounter(RefType.lexeme, id)` per id (spoken words are lexemes in this story).
- **Testability without a device.** Real STT needs a mic — not runnable in CI. Only the `SpeakEvaluator` interface is depended upon in testable code; the real `SttSpeakEvaluator` (a thin `SttService` wrapper) is not unit-tested here. Tests inject a fake evaluator returning a fixed score. The real speak/mic behaviour is verified on-device separately.
- Widget keys added by this plan: `diegetic-speak-sheet`, `diegetic-speak-listen`, `diegetic-speak-mic`, `diegetic-speak-skip`, `diegetic-speak-feedback`. Reuse existing reader keys (`story-reader-panel`, `story-reader-back`).
- Run tests with `flutter test <path>`. The full suite has 8 pre-existing `test/mining_packs/ja/` native-tokenizer failures (missing native lib), unrelated to this work — "green" means those 8 and no others.

---

### Task 1: `DiegeticEncounter` — introduce + encounter to rung 1

**Files:**
- Create: `lib/features/story/diegetic_encounter.dart`
- Test: `test/features/story/diegetic_encounter_test.dart`

**Interfaces:**
- Produces (used by Task 3's integration test and future wiring): `class DiegeticEncounter { const DiegeticEncounter({required LadderReview ladder, required String languageId}); Future<void> encounter(RefType refType, String refId); }`.

- [ ] **Step 1: Write the failing test**

Create `test/features/story/diegetic_encounter_test.dart`:

```dart
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/story/diegetic_encounter.dart';

void main() {
  late LearningDb learning;
  late DiegeticEncounter enc;

  setUp(() {
    learning = LearningDb.forTesting();
    enc = DiegeticEncounter(
      ladder: LadderReview(learning),
      languageId: 'lang_ja',
    );
  });

  tearDown(() async => learning.close());

  Future<LearnItem?> itemFor(String refId) =>
      (learning.select(learning.learnItems)..where((t) => t.refId.equals(refId)))
          .getSingleOrNull();

  test('a first diegetic encounter introduces the item and reaches rung 1',
      () async {
    await enc.encounter(RefType.lexeme, 'lex_ja_sumimasen');

    final item = await itemFor('lex_ja_sumimasen');
    expect(item, isNotNull);
    expect(item!.masteryRung, 1);
    expect(item.languageId, 'lang_ja');
  });

  test('encountering the same item twice stays at rung 1, no duplicate',
      () async {
    await enc.encounter(RefType.lexeme, 'lex_ja_sumimasen');
    await enc.encounter(RefType.lexeme, 'lex_ja_sumimasen');

    final rows = await (learning.select(learning.learnItems)
          ..where((t) => t.refId.equals('lex_ja_sumimasen')))
        .get();
    expect(rows, hasLength(1));
    expect(rows.single.masteryRung, 1);
  });

  test('an item already advanced beyond rung 0 is never demoted (INV-6)',
      () async {
    await learning.addLearnItemAtRung(
        'lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 4);

    await enc.encounter(RefType.lexeme, 'lex_ja_ame');

    final item = await itemFor('lex_ja_ame');
    expect(item!.masteryRung, 4);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/story/diegetic_encounter_test.dart`
Expected: FAIL — `diegetic_encounter.dart` does not exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/features/story/diegetic_encounter.dart`:

```dart
import '../../core/ladder/ladder_review.dart';
import '../../core/ladder/rung_defs.dart';

/// The SRS effect of a *successful* diegetic speak/trace moment (brief P6):
/// the produced item is introduced if new, then marked *encountered* — it
/// reaches rung 1 and no further. Rung 1 is not a productive rung (3–5), so
/// this honours INV-6 (only the diegetic activity itself is the exception,
/// not a productive rung), and rung 1 ≤ 2 keeps INV-5 intact even mid-episode.
///
/// [encounter] only ever promotes an item that is *currently at rung 0*, so
/// it never demotes a word the learner has already advanced (e.g. via a prior
/// episode), and it composes safely with P5b's episode-end batch introduce
/// (which is likewise idempotent). Speaking a word at both P07 and P22 leaves
/// it at rung 1.
///
/// [languageId] is the pack id (e.g. `'lang_ja'`), not an episode locale.
class DiegeticEncounter {
  final LadderReview ladder;
  final String languageId;

  const DiegeticEncounter({required this.ladder, required this.languageId});

  Future<void> encounter(RefType refType, String refId) async {
    await ladder.introduce(languageId, refType, refId);
    final id = '$languageId:${refType.name}:$refId';
    final item = await ladder.learning.getLearnItem(id);
    if (item != null && item.masteryRung == 0) {
      await ladder.markEncountered(item);
    }
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/story/diegetic_encounter_test.dart`
Expected: PASS (all 3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/diegetic_encounter.dart test/features/story/diegetic_encounter_test.dart
git commit -m "feat(story): add DiegeticEncounter — a successful diegetic moment reaches rung 1 (P6a)"
```

---

### Task 2: `SpeakEvaluator` interface + `DiegeticSpeakSheet` widget

**Files:**
- Create: `lib/features/story/speak_evaluator.dart`
- Create: `lib/features/story/diegetic_speak_sheet.dart`
- Test: `test/features/story/diegetic_speak_sheet_test.dart`

**Interfaces:**
- Produces (used by Task 3): `abstract class SpeakEvaluator { Future<double> evaluate(String target); }`; `class SttSpeakEvaluator implements SpeakEvaluator` (thin `SttService` wrapper, not unit-tested); `class DiegeticSpeakSheet extends StatefulWidget { const DiegeticSpeakSheet({required String targetText, required SpeakEvaluator evaluator, required Future<void> Function(String) speak, required VoidCallback onSuccess, required VoidCallback onSkip, double threshold = 0.6}); }`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/story/diegetic_speak_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/diegetic_speak_sheet.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';

class _FakeEvaluator implements SpeakEvaluator {
  final double score;
  int calls = 0;
  _FakeEvaluator(this.score);
  @override
  Future<double> evaluate(String target) async {
    calls++;
    return score;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required SpeakEvaluator evaluator,
  required void Function() onSuccess,
  required void Function() onSkip,
  List<String>? spoken,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: DiegeticSpeakSheet(
        targetText: 'すみません',
        evaluator: evaluator,
        speak: (t) async => spoken?.add(t),
        onSuccess: onSuccess,
        onSkip: onSkip,
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('a good attempt shows success and fires onSuccess once',
      (tester) async {
    var successes = 0;
    final evaluator = _FakeEvaluator(0.9);
    await _pump(tester,
        evaluator: evaluator, onSuccess: () => successes++, onSkip: () {});

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pumpAndSettle();

    expect(successes, 1);
    // A second mic tap after success does not re-fire.
    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pumpAndSettle();
    expect(successes, 1);
  });

  testWidgets('a poor attempt does not fire onSuccess; skip fires onSkip',
      (tester) async {
    var successes = 0;
    var skips = 0;
    await _pump(tester,
        evaluator: _FakeEvaluator(0.1),
        onSuccess: () => successes++,
        onSkip: () => skips++);

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pumpAndSettle();
    expect(successes, 0);
    expect(find.byKey(const ValueKey('diegetic-speak-feedback')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-skip')));
    await tester.pumpAndSettle();
    expect(skips, 1);
  });

  testWidgets('the listen button plays the target text via TTS',
      (tester) async {
    final spoken = <String>[];
    await _pump(tester,
        evaluator: _FakeEvaluator(0.0),
        onSuccess: () {},
        onSkip: () {},
        spoken: spoken);

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-listen')));
    await tester.pumpAndSettle();
    expect(spoken, ['すみません']);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/story/diegetic_speak_sheet_test.dart`
Expected: FAIL — `speak_evaluator.dart` / `diegetic_speak_sheet.dart` do not exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/features/story/speak_evaluator.dart`:

```dart
import '../../core/stt_service.dart';

/// Scores a spoken attempt at [target], returning 0.0–1.0. An interface so the
/// diegetic speak sheet can be widget-tested with a fake (a real microphone is
/// unavailable in tests); the real implementation wraps [SttService].
abstract class SpeakEvaluator {
  Future<double> evaluate(String target);
}

/// Real evaluator: listens on the mic via [SttService] and scores the
/// recognised text against [target] with `SttService.similarity`. Not
/// unit-tested (needs a device mic); verified on-device.
class SttSpeakEvaluator implements SpeakEvaluator {
  final SttService stt;
  final String locale;

  SttSpeakEvaluator({SttService? stt, this.locale = 'ja_JP'})
      : stt = stt ?? SttService.instance;

  @override
  Future<double> evaluate(String target) async {
    final heard = await stt.listen(locale: locale);
    return SttService.similarity(heard, target);
  }
}
```

Create `lib/features/story/diegetic_speak_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import 'speak_evaluator.dart';

/// The skippable, in-fiction speak-along shown at a `diegetic: true` speak
/// panel (brief P6, Folge 01 P07/P22). The reader can hear the word (TTS,
/// [speak]), say it into the mic ([evaluator]), and see gentle feedback. A
/// score ≥ [threshold] fires [onSuccess] exactly once (the caller turns that
/// into the SRS encounter). Nothing gates the story: [onSkip] dismisses the
/// moment at any time with no consequence (INV-1). No pass/fail lock.
class DiegeticSpeakSheet extends StatefulWidget {
  final String targetText;
  final SpeakEvaluator evaluator;
  final Future<void> Function(String text) speak;
  final VoidCallback onSuccess;
  final VoidCallback onSkip;
  final double threshold;

  const DiegeticSpeakSheet({
    super.key,
    required this.targetText,
    required this.evaluator,
    required this.speak,
    required this.onSuccess,
    required this.onSkip,
    this.threshold = 0.6,
  });

  @override
  State<DiegeticSpeakSheet> createState() => _DiegeticSpeakSheetState();
}

class _DiegeticSpeakSheetState extends State<DiegeticSpeakSheet> {
  String? _feedback;
  bool _succeeded = false;

  Future<void> _attempt() async {
    final score = await widget.evaluator.evaluate(widget.targetText);
    if (!mounted) return;
    if (score >= widget.threshold) {
      setState(() => _feedback = 'よくできました ✓');
      if (!_succeeded) {
        _succeeded = true;
        widget.onSuccess();
      }
    } else {
      setState(() => _feedback = 'もう一度どうぞ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('diegetic-speak-sheet'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.targetText, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                key: const ValueKey('diegetic-speak-listen'),
                icon: const Icon(Icons.volume_up),
                label: const Text('anhören'),
                onPressed: () => widget.speak(widget.targetText),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                key: const ValueKey('diegetic-speak-mic'),
                icon: const Icon(Icons.mic),
                label: const Text('nachsprechen'),
                onPressed: _attempt,
              ),
            ],
          ),
          if (_feedback != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _feedback!,
                key: const ValueKey('diegetic-speak-feedback'),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const ValueKey('diegetic-speak-skip'),
              onPressed: widget.onSkip,
              child: const Text('weiter'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/story/diegetic_speak_sheet_test.dart`
Expected: PASS (all 3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/speak_evaluator.dart lib/features/story/diegetic_speak_sheet.dart test/features/story/diegetic_speak_sheet_test.dart
git commit -m "feat(story): add SpeakEvaluator + skippable DiegeticSpeakSheet (P6a)"
```

---

### Task 3: Reader integration — open the speak sheet at diegetic-speak panels

**Files:**
- Modify: `lib/features/story/story_reader_screen.dart`
- Modify: `test/features/story/story_reader_screen_test.dart` (add tests only; do not change existing tests/call sites)

**Interfaces:**
- `StoryReaderScreen` gains two optional params: `final SpeakEvaluator? speakEvaluator;` and `final Future<void> Function(List<String> itemIds)? onDiegeticSpeakSuccess;`.

- [ ] **Step 1: Write the failing tests**

Add to `test/features/story/story_reader_screen_test.dart`. First add a small helper episode near the other `Episode _...()` helpers — a two-panel episode whose second panel carries a diegetic speak interaction and a bubble with an itemId token:

```dart
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
```

Add these tests (a fake evaluator is needed — define it in the test file if one isn't already present; the class below is self-contained):

```dart
class _FakeSpeakEvaluator implements SpeakEvaluator {
  final double score;
  _FakeSpeakEvaluator(this.score);
  @override
  Future<double> evaluate(String target) async => score;
}

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
```

Add the required imports at the top of the test file if not already present:
`import 'package:nihongo_app/features/story/speak_evaluator.dart';`

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/story/story_reader_screen_test.dart`
Expected: FAIL to compile — `No named parameter with the name 'speakEvaluator'` / `onDiegeticSpeakSuccess`.

- [ ] **Step 3: Write the implementation**

In `lib/features/story/story_reader_screen.dart`:

(a) Add the import:
```dart
import 'diegetic_speak_sheet.dart';
import 'speak_evaluator.dart';
```

(b) Add the two optional fields (after `onEpisodeComplete`):
```dart

  /// Scores a spoken attempt at a `diegetic: true` speak panel (P6a). When
  /// null, diegetic-speak panels open no overlay — the reader stays fully
  /// readable standalone (INV-1). The real implementation wraps the mic;
  /// tests inject a fake.
  final SpeakEvaluator? speakEvaluator;

  /// Called with the panel's item ids when a diegetic speak attempt succeeds
  /// (P6a). The caller turns this into the SRS encounter (rung 1). Optional;
  /// the reader never depends on it.
  final Future<void> Function(List<String> itemIds)? onDiegeticSpeakSuccess;
```
Add `this.speakEvaluator,` and `this.onDiegeticSpeakSuccess,` to the constructor.

(c) Add a `_maybeShowSpeak` hook (place it right after `_maybeShowDictionary`), and a small target-derivation helper:
```dart
  void _maybeShowSpeak(int position) {
    final evaluator = widget.speakEvaluator;
    if (evaluator == null) return;
    final panel = _panels[position];
    final hasSpeak = panel.interactions
        .any((i) => i.type == InteractionType.speak && i.diegetic);
    if (!hasSpeak) return;

    final targetText = panel.bubbles.map((b) => b.text).join(' ');
    final itemIds = <String>[
      for (final b in panel.bubbles)
        for (final t in b.tokens)
          if (t.itemId != null) t.itemId!,
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => DiegeticSpeakSheet(
          targetText: targetText,
          evaluator: evaluator,
          speak: widget.speak,
          onSuccess: () => widget.onDiegeticSpeakSuccess?.call(itemIds),
          onSkip: () => Navigator.of(sheetContext).pop(),
        ),
      );
    });
  }
```

(d) Call `_maybeShowSpeak(...)` right after each existing `_maybeShowDictionary(...)` call — in `_restorePosition` (`_maybeShowSpeak(clamped);`) and in `_goTo` (`_maybeShowSpeak(position);`).

Note: like the dictionary sheet, the speak sheet is a `showModalBottomSheet` opened in a post-frame callback and is freely dismissible; it does not gate the `story-reader-panel` tap flow.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/story/story_reader_screen_test.dart`
Expected: PASS — the four new tests plus every pre-existing reader test (the new params are optional, so existing call sites are untouched).

- [ ] **Step 5: Integration — a successful speak reaches rung 1 in a real DB**

Create `test/features/story/story_reader_diegetic_speak_test.dart`:

```dart
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/story/diegetic_encounter.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSpeakEvaluator implements SpeakEvaluator {
  final double score;
  _FakeSpeakEvaluator(this.score);
  @override
  Future<double> evaluate(String target) async => score;
}

Future<StoryProgressStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return StoryProgressStore(await SharedPreferences.getInstance());
}

Episode _episode() => Episode.fromJson({
      'id': 'ep_speak_int',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'Speak',
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
                {'type': 'speak', 'diegetic': true},
              ],
            },
          ],
        },
      ],
    });

void main() {
  testWidgets('a successful diegetic speak moves the spoken item to rung 1 in '
      'the real ladder', (tester) async {
    final learning = LearningDb.forTesting();
    addTearDown(() async => learning.close());
    final enc =
        DiegeticEncounter(ladder: LadderReview(learning), languageId: 'lang_ja');
    final store = await _freshStore();

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episode(),
        progressStore: store,
        speak: (_) async {},
        dictionaryEntries: const [],
        knownIds: const {},
        speakEvaluator: _FakeSpeakEvaluator(0.9),
        onDiegeticSpeakSuccess: (ids) async {
          for (final id in ids) {
            await enc.encounter(RefType.lexeme, id);
          }
        },
      ),
    ));
    await tester.pump();

    // Nothing in the SRS before the diegetic moment.
    expect(await learning.select(learning.learnItems).get(), isEmpty);

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pumpAndSettle();

    final item = await (learning.select(learning.learnItems)
          ..where((t) => t.refId.equals('lex_ja_sumimasen')))
        .getSingleOrNull();
    expect(item, isNotNull);
    expect(item!.masteryRung, 1);
  });
}
```

Run: `flutter test test/features/story/story_reader_diegetic_speak_test.dart`
Expected: PASS. If the item is null, the success callback never reached the encounter — check `_maybeShowSpeak` fires `onDiegeticSpeakSuccess` and that the panel's token `itemId` is read.

- [ ] **Step 6: Run the full story-feature suite together**

Run: `flutter test test/features/story/`
Expected: PASS across all story tests (P1–P5b plus this plan's Task 1/2/3).

- [ ] **Step 7: Commit**

```bash
git add lib/features/story/story_reader_screen.dart test/features/story/story_reader_screen_test.dart test/features/story/story_reader_diegetic_speak_test.dart
git commit -m "feat(story): open the diegetic speak sheet at P07/P22, feed a success to the ladder (P6a)"
```
