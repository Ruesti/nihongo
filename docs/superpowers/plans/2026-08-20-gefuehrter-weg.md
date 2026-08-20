# Der geführte Weg (Lektion ↔ Manga) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the lesson-grid Home with a single **guided path** that alternates focused **Lektion** steps (integrated character/word/grammar via the encounter ritual) and **Manga** steps (the growing picture-story), reusing everything already built — so a new learner is led *through* the language, not dropped on a menu.

**Architecture:** A per-language **Curriculum** (authored JSON asset: an ordered list of `LessonStep`/`MangaStep`) drives a new `/` screen (`JourneyHome`). A `JourneyService` computes the current step from the learner's progress (a step index in `SharedPreferences`) and known-set (`LearningDb`), skipping lesson steps whose items are already known. A lesson step runs the existing `EncounterView`s; a manga step opens the existing `ComicReaderScreen`. Onboarding gains a **vocabulary micro-check** so prior vocab is captured and the path starts further along. No lesson grid, no points, no flashcard-drill front — review surfaces inside reading.

**Tech Stack:** Dart 3.12, Flutter, Drift (LearningDb/MiningDb — no new migration; progress lives in SharedPreferences), Riverpod, go_router, `flutter_test` with `NativeDatabase.memory()`.

## Global Constraints

- **Package name:** `nihongo_app`. All imports `package:nihongo_app/...`.
- **Working dir (`<WT>`):** `/home/uli/projects/nihongo/.claude/worktrees/spec+onboarding-and-manga` (branch `spec/gefuehrter-weg`, off main). Test command: `flutter test <file> --no-pub`; analyze: `flutter analyze <paths>`.
- **I3 — Keine Gamification:** no streaks, points, XP, leaderboards on the journey. Calm progress text (e.g. "Kapitel 2") is allowed; score/point mechanics are not.
- **No flashcard-drill as the front experience:** the journey never shows an Anki-style due queue. Review surfaces *inside* the manga reading (existing in-reading review); the Review tab is demoted out of the nav bar.
- **Integrated, not kana-cudgel:** a lesson step bundles a *few* characters + words (+ grammar when content exists) together; never "all kana first". This is enforced by the authored curriculum content, not code.
- **I8 — sprach-blind:** the journey code keys on the active `languageCode` and loads `assets/curriculum/<lang>.json`; NO `if (lang == 'ja')` in `lib/features/journey/*.dart`.
- **Honesty:** the vocab micro-check marks a word known only when the learner explicitly confirms it.
- **Offline-first, system-locale (l10n):** all new display text via `AppLocalizations`.
- **Reuse, don't rebuild:** `EncounterView`, `ExerciseLoader`, `LadderReview`, `ComicReaderScreen`, `ComicRepository`, `ComicPack`, the SRS ladder, and the knowledge bridge already exist and must be reused as-is.

## Reused APIs (verbatim — do NOT reimplement)

- `EncounterView({required Encounter encounter, required VoidCallback onDone})` — `lib/features/encounter/encounter_view.dart`.
- `ExerciseLoader(LearningDb).load(LearnItem item, ScriptProfile profile) → Future<ExerciseContent>`; rung-0 returns `EncounterContent{Encounter encounter}` — `lib/core/ladder/exercise_loader.dart`, `exercise_content.dart`.
- `LadderReview(LearningDb, {KnowledgeBridge? bridge})` with `introduce(String languageId, RefType refType, String refId, {String? languageCode})` (idempotent, rung 0) and `markEncountered(LearnItem item, {String? languageCode})` (rung 0→1) — `lib/core/ladder/ladder_review.dart`.
- `LearningDb.getLearnItem(String id)` where `id == '$languageId:${refType.name}:$refId'`; `RefType {lexeme, character, grammar}` — `lib/core/ladder/rung_defs.dart`.
- `ComicReaderScreen({required ComicRepository repo, required TextDirection direction})`; `ComicRepository({required MiningDb db, required ComicPack pack, required Dictionary dictionary})`; `ComicPack.fromJson(Map)` — `lib/features/comic/`.
- Providers (`lib/app/knowledge_providers.dart`): `learningDbProvider` (`Provider<LearningDb>`, overridden in main), `miningDbProvider` (`Provider<MiningDb?>`), `knowledgeBridgeProvider` (`Provider<KnowledgeBridge?>`). `activeLanguageProvider` (`StateProvider<String>`, default `'ja'`) — `lib/features/language_select/language_select_screen.dart`.
- Seeded JA ids (`lib/packs/ja/ja_seed.dart`): characters `char_ja_a/i/u/e/o`; lexemes `lex_ja_dog/cat/water/eat/what` (writtenForm 犬/猫/水/食べる/何); concepts `concept_dog/cat/water/eat/what` (glossKey dog/cat/water/eat/what). No grammar/sentences/assets seeded.
- Comic assets: `assets/comic/ja_l0.json` (uses 猫), `assets/comic/ja_l1.json` (uses 猫+犬). Existing empty dictionary pattern: `_EmptyComicDictionary implements Dictionary` in `lib/features/mining_slice/reading_tab.dart:52-56`.
- **Test gotcha:** the old Home's `MascotWidget` runs an infinite animation → `pumpAndSettle()` hangs. The new `JourneyHome` must NOT use `MascotWidget`; then `pumpAndSettle` is safe.

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/features/journey/curriculum.dart` | Create | `Curriculum`/`CurriculumStep`(sealed `LessonStep`/`MangaStep`) + `fromJson` |
| `assets/curriculum/ja.json` | Create | Authored first arc (3 chapters) against seeded ids |
| `pubspec.yaml` | Modify | Declare `assets/curriculum/` |
| `lib/features/journey/journey_progress.dart` | Create | Step index per language in SharedPreferences |
| `lib/features/journey/journey_service.dart` | Create | Current-step computation (skip known lesson steps) + advance |
| `lib/features/journey/journey_providers.dart` | Create | `curriculumProvider`, `journeyProgressProvider`, `currentStepProvider` |
| `lib/features/journey/lesson_step_screen.dart` | Create | Runs a `LessonStep`'s encounters (introduce→EncounterView→markEncountered) |
| `lib/features/journey/manga_step_launcher.dart` | Create | Loads a `MangaStep`'s ComicPack, opens `ComicReaderScreen` |
| `lib/features/journey/journey_home.dart` | Create | The new `/` screen: current chapter + CTA → step → advance |
| `lib/app.dart` | Modify | `/` → `JourneyHome`; drop `/read`+`/review` from the nav bar (routes stay) |
| `lib/features/onboarding/vocab_check.dart` | Create | Micro-check widget: seeded lexemes → confirmed `Lexemes.id`s |
| `lib/features/onboarding/onboarding_flow.dart` | Modify | Insert `_Step.vocabCheck`; feed confirmed ids into `_finish` |
| `lib/l10n/app_en.arb`, `app_de.arb` | Modify | New journey/vocab-check strings |
| `tool/proof_journey.dart` | Create | Headless proof: walk the first arc end to end |
| `test/**` | Create | Unit + widget tests per task |

---

### Task 1: Curriculum model

**Files:**
- Create: `lib/features/journey/curriculum.dart`
- Test: `test/features/journey/curriculum_test.dart`

**Interfaces:**
- Produces: `enum CurriculumStepKind {lesson, manga}`; `sealed class CurriculumStep {String id; String chapterRef}`; `final class LessonStep extends CurriculumStep {List<String> characterIds, lexemeIds, grammarIds}`; `final class MangaStep extends CurriculumStep {String comicAsset}`; `class Curriculum {String languageCode, title; List<CurriculumStep> steps}` with `Curriculum.fromJson(Map<String,dynamic>)`.

- [ ] **Step 1: Write the failing test**

Create `test/features/journey/curriculum_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';

const _json = {
  'languageCode': 'ja',
  'title': 'Neko no hi',
  'steps': [
    {
      'id': 'c1-lesson',
      'kind': 'lesson',
      'chapterRef': 'Kapitel 1',
      'characterIds': ['char_ja_a', 'char_ja_i'],
      'lexemeIds': ['lex_ja_cat'],
      'grammarIds': <String>[],
    },
    {
      'id': 'c1-manga',
      'kind': 'manga',
      'chapterRef': 'Kapitel 1',
      'comicAsset': 'assets/comic/ja_l0.json',
    },
  ],
};

void main() {
  test('parses a mixed lesson/manga curriculum', () {
    final c = Curriculum.fromJson(_json);
    expect(c.languageCode, 'ja');
    expect(c.steps, hasLength(2));

    final lesson = c.steps[0];
    expect(lesson, isA<LessonStep>());
    expect((lesson as LessonStep).characterIds, ['char_ja_a', 'char_ja_i']);
    expect(lesson.lexemeIds, ['lex_ja_cat']);
    expect(lesson.chapterRef, 'Kapitel 1');

    final manga = c.steps[1];
    expect(manga, isA<MangaStep>());
    expect((manga as MangaStep).comicAsset, 'assets/comic/ja_l0.json');
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/journey/curriculum_test.dart --no-pub
```
Expected: FAIL — `curriculum.dart` does not exist.

- [ ] **Step 3: Create `lib/features/journey/curriculum.dart`**

```dart
enum CurriculumStepKind { lesson, manga }

/// One authored step on the guided path. Pure data — no Flutter/DB deps.
sealed class CurriculumStep {
  final String id;
  final String chapterRef;
  const CurriculumStep(this.id, this.chapterRef);
}

/// A focused learning step: a few characters + words (+ grammar when content
/// exists), introduced together via the encounter ritual. Never "all kana".
final class LessonStep extends CurriculumStep {
  final List<String> characterIds;
  final List<String> lexemeIds;
  final List<String> grammarIds;
  const LessonStep({
    required String id,
    required String chapterRef,
    required this.characterIds,
    required this.lexemeIds,
    required this.grammarIds,
  }) : super(id, chapterRef);
}

/// A story step: read this installment of the growing comic.
final class MangaStep extends CurriculumStep {
  final String comicAsset; // bundle path to a ComicPack JSON
  const MangaStep({
    required String id,
    required String chapterRef,
    required this.comicAsset,
  }) : super(id, chapterRef);
}

/// A per-language authored path of steps (loaded from assets/curriculum/<lang>.json).
class Curriculum {
  final String languageCode;
  final String title;
  final List<CurriculumStep> steps;
  const Curriculum({
    required this.languageCode,
    required this.title,
    required this.steps,
  });

  factory Curriculum.fromJson(Map<String, dynamic> j) => Curriculum(
        languageCode: j['languageCode'] as String,
        title: j['title'] as String,
        steps: [
          for (final s in (j['steps'] as List? ?? const []))
            _stepFromJson(s as Map<String, dynamic>),
        ],
      );

  static CurriculumStep _stepFromJson(Map<String, dynamic> j) {
    final id = j['id'] as String;
    final chapterRef = j['chapterRef'] as String? ?? '';
    final kind = (j['kind'] as String) == 'manga'
        ? CurriculumStepKind.manga
        : CurriculumStepKind.lesson;
    switch (kind) {
      case CurriculumStepKind.manga:
        return MangaStep(
          id: id,
          chapterRef: chapterRef,
          comicAsset: j['comicAsset'] as String,
        );
      case CurriculumStepKind.lesson:
        return LessonStep(
          id: id,
          chapterRef: chapterRef,
          characterIds: (j['characterIds'] as List?)?.cast<String>() ?? const [],
          lexemeIds: (j['lexemeIds'] as List?)?.cast<String>() ?? const [],
          grammarIds: (j['grammarIds'] as List?)?.cast<String>() ?? const [],
        );
    }
  }
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/journey/curriculum_test.dart --no-pub
```
Expected: 1 test PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/journey/curriculum.dart test/features/journey/curriculum_test.dart
git commit -m "feat(journey): Curriculum model (sealed lesson/manga steps)"
```

---

### Task 2: Authored first arc + asset wiring

**Files:**
- Create: `assets/curriculum/ja.json`
- Modify: `pubspec.yaml` (declare `assets/curriculum/`)
- Test: `test/features/journey/curriculum_asset_test.dart`

**Interfaces:**
- Consumes: `Curriculum.fromJson` (Task 1); seeded ids (see Global Constraints).
- Produces: a bundled JA curriculum that parses and references only real seeded ids + existing comic assets.

- [ ] **Step 1: Create `assets/curriculum/ja.json`** (3 chapters, interleaved — NOT all-kana-first; lessons teach what the following manga uses)

```json
{
  "languageCode": "ja",
  "title": "Neko no hi",
  "steps": [
    {"id": "c1-lesson", "kind": "lesson", "chapterRef": "Kapitel 1",
     "characterIds": ["char_ja_a", "char_ja_i"], "lexemeIds": ["lex_ja_cat"], "grammarIds": []},
    {"id": "c1-manga", "kind": "manga", "chapterRef": "Kapitel 1",
     "comicAsset": "assets/comic/ja_l0.json"},
    {"id": "c2-lesson", "kind": "lesson", "chapterRef": "Kapitel 2",
     "characterIds": ["char_ja_u", "char_ja_e"], "lexemeIds": ["lex_ja_dog"], "grammarIds": []},
    {"id": "c2-manga", "kind": "manga", "chapterRef": "Kapitel 2",
     "comicAsset": "assets/comic/ja_l1.json"},
    {"id": "c3-lesson", "kind": "lesson", "chapterRef": "Kapitel 3",
     "characterIds": ["char_ja_o"], "lexemeIds": ["lex_ja_water", "lex_ja_eat"], "grammarIds": []},
    {"id": "c3-manga", "kind": "manga", "chapterRef": "Kapitel 3",
     "comicAsset": "assets/comic/ja_l1.json"}
  ]
}
```

- [ ] **Step 2: Declare the asset dir in `pubspec.yaml`**

Under `flutter: assets:` add:
```yaml
    - assets/curriculum/
```

- [ ] **Step 3: Write the failing test**

Create `test/features/journey/curriculum_asset_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled JA curriculum parses and interleaves lesson/manga', () async {
    final raw = await rootBundle.loadString('assets/curriculum/ja.json');
    final c = Curriculum.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    expect(c.languageCode, 'ja');
    expect(c.steps.length, greaterThanOrEqualTo(4));
    // First chapter must teach before it reads: a lesson precedes a manga.
    expect(c.steps[0], isA<LessonStep>());
    expect(c.steps[1], isA<MangaStep>());
    // No "all kana first": the first lesson introduces at most a few characters.
    expect((c.steps[0] as LessonStep).characterIds.length, lessThanOrEqualTo(3));
  });
}
```

- [ ] **Step 4: Run the test**

```bash
cd <WT> && flutter pub get && flutter test test/features/journey/curriculum_asset_test.dart --no-pub
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add assets/curriculum/ pubspec.yaml test/features/journey/curriculum_asset_test.dart
git commit -m "feat(journey): authored JA first arc (interleaved lesson/manga)"
```

---

### Task 3: Journey progress store (SharedPreferences)

**Files:**
- Create: `lib/features/journey/journey_progress.dart`
- Test: `test/features/journey/journey_progress_test.dart`

**Interfaces:**
- Produces: `class JourneyProgress { const JourneyProgress(SharedPreferences); int stepIndex(String languageCode); Future<void> setStepIndex(String languageCode, int index); }` — key `journey_step:<lang>`, default 0.

- [ ] **Step 1: Write the failing test**

Create `test/features/journey/journey_progress_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/journey/journey_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults to 0 and round-trips per language', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final p = JourneyProgress(prefs);

    expect(p.stepIndex('ja'), 0);
    await p.setStepIndex('ja', 3);
    expect(p.stepIndex('ja'), 3);
    expect(p.stepIndex('es'), 0); // per-language isolation
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/journey/journey_progress_test.dart --no-pub
```
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create `lib/features/journey/journey_progress.dart`**

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Where the learner stands on the guided path: a single step index per
/// language. Deliberately in SharedPreferences (not the DB) — no schema
/// migration needed; a DB table is an easy future upgrade if richer state
/// is ever required.
class JourneyProgress {
  final SharedPreferences _prefs;
  const JourneyProgress(this._prefs);

  String _key(String languageCode) => 'journey_step:$languageCode';

  int stepIndex(String languageCode) => _prefs.getInt(_key(languageCode)) ?? 0;

  Future<void> setStepIndex(String languageCode, int index) =>
      _prefs.setInt(_key(languageCode), index);
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/journey/journey_progress_test.dart --no-pub
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/journey/journey_progress.dart test/features/journey/journey_progress_test.dart
git commit -m "feat(journey): step-index progress store (SharedPreferences)"
```

---

### Task 4: Journey sequencing (skip already-known lesson steps)

**Files:**
- Create: `lib/features/journey/journey_service.dart`
- Test: `test/features/journey/journey_service_test.dart`

**Interfaces:**
- Consumes: `Curriculum`/`LessonStep`/`MangaStep` (Task 1); `LearningDb.getLearnItem(id)` (id `'$langId:${refType.name}:$refId'`).
- Produces: `class JourneyService { JourneyService({required Curriculum curriculum, required LearningDb learning, required String languageId}); Future<int?> resolveStepIndex(int fromIndex); }` — returns the first index ≥ `fromIndex` whose step is not "already fully known"; `null` when past the end. A `LessonStep` is *already known* iff every referenced character/lexeme/grammar item already has a `LearnItem` (rung ≥ 1). `MangaStep`s are never skipped.

- [ ] **Step 1: Write the failing test**

Create `test/features/journey/journey_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';
import 'package:nihongo_app/features/journey/journey_service.dart';

Curriculum _curriculum() => const Curriculum(
      languageCode: 'ja',
      title: 'T',
      steps: [
        LessonStep(id: 'l1', chapterRef: 'K1', characterIds: ['char_ja_a'], lexemeIds: [], grammarIds: []),
        MangaStep(id: 'm1', chapterRef: 'K1', comicAsset: 'assets/comic/ja_l0.json'),
        LessonStep(id: 'l2', chapterRef: 'K2', characterIds: ['char_ja_i'], lexemeIds: [], grammarIds: []),
      ],
    );

void main() {
  late LearningDb db;
  setUp(() => db = LearningDb.forTesting());
  tearDown(() => db.close());

  JourneyService svc() =>
      JourneyService(curriculum: _curriculum(), learning: db, languageId: 'lang_ja');

  test('with nothing known, current step is index 0', () async {
    expect(await svc().resolveStepIndex(0), 0);
  });

  test('a lesson whose items are all already known is skipped', () async {
    // char_ja_a already introduced (rung ≥ 1) → step 0 is known → skip to 1 (manga).
    await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 3);
    expect(await svc().resolveStepIndex(0), 1);
  });

  test('past the end returns null', () async {
    expect(await svc().resolveStepIndex(3), isNull);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/journey/journey_service_test.dart --no-pub
```
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create `lib/features/journey/journey_service.dart`**

```dart
import '../../core/db/learning_db.dart';
import '../../core/ladder/rung_defs.dart';
import 'curriculum.dart';

/// Computes the learner's current position on the guided path: starting from a
/// stored index, skip forward over lesson steps whose items are ALL already
/// known (so a vocab-knower isn't re-taught), and stop at the first real step.
/// Manga steps are never skipped — reading is always worthwhile.
class JourneyService {
  final Curriculum curriculum;
  final LearningDb learning;
  final String languageId; // e.g. 'lang_ja'

  const JourneyService({
    required this.curriculum,
    required this.learning,
    required this.languageId,
  });

  Future<int?> resolveStepIndex(int fromIndex) async {
    var i = fromIndex;
    while (i < curriculum.steps.length) {
      final step = curriculum.steps[i];
      if (step is LessonStep && await _lessonAlreadyKnown(step)) {
        i++;
        continue;
      }
      return i;
    }
    return null; // path complete
  }

  Future<bool> _lessonAlreadyKnown(LessonStep step) async {
    final refs = <(RefType, String)>[
      for (final id in step.characterIds) (RefType.character, id),
      for (final id in step.lexemeIds) (RefType.lexeme, id),
      for (final id in step.grammarIds) (RefType.grammar, id),
    ];
    if (refs.isEmpty) return false; // an empty lesson is never "known"
    for (final (refType, refId) in refs) {
      final item =
          await learning.getLearnItem('$languageId:${refType.name}:$refId');
      if (item == null) return false; // something not yet introduced
    }
    return true;
  }
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/journey/journey_service_test.dart --no-pub
```
Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/journey/journey_service.dart test/features/journey/journey_service_test.dart
git commit -m "feat(journey): sequencing — skip already-known lesson steps"
```

---

### Task 5: Journey providers

**Files:**
- Create: `lib/features/journey/journey_providers.dart`
- Test: `test/features/journey/journey_providers_test.dart`

**Interfaces:**
- Consumes: `Curriculum` (Task 1), `activeLanguageProvider`, `learningDbProvider`.
- Produces: `curriculumProvider` (`FutureProvider<Curriculum?>` — loads `assets/curriculum/<lang>.json`, null on miss); `journeyProgressProvider` (`FutureProvider<JourneyProgress>`); `currentStepProvider` (`FutureProvider<CurriculumStep?>` — the resolved current step, or null if path complete / no curriculum).

- [ ] **Step 1: Write the failing test**

Create `test/features/journey/journey_providers_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';
import 'package:nihongo_app/features/journey/journey_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('currentStepProvider resolves the first step of the bundled JA arc',
      () async {
    SharedPreferences.setMockInitialValues({});
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      learningDbProvider.overrideWith((ref) => db),
    ]);
    addTearDown(container.dispose);

    final step = await container.read(currentStepProvider.future);
    expect(step, isNotNull);
    expect(step, isA<LessonStep>()); // arc opens with a lesson
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/journey/journey_providers_test.dart --no-pub
```
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create `lib/features/journey/journey_providers.dart`**

```dart
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/knowledge_providers.dart';
import '../language_select/language_select_screen.dart';
import 'curriculum.dart';
import 'journey_progress.dart';
import 'journey_service.dart';

/// The authored path for the active language, or null if none is bundled.
final curriculumProvider = FutureProvider<Curriculum?>((ref) async {
  final lang = ref.watch(activeLanguageProvider);
  try {
    final raw = await rootBundle.loadString('assets/curriculum/$lang.json');
    return Curriculum.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null; // no curriculum bundled for this language yet
  }
});

final journeyProgressProvider = FutureProvider<JourneyProgress>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return JourneyProgress(prefs);
});

/// The learner's current step (skipping already-known lessons), or null when
/// the path is complete or no curriculum exists.
final currentStepProvider = FutureProvider<CurriculumStep?>((ref) async {
  final lang = ref.watch(activeLanguageProvider);
  final curriculum = await ref.watch(curriculumProvider.future);
  if (curriculum == null) return null;
  final progress = await ref.watch(journeyProgressProvider.future);
  final service = JourneyService(
    curriculum: curriculum,
    learning: ref.watch(learningDbProvider),
    languageId: 'lang_$lang',
  );
  final index = await service.resolveStepIndex(progress.stepIndex(lang));
  if (index == null) return null;
  return curriculum.steps[index];
});
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/journey/journey_providers_test.dart --no-pub
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/journey/journey_providers.dart test/features/journey/journey_providers_test.dart
git commit -m "feat(journey): providers (curriculum, progress, current step)"
```

---

### Task 6: Lesson-step screen (runs the encounters)

**Files:**
- Create: `lib/features/journey/lesson_step_screen.dart`
- Test: `test/features/journey/lesson_step_screen_test.dart`

**Interfaces:**
- Consumes: `LessonStep` (Task 1); `LadderReview.introduce`/`markEncountered`; `ExerciseLoader.load`; `EncounterView`; `EncounterContent`; `learningDbProvider`, `knowledgeBridgeProvider`; a kana `ScriptProfile`.
- Produces: `LessonStepScreen({required LessonStep step, required String languageId, required VoidCallback onDone})` — introduces each item at rung 0, shows its `EncounterView` in sequence, calls `markEncountered`, then `onDone` when all are met.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/journey/lesson_step_screen_test.dart`:

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
import 'package:nihongo_app/l10n/app_localizations.dart';

void main() {
  testWidgets('runs the encounter for each item then calls onDone',
      (tester) async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp_ja_kana', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp_ja_kana', ttsVoice: 'ja-JP'));
    await db.into(db.characters).insert(CharactersCompanion.insert(
        id: 'char_ja_a', languageId: 'lang_ja', glyph: 'あ',
        readingsJson: jsonEncode(['a']), meaning: 'a'));

    var done = false;
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
          onDone: () => done = true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('あ'), findsOneWidget); // the encounter renders
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pumpAndSettle();

    expect(done, isTrue); // single item → onDone after its encounter
    // The item is now introduced (rung ≥ 1).
    final item = await db.getLearnItem('lang_ja:character:char_ja_a');
    expect(item, isNotNull);
    expect(item!.masteryRung, greaterThanOrEqualTo(1));
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/journey/lesson_step_screen_test.dart --no-pub
```
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create `lib/features/journey/lesson_step_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/knowledge_providers.dart';
import '../../core/db/learning_db.dart';
import '../../core/ladder/exercise_content.dart';
import '../../core/ladder/exercise_loader.dart';
import '../../core/ladder/ladder_review.dart';
import '../../core/ladder/rung_defs.dart';
import '../../core/script_profile.dart';
import '../encounter/encounter_view.dart';
import 'curriculum.dart';

/// A kana script profile is enough: resolveExercise(0, ...) ignores the
/// profile and returns an EncounterContent for every refType.
const _encounterProfile = ScriptProfile(
  id: 'sp',
  scriptType: ScriptType.syllabary,
  direction: Direction.ltr,
  decomposability: Decomposability.atomic,
  positionalForms: false,
  toneSystem: ToneSystem.none,
  needsScriptTrack: true,
  transliteration: 'romaji',
  inputMethods: [InputMethod.keyboard],
);

/// Runs a LessonStep: for each referenced item, introduce it (rung 0), show
/// its encounter (see/hear/trace/meaning), then markEncountered (rung 0→1).
/// Ungraded — this is teaching, not testing. Calls [onDone] when all met.
class LessonStepScreen extends ConsumerStatefulWidget {
  final LessonStep step;
  final String languageId; // 'lang_ja'
  final VoidCallback onDone;

  const LessonStepScreen({
    super.key,
    required this.step,
    required this.languageId,
    required this.onDone,
  });

  @override
  ConsumerState<LessonStepScreen> createState() => _LessonStepScreenState();
}

class _LessonStepScreenState extends ConsumerState<LessonStepScreen> {
  late final List<(RefType, String)> _refs = [
    for (final id in widget.step.characterIds) (RefType.character, id),
    for (final id in widget.step.lexemeIds) (RefType.lexeme, id),
    for (final id in widget.step.grammarIds) (RefType.grammar, id),
  ];
  int _index = 0;
  ExerciseContent? _content;
  LearnItem? _item;
  bool _loading = true;

  LearningDb get _db => ref.read(learningDbProvider);
  LadderReview get _review =>
      LadderReview(_db, bridge: ref.read(knowledgeBridgeProvider));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_index >= _refs.length) {
      widget.onDone();
      return;
    }
    final (refType, refId) = _refs[_index];
    await _review.introduce(widget.languageId, refType, refId);
    final item =
        await _db.getLearnItem('${widget.languageId}:${refType.name}:$refId');
    if (item == null) {
      // Referenced content missing from the pack — skip it, never crash.
      _index++;
      await _load();
      return;
    }
    final content = await ExerciseLoader(_db).load(item, _encounterProfile);
    if (!mounted) return;
    setState(() {
      _item = item;
      _content = content;
      _loading = false;
    });
  }

  Future<void> _next() async {
    final item = _item;
    if (item != null) {
      await _review.markEncountered(item, languageCode: widget.languageId);
    }
    _index++;
    if (_index >= _refs.length) {
      widget.onDone();
      return;
    }
    setState(() => _loading = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;
    return Scaffold(
      body: SafeArea(
        child: (_loading || content is! EncounterContent)
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: EncounterView(
                  encounter: content.encounter,
                  onDone: _next,
                ),
              ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/journey/lesson_step_screen_test.dart --no-pub
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/journey/lesson_step_screen.dart test/features/journey/lesson_step_screen_test.dart
git commit -m "feat(journey): lesson-step screen — runs encounters, marks met"
```

---

### Task 7: Manga-step launcher

**Files:**
- Create: `lib/features/journey/manga_step_launcher.dart`
- Test: `test/features/journey/manga_step_launcher_test.dart`

**Interfaces:**
- Consumes: `MangaStep` (Task 1); `ComicPack.fromJson`; `ComicReaderScreen`; `ComicRepository`; `miningDbProvider`.
- Produces: `Future<void> openMangaStep(BuildContext context, WidgetRef ref, MangaStep step)` — loads the step's `ComicPack`, opens `ComicReaderScreen`; returns when the reader is popped. Degrades gracefully (does nothing) if the pack can't load or `miningDbProvider` is null.

- [ ] **Step 1: Write the failing test**

Create `test/features/journey/manga_step_launcher_test.dart`. It verifies the loader resolves a bundled pack (pure function, no navigation):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/journey/manga_step_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadComicPackForStep returns a pack for a bundled asset', () async {
    final pack = await loadComicPackForStep('assets/comic/ja_l0.json');
    expect(pack, isNotNull);
    expect(pack!.languageCode, 'ja');
  });

  test('loadComicPackForStep returns null for a missing asset', () async {
    expect(await loadComicPackForStep('assets/comic/does_not_exist.json'), isNull);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/journey/manga_step_launcher_test.dart --no-pub
```
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create `lib/features/journey/manga_step_launcher.dart`**

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/knowledge_providers.dart';
import '../../core/language_pack/language_pack.dart' show Dictionary, Sense;
import '../comic/comic_pack.dart';
import '../comic/comic_reader_screen.dart';
import '../comic/comic_repository.dart';
import 'curriculum.dart';

/// Empty dictionary for the MVP — gloss sheet honestly degrades to "no entry".
/// Wiring a real per-language dictionary is a follow-up (same as reading_tab).
class _EmptyComicDictionary implements Dictionary {
  const _EmptyComicDictionary();
  @override
  List<Sense> lookup(String lemma, String pos) => const [];
}

/// Loads a ComicPack from a bundle asset path, or null if missing/malformed.
Future<ComicPack?> loadComicPackForStep(String comicAsset) async {
  try {
    final raw = await rootBundle.loadString(comicAsset);
    return ComicPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

/// Opens the manga reader for a MangaStep and returns when it is popped.
/// No-op (still resolves) if the pack can't load or mining DB is unavailable.
Future<void> openMangaStep(
  BuildContext context,
  WidgetRef ref,
  MangaStep step,
) async {
  final db = ref.read(miningDbProvider);
  final pack = await loadComicPackForStep(step.comicAsset);
  if (!context.mounted || db == null || pack == null) return;
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => ComicReaderScreen(
      repo: ComicRepository(
        db: db,
        pack: pack,
        dictionary: const _EmptyComicDictionary(),
      ),
      direction: TextDirection.ltr,
    ),
  ));
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/journey/manga_step_launcher_test.dart --no-pub
```
Expected: 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/journey/manga_step_launcher.dart test/features/journey/manga_step_launcher_test.dart
git commit -m "feat(journey): manga-step launcher (reuses ComicReaderScreen)"
```

---

### Task 8: New journey l10n strings

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`
- Test: `test/l10n/journey_l10n_test.dart`

**Interfaces:**
- Produces: keys `journeyStart` ("Los geht's"/"Let's go"), `journeyContinue` ("Weiter"/"Continue"), `journeyChapterLabel` ("Kapitel {n}"/"Chapter {n}"), `journeyPathComplete` ("Geschafft — mehr Geschichte kommt bald."/"Done — more story coming soon."), `journeyLessonStepTitle` ("Neu lernen"/"Learn something new"), `journeyMangaStepTitle` ("Weiterlesen"/"Read on"), `vocabCheckIntro` ("Welche Wörter kennst du schon?"/"Which words do you already know?"), `vocabCheckKnow` ("Kenne ich"/"I know it"), `vocabCheckDont` ("Neu für mich"/"New to me").

- [ ] **Step 1: Add keys to `lib/l10n/app_en.arb`** (before the closing brace; keep existing keys)

```json
  "journeyStart": "Let's go",
  "journeyContinue": "Continue",
  "journeyChapterLabel": "Chapter {n}",
  "@journeyChapterLabel": { "placeholders": { "n": { "type": "int" } } },
  "journeyPathComplete": "Done — more story coming soon.",
  "journeyLessonStepTitle": "Learn something new",
  "journeyMangaStepTitle": "Read on",
  "vocabCheckIntro": "Which words do you already know?",
  "vocabCheckKnow": "I know it",
  "vocabCheckDont": "New to me"
```

- [ ] **Step 2: Add the same keys to `lib/l10n/app_de.arb`**

```json
  "journeyStart": "Los geht's",
  "journeyContinue": "Weiter",
  "journeyChapterLabel": "Kapitel {n}",
  "@journeyChapterLabel": { "placeholders": { "n": { "type": "int" } } },
  "journeyPathComplete": "Geschafft — mehr Geschichte kommt bald.",
  "journeyLessonStepTitle": "Neu lernen",
  "journeyMangaStepTitle": "Weiterlesen",
  "vocabCheckIntro": "Welche Wörter kennst du schon?",
  "vocabCheckKnow": "Kenne ich",
  "vocabCheckDont": "Neu für mich"
```

Note: keep each file valid JSON — add a comma after the previous last key.

- [ ] **Step 3: Regenerate localizations**

```bash
cd <WT> && flutter gen-l10n
```
Expected: exits 0; the new getters exist on `AppLocalizations`.

- [ ] **Step 4: Write + run the test**

Create `test/l10n/journey_l10n_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

void main() {
  testWidgets('journey strings resolve in de and en', (tester) async {
    for (final (locale, expected) in [
      (const Locale('de'), 'Los geht\'s'),
      (const Locale('en'), 'Let\'s go'),
    ]) {
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) => Text(AppLocalizations.of(c)!.journeyStart),
        ),
      ));
      expect(find.text(expected), findsOneWidget);
    }
  });
}
```

```bash
cd <WT> && flutter test test/l10n/journey_l10n_test.dart --no-pub
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/ test/l10n/journey_l10n_test.dart
git commit -m "feat(l10n): journey + vocab-check strings (en + de)"
```

---

### Task 9: JourneyHome — the new `/` screen

**Files:**
- Create: `lib/features/journey/journey_home.dart`
- Test: `test/features/journey/journey_home_test.dart`

**Interfaces:**
- Consumes: `currentStepProvider`, `curriculumProvider`, `journeyProgressProvider` (Task 5); `LessonStepScreen` (Task 6); `openMangaStep` (Task 7); `AppLocalizations` (Task 8); `activeLanguageProvider`.
- Produces: `class JourneyHome extends ConsumerWidget` — a calm front door showing the current chapter + a single CTA. Tapping the CTA runs the current step (lesson full-screen or manga reader); on return it advances the stored step index and refreshes. NO lesson grid, NO mastery/points, NO `MascotWidget`.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/journey/journey_home_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/journey/journey_home.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the current chapter and a start CTA, no lesson grid',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = LearningDb.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWith((ref) => db)],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: JourneyHome(),
      ),
    ));
    await tester.pumpAndSettle();

    // Calm chapter label + a single CTA; NOT the old "Lektionen" grid.
    expect(find.text('Kapitel 1'), findsOneWidget);
    expect(find.text('Los geht\'s'), findsOneWidget);
    expect(find.text('Lektionen'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/journey/journey_home_test.dart --no-pub
```
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create `lib/features/journey/journey_home.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../language_select/language_select_screen.dart';
import 'curriculum.dart';
import 'journey_progress.dart';
import 'journey_providers.dart';
import 'lesson_step_screen.dart';
import 'manga_step_launcher.dart';

/// The guided path — the app's front door. Shows the current chapter and one
/// calm call-to-action that runs the current step, then advances. No grid,
/// no points, no drill queue.
class JourneyHome extends ConsumerWidget {
  const JourneyHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final stepAsync = ref.watch(currentStepProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: stepAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (step) {
              if (step == null) {
                return Center(child: Text(l.journeyPathComplete));
              }
              final isLesson = step is LessonStep;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(step.chapterRef,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(
                    isLesson ? l.journeyLessonStepTitle : l.journeyMangaStepTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey('journey-start'),
                    onPressed: () => _runStep(context, ref, step),
                    child: Text(l.journeyStart),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _runStep(
      BuildContext context, WidgetRef ref, CurriculumStep step) async {
    final lang = ref.read(activeLanguageProvider);
    if (step is LessonStep) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LessonStepScreen(
          step: step,
          languageId: 'lang_$lang',
          onDone: () => Navigator.of(context).maybePop(),
        ),
      ));
    } else if (step is MangaStep) {
      await openMangaStep(context, ref, step);
    }
    // Advance the stored index and refresh the resolved step.
    final progress = await ref.read(journeyProgressProvider.future);
    await progress.setStepIndex(lang, _indexAfter(ref, step));
    ref.invalidate(currentStepProvider);
  }

  /// The next raw index after the given step (progress is a monotonically
  /// advancing cursor; resolveStepIndex handles skipping known steps).
  int _indexAfter(WidgetRef ref, CurriculumStep step) {
    final curriculum = ref.read(curriculumProvider).valueOrNull;
    if (curriculum == null) return 0;
    final i = curriculum.steps.indexWhere((s) => s.id == step.id);
    return i < 0 ? 0 : i + 1;
  }
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/journey/journey_home_test.dart --no-pub
```
Expected: PASS. (No `MascotWidget`, so `pumpAndSettle` does not hang.)

- [ ] **Step 5: Commit**

```bash
git add lib/features/journey/journey_home.dart test/features/journey/journey_home_test.dart
git commit -m "feat(journey): JourneyHome — calm guided front door (no grid/points)"
```

---

### Task 10: Router — make the journey the front door; demote Lesen/Review

**Files:**
- Modify: `lib/app.dart`
- Test: `test/app/journey_front_door_test.dart`

**Interfaces:**
- Consumes: `JourneyHome` (Task 9), `onboardingCompleteProvider`.
- Produces: `/` renders `JourneyHome`; the bottom nav no longer shows Lesen or Review (their routes remain reachable, but the front experience is the journey).

- [ ] **Step 1: Write the failing test**

Create `test/app/journey_front_door_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/journey/journey_home.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('root shows JourneyHome (not the lesson grid) when onboarded',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = LearningDb.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        onboardingCompleteProvider.overrideWith((ref) => true),
        learningDbProvider.overrideWith((ref) => db),
      ],
      child: const NihongoApp(),
    ));
    // JourneyHome has no infinite animation, so settling is safe.
    await tester.pumpAndSettle();

    expect(find.byType(JourneyHome), findsOneWidget);
    expect(find.text('Lektionen'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/app/journey_front_door_test.dart --no-pub
```
Expected: FAIL — `/` still builds `HomeScreen` (the grid).

- [ ] **Step 3: Edit `lib/app.dart`**

(a) Add the import near the other feature imports:
```dart
import 'features/journey/journey_home.dart';
```

(b) In the `_routes` `ShellRoute`, change the `/` route builder from `HomeScreen()` to `JourneyHome()`:
```dart
        GoRoute(
          path: '/',
          pageBuilder: (ctx, state) =>
              const NoTransitionPage(child: JourneyHome()),
        ),
```

(c) In `_MainShell`, demote Lesen (`/read`) and Review (`/review`) out of the nav bar. Remove their two `NavigationDestination`s from `_destinations` and their two entries from the `static const _routes` list, keeping the remaining five aligned in the SAME order. The resulting `_routes` const must be exactly:
```dart
  static const _routes = ['/', '/progress', '/kaiwa', '/games', '/settings'];
```
and `_destinations` must list, in order: Home, Fortschritt, Gespräch, Spiele, Einstellungen (drop the Lesen and Review destinations). The `/read` and `/review` GoRoutes stay in the `ShellRoute` `routes:` list (still reachable by `context.go`), they are only removed from the nav bar.

- [ ] **Step 4: Run the test + the existing app tests**

```bash
cd <WT> && flutter test test/app/journey_front_door_test.dart test/app/onboarding_redirect_test.dart --no-pub
```
Expected: the new test PASSES; `onboarding_redirect_test.dart` still passes (it asserts the incomplete-onboarding redirect and a completed run reaching the shell — `JourneyHome` replaces `HomeScreen` transparently there). If `onboarding_redirect_test.dart` asserted `HomeScreen` specifically, update that expectation to `JourneyHome`.

- [ ] **Step 5: Analyze + commit**

```bash
cd <WT> && flutter analyze lib/app.dart && \
git add lib/app.dart test/app/journey_front_door_test.dart && \
git commit -m "feat(app): journey is the front door; demote Lesen/Review from nav"
```

---

### Task 11: Vocabulary micro-check (capture prior vocab)

**Files:**
- Create: `lib/features/onboarding/vocab_check.dart`
- Test: `test/features/onboarding/vocab_check_test.dart`

**Interfaces:**
- Consumes: `LearningDb` (query seeded `Lexemes` + `Concepts` for the active language); `AppLocalizations` (Task 8).
- Produces:
  - `Future<List<VocabCheckItem>> loadVocabCheckItems(LearningDb db, String languageId, {int limit = 12})` returning `class VocabCheckItem { final String lexemeId, writtenForm, reading, meaning; }` for the language's seeded lexemes.
  - `VocabCheckStep({required List<VocabCheckItem> items, required void Function(List<String> knownLexemeIds) onDone})` — a widget presenting each word ("Kenne ich"/"Neu für mich"); collects the confirmed `lexemeId`s and calls `onDone`.

- [ ] **Step 1: Write the failing test**

Create `test/features/onboarding/vocab_check_test.dart`:

```dart
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/onboarding/vocab_check.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

void main() {
  test('loadVocabCheckItems returns the seeded lexemes with meaning', () async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'x'));
    await db.into(db.concepts).insert(
        ConceptsCompanion.insert(id: 'c_cat', glossKey: 'cat', partOfSpeech: 'n'));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_cat', languageId: 'lang_ja', conceptId: 'c_cat',
        writtenForm: '猫', reading: 'ねこ'));

    final items = await loadVocabCheckItems(db, 'lang_ja');
    expect(items, hasLength(1));
    expect(items.single.lexemeId, 'lex_ja_cat');
    expect(items.single.writtenForm, '猫');
    expect(items.single.meaning, 'cat');
  });

  testWidgets('confirming a word returns its lexemeId', (tester) async {
    List<String>? result;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: VocabCheckStep(
        items: const [
          VocabCheckItem(
              lexemeId: 'lex_ja_cat', writtenForm: '猫', reading: 'ねこ', meaning: 'cat'),
        ],
        onDone: (known) => result = known,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kenne ich'));
    await tester.pumpAndSettle();

    expect(result, ['lex_ja_cat']);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/onboarding/vocab_check_test.dart --no-pub
```
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create `lib/features/onboarding/vocab_check.dart`**

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../core/db/learning_db.dart';
import '../../l10n/app_localizations.dart';

/// One word offered in the micro-check.
class VocabCheckItem {
  final String lexemeId;
  final String writtenForm;
  final String reading;
  final String meaning;
  const VocabCheckItem({
    required this.lexemeId,
    required this.writtenForm,
    required this.reading,
    required this.meaning,
  });
}

/// The seeded lexemes of a language, as check items (word + reading + meaning).
/// Small today (the JA seed has 5), grows with the pack — language-agnostic.
Future<List<VocabCheckItem>> loadVocabCheckItems(
  LearningDb db,
  String languageId, {
  int limit = 12,
}) async {
  final lexemes = await (db.select(db.lexemes)
        ..where((t) => t.languageId.equals(languageId))
        ..limit(limit))
      .get();
  final items = <VocabCheckItem>[];
  for (final lex in lexemes) {
    final concept = await (db.select(db.concepts)
          ..where((t) => t.id.equals(lex.conceptId)))
        .getSingleOrNull();
    items.add(VocabCheckItem(
      lexemeId: lex.id,
      writtenForm: lex.writtenForm,
      reading: lex.reading,
      meaning: concept?.glossKey ?? '',
    ));
  }
  return items;
}

/// Presents each word once; the learner marks "Kenne ich" / "Neu für mich".
/// Only confirmed words are returned — the honesty invariant (never mark
/// unconfirmed knowledge known).
class VocabCheckStep extends StatefulWidget {
  final List<VocabCheckItem> items;
  final void Function(List<String> knownLexemeIds) onDone;
  const VocabCheckStep({super.key, required this.items, required this.onDone});

  @override
  State<VocabCheckStep> createState() => _VocabCheckStepState();
}

class _VocabCheckStepState extends State<VocabCheckStep> {
  final List<String> _known = [];
  int _index = 0;

  void _answer(bool knows) {
    if (knows) _known.add(widget.items[_index].lexemeId);
    if (_index + 1 >= widget.items.length) {
      widget.onDone(List.of(_known));
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (widget.items.isEmpty) {
      // Nothing to check — resolve immediately on first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone(const []));
      return const SizedBox.shrink();
    }
    final item = widget.items[_index];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.vocabCheckIntro,
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(item.writtenForm,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(item.reading, textAlign: TextAlign.center),
              const Spacer(),
              FilledButton(
                onPressed: () => _answer(true),
                child: Text(l.vocabCheckKnow),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _answer(false),
                child: Text(l.vocabCheckDont),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/onboarding/vocab_check_test.dart --no-pub
```
Expected: 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/vocab_check.dart test/features/onboarding/vocab_check_test.dart
git commit -m "feat(onboarding): vocabulary micro-check (confirmed words only)"
```

---

### Task 12: Wire the micro-check into the onboarding flow

**Files:**
- Modify: `lib/features/onboarding/onboarding_flow.dart`
- Test: `test/features/onboarding/onboarding_vocab_flow_test.dart`

**Interfaces:**
- Consumes: `VocabCheckStep`/`loadVocabCheckItems` (Task 11); existing `_finish`, `PlacementService`, `learningDbProvider`.
- Produces: after "Ich kann schon etwas" → startpoint (kana Y/N) → the vocab micro-check → `_finish` with the confirmed `knownWordLexemeIds`. A "from zero" user never sees the check.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/onboarding/onboarding_vocab_flow_test.dart`:

```dart
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/onboarding/onboarding_flow.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('prior-knowledge path reaches the vocab check and marks a word known',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'x'));
    await db.into(db.concepts).insert(
        ConceptsCompanion.insert(id: 'c_cat', glossKey: 'cat', partOfSpeech: 'n'));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_cat', languageId: 'lang_ja', conceptId: 'c_cat',
        writtenForm: '猫', reading: 'ねこ'));

    var finished = false;
    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWith((ref) => db)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingFlow(onFinished: () => finished = true),
      ),
    ));

    await tester.tap(find.text('Weiter')); // welcome
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter')); // method
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ich kann schon etwas')); // placement → startpoint
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter')); // startpoint (no kana checked) → vocab check
    await tester.pumpAndSettle();

    // Vocab check appears; confirm the word.
    expect(find.text('猫'), findsOneWidget);
    await tester.tap(find.text('Kenne ich'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    // The confirmed word is now a mastered learn-item (rung ≥ 3).
    final item = await db.getLearnItem('lang_ja:lexeme:lex_ja_cat');
    expect(item, isNotNull);
    expect(item!.masteryRung, greaterThanOrEqualTo(3));
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/onboarding/onboarding_vocab_flow_test.dart --no-pub
```
Expected: FAIL — the startpoint "Weiter" currently calls `_finish` directly; there is no vocab-check step.

- [ ] **Step 3: Edit `lib/features/onboarding/onboarding_flow.dart`**

(a) Add imports:
```dart
import '../../app/knowledge_providers.dart' show learningDbProvider;
import 'vocab_check.dart';
```
(`learningDbProvider` may already be imported transitively; ensure it resolves.)

(b) Extend the step enum and add state:
```dart
enum _Step { welcome, method, placement, startpoint, vocabCheck }
```
Add fields to `_OnboardingFlowState`:
```dart
  List<VocabCheckItem> _vocabItems = const [];
  List<String> _knownWordIds = const [];
```

(c) Change the startpoint's `onDone` to load the vocab items and advance to the check instead of finishing directly. Replace the `_Step.startpoint` case's `onDone: () => _finish(fromZero: false)` with `onDone: _goToVocabCheck`, and add:
```dart
  Future<void> _goToVocabCheck() async {
    final db = ref.read(learningDbProvider);
    final items = await loadVocabCheckItems(db, widget.languageId);
    if (items.isEmpty) {
      await _finish(fromZero: false); // nothing to check
      return;
    }
    setState(() {
      _vocabItems = items;
      _step = _Step.vocabCheck;
    });
  }
```

(d) Add the `_Step.vocabCheck` case to the `switch (_step)`:
```dart
            _Step.vocabCheck => VocabCheckStep(
                items: _vocabItems,
                onDone: (known) {
                  _knownWordIds = known;
                  _finish(fromZero: false);
                },
              ),
```

(e) Change `_finish` to use the collected ids instead of `const []`:
```dart
      knownWordLexemeIds: _knownWordIds,
```
(replace the `knownWordLexemeIds: const [], // micro-check wiring is a later increment` line).

Note: `VocabCheckStep` returns its own `Scaffold`; the flow's outer `Scaffold`+`Padding` still wraps it — that is fine (nested Scaffold is acceptable here) but to avoid double padding you may render the vocab case without the outer padding. Keep it simple: leave the outer wrapper; the nested Scaffold renders correctly.

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/onboarding/onboarding_vocab_flow_test.dart test/features/onboarding/onboarding_flow_test.dart --no-pub
```
Expected: the new test PASSES; the existing `onboarding_flow_test.dart` (beginner path) still PASSES (the "from zero" button still calls `_finish(fromZero: true)` directly, bypassing the check).

- [ ] **Step 5: Analyze + commit**

```bash
cd <WT> && flutter analyze lib/features/onboarding/ && \
git add lib/features/onboarding/onboarding_flow.dart test/features/onboarding/onboarding_vocab_flow_test.dart && \
git commit -m "feat(onboarding): vocab micro-check step feeds known words into placement"
```

---

### Task 13: End-to-end proof + full verification

**Files:**
- Create: `tool/proof_journey.dart`

- [ ] **Step 1: Write the proof tool**

Create `tool/proof_journey.dart`, mirroring the repo's `tool/proof_*.dart` gate style:

```dart
// Proof: Der geführte Weg (docs/superpowers/specs/2026-08-20-gefuehrter-weg-lektion-manga-design.md)
//   "A learner walks the guided path: a lesson step introduces its items,
//    the sequencer then advances to the manga step; a vocab-knower's known
//    lesson is skipped."
//
// Usage:
//   dart run tool/proof_journey.dart

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';
import 'package:nihongo_app/features/journey/journey_service.dart';

Curriculum _curriculum() => const Curriculum(
      languageCode: 'ja',
      title: 'proof',
      steps: [
        LessonStep(id: 'l1', chapterRef: 'K1', characterIds: ['char_ja_a'], lexemeIds: [], grammarIds: []),
        MangaStep(id: 'm1', chapterRef: 'K1', comicAsset: 'assets/comic/ja_l0.json'),
        LessonStep(id: 'l2', chapterRef: 'K2', characterIds: ['char_ja_i'], lexemeIds: [], grammarIds: []),
      ],
    );

Future<void> main(List<String> args) async {
  final db = LearningDb.forTesting();
  await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
      id: 'sp_ja_kana', scriptType: 'syllabary', decomposability: 'atomic'));
  await db.into(db.languages).insert(LanguagesCompanion.insert(
      id: 'lang_ja', name: 'JA', scriptProfileId: 'sp_ja_kana', ttsVoice: 'ja-JP'));
  await db.into(db.characters).insert(CharactersCompanion.insert(
      id: 'char_ja_a', languageId: 'lang_ja', glyph: 'あ',
      readingsJson: jsonEncode(['a']), meaning: 'a'));
  await db.into(db.characters).insert(CharactersCompanion.insert(
      id: 'char_ja_i', languageId: 'lang_ja', glyph: 'い',
      readingsJson: jsonEncode(['i']), meaning: 'i'));

  final svc = JourneyService(
      curriculum: _curriculum(), learning: db, languageId: 'lang_ja');

  // Fresh learner → step 0 (the opening lesson).
  final firstIsLesson = (await svc.resolveStepIndex(0)) == 0;

  // Complete lesson 0 (introduce char_ja_a), then advance from index 1 → manga.
  await LadderReview(db).introduce('lang_ja', RefType.character, 'char_ja_a');
  final secondIsManga = (await svc.resolveStepIndex(1)) == 1;

  // A "vocab-knower" who already has char_ja_i mastered → step 2 (l2) is
  // skipped by resolveStepIndex when starting from 2.
  await LadderReview(db).introduce('lang_ja', RefType.character, 'char_ja_i');
  final knownLessonSkipped = (await svc.resolveStepIndex(2)) == null;

  print('=== Geführter-Weg gate ===');
  print('first step is the opening lesson: $firstIsLesson');
  print('after lesson → manga step:        $secondIsManga');
  print('already-known lesson is skipped:  $knownLessonSkipped');
  final pass = firstIsLesson && secondIsManga && knownLessonSkipped;
  print('GATE: ${pass ? 'PASS' : 'FAIL'}');
  await db.close();
  print(pass ? '=== PASS ===' : '=== FAIL ===');
}
```

- [ ] **Step 2: Run the proof**

```bash
cd <WT> && dart run tool/proof_journey.dart
```
Expected: prints `GATE: PASS` and `=== PASS ===`.

- [ ] **Step 3: Run the full suite + analyze**

```bash
cd <WT> && flutter test --no-pub
```
Expected: all tests PASS except the 8 pre-existing native-tokenizer FFI failures in `test/mining_packs/ja/` (missing `libja_tokenizer.so` in this headless environment — NOT caused by this work). Confirm the only failures are those 8; investigate any other.

```bash
cd <WT> && flutter analyze
```
Expected: 0 errors in the new `lib/features/journey/` + onboarding code.

- [ ] **Step 4: Commit**

```bash
git add tool/proof_journey.dart
git commit -m "test(proof): guided-path gate — lesson → manga, known lesson skipped"
```

---

## Self-Review notes (for the executor)

- **Spec coverage:** two-pillar rhythm (Tasks 1,6,7,9), curriculum spine + sequencing (1,2,4,5), journey is the front door / grid gone / Lesen+Review demoted (10), onboarding→journey (10 via existing `/onboarding`→`/`), vocab micro-check acknowledges prior vocab (11,12), reuse of encounter+ladder+manga+i+1 (6,7), small placeholder first arc (2), no gamification / no drill front / integrated-not-cudgel (enforced by content + Global Constraints), I8 language-agnostic (all journey code keys on active lang + asset path).
- **Deliberate simplifications (flag at review):** (1) progress is a SharedPreferences step index, not a DB table (no migration/codegen). (2) The vocab micro-check offers the *seeded* lexemes (JA seed has 5) — thin today, grows with the pack; a bigger curated word set is a content follow-up. (3) The manga step uses the empty dictionary (gloss "—"), same as the shipped manga MVP; real per-language dictionary is a follow-up. (4) `/read` and `/review` routes remain reachable (removed only from the nav bar), not deleted — a full teardown of the legacy grid/`data/lessons.dart`/legacy `AppDatabase` is a later cleanup.
- **Verify before coding UI tasks:** confirm the exact current `_destinations`/`_routes` contents in `lib/app.dart` and the exact `onboarding_flow_test.dart` expectations before editing (Tasks 10, 12), and match whatever is on disk.
- **Content is the real fun:** this plan builds the *vehicle* end-to-end against a 3-chapter placeholder arc. Whether it is *fun* depends on authoring a good story + lessons on top — the ongoing content track the structure now enables.
