# Phase 1: SM-2 Engine + Review Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the SM-2 scheduling engine, 5-rung ladder with exercise-type resolver, and prove the full review loop works end-to-end via integration tests — no UI, no games, no AI.

**Architecture:** Three pure-Dart modules (`core/srs/`, `core/ladder/`) handle all logic with no Flutter/Drift dependencies; a schema migration adds `consecutiveCorrect` to `learn_items`; DAOs on `LearningDb` wire logic to storage. Promotion requires 3 consecutive good/easy results at the same rung; demotion on `again` drops one rung. Both invariants I1 (no MC on production rungs) and I2 (SRS timing ≠ difficulty) are enforced by design.

**Tech Stack:** Dart 3.11 (pure functions, enums, pattern-matching switch), Drift 2.22 (schema migration via `MigrationStrategy`), flutter_test / `NativeDatabase.memory()`.

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/core/srs/scheduler.dart` | Create | SM-2 pure function — updates ease/interval/dueAt, knows nothing about rung |
| `lib/core/ladder/rung_defs.dart` | Create | ExerciseType enum, RefType enum, `resolveExercise()` — no state |
| `lib/core/ladder/ladder_service.dart` | Create | `processResult()` — combines SM-2 + promotion/demotion logic |
| `lib/core/db/tables.dart` | Modify | Add `consecutiveCorrect` column to `LearnItems` |
| `lib/core/db/learning_db.dart` | Modify | schemaVersion→2, migration, DAO methods |
| `lib/core/db/learning_db.g.dart` | Regenerated | via `dart run build_runner build` |
| `test/core/srs/scheduler_test.dart` | Create | Unit tests for SM-2 |
| `test/core/ladder/rung_defs_test.dart` | Create | Unit tests for exercise resolver |
| `test/core/ladder/ladder_service_test.dart` | Create | Unit tests for promotion/demotion |
| `test/core/db/review_loop_test.dart` | Create | Integration test — proves the full loop |

---

### Task 1: SM-2 scheduler

**Files:**
- Create: `lib/core/srs/scheduler.dart`
- Create: `test/core/srs/scheduler_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/srs/scheduler_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/srs/scheduler.dart';

void main() {
  const base = ScheduleInput(ease: 2.5, intervalDays: 0, reps: 0);

  test('again resets interval and reduces ease', () {
    final out = schedule(base, ReviewResult.again);
    expect(out.intervalDays, 0);
    expect(out.ease, closeTo(2.3, 0.01));
    expect(out.reps, 0);
    expect(out.dueAt.isAfter(DateTime.now()), isTrue);
    expect(
      out.dueAt.isBefore(DateTime.now().add(const Duration(minutes: 2))),
      isTrue,
    );
  });

  test('good on first rep gives interval=1', () {
    final out = schedule(base, ReviewResult.good);
    expect(out.intervalDays, 1);
    expect(out.reps, 1);
    expect(out.ease, closeTo(2.5, 0.01));
  });

  test('good on second rep gives interval=4', () {
    final out = schedule(
      const ScheduleInput(ease: 2.5, intervalDays: 1, reps: 1),
      ReviewResult.good,
    );
    expect(out.intervalDays, 4);
    expect(out.reps, 2);
  });

  test('good on third rep multiplies interval by ease', () {
    final out = schedule(
      const ScheduleInput(ease: 2.5, intervalDays: 4, reps: 2),
      ReviewResult.good,
    );
    expect(out.intervalDays, 10); // 4 * 2.5 = 10
    expect(out.reps, 3);
  });

  test('easy on first rep gives interval=4 and increases ease', () {
    final out = schedule(base, ReviewResult.easy);
    expect(out.intervalDays, 4);
    expect(out.ease, closeTo(2.6, 0.01));
    expect(out.reps, 1);
  });

  test('hard increases interval slightly and reduces ease', () {
    final out = schedule(
      const ScheduleInput(ease: 2.5, intervalDays: 4, reps: 2),
      ReviewResult.hard,
    );
    expect(out.ease, closeTo(2.35, 0.01));
    expect(out.intervalDays, 5); // ceil(4 * 1.2) = 5
    expect(out.reps, 2); // reps unchanged on hard
  });

  test('hard on new card gives interval=1', () {
    final out = schedule(base, ReviewResult.hard);
    expect(out.intervalDays, 1);
  });

  test('ease never drops below 1.3', () {
    final out = schedule(
      const ScheduleInput(ease: 1.35, intervalDays: 1, reps: 1),
      ReviewResult.again,
    );
    expect(out.ease, closeTo(1.3, 0.01));
  });

  test('ease never exceeds 3.0', () {
    final out = schedule(
      const ScheduleInput(ease: 2.95, intervalDays: 4, reps: 2),
      ReviewResult.easy,
    );
    expect(out.ease, closeTo(3.0, 0.01));
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/srs/scheduler_test.dart
```
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Create `lib/core/srs/scheduler.dart`**

```dart
enum ReviewResult { again, hard, good, easy }

class ScheduleInput {
  final double ease;
  final int intervalDays;
  final int reps;

  const ScheduleInput({
    required this.ease,
    required this.intervalDays,
    required this.reps,
  });
}

class ScheduleOutput {
  final double ease;
  final int intervalDays;
  final DateTime dueAt;
  final int reps;

  const ScheduleOutput({
    required this.ease,
    required this.intervalDays,
    required this.dueAt,
    required this.reps,
  });
}

ScheduleOutput schedule(ScheduleInput input, ReviewResult result) {
  final now = DateTime.now();
  double ease = input.ease.clamp(1.3, 3.0);
  int interval = input.intervalDays;
  int reps = input.reps;

  switch (result) {
    case ReviewResult.again:
      interval = 0;
      ease = (ease - 0.2).clamp(1.3, 3.0);
      reps = 0;
    case ReviewResult.hard:
      interval = interval == 0 ? 1 : (interval * 1.2).round().clamp(1, 999);
      ease = (ease - 0.15).clamp(1.3, 3.0);
    case ReviewResult.good:
      if (reps == 0) {
        interval = 1;
      } else if (reps == 1) {
        interval = 4;
      } else {
        interval = (interval * ease).round().clamp(1, 999);
      }
      reps++;
    case ReviewResult.easy:
      if (reps == 0) {
        interval = 4;
      } else if (reps == 1) {
        interval = 7;
      } else {
        interval = (interval * ease * 1.3).round().clamp(1, 999);
      }
      ease = (ease + 0.1).clamp(1.3, 3.0);
      reps++;
  }

  final dueAt = result == ReviewResult.again
      ? now.add(const Duration(minutes: 1))
      : now.add(Duration(days: interval));

  return ScheduleOutput(
    ease: ease,
    intervalDays: interval,
    dueAt: dueAt,
    reps: reps,
  );
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/srs/scheduler_test.dart
```
Expected: 9 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/srs/scheduler.dart test/core/srs/scheduler_test.dart
git commit -m "feat(phase1): SM-2 scheduler — pure function, decoupled from rung (I2)"
```

---

### Task 2: Rung definitions and exercise resolver

**Files:**
- Create: `lib/core/ladder/rung_defs.dart`
- Create: `test/core/ladder/rung_defs_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/ladder/rung_defs_test.dart`:

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
      expect(
        resolveExercise(1, RefType.lexeme, _jaKanaProfile),
        ExerciseType.recognition,
      );
      expect(
        resolveExercise(1, RefType.character, _jaKanaProfile),
        ExerciseType.recognition,
      );
      expect(
        resolveExercise(1, RefType.lexeme, _esProfile),
        ExerciseType.recognition,
      );
    });

    test('rung 2 → readingInput', () {
      expect(
        resolveExercise(2, RefType.lexeme, _jaKanaProfile),
        ExerciseType.readingInput,
      );
      expect(
        resolveExercise(2, RefType.character, _jaKanaProfile),
        ExerciseType.readingInput,
      );
    });

    test('rung 3 → productionInput (I1: no MC on production rungs)', () {
      expect(
        resolveExercise(3, RefType.lexeme, _jaKanaProfile),
        ExerciseType.productionInput,
      );
      expect(
        resolveExercise(3, RefType.character, _jaKanaProfile),
        ExerciseType.productionInput,
      );
    });

    test('rung 4 and 5 → productionInput', () {
      expect(
        resolveExercise(4, RefType.lexeme, _jaKanaProfile),
        ExerciseType.productionInput,
      );
      expect(
        resolveExercise(5, RefType.lexeme, _jaKanaProfile),
        ExerciseType.productionInput,
      );
    });

    test('productionInput is never recognition (I1 invariant)', () {
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
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Create `lib/core/ladder/rung_defs.dart`**

```dart
import '../script_profile.dart';

enum ExerciseType {
  recognition,     // rung 1: show written/glyph, identify meaning
  readingInput,    // rung 2: show written/glyph, type reading
  productionInput, // rung 3+: show meaning, type written form (no MC — I1)
}

enum RefType { lexeme, character, grammar }

const int promotionThreshold = 3;

ExerciseType resolveExercise(int rung, RefType refType, ScriptProfile profile) {
  if (rung <= 1) return ExerciseType.recognition;
  if (rung == 2) return ExerciseType.readingInput;
  return ExerciseType.productionInput;
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/ladder/rung_defs_test.dart
```
Expected: 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/ladder/rung_defs.dart test/core/ladder/rung_defs_test.dart
git commit -m "feat(phase1): rung defs + exercise resolver — rungs 1-3, I1 enforced"
```

---

### Task 3: Ladder service

**Files:**
- Create: `lib/core/ladder/ladder_service.dart`
- Create: `test/core/ladder/ladder_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/ladder/ladder_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/ladder_service.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/srs/scheduler.dart';

const _base = ScheduleInput(ease: 2.5, intervalDays: 0, reps: 0);

void main() {
  group('processResult — promotion', () {
    test('3 consecutive good results promote rung 1 → 2', () {
      var rung = 1;
      var consecutive = 0;

      for (int i = 0; i < promotionThreshold; i++) {
        final r = processResult(
          currentRung: rung,
          consecutiveCorrect: consecutive,
          scheduleInput: _base,
          result: ReviewResult.good,
        );
        rung = r.newMasteryRung;
        consecutive = r.newConsecutiveCorrect;
      }

      expect(rung, 2);
      expect(consecutive, 0);
    });

    test('3 consecutive easy results promote rung 1 → 2', () {
      var rung = 1;
      var consecutive = 0;

      for (int i = 0; i < promotionThreshold; i++) {
        final r = processResult(
          currentRung: rung,
          consecutiveCorrect: consecutive,
          scheduleInput: _base,
          result: ReviewResult.easy,
        );
        rung = r.newMasteryRung;
        consecutive = r.newConsecutiveCorrect;
      }

      expect(rung, 2);
    });

    test('rung 5 good does not exceed 5', () {
      final r = processResult(
        currentRung: 5,
        consecutiveCorrect: promotionThreshold - 1,
        scheduleInput: _base,
        result: ReviewResult.good,
      );
      expect(r.newMasteryRung, 5);
      expect(r.newConsecutiveCorrect, 0);
    });

    test('2 good then again does NOT promote', () {
      var rung = 1;
      var consecutive = 0;

      for (int i = 0; i < 2; i++) {
        final r = processResult(
          currentRung: rung,
          consecutiveCorrect: consecutive,
          scheduleInput: _base,
          result: ReviewResult.good,
        );
        rung = r.newMasteryRung;
        consecutive = r.newConsecutiveCorrect;
      }
      expect(rung, 1);
      expect(consecutive, 2);

      final demote = processResult(
        currentRung: rung,
        consecutiveCorrect: consecutive,
        scheduleInput: _base,
        result: ReviewResult.again,
      );
      expect(demote.newMasteryRung, 1); // was already rung 1 → clamp
      expect(demote.newConsecutiveCorrect, 0);
    });
  });

  group('processResult — demotion', () {
    test('again on rung 3 demotes to rung 2', () {
      final r = processResult(
        currentRung: 3,
        consecutiveCorrect: 1,
        scheduleInput: _base,
        result: ReviewResult.again,
      );
      expect(r.newMasteryRung, 2);
      expect(r.newConsecutiveCorrect, 0);
    });

    test('again on rung 1 stays at rung 1 (min clamp)', () {
      final r = processResult(
        currentRung: 1,
        consecutiveCorrect: 0,
        scheduleInput: _base,
        result: ReviewResult.again,
      );
      expect(r.newMasteryRung, 1);
    });
  });

  group('processResult — hard', () {
    test('hard resets consecutiveCorrect but does not change rung', () {
      final r = processResult(
        currentRung: 2,
        consecutiveCorrect: 2,
        scheduleInput: _base,
        result: ReviewResult.hard,
      );
      expect(r.newMasteryRung, 2);
      expect(r.newConsecutiveCorrect, 0);
    });

    test('hard still updates SRS (scheduleOutput populated)', () {
      final r = processResult(
        currentRung: 1,
        consecutiveCorrect: 0,
        scheduleInput: const ScheduleInput(ease: 2.5, intervalDays: 4, reps: 2),
        result: ReviewResult.hard,
      );
      expect(r.scheduleOutput.intervalDays, 5); // ceil(4 * 1.2)
      expect(r.scheduleOutput.ease, closeTo(2.35, 0.01));
    });
  });

  test('good result populates scheduleOutput', () {
    final r = processResult(
      currentRung: 1,
      consecutiveCorrect: 0,
      scheduleInput: _base,
      result: ReviewResult.good,
    );
    expect(r.scheduleOutput.intervalDays, 1);
    expect(r.scheduleOutput.reps, 1);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/ladder/ladder_service_test.dart
```
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Create `lib/core/ladder/ladder_service.dart`**

```dart
import 'rung_defs.dart';
import '../srs/scheduler.dart';

class LadderResult {
  final ScheduleOutput scheduleOutput;
  final int newMasteryRung;
  final int newConsecutiveCorrect;

  const LadderResult({
    required this.scheduleOutput,
    required this.newMasteryRung,
    required this.newConsecutiveCorrect,
  });
}

LadderResult processResult({
  required int currentRung,
  required int consecutiveCorrect,
  required ScheduleInput scheduleInput,
  required ReviewResult result,
}) {
  final sched = schedule(scheduleInput, result);

  int newRung = currentRung;
  int newConsecutive;

  switch (result) {
    case ReviewResult.again:
      newRung = (currentRung - 1).clamp(1, 5);
      newConsecutive = 0;
    case ReviewResult.hard:
      newConsecutive = 0;
    case ReviewResult.good:
    case ReviewResult.easy:
      final proposed = consecutiveCorrect + 1;
      if (proposed >= promotionThreshold) {
        newRung = (currentRung + 1).clamp(1, 5);
        newConsecutive = 0;
      } else {
        newConsecutive = proposed;
      }
  }

  return LadderResult(
    scheduleOutput: sched,
    newMasteryRung: newRung,
    newConsecutiveCorrect: newConsecutive,
  );
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/ladder/ladder_service_test.dart
```
Expected: 9 tests PASS.

- [ ] **Step 5: Run full suite to confirm no regressions**

```bash
cd /home/uli/Projects/nihongo && flutter test
```
Expected: All prior tests still PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/ladder/ladder_service.dart test/core/ladder/ladder_service_test.dart
git commit -m "feat(phase1): ladder service — promotion after 3 consecutive, demotion on again"
```

---

### Task 4: Schema migration + LearnItem DAOs

**Files:**
- Modify: `lib/core/db/tables.dart` (add `consecutiveCorrect` to `LearnItems`)
- Modify: `lib/core/db/learning_db.dart` (schemaVersion→2, migration, DAOs)
- Regenerate: `lib/core/db/learning_db.g.dart`

- [ ] **Step 1: Add `consecutiveCorrect` column to `LearnItems` in `lib/core/db/tables.dart`**

Replace only the `LearnItems` class (lines 140–163). Keep all other table classes unchanged:

```dart
class LearnItems extends Table {
  TextColumn get id => text()();
  TextColumn get languageId =>
      text().references(Languages, #id, onDelete: KeyAction.cascade)();
  TextColumn get refType => text()(); // lexeme|character|grammar
  TextColumn get refId => text()();
  IntColumn get masteryRung =>
      integer().withDefault(const Constant(1))();
  RealColumn get ease =>
      real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get dueAt => dateTime()();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get consecutiveCorrect =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {languageId, refType, refId}
      ];
}
```

- [ ] **Step 2: Replace `lib/core/db/learning_db.dart` with this complete content**

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ladder/ladder_service.dart';
import '../ladder/rung_defs.dart';
import '../srs/scheduler.dart';
import 'tables.dart';

part 'learning_db.g.dart';

final learningDbProvider = Provider<LearningDb>((ref) {
  final db = LearningDb();
  ref.onDispose(db.close);
  return db;
});

@DriftDatabase(tables: [
  Concepts,
  Assets,
  ScriptProfiles,
  Languages,
  Lexemes,
  Characters,
  CharComponents,
  CanDoGoals,
  GrammarPoints,
  Sentences,
  LearnItems,
  ReviewLog,
])
class LearningDb extends _$LearningDb {
  LearningDb() : super(_openConnection());

  LearningDb.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(learnItems, learnItems.consecutiveCorrect);
          }
        },
      );

  // --- LearnItem DAOs ---

  Future<void> addLearnItem(
    String langId,
    RefType refType,
    String refId,
  ) =>
      _insertLearnItem(langId, refType, refId, rung: 1);

  Future<void> addLearnItemAtRung(
    String langId,
    RefType refType,
    String refId, {
    required int rung,
  }) =>
      _insertLearnItem(langId, refType, refId, rung: rung);

  Future<void> _insertLearnItem(
    String langId,
    RefType refType,
    String refId, {
    required int rung,
  }) async {
    await into(learnItems).insertOnConflictUpdate(
      LearnItemsCompanion(
        id: Value('$langId:${refType.name}:$refId'),
        languageId: Value(langId),
        refType: Value(refType.name),
        refId: Value(refId),
        masteryRung: Value(rung),
        consecutiveCorrect: const Value(0),
        dueAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<LearnItem>> getDueItems(String langId, {int limit = 20}) {
    final now = DateTime.now();
    return (select(learnItems)
          ..where((t) =>
              t.languageId.equals(langId) &
              t.dueAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.dueAt)])
          ..limit(limit))
        .get();
  }

  Future<void> applyReviewResult(
    LearnItem item,
    LadderResult ladderResult,
    ReviewResult reviewResult,
  ) async {
    await transaction(() async {
      final newLapses =
          reviewResult == ReviewResult.again ? item.lapses + 1 : item.lapses;

      await (update(learnItems)..where((t) => t.id.equals(item.id))).write(
        LearnItemsCompanion(
          masteryRung: Value(ladderResult.newMasteryRung),
          consecutiveCorrect: Value(ladderResult.newConsecutiveCorrect),
          ease: Value(ladderResult.scheduleOutput.ease),
          intervalDays: Value(ladderResult.scheduleOutput.intervalDays),
          dueAt: Value(ladderResult.scheduleOutput.dueAt),
          reps: Value(ladderResult.scheduleOutput.reps),
          lapses: Value(newLapses),
        ),
      );

      await into(reviewLog).insert(
        ReviewLogCompanion(
          id: Value('${item.id}_${DateTime.now().millisecondsSinceEpoch}'),
          learnItemId: Value(item.id),
          rung: Value(item.masteryRung),
          result: Value(reviewResult.name),
          ts: Value(DateTime.now()),
        ),
      );
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'learning.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

- [ ] **Step 3: Run build_runner to regenerate `learning_db.g.dart`**

```bash
cd /home/uli/Projects/nihongo && dart run build_runner build --delete-conflicting-outputs
```
Expected: exits 0. The generated file now includes `consecutiveCorrect` in `LearnItem` and `LearnItemsCompanion`.

- [ ] **Step 4: Run `flutter analyze`**

```bash
cd /home/uli/Projects/nihongo && flutter analyze
```
Expected: 0 errors. Fix any before continuing.

- [ ] **Step 5: Run existing tests to confirm nothing broke**

```bash
cd /home/uli/Projects/nihongo && flutter test
```
Expected: All prior tests PASS (the schema tests use in-memory DB which always gets the full schema via `onCreate`).

- [ ] **Step 6: Commit**

```bash
git add lib/core/db/tables.dart lib/core/db/learning_db.dart lib/core/db/learning_db.g.dart
git commit -m "feat(phase1): schema v2 (consecutiveCorrect), migration, LearnItem DAOs"
```

---

### Task 5: Integration test — prove the review loop

**Files:**
- Create: `test/core/db/review_loop_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/db/review_loop_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_service.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/srs/scheduler.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedJaPack(db);
    await db.addLearnItem('lang_ja', RefType.lexeme, 'lex_ja_dog');
  });

  tearDown(() async => db.close());

  test('new item is immediately due at rung 1', () async {
    final due = await db.getDueItems('lang_ja');
    expect(due.length, 1);
    expect(due.first.masteryRung, 1);
    expect(due.first.consecutiveCorrect, 0);
    expect(due.first.refType, 'lexeme');
    expect(due.first.refId, 'lex_ja_dog');
  });

  test('3 good results promote item from rung 1 to rung 2', () async {
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

    final promoted = (await db.select(db.learnItems).get()).first;
    expect(promoted.masteryRung, 2);
    expect(promoted.consecutiveCorrect, 0);
  });

  test('again on rung 3 item demotes to rung 2 and increments lapses', () async {
    await db.addLearnItemAtRung(
      'lang_ja', RefType.character, 'char_ja_a',
      rung: 3,
    );

    final items = await db.select(db.learnItems).get();
    final item = items.firstWhere((i) => i.masteryRung == 3);

    final result = processResult(
      currentRung: item.masteryRung,
      consecutiveCorrect: item.consecutiveCorrect,
      scheduleInput: ScheduleInput(
        ease: item.ease,
        intervalDays: item.intervalDays,
        reps: item.reps,
      ),
      result: ReviewResult.again,
    );
    await db.applyReviewResult(item, result, ReviewResult.again);

    final updated = await (db.select(db.learnItems)
          ..where((t) => t.id.equals(item.id)))
        .getSingle();
    expect(updated.masteryRung, 2);
    expect(updated.lapses, 1);
    expect(updated.consecutiveCorrect, 0);
  });

  test('review_log records rung-before-result and result string', () async {
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

    final logs = await db.select(db.reviewLog).get();
    expect(logs.length, 1);
    expect(logs.first.result, 'good');
    expect(logs.first.rung, 1); // rung BEFORE promotion
    expect(logs.first.learnItemId, item.id);
  });

  test('item is not due after good review (interval=1 day)', () async {
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

    final due = await db.getDueItems('lang_ja');
    expect(due, isEmpty);
  });

  test('item is due again immediately after again result', () async {
    final item = (await db.select(db.learnItems).get()).first;
    final result = processResult(
      currentRung: item.masteryRung,
      consecutiveCorrect: item.consecutiveCorrect,
      scheduleInput: ScheduleInput(
        ease: item.ease,
        intervalDays: item.intervalDays,
        reps: item.reps,
      ),
      result: ReviewResult.again,
    );
    await db.applyReviewResult(item, result, ReviewResult.again);

    // dueAt = now + 1 minute — still in the future, so not due yet
    // But it's much sooner than a "good" result
    final updated = (await db.select(db.learnItems).get()).first;
    final minutesUntilDue =
        updated.dueAt.difference(DateTime.now()).inMinutes;
    expect(minutesUntilDue, lessThanOrEqualTo(2));
    expect(minutesUntilDue, greaterThanOrEqualTo(0));
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/db/review_loop_test.dart
```
Expected: FAIL — `addLearnItem` and `getDueItems` not found (they were just added in Task 4, so this should actually PASS if Task 4 is complete). If Task 4 is done correctly, skip to Step 4.

- [ ] **Step 3: Run full suite**

```bash
cd /home/uli/Projects/nihongo && flutter test
```
Expected: All tests PASS including the 6 new integration tests.

- [ ] **Step 4: Commit**

```bash
git add test/core/db/review_loop_test.dart
git commit -m "test(phase1): integration test — full review loop proven end-to-end"
```

---

### Task 6: Final verification

- [ ] **Step 1: Run full test suite**

```bash
cd /home/uli/Projects/nihongo && flutter test
```
Expected: All tests pass. Count should include:
- 6 ScriptProfile tests (Phase 0)
- 9 LearningDb tests (Phase 0)
- 9 Scheduler tests (Phase 1)
- 5 RungDefs tests (Phase 1)
- 9 LadderService tests (Phase 1)
- 6 ReviewLoop integration tests (Phase 1)
- 1 Widget test
= 45 tests

- [ ] **Step 2: Run flutter analyze**

```bash
cd /home/uli/Projects/nihongo && flutter analyze
```
Expected: 0 errors, 0 warnings.

- [ ] **Step 3: Confirm git clean**

```bash
git status
```
Expected: `nothing to commit, working tree clean` (aside from any pre-existing untracked files like `CLAUDE.md`, `CLAUDE2.md`, `linux/`).
