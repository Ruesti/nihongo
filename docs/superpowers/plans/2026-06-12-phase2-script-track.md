# Phase 2: Script Track + Rung 4 (Write-Trace) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the mastery ladder to rung 4 (write-trace), add exercise content loading, and prove the hiragana character track through all 4 rungs end-to-end.

**Architecture:** `writeTrace` is added to `ExerciseType` and `resolveExercise` maps rung 4 → writeTrace (always, per spec §5). A sealed `ExerciseContent` class with 4 variants holds what the UI will eventually render. `ExerciseLoader` is a thin DB-backed service: given a `LearnItem` + `ScriptProfile`, it loads the character/lexeme row and returns the right content variant. No schema changes — `characters` and `lexemes` tables from Phase 0 contain everything needed.

**Tech Stack:** Dart 3.11 (sealed classes, exhaustive pattern-matching switch), Drift 2.22, flutter_test / `NativeDatabase.memory()`

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/core/ladder/rung_defs.dart` | Modify | Add `writeTrace` to `ExerciseType`; rung 4 → writeTrace in `resolveExercise` |
| `lib/core/ladder/exercise_content.dart` | Create | Sealed class with 4 content variants (pure data, no DB) |
| `lib/core/ladder/exercise_loader.dart` | Create | DB-backed loader: `LearnItem` + `ScriptProfile` → `ExerciseContent` |
| `test/core/ladder/rung_defs_test.dart` | Modify | Replace "rung 4 and 5 → productionInput" with separate writeTrace + productionInput tests |
| `test/core/ladder/exercise_loader_test.dart` | Create | Integration tests: content at each rung, lexeme loading, character promotion loop |

---

## Existing seed data (from `lib/packs/ja/ja_seed.dart`)

Character data used in tests:
- `char_ja_a`: glyph `あ`, readingsJson `'["a"]'`, meaning `'vowel a'`
- `char_ja_i`: glyph `い`, readingsJson `'["i"]'`, meaning `'vowel i'`

Lexeme data:
- `lex_ja_dog`: writtenForm `'犬'`, reading `'いぬ'`, conceptId `'concept_dog'`

Concept data:
- `concept_dog`: glossKey `'dog'`

---

### Task 1: Add `writeTrace` to ExerciseType and update resolveExercise

**Files:**
- Modify: `lib/core/ladder/rung_defs.dart`
- Modify: `test/core/ladder/rung_defs_test.dart`

- [ ] **Step 1: Update the test first (will fail — writeTrace doesn't exist yet)**

Replace `test/core/ladder/rung_defs_test.dart` entirely with this content:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/script_profile.dart';

const _jaKanaProfile = ScriptProfile(
  id: 'sp_ja_kana',
  scriptType: ScriptType.syllabary,
  direction: Direction.ltr,
  decomposability: Decomposability.atomic,
  positionalForms: false,
  toneSystem: ToneSystem.pitchAccent,
  needsScriptTrack: true,
  transliteration: 'romaji',
  inputMethods: [InputMethod.keyboard],
);

const _esProfile = ScriptProfile(
  id: 'sp_es',
  scriptType: ScriptType.alphabet,
  direction: Direction.ltr,
  decomposability: Decomposability.atomic,
  positionalForms: false,
  toneSystem: ToneSystem.none,
  needsScriptTrack: false,
  transliteration: 'none',
  inputMethods: [InputMethod.keyboard],
);

void main() {
  group('resolveExercise', () {
    test('rung 1 → recognition (any refType, any profile)', () {
      expect(resolveExercise(1, RefType.lexeme, _jaKanaProfile), ExerciseType.recognition);
      expect(resolveExercise(1, RefType.character, _jaKanaProfile), ExerciseType.recognition);
      expect(resolveExercise(1, RefType.lexeme, _esProfile), ExerciseType.recognition);
    });

    test('rung 2 → readingInput', () {
      expect(resolveExercise(2, RefType.lexeme, _jaKanaProfile), ExerciseType.readingInput);
      expect(resolveExercise(2, RefType.character, _jaKanaProfile), ExerciseType.readingInput);
    });

    test('rung 3 → productionInput (I1: no MC on production rungs)', () {
      expect(resolveExercise(3, RefType.lexeme, _jaKanaProfile), ExerciseType.productionInput);
      expect(resolveExercise(3, RefType.character, _jaKanaProfile), ExerciseType.productionInput);
    });

    test('rung 4 → writeTrace (always, per spec §5)', () {
      expect(resolveExercise(4, RefType.lexeme, _jaKanaProfile), ExerciseType.writeTrace);
      expect(resolveExercise(4, RefType.character, _jaKanaProfile), ExerciseType.writeTrace);
      expect(resolveExercise(4, RefType.lexeme, _esProfile), ExerciseType.writeTrace);
    });

    test('rung 5 → productionInput', () {
      expect(resolveExercise(5, RefType.lexeme, _jaKanaProfile), ExerciseType.productionInput);
      expect(resolveExercise(5, RefType.character, _jaKanaProfile), ExerciseType.productionInput);
    });

    test('production rungs never return recognition (I1 invariant)', () {
      for (final rung in [3, 4, 5]) {
        final type = resolveExercise(rung, RefType.lexeme, _jaKanaProfile);
        expect(type, isNot(ExerciseType.recognition));
      }
    });
  });

  test('promotionThreshold is 3', () {
    expect(promotionThreshold, 3);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/ladder/rung_defs_test.dart
```
Expected: FAIL — `ExerciseType.writeTrace` undefined.

- [ ] **Step 3: Update `lib/core/ladder/rung_defs.dart`**

Replace entire file with:

```dart
import '../script_profile.dart';

enum ExerciseType {
  recognition,     // rung 1: show written/glyph, identify meaning
  readingInput,    // rung 2: show written/glyph, type reading
  productionInput, // rung 3, 5: show meaning, type written form (no MC — I1)
  writeTrace,      // rung 4: show glyph + stroke order, trace it (spec §5)
}

enum RefType { lexeme, character, grammar }

const int promotionThreshold = 3;

ExerciseType resolveExercise(int rung, RefType refType, ScriptProfile profile) {
  assert(rung >= 1 && rung <= 5, 'rung must be 1–5, got $rung');
  if (rung <= 1) return ExerciseType.recognition;
  if (rung == 2) return ExerciseType.readingInput;
  if (rung == 4) return ExerciseType.writeTrace;
  return ExerciseType.productionInput;
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/ladder/rung_defs_test.dart
```
Expected: 7 tests PASS.

- [ ] **Step 5: Run full suite to confirm no regressions**

```bash
cd /home/uli/Projects/nihongo && flutter test
```
Expected: All 46 prior tests still PASS. (The `ExerciseType` enum addition is non-breaking — existing switch statements that previously fell through to `productionInput` for rung 4 are in test code only, and the updated test already accounts for `writeTrace`.)

- [ ] **Step 6: Commit**

```bash
git add lib/core/ladder/rung_defs.dart test/core/ladder/rung_defs_test.dart
git commit -m "feat(phase2): add writeTrace exercise type — rung 4 always (spec §5)"
```

---

### Task 2: ExerciseContent sealed class

**Files:**
- Create: `lib/core/ladder/exercise_content.dart`

This is pure data — no logic, no DB, no tests in isolation. The integration tests in Task 3 verify all fields are populated correctly.

- [ ] **Step 1: Create `lib/core/ladder/exercise_content.dart`**

```dart
sealed class ExerciseContent {}

final class RecognitionContent extends ExerciseContent {
  final String displayForm; // glyph or writtenForm to show
  final String answer;      // expected identification (meaning or glossKey)

  RecognitionContent({required this.displayForm, required this.answer});
}

final class ReadingInputContent extends ExerciseContent {
  final String displayForm;
  final String expectedReading;

  ReadingInputContent({
    required this.displayForm,
    required this.expectedReading,
  });
}

final class ProductionInputContent extends ExerciseContent {
  final String prompt;       // meaning or glossKey — what to show the learner
  final String expectedForm; // writtenForm or glyph — what the learner must type

  ProductionInputContent({required this.prompt, required this.expectedForm});
}

final class WriteTraceContent extends ExerciseContent {
  final String glyph;
  final String? strokeOrderAssetId; // null until assets are generated (Phase 6)
  final String expectedReading;

  WriteTraceContent({
    required this.glyph,
    this.strokeOrderAssetId,
    required this.expectedReading,
  });
}
```

- [ ] **Step 2: Run flutter analyze to confirm it compiles cleanly**

```bash
cd /home/uli/Projects/nihongo && flutter analyze lib/core/ladder/exercise_content.dart
```
Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/ladder/exercise_content.dart
git commit -m "feat(phase2): ExerciseContent sealed class — 4 variants for rung 1-4"
```

---

### Task 3: ExerciseLoader + integration tests

**Files:**
- Create: `lib/core/ladder/exercise_loader.dart`
- Create: `test/core/ladder/exercise_loader_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/core/ladder/exercise_loader_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/exercise_content.dart';
import 'package:nihongo_app/core/ladder/exercise_loader.dart';
import 'package:nihongo_app/core/ladder/ladder_service.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/script_profile.dart';
import 'package:nihongo_app/core/srs/scheduler.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

const _jaProfile = ScriptProfile(
  id: 'sp_ja_kana',
  scriptType: ScriptType.syllabary,
  direction: Direction.ltr,
  decomposability: Decomposability.atomic,
  positionalForms: false,
  toneSystem: ToneSystem.pitchAccent,
  needsScriptTrack: true,
  transliteration: 'romaji',
  inputMethods: [InputMethod.keyboard],
);

void main() {
  late LearningDb db;
  late ExerciseLoader loader;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedJaPack(db);
    loader = ExerciseLoader(db);
  });

  tearDown(() async => db.close());

  group('character content — each rung', () {
    test('rung 1 → RecognitionContent with glyph and meaning', () async {
      await db.addLearnItem('lang_ja', RefType.character, 'char_ja_a');
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _jaProfile);

      expect(content, isA<RecognitionContent>());
      final rec = content as RecognitionContent;
      expect(rec.displayForm, 'あ');
      expect(rec.answer, 'vowel a');
    });

    test('rung 2 → ReadingInputContent with glyph and expected reading', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 2);
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _jaProfile);

      expect(content, isA<ReadingInputContent>());
      final read = content as ReadingInputContent;
      expect(read.displayForm, 'あ');
      expect(read.expectedReading, 'a');
    });

    test('rung 3 → ProductionInputContent with meaning prompt', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 3);
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _jaProfile);

      expect(content, isA<ProductionInputContent>());
      final prod = content as ProductionInputContent;
      expect(prod.prompt, 'vowel a');
      expect(prod.expectedForm, 'あ');
    });

    test('rung 4 → WriteTraceContent with glyph and reading', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 4);
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _jaProfile);

      expect(content, isA<WriteTraceContent>());
      final trace = content as WriteTraceContent;
      expect(trace.glyph, 'あ');
      expect(trace.expectedReading, 'a');
      expect(trace.strokeOrderAssetId, isNull); // no stroke assets yet (Phase 6)
    });
  });

  group('lexeme content loading', () {
    test('rung 1 → RecognitionContent with writtenForm and glossKey', () async {
      await db.addLearnItem('lang_ja', RefType.lexeme, 'lex_ja_dog');
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _jaProfile);

      expect(content, isA<RecognitionContent>());
      final rec = content as RecognitionContent;
      expect(rec.displayForm, '犬');
      expect(rec.answer, 'dog');
    });

    test('rung 2 → ReadingInputContent with writtenForm and reading', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog', rung: 2);
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _jaProfile);

      expect(content, isA<ReadingInputContent>());
      final read = content as ReadingInputContent;
      expect(read.displayForm, '犬');
      expect(read.expectedReading, 'いぬ');
    });
  });

  test('character promotion loop: rung 1 → rung 4, content is WriteTraceContent', () async {
    await db.addLearnItem('lang_ja', RefType.character, 'char_ja_i');

    // 3 promotions × 3 consecutive good = 9 reviews total
    for (int targetRung = 1; targetRung <= 3; targetRung++) {
      for (int i = 0; i < promotionThreshold; i++) {
        final item = (await db.select(db.learnItems).get()).first;
        final result = processResult(
          currentRung: item.masteryRung,
          consecutiveCorrect: item.consecutiveCorrect,
          scheduleInput: ScheduleInput(
            ease: item.ease,
            intervalDays: item.intervalDays,
            reps: item.reps,
          ),
          result: ReviewResult.good,
        );
        await db.applyReviewResult(item, result, ReviewResult.good);
      }
    }

    final promoted = (await db.select(db.learnItems).get()).first;
    expect(promoted.masteryRung, 4);

    final content = await loader.load(promoted, _jaProfile);
    expect(content, isA<WriteTraceContent>());
    final trace = content as WriteTraceContent;
    expect(trace.glyph, 'い');
    expect(trace.expectedReading, 'i');
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/ladder/exercise_loader_test.dart
```
Expected: FAIL — `ExerciseLoader` undefined.

- [ ] **Step 3: Create `lib/core/ladder/exercise_loader.dart`**

```dart
import 'dart:convert';

import '../db/learning_db.dart';
import '../script_profile.dart';
import 'exercise_content.dart';
import 'rung_defs.dart';

class ExerciseLoader {
  final LearningDb _db;

  ExerciseLoader(this._db);

  Future<ExerciseContent> load(LearnItem item, ScriptProfile profile) {
    final refType = RefType.values.byName(item.refType);
    final exerciseType = resolveExercise(item.masteryRung, refType, profile);

    return switch (refType) {
      RefType.character => _loadCharacter(item.refId, exerciseType),
      RefType.lexeme => _loadLexeme(item.refId, exerciseType),
      RefType.grammar =>
        throw UnimplementedError('grammar exercises not yet supported'),
    };
  }

  Future<ExerciseContent> _loadCharacter(
    String charId,
    ExerciseType type,
  ) async {
    final char = await (_db.select(_db.characters)
          ..where((t) => t.id.equals(charId)))
        .getSingle();
    final readings = (jsonDecode(char.readingsJson) as List).cast<String>();
    final reading = readings.isNotEmpty ? readings.first : '';

    return switch (type) {
      ExerciseType.recognition =>
        RecognitionContent(displayForm: char.glyph, answer: char.meaning),
      ExerciseType.readingInput =>
        ReadingInputContent(displayForm: char.glyph, expectedReading: reading),
      ExerciseType.productionInput =>
        ProductionInputContent(prompt: char.meaning, expectedForm: char.glyph),
      ExerciseType.writeTrace => WriteTraceContent(
          glyph: char.glyph,
          strokeOrderAssetId: char.strokeOrderAssetId,
          expectedReading: reading,
        ),
    };
  }

  Future<ExerciseContent> _loadLexeme(
    String lexemeId,
    ExerciseType type,
  ) async {
    final lexeme = await (_db.select(_db.lexemes)
          ..where((t) => t.id.equals(lexemeId)))
        .getSingle();
    final concept = await (_db.select(_db.concepts)
          ..where((t) => t.id.equals(lexeme.conceptId)))
        .getSingle();

    return switch (type) {
      ExerciseType.recognition =>
        RecognitionContent(displayForm: lexeme.writtenForm, answer: concept.glossKey),
      ExerciseType.readingInput => ReadingInputContent(
          displayForm: lexeme.writtenForm,
          expectedReading: lexeme.reading,
        ),
      ExerciseType.productionInput => ProductionInputContent(
          prompt: concept.glossKey,
          expectedForm: lexeme.writtenForm,
        ),
      ExerciseType.writeTrace => ProductionInputContent(
          prompt: concept.glossKey,
          expectedForm: lexeme.writtenForm,
        ),
    };
  }
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/ladder/exercise_loader_test.dart
```
Expected: 7 tests PASS.

- [ ] **Step 5: Run full suite**

```bash
cd /home/uli/Projects/nihongo && flutter test
```
Expected: All 46 prior + 7 new = 53 tests PASS.

- [ ] **Step 6: Run flutter analyze**

```bash
cd /home/uli/Projects/nihongo && flutter analyze lib/core/ladder/
```
Expected: 0 errors.

- [ ] **Step 7: Commit**

```bash
git add lib/core/ladder/exercise_loader.dart test/core/ladder/exercise_loader_test.dart
git commit -m "feat(phase2): ExerciseLoader — character + lexeme content for rungs 1-4"
```

---

### Task 4: Final verification

- [ ] **Step 1: Run full test suite**

```bash
cd /home/uli/Projects/nihongo && flutter test
```
Expected: 54 tests PASS. Breakdown:
- 1 widget smoke test
- Phase 0: 15 tests (ScriptProfile 6 + LearningDb 9)
- Phase 1: 31 tests (scheduler 9 + rung_defs 7 + ladder_service 9 + review_loop 6)
- Phase 2: 7 tests (exercise_loader)

- [ ] **Step 2: Run flutter analyze**

```bash
cd /home/uli/Projects/nihongo && flutter analyze
```
Expected: 0 errors (pre-existing info-level deprecation warnings in lib/widgets/ are acceptable).

- [ ] **Step 3: Confirm git log**

```bash
git log --oneline -5
```
Expected: 3 phase2 commits visible at the top.
