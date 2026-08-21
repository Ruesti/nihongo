# Reicher Lern-Loop — Phase 1 (Erleben & Lesen) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the guided path's learning *visibly richer* — a character shows its stroke order and you **trace it yourself**, and the story scene's words are **tappable to their meaning** — over a fuller first chapter, so the experience is finally judgeable on the device.

**Architecture:** Phase 1 of the richer-lern-loop spec (`docs/superpowers/specs/2026-08-20-reicher-lern-loop-design.md`). No schema migration, no new art. It (1) wires the already-bundled KanjiVG stroke data into the seed, (2) builds a reusable interactive `TracePractice` widget from the existing trace primitives and adds it as a beat in the character lesson, (3) swaps the comic's empty dictionary for a real bundled one so word-taps show meaning, and (4) authors a fuller first chapter + a real multi-bubble readable scene. Later phases (practice/refresh, grammar, example sentences) get their own plans.

**Tech Stack:** Dart 3.12, Flutter, Drift (no migration in Phase 1), Riverpod, `flutter_test`. Test cmd: `flutter test <file> --no-pub`; analyze: `flutter analyze <paths>`.

## Global Constraints

- **Package `nihongo_app`.** Working dir (`<WT>`): `/home/uli/projects/nihongo/.claude/worktrees/spec+onboarding-and-manga` (branch `spec/gefuehrter-weg`).
- **I3 no gamification; offline-first; system-locale; I8 language-agnostic** in journey/comic code (no `if (lang == 'ja')`).
- **„Erst erleben, dann prüfen":** the trace is part of *learning* (ungraded), not a test.
- **Graceful degradation (Asset-Doktrin §6):** missing stroke asset → skip the trace beat; missing/unknown word in the dictionary → gloss shows nothing, never crash.
- **No schema change in Phase 1.** No `build_runner`. (Grammar/sentence schema changes are later phases.)

## Reuse (verbatim from the codebase — do NOT reimplement)

- `strokeAssetForKana(String kana) → String?` (`lib/data/kana_strokes.dart`) — returns `'assets/kanji_svg/<hex>.svg'` for あいうえお, else null. SVGs already bundled.
- `KanjiSvgLoader.loadStrokes(String assetPath, {double canvasSize = 300}) → Future<List<List<Offset>>?>` (`lib/features/kanji_games/trace/kanji_svg_loader.dart`) — cached, null on failure.
- `StrokeValidator.isAcceptable(List<Offset> user, List<Offset> reference) → bool`; `StrokeValidator.directionHint(user, reference) → String?` (`lib/features/kanji_games/trace/stroke_validator.dart`) — all static, pure.
- `StrokePainter({required List<List<Offset>> referenceStrokes, required List<List<Offset>> userStrokes, required int completedStrokes, required bool showGuide, int? highlightStroke})` (`lib/features/kanji_games/trace/stroke_painter.dart`) — a `CustomPainter`.
- `LessonStepScreen` (`lib/features/journey/lesson_step_screen.dart`) — currently: per ref, `introduce`→`EncounterView`→`markEncountered`. `_refs` is `List<(RefType, String)>`. `RefType {lexeme, character, grammar}` from `rung_defs.dart`.
- `ComicRepository({required MiningDb db, required ComicPack pack, required Dictionary dictionary})` + `tap(Token) → WordTapResult` calls `dictionary.lookup(token.lemma, '')` (`lib/features/comic/comic_repository.dart`, `lib/core/text_track/word_tap.dart`). `Dictionary` = `abstract interface class Dictionary { List<Sense> lookup(String lemma, String pos); }`; `Sense({required String pos, required List<String> glosses})` (`lib/core/language_pack/language_pack.dart`).
- `openMangaStep(context, ref, MangaStep)` + `_EmptyComicDictionary` (`lib/features/journey/manga_step_launcher.dart`) — the swap site for a real dictionary.
- JA seed (`lib/packs/ja/ja_seed.dart`): kana `CharactersCompanion` rows (id/languageId/glyph/readingsJson/meaning), the tuple-list + for-loop idiom. Companions: `CharactersCompanion`, `LexemesCompanion`, `ConceptsCompanion`, `AssetsCompanion`. Existing ids: chars `char_ja_a/i/u/e/o`; lexemes `lex_ja_dog/cat/water/eat/what`; concepts `concept_*`.
- Curriculum + comic assets: `assets/curriculum/ja.json`, `assets/comic/ja_l0.json`/`ja_l1.json`, `ComicPack.fromJson` (Bubble{rect,lang,text,tokens,reading?}, BubbleLang{l1,l2}).

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/packs/ja/ja_seed.dart` | Modify | Set `strokeOrderAssetId` on kana; add more kana/words (Task 5) |
| `lib/features/journey/trace_practice.dart` | Create | Interactive `TracePractice` widget (nachzeichnen) |
| `lib/features/journey/lesson_step_screen.dart` | Modify | Add a trace beat after a character encounter |
| `lib/features/comic/bundled_dictionary.dart` | Create | `BundledDictionary` (lemma → senses) + JA data |
| `lib/features/journey/manga_step_launcher.dart` | Modify | Use `BundledDictionary` instead of `_EmptyComicDictionary` |
| `assets/comic/ja_l0.json`, `ja_l1.json` | Modify | Real multi-bubble readable scene |
| `assets/curriculum/ja.json` | Modify | Fuller first chapter |
| `tool/proof_richloop_phase1.dart` | Create | Headless proof |
| `test/**` | Create | Unit + widget tests per task |

---

### Task 1: Stroke-order seed fix (kana show how they're written)

**Files:**
- Modify: `lib/packs/ja/ja_seed.dart`
- Test: `test/packs/ja/ja_seed_strokes_test.dart`

**Interfaces:**
- Consumes: `strokeAssetForKana` (`lib/data/kana_strokes.dart`).
- Produces: seeded kana `Characters` rows carry `strokeOrderAssetId` = the KanjiVG asset path.

- [ ] **Step 1: Write the failing test**

Create `test/packs/ja/ja_seed_strokes_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

void main() {
  test('seeded kana carry their KanjiVG strokeOrderAssetId', () async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await seedJaPack(db);

    final a = await (db.select(db.characters)
          ..where((t) => t.id.equals('char_ja_a')))
        .getSingle();
    expect(a.strokeOrderAssetId, 'assets/kanji_svg/3042.svg');
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/packs/ja/ja_seed_strokes_test.dart --no-pub
```
Expected: FAIL — `strokeOrderAssetId` is null.

- [ ] **Step 3: Edit `lib/packs/ja/ja_seed.dart`**

Add the import at the top (after the existing imports):

```dart
import '../../data/kana_strokes.dart';
```

In the kana `for` loop, add `strokeOrderAssetId` to the `CharactersCompanion`:

```dart
    for (final (id, glyph, readings, meaning) in charRows) {
      await db.into(db.characters).insertOnConflictUpdate(
            CharactersCompanion(
              id: Value(id),
              languageId: const Value('lang_ja'),
              glyph: Value(glyph),
              readingsJson: Value(jsonEncode(readings)),
              meaning: Value(meaning),
              strokeOrderAssetId: Value(strokeAssetForKana(glyph)),
            ),
          );
    }
```

(`strokeAssetForKana` returns null for a kana with no bundled SVG — the column is nullable, so that degrades cleanly.)

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/packs/ja/ja_seed_strokes_test.dart --no-pub
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/packs/ja/ja_seed.dart test/packs/ja/ja_seed_strokes_test.dart
git commit -m "feat(seed): kana carry KanjiVG strokeOrderAssetId (encounter shows stroke order)"
```

---

### Task 2: `TracePractice` widget (nachzeichnen)

**Files:**
- Create: `lib/features/journey/trace_practice.dart`
- Test: `test/features/journey/trace_practice_test.dart`

**Interfaces:**
- Consumes: `KanjiSvgLoader.loadStrokes`, `StrokeValidator.isAcceptable`, `StrokePainter`.
- Produces: `TracePractice({required String assetPath, required VoidCallback onDone})` — loads the reference strokes, lets the learner draw stroke-by-stroke (validated), calls `onDone` when all strokes are traced. If the asset can't load (no strokes), calls `onDone` on the first frame (degrade — nothing to trace).

- [ ] **Step 1: Write the failing widget test**

Create `test/features/journey/trace_practice_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/journey/trace_practice.dart';

void main() {
  testWidgets('degrades: a missing stroke asset resolves onDone immediately',
      (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TracePractice(
          assetPath: 'assets/kanji_svg/does_not_exist.svg',
          onDone: () => done = true,
        ),
      ),
    ));
    await tester.pump(); // FutureBuilder resolves (loader returns null)
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('renders a trace canvas for a bundled kana', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TracePractice(
          assetPath: 'assets/kanji_svg/3042.svg', // あ
          onDone: () {},
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
    // The canvas is present (CustomPaint with our painter).
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/journey/trace_practice_test.dart --no-pub
```
Expected: FAIL — `trace_practice.dart` does not exist.

- [ ] **Step 3: Create `lib/features/journey/trace_practice.dart`**

```dart
import 'package:flutter/material.dart';

import '../kanji_games/trace/kanji_svg_loader.dart';
import '../kanji_games/trace/stroke_painter.dart';
import '../kanji_games/trace/stroke_validator.dart';

/// Interactive "trace the character" beat (nachzeichnen). Loads the KanjiVG
/// reference strokes, shows them as a faint guide, and lets the learner draw
/// each stroke; a stroke is accepted when it is close enough to the reference
/// (StrokeValidator). Calls [onDone] when all strokes are traced — or
/// immediately if the asset has no strokes (graceful degrade).
class TracePractice extends StatefulWidget {
  final String assetPath;
  final VoidCallback onDone;
  const TracePractice({super.key, required this.assetPath, required this.onDone});

  @override
  State<TracePractice> createState() => _TracePracticeState();
}

const double _canvas = 300;

class _TracePracticeState extends State<TracePractice> {
  List<List<Offset>>? _reference; // null while loading
  bool _resolved = false;
  final List<List<Offset>> _userStrokes = [];
  List<Offset> _current = [];
  int _completed = 0;
  String? _hint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final strokes =
        await KanjiSvgLoader.loadStrokes(widget.assetPath, canvasSize: _canvas);
    if (!mounted) return;
    if (strokes == null || strokes.isEmpty) {
      widget.onDone(); // nothing to trace → degrade
      return;
    }
    setState(() {
      _reference = strokes;
      _resolved = true;
    });
  }

  void _onPanStart(DragStartDetails d) {
    if (_reference == null) return;
    _current = [d.localPosition];
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_reference == null) return;
    setState(() => _current = [..._current, d.localPosition]);
  }

  void _onPanEnd(DragEndDetails d) {
    final ref = _reference;
    if (ref == null || _completed >= ref.length) return;
    final target = ref[_completed];
    if (StrokeValidator.isAcceptable(_current, target)) {
      setState(() {
        _userStrokes.add(_current);
        _current = [];
        _completed++;
        _hint = null;
      });
      if (_completed >= ref.length) widget.onDone();
    } else {
      setState(() {
        _hint = StrokeValidator.directionHint(_current, target) ??
            'Noch mal versuchen';
        _current = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return const SizedBox(
        height: _canvas,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final ref = _reference!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Fahr das Zeichen nach — Strich ${_completed + 1} von ${ref.length}',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Container(
            width: _canvas,
            height: _canvas,
            decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
            child: CustomPaint(
              painter: StrokePainter(
                referenceStrokes: ref,
                userStrokes: [..._userStrokes, if (_current.isNotEmpty) _current],
                completedStrokes: _completed,
                showGuide: true,
                highlightStroke: _completed < ref.length ? _completed : null,
              ),
            ),
          ),
        ),
        if (_hint != null) ...[
          const SizedBox(height: 8),
          Text(_hint!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/journey/trace_practice_test.dart --no-pub
```
Expected: 2 tests PASS.

- [ ] **Step 5: Analyze + commit**

```bash
cd <WT> && flutter analyze lib/features/journey/trace_practice.dart test/features/journey/trace_practice_test.dart && \
git add lib/features/journey/trace_practice.dart test/features/journey/trace_practice_test.dart && \
git commit -m "feat(journey): TracePractice — interactive stroke-by-stroke nachzeichnen"
```

---

### Task 3: Add the trace beat to the character lesson

**Files:**
- Modify: `lib/features/journey/lesson_step_screen.dart`
- Test: `test/features/journey/lesson_trace_beat_test.dart`

**Interfaces:**
- Consumes: `TracePractice` (Task 2), the existing `EncounterView` flow.
- Produces: for a **character** ref whose encounter has a `strokeOrderAssetId`, the lesson shows the `EncounterView`, then on "Weiter" shows `TracePractice`, then on trace-done runs the existing `markEncountered` + advance. Non-character refs (or characters without a stroke asset) keep the existing encounter-only flow.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/journey/lesson_trace_beat_test.dart`:

```dart
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';
import 'package:nihongo_app/features/journey/lesson_step_screen.dart';
import 'package:nihongo_app/features/journey/trace_practice.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

void main() {
  testWidgets('a character with a stroke asset shows the trace beat after the encounter',
      (tester) async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'ja-JP'));
    await db.into(db.characters).insert(CharactersCompanion.insert(
        id: 'char_ja_a', languageId: 'lang_ja', glyph: 'あ',
        readingsJson: jsonEncode(['a']), meaning: 'a',
        strokeOrderAssetId: const Value('assets/kanji_svg/3042.svg')));

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWith((ref) => db)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LessonStepScreen(
          step: const LessonStep(
              id: 'l1', chapterRef: 'K1',
              characterIds: ['char_ja_a'], lexemeIds: [], grammarIds: []),
          languageId: 'lang_ja',
          onDone: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Encounter first (glyph + Verstanden). Tap it → trace beat appears.
    expect(find.text('あ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pump();
    await tester.pump();
    expect(find.byType(TracePractice), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/journey/lesson_trace_beat_test.dart --no-pub
```
Expected: FAIL — no `TracePractice` in the tree (the lesson currently advances straight to markEncountered).

- [ ] **Step 3: Edit `lib/features/journey/lesson_step_screen.dart`**

Add the import (with the other feature imports):
```dart
import 'trace_practice.dart';
```

Add a state flag and change the flow so a character encounter is followed by a trace beat. Add a field to `_LessonStepScreenState`:
```dart
  bool _tracing = false;
```

Change `_next()` so that, when the just-shown item is a **character with a stroke asset**, it switches into the trace beat instead of advancing immediately. Replace `_next` with:
```dart
  Future<void> _next() async {
    if (_advancing) return;
    // If the current character has a stroke asset and we haven't traced yet,
    // show the trace beat before marking it encountered.
    final content = _content;
    if (!_tracing &&
        content is EncounterContent &&
        content.encounter is CharacterEncounter &&
        (content.encounter as CharacterEncounter).strokeOrderAssetId != null) {
      setState(() => _tracing = true);
      return;
    }
    _advancing = true;
    _tracing = false;
    final item = _item;
    if (item != null) {
      await _review.markEncountered(item, languageCode: widget.languageId);
    }
    if (!mounted) return;
    _index++;
    if (_index >= _refs.length) {
      widget.onDone();
      return;
    }
    setState(() => _loading = true);
    await _load();
    _advancing = false;
  }
```
Add the `Encounter`/`CharacterEncounter` import for the `is` check:
```dart
import '../../core/ladder/encounter.dart';
```
In `_load()`, reset `_tracing`:
```dart
    setState(() {
      _item = item;
      _content = content;
      _loading = false;
      _tracing = false;
    });
```
In `build`, render the trace beat when `_tracing`:
```dart
  @override
  Widget build(BuildContext context) {
    final content = _content;
    return Scaffold(
      body: SafeArea(
        child: (_loading || content is! EncounterContent)
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: _tracing
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: TracePractice(
                          assetPath:
                              (content.encounter as CharacterEncounter)
                                  .strokeOrderAssetId!,
                          onDone: _next, // trace done → markEncountered + advance
                        ),
                      )
                    : EncounterView(
                        encounter: content.encounter,
                        onDone: _next, // encounter done → trace beat (if char)
                      ),
              ),
      ),
    );
  }
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/journey/lesson_trace_beat_test.dart test/features/journey/lesson_step_screen_test.dart --no-pub
```
Expected: the new test PASSES; the existing `lesson_step_screen_test.dart` still PASSES (its character has NO stroke asset → no trace beat → same behavior; if it did set one, update it — but the existing test's char has none).

- [ ] **Step 5: Analyze + commit**

```bash
cd <WT> && flutter analyze lib/features/journey/lesson_step_screen.dart && \
git add lib/features/journey/lesson_step_screen.dart test/features/journey/lesson_trace_beat_test.dart && \
git commit -m "feat(journey): character lesson adds a trace beat after the encounter"
```

---

### Task 4: Real comic dictionary (word-tap → meaning)

**Files:**
- Create: `lib/features/comic/bundled_dictionary.dart`
- Modify: `lib/features/journey/manga_step_launcher.dart`
- Test: `test/features/comic/bundled_dictionary_test.dart`

**Interfaces:**
- Consumes: `Dictionary`/`Sense` (`lib/core/language_pack/language_pack.dart`).
- Produces: `class BundledDictionary implements Dictionary` backed by a `Map<String, List<Sense>>` (lemma → senses), plus `const jaBundledDictionary` with the first chapter's words. Wired into `openMangaStep`.

- [ ] **Step 1: Write the failing test**

Create `test/features/comic/bundled_dictionary_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/comic/bundled_dictionary.dart';

void main() {
  test('looks up a known lemma, returns senses; unknown → empty', () {
    final senses = jaBundledDictionary.lookup('猫', '');
    expect(senses, isNotEmpty);
    expect(senses.first.glosses, contains('Katze'));

    expect(jaBundledDictionary.lookup('不明', ''), isEmpty);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/comic/bundled_dictionary_test.dart --no-pub
```
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create `lib/features/comic/bundled_dictionary.dart`**

```dart
import '../../core/language_pack/language_pack.dart' show Dictionary, Sense;

/// A tiny bundled lemma→meaning dictionary so tapping an L2 word in the comic
/// shows a real gloss (instead of "—"). Keyed on lemma; the pos argument is
/// ignored (WordTapHandler always passes ''). Grows with the curriculum;
/// a full JMdict-backed dictionary is a later concern.
class BundledDictionary implements Dictionary {
  final Map<String, List<Sense>> _byLemma;
  const BundledDictionary(this._byLemma);

  @override
  List<Sense> lookup(String lemma, String pos) => _byLemma[lemma] ?? const [];
}

/// The Japanese first-chapter vocabulary (matches the seeded lexemes).
const BundledDictionary jaBundledDictionary = BundledDictionary({
  '猫': [Sense(pos: 'n', glosses: ['Katze'])],
  '犬': [Sense(pos: 'n', glosses: ['Hund'])],
  '水': [Sense(pos: 'n', glosses: ['Wasser'])],
  '食べる': [Sense(pos: 'v', glosses: ['essen'])],
  '何': [Sense(pos: 'pron', glosses: ['was'])],
});
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/comic/bundled_dictionary_test.dart --no-pub
```
Expected: PASS.

- [ ] **Step 5: Wire it into `manga_step_launcher.dart`**

Replace the `_EmptyComicDictionary` usage. Add the import:
```dart
import '../comic/bundled_dictionary.dart';
```
Change the `ComicRepository` construction in `openMangaStep` to use the bundled dictionary:
```dart
      repo: ComicRepository(
        db: db,
        pack: pack,
        dictionary: jaBundledDictionary,
      ),
```
Delete the now-unused private `_EmptyComicDictionary` class from this file (and its `Sense`/`Dictionary`-only import if it becomes unused — keep the import if still referenced elsewhere in the file; it is not, so remove `show Dictionary, Sense` if the analyzer flags it unused).

- [ ] **Step 6: Analyze + commit**

```bash
cd <WT> && flutter analyze lib/features/comic/bundled_dictionary.dart lib/features/journey/manga_step_launcher.dart && \
git add lib/features/comic/bundled_dictionary.dart lib/features/journey/manga_step_launcher.dart test/features/comic/bundled_dictionary_test.dart && \
git commit -m "feat(comic): bundled dictionary so word-taps show real meaning (not '—')"
```

---

### Task 5: A fuller, readable first chapter (content)

**Files:**
- Modify: `lib/packs/ja/ja_seed.dart` (more kana + words)
- Modify: `assets/comic/ja_l0.json`, `assets/comic/ja_l1.json` (real multi-bubble scene)
- Modify: `assets/curriculum/ja.json` (fuller chapters)
- Test: `test/features/journey/rich_chapter_test.dart`

**Interfaces:**
- Consumes: everything above; the curriculum + comic parsers.
- Produces: a first arc with more substance — additional seeded kana (with stroke assets via Task 1's loop) + words, comic scenes with several bubbles mixing German + learned Japanese, and a curriculum that teaches them before reading.

- [ ] **Step 1: Add more kana + a couple more words to `lib/packs/ja/ja_seed.dart`**

Extend `charRows` with the か-row start (か = U+304B) so a lesson can teach beyond the vowels. Add a bundled stroke SVG only if present; the loop already sets `strokeOrderAssetId: Value(strokeAssetForKana(glyph))`, which returns null for kana without a bundled SVG (degrades to no-trace). Add to `charRows`:
```dart
      ('char_ja_ka', 'か', ['ka'], 'ka'),
      ('char_ja_ki', 'き', ['ki'], 'ki'),
```
Extend `conceptRows` + `lexemeRows` with one more everyday word (a greeting is not a noun; keep it simple — reuse existing concepts). No new concept needed if you only add kana. Leave lexemes as the existing five (`猫/犬/水/食べる/何`) — they already back the dictionary and the scene.

(Note: か/き have no bundled KanjiVG SVG in `_bundledKanaCodepoints`, so their trace beat is skipped — honest degrade. The vowels あいうえお keep their trace.)

- [ ] **Step 2: Author a real readable scene in `assets/comic/ja_l0.json`**

Replace the single-bubble placeholder with a small readable scene (German narration + learned Japanese, so the learner *reads* it). Keep the existing schema (`languageCode`, `title`, `level`, `l2Ratio`, `pages[].bubbles[]` with `rect` normalized 0..1, `lang` `l1`/`l2`, `text`, `tokens`, optional `reading`). Example page:
```json
{
  "languageCode": "ja",
  "title": "Neko no hi",
  "level": 0,
  "l2Ratio": 0.35,
  "pages": [
    {
      "pageRef": "p1",
      "imageAsset": "assets/comic/placeholder_page.png",
      "aspectRatio": 0.7,
      "bubbles": [
        {"rect": {"left": 0.06, "top": 0.06, "right": 0.62, "bottom": 0.16},
         "lang": "l1", "text": "Am Morgen. Ein Tier kommt.", "tokens": []},
        {"rect": {"left": 0.5, "top": 0.4, "right": 0.94, "bottom": 0.52},
         "lang": "l2", "text": "猫", "reading": "ねこ",
         "tokens": [{"surface": "猫", "lemma": "猫", "reading": "ねこ", "pos": "n", "charStart": 0, "charEnd": 1}]},
        {"rect": {"left": 0.06, "top": 0.6, "right": 0.7, "bottom": 0.72},
         "lang": "l1", "text": "Eine Katze! Und sie will …", "tokens": []},
        {"rect": {"left": 0.4, "top": 0.82, "right": 0.94, "bottom": 0.94},
         "lang": "l2", "text": "水", "reading": "みず",
         "tokens": [{"surface": "水", "lemma": "水", "reading": "みず", "pos": "n", "charStart": 0, "charEnd": 1}]}
      ]
    }
  ]
}
```
Do the same for `ja_l1.json` with 犬 (Hund) added and a slightly higher `l2Ratio`. Keep every L2 `lemma` present in `jaBundledDictionary` (Task 4) so taps gloss.

- [ ] **Step 3: Update `assets/curriculum/ja.json`** so a chapter teaches the vowels + a word, then reads the scene (interleaved, not all-kana-first):
```json
{
  "languageCode": "ja",
  "title": "Neko no hi",
  "steps": [
    {"id": "c1-lesson", "kind": "lesson", "chapterRef": "Kapitel 1",
     "characterIds": ["char_ja_a", "char_ja_i", "char_ja_u"], "lexemeIds": ["lex_ja_cat", "lex_ja_water"], "grammarIds": []},
    {"id": "c1-manga", "kind": "manga", "chapterRef": "Kapitel 1", "comicAsset": "assets/comic/ja_l0.json"},
    {"id": "c2-lesson", "kind": "lesson", "chapterRef": "Kapitel 2",
     "characterIds": ["char_ja_e", "char_ja_o"], "lexemeIds": ["lex_ja_dog"], "grammarIds": []},
    {"id": "c2-manga", "kind": "manga", "chapterRef": "Kapitel 2", "comicAsset": "assets/comic/ja_l1.json"}
  ]
}
```

- [ ] **Step 4: Write + run the test**

Create `test/features/journey/rich_chapter_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/bundled_dictionary.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<String> load(String p) => rootBundle.loadString(p);

  test('chapter 1 teaches a few kana + a word before reading', () async {
    final c = Curriculum.fromJson(
        jsonDecode(await load('assets/curriculum/ja.json')) as Map<String, dynamic>);
    final first = c.steps[0] as LessonStep;
    expect(first.characterIds.length, greaterThanOrEqualTo(2));
    expect(first.lexemeIds, isNotEmpty);
    expect(c.steps[1], isA<MangaStep>());
  });

  test('every L2 word in the scene has a gloss in the bundled dictionary', () async {
    final pack = ComicPack.fromJson(
        jsonDecode(await load('assets/comic/ja_l0.json')) as Map<String, dynamic>);
    for (final page in pack.pages) {
      for (final b in page.bubbles.where((b) => b.lang == BubbleLang.l2)) {
        for (final t in b.tokens) {
          expect(jaBundledDictionary.lookup(t.lemma, ''), isNotEmpty,
              reason: 'no gloss for ${t.lemma}');
        }
      }
    }
  });
}
```

```bash
cd <WT> && flutter pub get && flutter test test/features/journey/rich_chapter_test.dart --no-pub
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/packs/ja/ja_seed.dart assets/comic/ja_l0.json assets/comic/ja_l1.json assets/curriculum/ja.json test/features/journey/rich_chapter_test.dart
git commit -m "feat(content): fuller first chapter — more kana + a readable multi-bubble scene"
```

---

### Task 6: Proof + full verification

**Files:**
- Create: `tool/proof_richloop_phase1.dart`

- [ ] **Step 1: Write the proof tool**

Create `tool/proof_richloop_phase1.dart`:

```dart
// Proof: Reicher Lern-Loop Phase 1
//   "Kana carry stroke assets; the scene's L2 words all resolve to a gloss."
//
// Usage: dart run tool/proof_richloop_phase1.dart

import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/comic/bundled_dictionary.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

Future<void> main(List<String> args) async {
  final db = LearningDb.forTesting();
  await seedJaPack(db);
  final a = await db.getLearnItem('lang_ja:character:char_ja_a'); // may be null (not introduced)
  final chars = await db.select(db.characters).get();
  final aRow = chars.firstWhere((c) => c.id == 'char_ja_a');
  final strokeOk = aRow.strokeOrderAssetId == 'assets/kanji_svg/3042.svg';

  final glossOk = jaBundledDictionary.lookup('猫', '').isNotEmpty &&
      jaBundledDictionary.lookup('水', '').isNotEmpty;

  print('=== Rich-Loop Phase 1 gate ===');
  print('kana carries stroke asset: $strokeOk');
  print('scene words have glosses:  $glossOk');
  final pass = strokeOk && glossOk;
  print('GATE: ${pass ? 'PASS' : 'FAIL'}');
  await db.close();
  print(pass ? '=== PASS ===' : '=== FAIL ===');
  // (a is referenced to avoid an unused-var lint if the analyzer is strict)
  assert(a == null || a != null);
}
```

- [ ] **Step 2: Run the proof**

```bash
cd <WT> && dart run tool/proof_richloop_phase1.dart
```
Expected: `GATE: PASS`, `=== PASS ===`.

- [ ] **Step 3: Full suite + analyze**

```bash
cd <WT> && flutter test --no-pub
```
Expected: all pass except the 8 pre-existing native-tokenizer FFI failures in `test/mining_packs/ja/`. Confirm only those 8 fail.

```bash
cd <WT> && flutter analyze
```
Expected: 0 errors in new code.

- [ ] **Step 4: Commit**

```bash
git add tool/proof_richloop_phase1.dart
git commit -m "test(proof): rich-loop phase 1 gate (stroke assets + scene glosses)"
```

---

## Self-Review notes (for the executor)

- **Spec coverage (Phase 1 subset):** stroke order wired (Task 1), interactive nachzeichnen (Tasks 2–3), word-tap → meaning (Task 4), fuller readable chapter (Task 5), proof (Task 6). Deferred to later phases (own plans): the `GradedExerciseRunner` extraction + Kurz-üben + RefreshStep (practice/wiederholen), grammar schema + content + graded practice, concept images (real art) + example sentences (schema link).
- **No schema migration in Phase 1** — deliberately, to keep it fast and low-risk; the schema-heavy grammar/sentence work is Phase 3/4.
- **Verify before coding:** confirm the exact current bodies of `lesson_step_screen.dart` `_next`/`_load`/`build` and `manga_step_launcher.dart` before editing (Tasks 3, 4) and match what is on disk.
- **Device test after Phase 1:** the whole point — build (split-per-abi arm64 release, Impeller off for the S23) and deploy so the learner can judge the trace + gloss + readable scene.
