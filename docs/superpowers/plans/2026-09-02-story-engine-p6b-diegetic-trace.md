# Story-Engine P6b — Diegetic trace moment (P24) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the diegetic **tracing** moment of the brief's phase P6 (Folge 01 panel P24 — the episode's one "Schreibmoment", where she traces あめ). At a panel carrying a `trace` interaction marked `diegetic: true`, the reader offers an in-fiction handwriting canvas: trace the word, and on an accepted attempt the traced item reaches SRS **rung 1** — while the whole moment stays **skippable without losing progress**. This completes P6 (P6a already shipped the P07/P22 speaking moments). It is the INV-6 exception ("Nachzeichnen läuft nicht im Story-Modus. Ausnahme: `diegetic: true` Panels"): the productive tracing runs only here, its SRS effect capped at rung 1 (not a productive rung 3–5, and ≤ rung 2 keeps INV-5).

**Architecture:** Mirrors P6a exactly, and **reuses P6a's `DiegeticEncounter` unchanged** for the SRS effect (no new SRS unit). Two pieces:
- `TraceEvaluator` (interface) + `KanaTraceEvaluator` (real impl) + `DiegeticTraceSheet` (widget) — the skippable trace overlay. The sheet depends on the `TraceEvaluator` **interface**, so tests inject a fake (real stroke references are loaded from bundled SVG assets, awkward in a widget test). This is the direct analogue of P6a's `SpeakEvaluator`/`SttSpeakEvaluator`/`DiegeticSpeakSheet`.
- Reader integration — `StoryReaderScreen` gains two **optional** injected deps (`traceEvaluator`, `onDiegeticTraceSuccess`) and a `_maybeShowTrace` hook beside `_maybeShowSpeak`/`_maybeShowDictionary`. With nothing injected the reader is unchanged (INV-1). On a successful trace it fires `onDiegeticTraceSuccess(itemIds)`; wiring that to `DiegeticEncounter` (over a real DB) is the integration test's job and the future app-wiring's.

**Tech Stack:** Dart 3.11 / Flutter, Drift/SQLite (`LearningDb.forTesting()`), `flutter_test`. Reuses `DiegeticEncounter` (`lib/features/story/diegetic_encounter.dart`), `strokeAssetForKana` (`lib/data/kana_strokes.dart`), `KanjiSvgLoader` (`lib/features/kanji_games/trace/kanji_svg_loader.dart`). No new packages.

## Global Constraints

- Base branch: `origin/main` (`7a467ec`) — includes all of P0–P6a. The reader already has `_maybeShowDictionary` (P4b) and `_maybeShowSpeak` (P6a); this plan adds the trace sibling.
- **The fixture and `episode.dart` need NO changes.** `test/fixtures/story/pilot_01_regen_fixture.dart` panel `index: 24` already carries `{'type': 'trace', 'diegetic': true}`; `InteractionType.trace` already exists and `StoryInteraction` already parses `diegetic`. Do not modify these.
- **Reuse `DiegeticEncounter` as-is.** The trace success maps to `DiegeticEncounter.encounter(RefType.lexeme, itemId)` (same rung-1, idempotent, non-demoting semantics as P6a). Do NOT write a new SRS unit and do NOT push past rung 1 (INV-5/INV-6).
- **Derive the trace target from TOKENS, not bubble text.** P24 has TWO bubbles: the target `'あめ'` (one token, `itemId: 'lex_ja_ame'`) and an inert margin note `'(unleserliche Randnotiz…)'` with **no tokens** (deliberately non-resolvable, INV-7). The reader must build `targetText` and `itemIds` from the panel's bubble **tokens that have a non-null `itemId`** — never from `bubble.text` (which would wrongly fold in the note). This differs from P6a's speak-target derivation and is the one correctness subtlety of this phase.
- **Everything optional / skippable (INV-1).** `traceEvaluator` and `onDiegeticTraceSuccess` are nullable reader params. The trace sheet opens only when a diegetic-trace panel is reached AND a `traceEvaluator` is injected; it always has a skip control; skipping loses no reading progress and triggers no SRS effect. No path gates navigation.
- **Kana scoring reality (documented, honest).** Stroke references come from KanjiVG SVGs via `strokeAssetForKana`. あ (U+3042) is bundled (`assets/kanji_svg/3042.svg`); め (U+3081) is not. `KanaTraceEvaluator` therefore uses a **stroke-count sufficiency** bar (did the reader draw at least the expected number of strokes — the real per-char reference stroke counts where bundled, a minimum of 1 where not), returning accept/reject. Precise per-stroke shape scoring (`StrokeValidator`) and bundling め's SVG are noted upgrades, NOT part of this slice — this keeps P6b shippable and honest rather than pretending to robustly shape-score an unsegmented, partly-unbundled kana word. `KanaTraceEvaluator` (the real impl) is not unit-tested (needs bundled assets); tests use a fake evaluator.
- Widget keys added: `diegetic-trace-sheet`, `diegetic-trace-canvas`, `diegetic-trace-done`, `diegetic-trace-skip`, `diegetic-trace-clear`, `diegetic-trace-feedback`. Reuse existing reader keys (`story-reader-panel`, `story-reader-back`).
- Run tests with `flutter test <path>`. The full suite has 8 pre-existing `test/mining_packs/ja/` native-tokenizer failures, unrelated — "green" means those 8 and no others.

---

### Task 1: `TraceEvaluator` + `KanaTraceEvaluator` + `DiegeticTraceSheet` widget

**Files:**
- Create: `lib/features/story/trace_evaluator.dart`
- Create: `lib/features/story/diegetic_trace_sheet.dart`
- Test: `test/features/story/diegetic_trace_sheet_test.dart`

**Interfaces:**
- Produces (used by Task 2): `abstract class TraceEvaluator { Future<bool> evaluate(String target, List<List<Offset>> userStrokes); }`; `class KanaTraceEvaluator implements TraceEvaluator` (real, not unit-tested); `class DiegeticTraceSheet extends StatefulWidget { const DiegeticTraceSheet({required String targetText, required TraceEvaluator evaluator, required VoidCallback onSuccess, required VoidCallback onSkip}); }`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/story/diegetic_trace_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/diegetic_trace_sheet.dart';
import 'package:nihongo_app/features/story/trace_evaluator.dart';

class _FakeTraceEvaluator implements TraceEvaluator {
  final bool ok;
  int calls = 0;
  _FakeTraceEvaluator(this.ok);
  @override
  Future<bool> evaluate(String target, List<List<Offset>> userStrokes) async {
    calls++;
    return ok;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required TraceEvaluator evaluator,
  required void Function() onSuccess,
  required void Function() onSkip,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: DiegeticTraceSheet(
        targetText: 'あめ',
        evaluator: evaluator,
        onSuccess: onSuccess,
        onSkip: onSkip,
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('an accepted trace shows success and fires onSuccess once',
      (tester) async {
    var successes = 0;
    await _pump(tester,
        evaluator: _FakeTraceEvaluator(true),
        onSuccess: () => successes++,
        onSkip: () {});

    // Draw a stroke on the canvas, then submit.
    await tester.drag(
        find.byKey(const ValueKey('diegetic-trace-canvas')), const Offset(60, 40));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('diegetic-trace-done')));
    await tester.pumpAndSettle();

    expect(successes, 1);
    expect(find.byKey(const ValueKey('diegetic-trace-feedback')), findsOneWidget);

    // A second submit after success does not re-fire.
    await tester.tap(find.byKey(const ValueKey('diegetic-trace-done')));
    await tester.pumpAndSettle();
    expect(successes, 1);
  });

  testWidgets('a rejected trace does not fire onSuccess; skip fires onSkip',
      (tester) async {
    var successes = 0;
    var skips = 0;
    await _pump(tester,
        evaluator: _FakeTraceEvaluator(false),
        onSuccess: () => successes++,
        onSkip: () => skips++);

    await tester.tap(find.byKey(const ValueKey('diegetic-trace-done')));
    await tester.pumpAndSettle();
    expect(successes, 0);
    expect(find.byKey(const ValueKey('diegetic-trace-feedback')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('diegetic-trace-skip')));
    await tester.pumpAndSettle();
    expect(skips, 1);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/story/diegetic_trace_sheet_test.dart`
Expected: FAIL — `trace_evaluator.dart` / `diegetic_trace_sheet.dart` do not exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/features/story/trace_evaluator.dart`:

```dart
import 'package:flutter/widgets.dart';

import '../../data/kana_strokes.dart';
import '../kanji_games/trace/kanji_svg_loader.dart';

/// Judges a handwriting attempt at [target] (a short kana string), returning
/// whether it's an acceptable trace. An interface so [DiegeticTraceSheet] can
/// be widget-tested with a fake — the real evaluator loads stroke references
/// from bundled SVG assets, awkward in a widget test. Direct analogue of
/// P6a's `SpeakEvaluator`.
abstract class TraceEvaluator {
  Future<bool> evaluate(String target, List<List<Offset>> userStrokes);
}

/// Real evaluator: accepts when the reader drew at least the expected number
/// of strokes for [target]. The expected count is the real per-character
/// KanjiVG reference stroke count where a kana SVG is bundled
/// (`strokeAssetForKana`), and a minimum of 1 where it isn't (e.g. め today).
/// A deliberately honest "did you make a genuine attempt" bar — precise
/// per-stroke shape scoring (`StrokeValidator`) and bundling more kana SVGs
/// are noted upgrades, not this slice. Not unit-tested (needs bundled assets).
class KanaTraceEvaluator implements TraceEvaluator {
  const KanaTraceEvaluator();

  @override
  Future<bool> evaluate(String target, List<List<Offset>> userStrokes) async {
    if (userStrokes.isEmpty) return false;
    var expected = 0;
    for (final ch in target.split('')) {
      final asset = strokeAssetForKana(ch);
      if (asset == null) {
        expected += 1;
        continue;
      }
      final ref = await KanjiSvgLoader.loadStrokes(asset);
      expected += (ref == null || ref.isEmpty) ? 1 : ref.length;
    }
    return userStrokes.length >= expected;
  }
}
```

Create `lib/features/story/diegetic_trace_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import 'trace_evaluator.dart';

/// The skippable, in-fiction handwriting canvas shown at a `diegetic: true`
/// trace panel (brief P6, Folge 01 P24). The reader traces [targetText] and
/// taps "fertig"; [evaluator] judges the attempt. An accepted trace fires
/// [onSuccess] exactly once (the caller turns that into the SRS encounter).
/// Nothing gates the story: [onSkip] dismisses at any time with no
/// consequence (INV-1). No pass/fail lock.
class DiegeticTraceSheet extends StatefulWidget {
  final String targetText;
  final TraceEvaluator evaluator;
  final VoidCallback onSuccess;
  final VoidCallback onSkip;

  const DiegeticTraceSheet({
    super.key,
    required this.targetText,
    required this.evaluator,
    required this.onSuccess,
    required this.onSkip,
  });

  @override
  State<DiegeticTraceSheet> createState() => _DiegeticTraceSheetState();
}

class _DiegeticTraceSheetState extends State<DiegeticTraceSheet> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  String? _feedback;
  bool _succeeded = false;

  void _panStart(DragStartDetails d) => _current = [d.localPosition];

  void _panUpdate(DragUpdateDetails d) =>
      setState(() => _current.add(d.localPosition));

  void _panEnd(DragEndDetails d) {
    setState(() {
      _strokes.add(List.of(_current));
      _current = [];
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _current = [];
      _feedback = null;
    });
  }

  Future<void> _submit() async {
    final ok = await widget.evaluator.evaluate(widget.targetText, _strokes);
    if (!mounted) return;
    if (ok) {
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
      key: const ValueKey('diegetic-trace-sheet'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('なぞって: ${widget.targetText}',
              style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 12),
          GestureDetector(
            key: const ValueKey('diegetic-trace-canvas'),
            onPanStart: _panStart,
            onPanUpdate: _panUpdate,
            onPanEnd: _panEnd,
            child: Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(color: const Color(0xFFBBBBBB)),
              ),
              child: CustomPaint(
                painter: _InkPainter(_strokes, _current),
                size: Size.infinite,
              ),
            ),
          ),
          if (_feedback != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_feedback!,
                  key: const ValueKey('diegetic-trace-feedback')),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                key: const ValueKey('diegetic-trace-clear'),
                onPressed: _clear,
                child: const Text('löschen'),
              ),
              const Spacer(),
              TextButton(
                key: const ValueKey('diegetic-trace-done'),
                onPressed: _submit,
                child: const Text('fertig'),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const ValueKey('diegetic-trace-skip'),
                onPressed: widget.onSkip,
                child: const Text('weiter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  _InkPainter(this.strokes, this.current);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final stroke in [...strokes, current]) {
      for (var i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter old) => true;
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/story/diegetic_trace_sheet_test.dart`
Expected: PASS (both tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/trace_evaluator.dart lib/features/story/diegetic_trace_sheet.dart test/features/story/diegetic_trace_sheet_test.dart
git commit -m "feat(story): add TraceEvaluator + skippable DiegeticTraceSheet (P6b)"
```

---

### Task 2: Reader integration — open the trace sheet at the diegetic-trace panel

**Files:**
- Modify: `lib/features/story/story_reader_screen.dart`
- Modify: `test/features/story/story_reader_screen_test.dart` (add tests only; do not change existing tests/call sites)
- Test: `test/features/story/story_reader_diegetic_trace_test.dart` (new integration test)

**Interfaces:**
- `StoryReaderScreen` gains two optional params: `final TraceEvaluator? traceEvaluator;` and `final Future<void> Function(List<String> itemIds)? onDiegeticTraceSuccess;`.

- [ ] **Step 1: Write the failing tests**

Add to `test/features/story/story_reader_screen_test.dart` a helper mirroring P24's shape (a token bubble AND an inert note bubble) plus a fake evaluator, then the tests:

```dart
class _FakeTraceEvaluator implements TraceEvaluator {
  final bool ok;
  _FakeTraceEvaluator(this.ok);
  @override
  Future<bool> evaluate(String target, List<List<Offset>> userStrokes) async =>
      ok;
}

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
```

```dart
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
```

Add the import if not present: `import 'package:nihongo_app/features/story/trace_evaluator.dart';`

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/story/story_reader_screen_test.dart`
Expected: FAIL to compile — `No named parameter with the name 'traceEvaluator'`.

- [ ] **Step 3: Write the implementation**

In `lib/features/story/story_reader_screen.dart`:

(a) Add imports: `import 'diegetic_trace_sheet.dart';` and `import 'trace_evaluator.dart';`

(b) Add the two optional fields (after `onDiegeticSpeakSuccess`):
```dart

  /// Judges a handwriting attempt at a `diegetic: true` trace panel (P6b).
  /// When null, diegetic-trace panels open no overlay — the reader stays
  /// fully readable standalone (INV-1). Tests inject a fake.
  final TraceEvaluator? traceEvaluator;

  /// Called with the panel's item ids when a diegetic trace attempt is
  /// accepted (P6b). The caller turns this into the SRS encounter (rung 1).
  final Future<void> Function(List<String> itemIds)? onDiegeticTraceSuccess;
```
Add `this.traceEvaluator,` and `this.onDiegeticTraceSuccess,` to the constructor.

(c) Add `_maybeShowTrace` right after `_maybeShowSpeak`:
```dart
  void _maybeShowTrace(int position) {
    final evaluator = widget.traceEvaluator;
    if (evaluator == null) return;
    final panel = _panels[position];
    final hasTrace = panel.interactions
        .any((i) => i.type == InteractionType.trace && i.diegetic);
    if (!hasTrace) return;

    // Derive the trace target from tokens (surface + itemId), NOT bubble
    // text — P24 carries an inert margin-note bubble with no tokens that
    // must be excluded.
    final tokens = [
      for (final b in panel.bubbles)
        for (final t in b.tokens)
          if (t.itemId != null) t,
    ];
    if (tokens.isEmpty) return;
    final targetText = tokens.map((t) => t.surface).join();
    final itemIds = tokens.map((t) => t.itemId!).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => DiegeticTraceSheet(
          targetText: targetText,
          evaluator: evaluator,
          onSuccess: () => widget.onDiegeticTraceSuccess?.call(itemIds),
          onSkip: () => Navigator.of(sheetContext).pop(),
        ),
      );
    });
  }
```

(d) Call `_maybeShowTrace(...)` right after each existing `_maybeShowSpeak(...)` call — in `_restorePosition` (`_maybeShowTrace(clamped);`) and in `_goTo` (`_maybeShowTrace(position);`).

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/story/story_reader_screen_test.dart`
Expected: PASS — the four new tests plus every pre-existing reader test.

- [ ] **Step 5: Integration — a successful trace reaches rung 1 in a real DB**

Create `test/features/story/story_reader_diegetic_trace_test.dart`:

```dart
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/story/diegetic_encounter.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:nihongo_app/features/story/trace_evaluator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTraceEvaluator implements TraceEvaluator {
  final bool ok;
  _FakeTraceEvaluator(this.ok);
  @override
  Future<bool> evaluate(String target, List<List<Offset>> userStrokes) async =>
      ok;
}

Future<StoryProgressStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return StoryProgressStore(await SharedPreferences.getInstance());
}

Episode _episode() => Episode.fromJson({
      'id': 'ep_trace_int',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'Trace',
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
                {'type': 'trace', 'diegetic': true},
              ],
            },
          ],
        },
      ],
    });

void main() {
  testWidgets('a successful diegetic trace moves the traced item to rung 1 in '
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
        traceEvaluator: _FakeTraceEvaluator(true),
        onDiegeticTraceSuccess: (ids) async {
          for (final id in ids) {
            await enc.encounter(RefType.lexeme, id);
          }
        },
      ),
    ));
    await tester.pump();

    expect(await learning.select(learning.learnItems).get(), isEmpty);

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byKey(const ValueKey('diegetic-trace-canvas')), const Offset(60, 40));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('diegetic-trace-done')));
    await tester.pumpAndSettle();

    final item = await (learning.select(learning.learnItems)
          ..where((t) => t.refId.equals('lex_ja_ame')))
        .getSingleOrNull();
    expect(item, isNotNull);
    expect(item!.masteryRung, 1);
  });
}
```

Run: `flutter test test/features/story/story_reader_diegetic_trace_test.dart`
Expected: PASS. If the item is null, the success callback never reached the encounter — check `_maybeShowTrace` fires `onDiegeticTraceSuccess` with the token's itemId.

- [ ] **Step 6: Run the full story-feature suite together**

Run: `flutter test test/features/story/`
Expected: PASS across all story tests (P1–P6a plus this plan's Task 1/2).

- [ ] **Step 7: Commit**

```bash
git add lib/features/story/story_reader_screen.dart test/features/story/story_reader_screen_test.dart test/features/story/story_reader_diegetic_trace_test.dart
git commit -m "feat(story): open the diegetic trace sheet at P24, feed a success to the ladder (P6b)"
```
