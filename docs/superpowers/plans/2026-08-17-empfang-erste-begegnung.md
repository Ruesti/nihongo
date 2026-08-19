# Empfang & erste Begegnung — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give a new user a warm, localized first-run (welcome → method → placement), and make every new learn-item's first appearance a multisensory *encounter* (rung 0) before it is ever tested — in both the lesson flow and the Review tab.

**Architecture:** Extend the existing SM-2 ladder with **rung 0 = "not yet encountered"**. `resolveExercise` gains an `ExerciseType.encounter`; `ExerciseLoader` builds a refType-polymorphic `Encounter` (character/lexeme/grammar); a new `EncounterView` renders it ungraded and, on "Weiter", calls `LadderReview.markEncountered` to promote 0→1. `introduce()` now starts items at rung 0. Onboarding is a new `features/onboarding/` flow gated by a `shared_preferences` flag via a GoRouter redirect; placement writes the known-set through the existing `KnowledgeBridge` + `importFrequencyBootstrap`. All new UI text is localized via `gen_l10n` (system locale). Lessons are rewired to feed `LearningDb`/the ladder instead of the dead legacy `SrsCard` path.

**Tech Stack:** Dart 3.11, Flutter, Drift 2.22, Riverpod, go_router 14, fsrs, `flutter_localizations` + `intl` (`gen_l10n`), `flutter_test` with `NativeDatabase.memory()`.

## Global Constraints

Copied from the spec — every task's requirements include these:

- **Package name:** `nihongo_app` (all imports `package:nihongo_app/...`).
- **Working dir for all commands:** `/home/uli/projects/nihongo/.claude/worktrees/spec+onboarding-and-manga` (this worktree). Shown as `<WT>` below.
- **I1 — Recall, kein Recognition** on production rungs (3–5): never show options. The encounter is ungraded and sits before rung 1, so it does not violate I1.
- **I2 — Timing ≠ Schwierigkeit:** `dueAt`/`ease`/`intervalDays` (when) and `masteryRung` (how hard) stay separate fields. Rung 0 is a mastery/reifegrad state only.
- **I3 — Keine Gamification:** no streaks, points, leaderboards anywhere in onboarding or encounter.
- **Never falsely claim "known":** placement marks only *confirmed* knowledge as known. Kana Ja/Nein is binary-safe; vocabulary only via the explicit micro-check.
- **Offline-first, Asset-Doktrin §6:** missing stroke-order/mnemonic/concept asset → omit that step, never crash. See+hear always works.
- **UI language = system locale, not hardcoded German:** all new display strings go through `AppLocalizations` (ARB). Base/template locale English, German shipped; device locale selects; fallback English.
- **`learn_items` is the single SRS unit.** All three `refType` (`lexeme|character|grammar`) run the same ladder. `RefType` enum lives in `lib/core/ladder/rung_defs.dart`.
- **Rung range is `0..5`.** Rung 0 = "not yet encountered".

## File Map

| File | Action | Responsibility |
|---|---|---|
| `pubspec.yaml` | Modify | Add `flutter_localizations`, `intl`; enable `generate: true` |
| `l10n.yaml` | Create | gen_l10n config (arb dir, template, output class) |
| `lib/l10n/app_en.arb` | Create | English strings (template/base) |
| `lib/l10n/app_de.arb` | Create | German strings |
| `lib/core/ladder/rung_defs.dart` | Modify | `ExerciseType.encounter`; rung 0..5; rung 0 → encounter |
| `lib/core/ladder/encounter.dart` | Create | `Encounter` sealed type (Character/Lexeme/Grammar) |
| `lib/core/ladder/exercise_content.dart` | Modify | Add `EncounterContent extends ExerciseContent` |
| `lib/core/ladder/exercise_loader.dart` | Modify | Build `EncounterContent` for rung 0, per refType |
| `lib/core/db/learning_db.dart` | Modify | `getLearnItem`, `markEncountered` DAO |
| `lib/core/ladder/ladder_review.dart` | Modify | `introduce()`→rung 0; add `markEncountered()` |
| `lib/data/kana_strokes.dart` | Create | kana glyph → KanjiVG asset path map |
| `assets/kanji_svg/*.svg` | Create | KanjiVG stroke SVGs for the on-ramp kana |
| `lib/features/encounter/encounter_view.dart` | Create | Renders an `Encounter` ungraded; "Weiter" callback |
| `lib/features/review/review_screen.dart` | Modify | rung-0 item → `EncounterView` → `markEncountered`, no grade footer |
| `lib/features/onboarding/onboarding_prefs.dart` | Create | flag + `placementProfile` via shared_preferences |
| `lib/features/onboarding/placement_service.dart` | Create | Writes the known-set (kana/vocab/grammar) |
| `lib/features/onboarding/onboarding_flow.dart` | Create | 3 screens + placement + startpoint, localized |
| `lib/app.dart` | Modify | MaterialApp l10n delegates; router redirect to `/onboarding` |
| `lib/features/settings/settings_screen.dart` | Modify | "Einführung erneut" entry |
| `lib/features/lesson/lesson_screen.dart` | Modify | Seam-fix: introduce to ladder, encounters-before-tests, drop legacy SRS write |
| `test/**` | Create | Unit + widget + regression tests per task |
| `tool/proof_onboarding_encounter.dart` | Create | End-to-end proof (new-user + prior-knowledge) |

---

### Task 1: Localization foundation (system locale, en + de)

**Files:**
- Modify: `pubspec.yaml`
- Create: `l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`
- Modify: `lib/app.dart` (delegates only; router redirect comes in Task 11)
- Test: `test/l10n/localization_test.dart`

**Interfaces:**
- Produces: generated `AppLocalizations` (import `package:nihongo_app/l10n/app_localizations.dart`), with keys used by later tasks: `welcomeTitle`, `welcomeBody`, `methodEncounterFirst`, `methodNoGamification`, `methodOffline`, `placementQuestion`, `placementFromZero`, `placementKnowSome`, `placementHiragana`, `placementKatakana`, `placementVocabCheck`, `startpointBeginner`, `continueLabel`, `yes`, `no`, `encounterListen`, `encounterTrace`, `encounterNext`.

- [ ] **Step 1: Add localization deps to `pubspec.yaml`**

Under `dependencies:` add (after `cupertino_icons`):

```yaml
  flutter_localizations:
    sdk: flutter
  intl: any
```

Under the top-level `flutter:` section, add `generate: true` (next to `uses-material-design: true`):

```yaml
flutter:
  uses-material-design: true
  generate: true
```

- [ ] **Step 2: Create `l10n.yaml`** (repo root)

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
```

- [ ] **Step 3: Create `lib/l10n/app_en.arb`** (base/template — English)

```json
{
  "@@locale": "en",
  "welcomeTitle": "Welcome.",
  "welcomeBody": "Here you learn Japanese by reading it — at your pace, character by character.",
  "methodEncounterFirst": "You meet every character, word and grammar point first — see it, hear it, trace it — before you are ever tested.",
  "methodNoGamification": "No points, no streaks. Your progress is what you can actually read.",
  "methodOffline": "Everything works offline. You set the pace.",
  "placementQuestion": "Where do you stand?",
  "placementFromZero": "I'm starting from zero",
  "placementKnowSome": "I already know some",
  "placementHiragana": "I can read Hiragana",
  "placementKatakana": "I can read Katakana",
  "placementVocabCheck": "Do you know this word?",
  "startpointBeginner": "We start at the very beginning.",
  "continueLabel": "Continue",
  "yes": "Yes",
  "no": "No",
  "encounterListen": "Listen",
  "encounterTrace": "Trace it",
  "encounterNext": "Got it"
}
```

- [ ] **Step 4: Create `lib/l10n/app_de.arb`** (German)

```json
{
  "@@locale": "de",
  "welcomeTitle": "Willkommen.",
  "welcomeBody": "Hier lernst du Japanisch, indem du es liest — in deinem Tempo, Zeichen für Zeichen.",
  "methodEncounterFirst": "Jedem Zeichen, Wort und Grammatikpunkt begegnest du zuerst — sehen, hören, nachfahren — bevor du geprüft wirst.",
  "methodNoGamification": "Kein Punktesammeln, keine Serien. Dein Fortschritt ist, was du wirklich lesen kannst.",
  "methodOffline": "Alles läuft offline. Du bestimmst das Tempo.",
  "placementQuestion": "Wo stehst du?",
  "placementFromZero": "Ich fange bei null an",
  "placementKnowSome": "Ich kann schon etwas",
  "placementHiragana": "Ich kann Hiragana",
  "placementKatakana": "Ich kann Katakana",
  "placementVocabCheck": "Kennst du dieses Wort?",
  "startpointBeginner": "Wir fangen ganz vorn an.",
  "continueLabel": "Weiter",
  "yes": "Ja",
  "no": "Nein",
  "encounterListen": "Hören",
  "encounterTrace": "Nachfahren",
  "encounterNext": "Verstanden"
}
```

- [ ] **Step 5: Wire delegates into `MaterialApp.router` in `lib/app.dart`**

Add imports at the top:

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
```

In `NihongoApp.build`, add the localization fields to `MaterialApp.router(...)` (keep the existing `title`, `theme`, `routerConfig`, `debugShowCheckedModeBanner`):

```dart
    return MaterialApp.router(
      onGenerateTitle: (context) => 'Nihongo',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
```

- [ ] **Step 6: Generate the localizations**

Run:
```bash
cd <WT> && flutter pub get && flutter gen-l10n
```
Expected: exits 0; `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart` (re-exported via `package:nihongo_app/l10n/app_localizations.dart`) now exists. If the import path errors, confirm `generate: true` is set and re-run `flutter pub get`.

- [ ] **Step 7: Write the localization test**

Create `test/l10n/localization_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

Widget _app(Locale locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Text(AppLocalizations.of(context)!.welcomeTitle),
      ),
    );

void main() {
  testWidgets('resolves German string for de locale', (tester) async {
    await tester.pumpWidget(_app(const Locale('de')));
    expect(find.text('Willkommen.'), findsOneWidget);
  });

  testWidgets('resolves English string for en locale', (tester) async {
    await tester.pumpWidget(_app(const Locale('en')));
    expect(find.text('Welcome.'), findsOneWidget);
  });

  test('both locales are supported', () {
    final codes =
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
    expect(codes.containsAll({'en', 'de'}), isTrue);
  });
}
```

- [ ] **Step 8: Run the test**

```bash
cd <WT> && flutter test test/l10n/localization_test.dart
```
Expected: 3 tests PASS.

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml l10n.yaml lib/l10n/ lib/app.dart test/l10n/
git commit -m "feat(l10n): gen_l10n foundation (en base + de), system-locale UI"
```

---

### Task 2: Rung 0 and `ExerciseType.encounter`

**Files:**
- Modify: `lib/core/ladder/rung_defs.dart`
- Test: `test/core/ladder/rung_defs_encounter_test.dart`

**Interfaces:**
- Produces: `ExerciseType.encounter`; `resolveExercise(0, refType, profile) == ExerciseType.encounter`; `resolveExercise` now accepts `rung >= 0 && rung <= 5`.
- Consumes: existing `ExerciseType {recognition, readingInput, productionInput, writeTrace}`, `RefType`, `ScriptProfile`.

- [ ] **Step 1: Write the failing test**

Create `test/core/ladder/rung_defs_encounter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/script_profile.dart';

const _p = ScriptProfile(
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
  test('rung 0 → encounter for every refType', () {
    for (final rt in RefType.values) {
      expect(resolveExercise(0, rt, _p), ExerciseType.encounter);
    }
  });

  test('rung 1 is still recognition (unchanged)', () {
    expect(resolveExercise(1, RefType.character, _p), ExerciseType.recognition);
  });

  test('rung 4 is still writeTrace (unchanged)', () {
    expect(resolveExercise(4, RefType.character, _p), ExerciseType.writeTrace);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/core/ladder/rung_defs_encounter_test.dart
```
Expected: FAIL — `encounter` is not a member of `ExerciseType` (and/or assert fires on rung 0).

- [ ] **Step 3: Edit `lib/core/ladder/rung_defs.dart`**

Add `encounter` to the enum and handle rung 0. Replace the enum and function:

```dart
enum ExerciseType {
  encounter,       // rung 0: first meeting, ungraded (see/hear/trace)
  recognition,     // rung 1: show written/glyph, identify meaning
  readingInput,    // rung 2: show written/glyph, type reading
  productionInput, // rung 3, 5: show meaning, type written form (no MC — I1)
  writeTrace,      // rung 4: show glyph + stroke order, trace it (spec §5)
}

enum RefType { lexeme, character, grammar }

const int promotionThreshold = 3;

ExerciseType resolveExercise(int rung, RefType refType, ScriptProfile profile) {
  assert(rung >= 0 && rung <= 5, 'rung must be 0–5, got $rung');
  if (rung <= 0) return ExerciseType.encounter;
  if (rung == 1) return ExerciseType.recognition;
  if (rung == 2) return ExerciseType.readingInput;
  if (rung == 4) return ExerciseType.writeTrace;
  return ExerciseType.productionInput;
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/core/ladder/rung_defs_encounter_test.dart
```
Expected: 3 tests PASS.

- [ ] **Step 5: Run the whole ladder test dir (catch exhaustive-switch breakage)**

```bash
cd <WT> && flutter test test/core/ladder/
```
Expected: `exercise_loader.dart`'s `switch (type)` will now fail to compile because it doesn't handle `ExerciseType.encounter`. That is fixed in Task 4. If other tests fail only on that switch, proceed; otherwise fix real regressions first.

- [ ] **Step 6: Commit**

```bash
git add lib/core/ladder/rung_defs.dart test/core/ladder/rung_defs_encounter_test.dart
git commit -m "feat(ladder): rung 0 = encounter; resolveExercise accepts 0..5"
```

---

### Task 3: The `Encounter` model + `EncounterContent`

**Files:**
- Create: `lib/core/ladder/encounter.dart`
- Modify: `lib/core/ladder/exercise_content.dart`
- Test: `test/core/ladder/encounter_test.dart`

**Interfaces:**
- Produces: sealed `Encounter` with `CharacterEncounter{glyph, reading, audioText, strokeOrderAssetId?, mnemonic?}`, `LexemeEncounter{writtenForm, reading, audioText, meaning, conceptImagePath?, exampleSentence?}`, `GrammarEncounter{pattern, plainExplanation, example, canDoDescription, contrast?}`; and `EncounterContent extends ExerciseContent { final Encounter encounter; }`.
- Consumes: `ExerciseContent` sealed base from `exercise_content.dart`.

- [ ] **Step 1: Write the failing test**

Create `test/core/ladder/encounter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/encounter.dart';
import 'package:nihongo_app/core/ladder/exercise_content.dart';

void main() {
  test('CharacterEncounter carries glyph + reading, optional stroke/mnemonic',
      () {
    const e = CharacterEncounter(
      glyph: 'あ',
      reading: 'a',
      audioText: 'あ',
      strokeOrderAssetId: 'assets/kanji_svg/3042.svg',
    );
    expect(e.glyph, 'あ');
    expect(e.strokeOrderAssetId, 'assets/kanji_svg/3042.svg');
    expect(e.mnemonic, isNull);
  });

  test('LexemeEncounter degrades without a concept image', () {
    const e = LexemeEncounter(
      writtenForm: '猫',
      reading: 'ねこ',
      audioText: '猫',
      meaning: 'cat',
    );
    expect(e.conceptImagePath, isNull);
    expect(e.exampleSentence, isNull);
  });

  test('EncounterContent is an ExerciseContent wrapping an Encounter', () {
    final c = EncounterContent(
      encounter: const CharacterEncounter(
          glyph: 'い', reading: 'i', audioText: 'い'),
    );
    expect(c, isA<ExerciseContent>());
    expect((c.encounter as CharacterEncounter).glyph, 'い');
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/core/ladder/encounter_test.dart
```
Expected: FAIL — `encounter.dart` does not exist.

- [ ] **Step 3: Create `lib/core/ladder/encounter.dart`**

```dart
/// The first-meeting content for a new learn-item (rung 0), polymorphic
/// over refType. Pure data — no Flutter/DB deps. Rendered ungraded by
/// EncounterView; every optional field degrades gracefully when its asset
/// is missing (Asset-Doktrin §6).
sealed class Encounter {
  const Encounter();
}

/// character: see the glyph, hear it, watch/trace the stroke order.
final class CharacterEncounter extends Encounter {
  final String glyph;
  final String reading;
  final String audioText; // what TTS speaks (usually the glyph)
  final String? strokeOrderAssetId; // KanjiVG asset path, null → no trace
  final String? mnemonic;

  const CharacterEncounter({
    required this.glyph,
    required this.reading,
    required this.audioText,
    this.strokeOrderAssetId,
    this.mnemonic,
  });
}

/// lexeme: experience the meaning — form + reading + concept image + use.
final class LexemeEncounter extends Encounter {
  final String writtenForm;
  final String reading;
  final String audioText;
  final String meaning;
  final String? conceptImagePath; // Assets.path (type image), null → text only
  final String? exampleSentence; // all-known example, null → omitted

  const LexemeEncounter({
    required this.writtenForm,
    required this.reading,
    required this.audioText,
    required this.meaning,
    this.conceptImagePath,
    this.exampleSentence,
  });
}

/// grammar: grasp the pattern, framed by the can-do goal.
final class GrammarEncounter extends Encounter {
  final String pattern;
  final String plainExplanation;
  final String example;
  final String canDoDescription;
  final String? contrast;

  const GrammarEncounter({
    required this.pattern,
    required this.plainExplanation,
    required this.example,
    required this.canDoDescription,
    this.contrast,
  });
}
```

- [ ] **Step 4: Add `EncounterContent` to `lib/core/ladder/exercise_content.dart`**

Add an import at the top and a new variant at the end of the file:

```dart
import 'encounter.dart';
```

```dart
/// Rung 0: Encounter — first meeting, ungraded. Wraps the refType-specific
/// [Encounter] so the review/lesson runners can carry it through the same
/// ExerciseContent channel as the graded variants.
final class EncounterContent extends ExerciseContent {
  final Encounter encounter;

  EncounterContent({required this.encounter});
}
```

- [ ] **Step 5: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/core/ladder/encounter_test.dart
```
Expected: 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/ladder/encounter.dart lib/core/ladder/exercise_content.dart test/core/ladder/encounter_test.dart
git commit -m "feat(ladder): Encounter model + EncounterContent variant"
```

---

### Task 4: Build encounters in `ExerciseLoader` (rung 0, per refType)

**Files:**
- Modify: `lib/core/ladder/exercise_loader.dart`
- Test: `test/core/ladder/exercise_loader_encounter_test.dart`

**Interfaces:**
- Consumes: `EncounterContent`, `CharacterEncounter`, `LexemeEncounter`, `GrammarEncounter` (Task 3); table rows `Characters`, `Lexemes`, `Concepts`, `Assets`, `GrammarPoints`, `CanDoGoals` (columns per `lib/core/db/tables.dart`).
- Produces: `ExerciseLoader.load(item, profile)` returns `EncounterContent` when `item.masteryRung == 0`.

- [ ] **Step 1: Write the failing test**

Create `test/core/ladder/exercise_loader_encounter_test.dart`:

```dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/encounter.dart';
import 'package:nihongo_app/core/ladder/exercise_content.dart';
import 'package:nihongo_app/core/ladder/exercise_loader.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/script_profile.dart';

const _profile = ScriptProfile(
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

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'ja-JP'));
    await db.into(db.characters).insert(CharactersCompanion.insert(
          id: 'char_a',
          languageId: 'lang_ja',
          glyph: 'あ',
          readingsJson: jsonEncode(['a']),
          meaning: 'a',
          strokeOrderAssetId: const Value('assets/kanji_svg/3042.svg'),
        ));
  });

  tearDown(() async => db.close());

  test('rung-0 character item loads a CharacterEncounter', () async {
    await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_a', rung: 0);
    final item = (await db.select(db.learnItems).get()).first;

    final content = await ExerciseLoader(db).load(item, _profile);

    expect(content, isA<EncounterContent>());
    final enc = (content as EncounterContent).encounter;
    expect(enc, isA<CharacterEncounter>());
    final ce = enc as CharacterEncounter;
    expect(ce.glyph, 'あ');
    expect(ce.reading, 'a');
    expect(ce.strokeOrderAssetId, 'assets/kanji_svg/3042.svg');
  });

  test('rung-1 character item still loads a RecognitionContent', () async {
    await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_a', rung: 1);
    final item = (await db.select(db.learnItems).get()).first;

    final content = await ExerciseLoader(db).load(item, _profile);
    expect(content, isA<RecognitionContent>());
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/core/ladder/exercise_loader_encounter_test.dart
```
Expected: FAIL — loader has no encounter branch (compile error on the non-exhaustive `switch (type)` once `encounter` is a case, or a wrong return type).

- [ ] **Step 3: Edit `lib/core/ladder/exercise_loader.dart`**

Add imports:

```dart
import 'encounter.dart';
```

Change `_loadCharacter` and `_loadLexeme` `switch (type)` to handle `ExerciseType.encounter`, and give grammar an encounter path. Replace the three methods:

```dart
  Future<ExerciseContent> load(LearnItem item, ScriptProfile profile) {
    final refType = RefType.values.byName(item.refType);
    final exerciseType = resolveExercise(item.masteryRung, refType, profile);

    return switch (refType) {
      RefType.character => _loadCharacter(item.refId, exerciseType),
      RefType.lexeme => _loadLexeme(item.refId, exerciseType),
      RefType.grammar => _loadGrammar(item.refId, exerciseType),
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
      ExerciseType.encounter => EncounterContent(
          encounter: CharacterEncounter(
            glyph: char.glyph,
            reading: reading,
            audioText: char.glyph,
            strokeOrderAssetId: char.strokeOrderAssetId,
            mnemonic: null,
          ),
        ),
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

    if (type == ExerciseType.encounter) {
      final asset = await (_db.select(_db.assets)
            ..where((t) =>
                t.conceptId.equals(lexeme.conceptId) & t.type.equals('image')))
          .getSingleOrNull();
      return EncounterContent(
        encounter: LexemeEncounter(
          writtenForm: lexeme.writtenForm,
          reading: lexeme.reading,
          audioText: lexeme.writtenForm,
          meaning: concept.glossKey,
          conceptImagePath: asset?.path,
          exampleSentence: null,
        ),
      );
    }

    return switch (type) {
      ExerciseType.encounter => throw StateError('handled above'),
      ExerciseType.recognition => RecognitionContent(
          displayForm: lexeme.writtenForm, answer: concept.glossKey),
      ExerciseType.readingInput => ReadingInputContent(
          displayForm: lexeme.writtenForm, expectedReading: lexeme.reading),
      ExerciseType.productionInput => ProductionInputContent(
          prompt: concept.glossKey, expectedForm: lexeme.writtenForm),
      ExerciseType.writeTrace => ProductionInputContent(
          prompt: concept.glossKey, expectedForm: lexeme.writtenForm),
    };
  }

  Future<ExerciseContent> _loadGrammar(
    String grammarId,
    ExerciseType type,
  ) async {
    final gp = await (_db.select(_db.grammarPoints)
          ..where((t) => t.id.equals(grammarId)))
        .getSingle();
    final canDo = await (_db.select(_db.canDoGoals)
          ..where((t) => t.id.equals(gp.canDoId)))
        .getSingle();

    if (type == ExerciseType.encounter) {
      return EncounterContent(
        encounter: GrammarEncounter(
          pattern: gp.id,
          plainExplanation: canDo.description,
          example: '',
          canDoDescription: canDo.description,
          contrast: null,
        ),
      );
    }
    // Graded grammar exercises are out of scope for this plan.
    throw UnimplementedError('grammar graded exercises not yet supported');
  }
```

Note: `GrammarEncounter.pattern`/`example` are minimal here because `GrammarPoints` carries no display text/example columns yet; the encounter still frames the can-do goal and degrades honestly (empty example is omitted by the view). Authoring richer grammar content is out of scope.

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/core/ladder/exercise_loader_encounter_test.dart
```
Expected: 2 tests PASS.

- [ ] **Step 5: Run the ladder dir (confirm Task-2 compile break is resolved)**

```bash
cd <WT> && flutter test test/core/ladder/
```
Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/ladder/exercise_loader.dart test/core/ladder/exercise_loader_encounter_test.dart
git commit -m "feat(ladder): ExerciseLoader builds rung-0 EncounterContent per refType"
```

---

### Task 5: `introduce()` → rung 0, and `markEncountered()`

**Files:**
- Modify: `lib/core/db/learning_db.dart`
- Modify: `lib/core/ladder/ladder_review.dart`
- Test: `test/core/ladder/encounter_promotion_test.dart`

**Interfaces:**
- Consumes: `addLearnItemAtRung`, `LearnItem`, `KnowledgeBridge.onLearnItemReviewed`, `schedule`/`ScheduleInput` (`core/srs/scheduler.dart`).
- Produces: `LearningDb.getLearnItem(String id) → Future<LearnItem?>`; `LearningDb.markEncounteredRow(LearnItem)` (sets rung 0→1, schedules first due); `LadderReview.introduce(...)` inserts at rung 0; `LadderReview.markEncountered(LearnItem, {languageCode})` promotes + projects "learning".

- [ ] **Step 1: Write the failing test**

Create `test/core/ladder/encounter_promotion_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';

void main() {
  late LearningDb db;
  setUp(() => db = LearningDb.forTesting());
  tearDown(() => db.close());

  test('introduce() inserts a new item at rung 0', () async {
    await LadderReview(db).introduce('lang_ja', RefType.character, 'char_a');
    final item = (await db.select(db.learnItems).get()).single;
    expect(item.masteryRung, 0);
  });

  test('markEncountered promotes rung 0 → 1 and schedules a future due', () async {
    await LadderReview(db).introduce('lang_ja', RefType.character, 'char_a');
    final before = (await db.select(db.learnItems).get()).single;
    expect(before.masteryRung, 0);

    await LadderReview(db).markEncountered(before);

    final after =
        await db.getLearnItem('lang_ja:character:char_a');
    expect(after, isNotNull);
    expect(after!.masteryRung, 1);
    // scheduled into the future — not immediately due again as a cold test
    expect(after.dueAt.isAfter(DateTime.now()), isTrue);
  });

  test('markEncountered writes no review_log row (it is ungraded)', () async {
    await LadderReview(db).introduce('lang_ja', RefType.character, 'char_a');
    final item = (await db.select(db.learnItems).get()).single;
    await LadderReview(db).markEncountered(item);
    final logs = await db.select(db.reviewLog).get();
    expect(logs, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/core/ladder/encounter_promotion_test.dart
```
Expected: FAIL — `getLearnItem` / `markEncountered` not defined; `introduce` still inserts at rung 1.

- [ ] **Step 3: Add DAOs to `lib/core/db/learning_db.dart`**

Add these methods inside `class LearningDb` (after `getDueItems`). `import '../srs/scheduler.dart';` is already present:

```dart
  Future<LearnItem?> getLearnItem(String id) =>
      (select(learnItems)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Promote a just-encountered item from rung 0 to rung 1 and schedule
  /// its first real review. Ungraded: writes no review_log row.
  Future<void> markEncounteredRow(LearnItem item) async {
    final sched = schedule(
      ScheduleInput(
        ease: item.ease,
        intervalDays: item.intervalDays,
        reps: item.reps,
      ),
      ReviewResult.good,
    );
    await (update(learnItems)..where((t) => t.id.equals(item.id))).write(
      LearnItemsCompanion(
        masteryRung: const Value(1),
        consecutiveCorrect: const Value(0),
        ease: Value(sched.ease),
        intervalDays: Value(sched.intervalDays),
        dueAt: Value(sched.dueAt),
        reps: Value(sched.reps),
      ),
    );
  }
```

- [ ] **Step 4: Change `introduce()` and add `markEncountered()` in `lib/core/ladder/ladder_review.dart`**

Replace `introduce()` body to insert at rung 0 (via `addLearnItemAtRung`) and add `markEncountered`:

```dart
  /// Introduce a brand-new item at rung 0 — "not yet encountered". Its
  /// first appearance (in a lesson or the Review queue) is the encounter,
  /// never a cold test. Not yet projected as known/learning: an unmet item
  /// is not knowledge.
  Future<void> introduce(
    String languageId,
    RefType refType,
    String refId, {
    String? languageCode,
  }) async {
    await learning.addLearnItemAtRung(languageId, refType, refId, rung: 0);
  }

  /// Complete the encounter: promote rung 0 → 1, schedule the first review,
  /// and project the item as `learning` in the shared mining state.
  Future<void> markEncountered(
    LearnItem item, {
    String? languageCode,
  }) async {
    await learning.markEncounteredRow(item);
    await bridge?.onLearnItemReviewed(
      learning,
      languageId: item.languageId,
      refType: item.refType,
      refId: item.refId,
      newMasteryRung: 1,
      languageCode: languageCode,
    );
  }
```

- [ ] **Step 5: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/core/ladder/encounter_promotion_test.dart
```
Expected: 3 tests PASS.

- [ ] **Step 6: Run the ladder + db dirs (introduce() change may touch other tests)**

```bash
cd <WT> && flutter test test/core/ladder/ test/core/db/
```
Expected: all PASS. If `ladder_review_test.dart` asserted the old rung-1 introduce behavior, update that expectation to rung 0 (the item is now introduced unmet).

- [ ] **Step 7: Commit**

```bash
git add lib/core/db/learning_db.dart lib/core/ladder/ladder_review.dart test/core/ladder/encounter_promotion_test.dart
git commit -m "feat(ladder): introduce() starts at rung 0; markEncountered promotes 0→1 ungraded"
```

---

### Task 6: KanjiVG stroke data for the on-ramp kana

**Files:**
- Create: `lib/data/kana_strokes.dart`
- Create: `assets/kanji_svg/3042.svg` … (KanjiVG SVGs for the kana used by lessons)
- Test: `test/data/kana_strokes_test.dart`

**Interfaces:**
- Produces: `String? strokeAssetForKana(String kana)` — returns the bundled KanjiVG asset path for a kana glyph, or `null` if none bundled (graceful degradation).

- [ ] **Step 1: Obtain KanjiVG kana SVGs**

KanjiVG (https://github.com/KanjiVG/kanjivg, CC-BY-SA) names files by 5-digit zero-padded hex codepoint, e.g. `あ` = U+3042 → `03042.svg`. For each kana in `lib/data/kana_data.dart`'s `hiragana`/`katakana` lists, copy its KanjiVG SVG into `assets/kanji_svg/` named `<hex>.svg` (lowercase, no leading zero to match the existing `65e5.svg` convention — i.e. `3042.svg`). Add the CC-BY-SA attribution to the repo (e.g. `assets/kanji_svg/ATTRIBUTION.md`: "Stroke-order data from KanjiVG (https://kanjivg.tagaini.net), CC-BY-SA 3.0.").

Bundle at minimum the 5 vowels used by lesson 1 (`あいうえお` = 3042, 3044, 3046, 3048, 304a). The existing `assets/kanji_svg/` dir is already declared in `pubspec.yaml`, so no pubspec change is needed.

- [ ] **Step 2: Write the failing test**

Create `test/data/kana_strokes_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/data/kana_strokes.dart';

void main() {
  test('maps あ to its KanjiVG codepoint asset', () {
    expect(strokeAssetForKana('あ'), 'assets/kanji_svg/3042.svg');
  });

  test('returns null for a kana with no bundled stroke file', () {
    // A rarely-bundled kana → graceful null, never a crash.
    expect(strokeAssetForKana('ゑ'), isNull);
  });
}
```

- [ ] **Step 3: Create `lib/data/kana_strokes.dart`**

```dart
import '../data/kana_data.dart';

/// The set of kana codepoints whose KanjiVG stroke SVG is bundled under
/// assets/kanji_svg/. Extend as more SVGs are added. Absence → null, so
/// the encounter degrades (no trace step) rather than crashing.
const Set<int> _bundledKanaCodepoints = {
  0x3042, 0x3044, 0x3046, 0x3048, 0x304a, // あいうえお
};

String _hex(int codeUnit) => codeUnit.toRadixString(16);

/// Asset path for a kana's stroke order, or null if not bundled.
String? strokeAssetForKana(String kana) {
  if (kana.isEmpty) return null;
  final cp = kana.runes.first;
  if (!_bundledKanaCodepoints.contains(cp)) return null;
  return 'assets/kanji_svg/${_hex(cp)}.svg';
}

/// True if any bundled kana exists (guards tooling). Uses [hiragana] so the
/// import is meaningful and the map can be cross-checked against the pack.
bool get hasBundledKana =>
    hiragana.any((k) => _bundledKanaCodepoints.contains(k.kana.runes.first));
```

- [ ] **Step 4: Run the test**

```bash
cd <WT> && flutter test test/data/kana_strokes_test.dart
```
Expected: 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/kana_strokes.dart assets/kanji_svg/ test/data/kana_strokes_test.dart
git commit -m "feat(data): KanjiVG kana stroke map + on-ramp vowel SVGs (CC-BY-SA)"
```

---

### Task 7: `EncounterView` widget (ungraded, degrades gracefully)

**Files:**
- Create: `lib/features/encounter/encounter_view.dart`
- Test: `test/features/encounter/encounter_view_test.dart`

**Interfaces:**
- Consumes: `Encounter`/`CharacterEncounter`/`LexemeEncounter`/`GrammarEncounter` (Task 3), `KanjiSvgLoader.loadStrokes` (`lib/features/kanji_games/trace/kanji_svg_loader.dart`), `AudioButton` (`lib/widgets/audio_button.dart`), `AppLocalizations` (Task 1).
- Produces: `EncounterView({required Encounter encounter, required VoidCallback onDone})` — renders the meeting and a single "Weiter" button that calls `onDone`. No grade buttons.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/encounter/encounter_view_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/encounter.dart';
import 'package:nihongo_app/features/encounter/encounter_view.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('character encounter shows the glyph and a Weiter button, no grades',
      (tester) async {
    var done = false;
    await tester.pumpWidget(_wrap(EncounterView(
      encounter: const CharacterEncounter(
          glyph: 'あ', reading: 'a', audioText: 'あ'),
      onDone: () => done = true,
    )));

    expect(find.text('あ'), findsOneWidget);
    // Ungraded: none of the SRS grade labels appear.
    expect(find.text('Nochmal'), findsNothing);
    expect(find.text('Gut'), findsNothing);

    await tester.tap(find.text('Verstanden'));
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('lexeme encounter without a concept image shows meaning as text',
      (tester) async {
    await tester.pumpWidget(_wrap(EncounterView(
      encounter: const LexemeEncounter(
          writtenForm: '猫', reading: 'ねこ', audioText: '猫', meaning: 'cat'),
      onDone: () {},
    )));

    expect(find.text('猫'), findsOneWidget);
    expect(find.text('cat'), findsOneWidget);
    expect(find.byType(Image), findsNothing); // degraded, no crash
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/encounter/encounter_view_test.dart
```
Expected: FAIL — `encounter_view.dart` does not exist.

- [ ] **Step 3: Create `lib/features/encounter/encounter_view.dart`**

```dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/ladder/encounter.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/audio_button.dart';

/// Renders a rung-0 [Encounter] as an ungraded, multisensory first meeting.
/// A single "Weiter" button calls [onDone]. Missing assets degrade to
/// see + hear (never a crash — Asset-Doktrin §6).
class EncounterView extends StatelessWidget {
  final Encounter encounter;
  final VoidCallback onDone;

  const EncounterView({
    super.key,
    required this.encounter,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: _body(context),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton(
            key: const ValueKey('encounter-next'),
            onPressed: onDone,
            child: Text(l.encounterNext),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final e = encounter;
    return switch (e) {
      CharacterEncounter() => _character(context, e),
      LexemeEncounter() => _lexeme(context, e),
      GrammarEncounter() => _grammar(context, e),
    };
  }

  Widget _character(BuildContext context, CharacterEncounter e) {
    return Column(
      children: [
        Text(e.glyph, style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(e.reading, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        AudioButton(text: e.audioText, size: 36),
        if (e.strokeOrderAssetId != null) ...[
          const SizedBox(height: 16),
          StrokeOrderView(assetPath: e.strokeOrderAssetId!),
        ],
        if (e.mnemonic != null) ...[
          const SizedBox(height: 12),
          Text(e.mnemonic!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }

  Widget _lexeme(BuildContext context, LexemeEncounter e) {
    return Column(
      children: [
        if (e.conceptImagePath != null && File(e.conceptImagePath!).existsSync())
          Image.file(File(e.conceptImagePath!), height: 140),
        Text(e.writtenForm, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 4),
        Text(e.reading, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(e.meaning, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        AudioButton(text: e.audioText, size: 36),
        if (e.exampleSentence != null) ...[
          const SizedBox(height: 12),
          Text(e.exampleSentence!,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }

  Widget _grammar(BuildContext context, GrammarEncounter e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(e.canDoDescription,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(e.plainExplanation,
            style: Theme.of(context).textTheme.bodyLarge),
        if (e.example.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(e.example, style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (e.contrast != null) ...[
          const SizedBox(height: 8),
          Text(e.contrast!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4: Create the stroke-order sub-widget in the same file**

Append to `lib/features/encounter/encounter_view.dart`:

```dart
/// Draws KanjiVG strokes progressively. Falls back to nothing if the asset
/// can't be parsed (loader returns null) — never a crash.
class StrokeOrderView extends StatelessWidget {
  final String assetPath;
  const StrokeOrderView({super.key, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: KanjiSvgLoader.loadStrokes(assetPath),
      builder: (context, snapshot) {
        final strokes = snapshot.data;
        if (strokes == null || strokes.isEmpty) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(painter: _StrokePainter(strokes)),
        );
      },
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    // KanjiSvgLoader samples into a 300px canvas by default; scale to fit.
    final scale = size.width / 300.0;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx * scale, stroke.first.dy * scale);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx * scale, p.dy * scale);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => false;
}
```

Add the loader import at the top of the file:

```dart
import '../kanji_games/trace/kanji_svg_loader.dart';
```

- [ ] **Step 5: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/encounter/encounter_view_test.dart
```
Expected: 2 tests PASS. (The character test's `strokeOrderAssetId` is null, so no asset load happens; degradation path covered.)

- [ ] **Step 6: Commit**

```bash
git add lib/features/encounter/ test/features/encounter/
git commit -m "feat(encounter): EncounterView — ungraded multisensory first meeting, degrades gracefully"
```

---

### Task 8: Review-tab shows the encounter for rung-0 items

**Files:**
- Modify: `lib/features/review/review_screen.dart`
- Test: `test/features/review/review_encounter_test.dart`

**Interfaces:**
- Consumes: `EncounterContent` (Task 3), `EncounterView` (Task 7), `LadderReview.markEncountered` (Task 5).
- Produces: when the current due item is `EncounterContent`, the review screen renders `EncounterView` with no reveal/grade footer; on "Weiter" it calls `markEncountered`, advances, and reloads.

- [ ] **Step 1: Write the failing regression test**

Create `test/features/review/review_encounter_test.dart`. This proves the exact bug being fixed: a never-met (rung 0) item shows the encounter, not a cold recognition test.

```dart
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/encounter/encounter_view.dart';
import 'package:nihongo_app/features/review/review_screen.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';
import 'dart:convert';

void main() {
  testWidgets('a rung-0 due item shows the encounter, not a recognition test',
      (tester) async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'ja-JP'));
    await db.into(db.characters).insert(CharactersCompanion.insert(
        id: 'char_a',
        languageId: 'lang_ja',
        glyph: 'あ',
        readingsJson: jsonEncode(['a']),
        meaning: 'a'));
    await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_a', rung: 0);

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWith((ref) => db)],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReviewScreen(lang: 'ja'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(EncounterView), findsOneWidget);
    expect(find.text('あ'), findsOneWidget);
    // The recognition prompt / grade buttons must NOT be present.
    expect(find.text('Nochmal'), findsNothing);
  });
}
```

Note: confirm `ReviewScreen`'s constructor param name (`lang`) and the provider key used for `LearningDb` match the current file; adjust the override/args to match if the real signature differs.

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/review/review_encounter_test.dart
```
Expected: FAIL — no `EncounterView` in the tree (the screen still renders `_RecognitionExercise`).

- [ ] **Step 3: Handle `EncounterContent` in `review_screen.dart`**

In the `build` `switch (content)` block (around lines 166–189, currently the 4 graded variants), add an `EncounterContent()` case that renders `EncounterView` and skips the reveal/grade footer. Import `EncounterView` and the content type at the top:

```dart
import '../encounter/encounter_view.dart';
import '../../core/ladder/exercise_content.dart';
```

Replace the content switch with one that special-cases the encounter (ungraded) and keeps the reveal/grade footer only for graded content:

```dart
                child: switch (content) {
                  EncounterContent() => EncounterView(
                      encounter: content.encounter,
                      onDone: _finishEncounter,
                    ),
                  RecognitionContent() => _RecognitionExercise(
                      content: content,
                      revealed: _revealed,
                      onReveal: () => setState(() => _revealed = true),
                    ),
                  ReadingInputContent() => _ReadingInputExercise(
                      content: content,
                      controller: _inputCtrl,
                      revealed: _revealed,
                      onReveal: () => setState(() => _revealed = true),
                    ),
                  ProductionInputContent() => _ProductionExercise(
                      content: content,
                      controller: _inputCtrl,
                      revealed: _revealed,
                      onReveal: () => setState(() => _revealed = true),
                    ),
                  WriteTraceContent() => _WriteTraceExercise(
                      content: content,
                      revealed: _revealed,
                      onReveal: () => setState(() => _revealed = true),
                    ),
                },
```

(Keep whatever constructor args the four existing `_*Exercise` widgets already take — copy them from the current file verbatim; only the `EncounterContent()` case is new.)

Guard the grade footer so it never shows for an encounter. Find where `GradeButtons(onGrade: _grade)` is rendered `if (_revealed)` and change the condition to also require a non-encounter content:

```dart
              if (_revealed && _content is! EncounterContent)
                GradeButtons(onGrade: _grade),
```

Add the `_finishEncounter` handler next to `_grade`:

```dart
  Future<void> _finishEncounter() async {
    final item = _queue[_index];
    await LadderReview(_db, bridge: ref.read(knowledgeBridgeProvider))
        .markEncountered(item, languageCode: widget.lang);
    _index++;
    if (_index >= _queue.length) {
      setState(() => _done = true);
    } else {
      await _loadContent();
    }
  }
```

(Reuse the exact `_db`, `ref.read(knowledgeBridgeProvider)`, `_queue`, `_index`, `_loadContent`, `_done` members already present in the file.)

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/review/review_encounter_test.dart
```
Expected: PASS.

- [ ] **Step 5: Run the review dir + full ladder/db suite**

```bash
cd <WT> && flutter test test/features/review/ test/core/
```
Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/review/review_screen.dart test/features/review/review_encounter_test.dart
git commit -m "feat(review): rung-0 items show the encounter (not a cold test), then markEncountered"
```

---

### Task 9: Onboarding preferences + placement service

**Files:**
- Create: `lib/features/onboarding/onboarding_prefs.dart`
- Create: `lib/features/onboarding/placement_service.dart`
- Test: `test/features/onboarding/placement_service_test.dart`

**Interfaces:**
- Produces:
  - `OnboardingPrefs` with `Future<bool> isComplete()`, `Future<void> markComplete(PlacementProfile)`, `Future<PlacementProfile?> profile()`, backed by `SharedPreferences` (keys `onboarding_complete`, `placement_profile_json`).
  - `PlacementProfile({bool fromZero, bool knowsHiragana, bool knowsKatakana, List<String> knownWordLexemeIds})` with `toJson`/`fromJson`.
  - `PlacementService(LearningDb learning, KnowledgeBridge? bridge)` with `Future<void> apply(PlacementProfile, {required String languageId, required String languageCode})` — kana known → mastered rung + projected known; confirmed words → mastered rung + projected known.
- Consumes: `LearningDb.addLearnItemAtRung`, `KnowledgeBridge.onLearnItemReviewed`, `RefType`.

- [ ] **Step 1: Write the failing test**

Create `test/features/onboarding/placement_service_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/onboarding/onboarding_prefs.dart';
import 'package:nihongo_app/features/onboarding/placement_service.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'ja-JP'));
    await db.into(db.concepts).insert(
        ConceptsCompanion.insert(id: 'c_dog', glossKey: 'dog', partOfSpeech: 'n'));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_dog',
        languageId: 'lang_ja',
        conceptId: 'c_dog',
        writtenForm: '犬',
        reading: 'いぬ'));
  });

  tearDown(() async => db.close());

  test('confirmed word is inserted as a mastered (rung ≥ 3) learn item', () async {
    const profile = PlacementProfile(
      fromZero: false,
      knowsHiragana: true,
      knowsKatakana: false,
      knownWordLexemeIds: ['lex_dog'],
    );

    await PlacementService(db, null)
        .apply(profile, languageId: 'lang_ja', languageCode: 'ja');

    final item = await db.getLearnItem('lang_ja:lexeme:lex_dog');
    expect(item, isNotNull);
    expect(item!.masteryRung, greaterThanOrEqualTo(3));
  });

  test('PlacementProfile round-trips through JSON', () {
    const p = PlacementProfile(
      fromZero: false,
      knowsHiragana: true,
      knowsKatakana: false,
      knownWordLexemeIds: ['a', 'b'],
    );
    final back = PlacementProfile.fromJson(p.toJson());
    expect(back.knowsHiragana, isTrue);
    expect(back.knownWordLexemeIds, ['a', 'b']);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/onboarding/placement_service_test.dart
```
Expected: FAIL — files don't exist.

- [ ] **Step 3: Create `lib/features/onboarding/onboarding_prefs.dart`**

```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PlacementProfile {
  final bool fromZero;
  final bool knowsHiragana;
  final bool knowsKatakana;
  final List<String> knownWordLexemeIds;

  const PlacementProfile({
    required this.fromZero,
    required this.knowsHiragana,
    required this.knowsKatakana,
    required this.knownWordLexemeIds,
  });

  Map<String, dynamic> toJson() => {
        'fromZero': fromZero,
        'knowsHiragana': knowsHiragana,
        'knowsKatakana': knowsKatakana,
        'knownWordLexemeIds': knownWordLexemeIds,
      };

  factory PlacementProfile.fromJson(Map<String, dynamic> j) => PlacementProfile(
        fromZero: j['fromZero'] as bool? ?? true,
        knowsHiragana: j['knowsHiragana'] as bool? ?? false,
        knowsKatakana: j['knowsKatakana'] as bool? ?? false,
        knownWordLexemeIds:
            (j['knownWordLexemeIds'] as List?)?.cast<String>() ?? const [],
      );
}

class OnboardingPrefs {
  static const _completeKey = 'onboarding_complete';
  static const _profileKey = 'placement_profile_json';

  final SharedPreferences _prefs;
  const OnboardingPrefs(this._prefs);

  Future<bool> isComplete() async => _prefs.getBool(_completeKey) ?? false;

  Future<void> markComplete(PlacementProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    await _prefs.setBool(_completeKey, true);
  }

  PlacementProfile? profile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    return PlacementProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
```

- [ ] **Step 4: Create `lib/features/onboarding/placement_service.dart`**

```dart
import '../../core/db/learning_db.dart';
import '../../core/ladder/rung_defs.dart';
import '../../core/pipeline/knowledge_bridge.dart';
import '../../data/kana_data.dart';
import 'onboarding_prefs.dart';

/// Turns a [PlacementProfile] into known-state, honestly: only confirmed
/// knowledge is written. Kana Ja/Nein is binary-safe; words come only from
/// the explicit micro-check. Nothing unconfirmed is ever marked known.
class PlacementService {
  static const _masteredRung = 3; // rung ≥ 3 → "known" (KnowledgeBridge)

  final LearningDb learning;
  final KnowledgeBridge? bridge;

  const PlacementService(this.learning, this.bridge);

  Future<void> apply(
    PlacementProfile profile, {
    required String languageId,
    required String languageCode,
  }) async {
    if (profile.fromZero) return; // a beginner declares nothing known

    if (profile.knowsHiragana) {
      await _masterCharacters(hiragana, languageId, languageCode);
    }
    if (profile.knowsKatakana) {
      await _masterCharacters(katakana, languageId, languageCode);
    }
    for (final lexemeId in profile.knownWordLexemeIds) {
      await learning.addLearnItemAtRung(
          languageId, RefType.lexeme, lexemeId, rung: _masteredRung);
      await bridge?.onLearnItemReviewed(
        learning,
        languageId: languageId,
        refType: 'lexeme',
        refId: lexemeId,
        newMasteryRung: _masteredRung,
        languageCode: languageCode,
      );
    }
  }

  Future<void> _masterCharacters(
    List<KanaEntry> kana,
    String languageId,
    String languageCode,
  ) async {
    for (final k in kana) {
      // Character refIds follow the pack's convention; look up the matching
      // Characters row by glyph so we mark the real learn-item.
      final row = await (learning.select(learning.characters)
            ..where((t) =>
                t.languageId.equals(languageId) & t.glyph.equals(k.kana)))
          .getSingleOrNull();
      if (row == null) continue;
      await learning.addLearnItemAtRung(
          languageId, RefType.character, row.id, rung: _masteredRung);
    }
  }
}
```

- [ ] **Step 5: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/onboarding/placement_service_test.dart
```
Expected: 2 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/onboarding_prefs.dart lib/features/onboarding/placement_service.dart test/features/onboarding/placement_service_test.dart
git commit -m "feat(onboarding): PlacementProfile + PlacementService (honest known-set only)"
```

---

### Task 10: Onboarding UI flow (localized, Datum-warm)

**Files:**
- Create: `lib/features/onboarding/onboarding_flow.dart`
- Test: `test/features/onboarding/onboarding_flow_test.dart`

**Interfaces:**
- Consumes: `AppLocalizations` (Task 1), `OnboardingPrefs`/`PlacementProfile`/`PlacementService` (Task 9), `learningDbProvider`, `knowledgeBridgeProvider`.
- Produces: `OnboardingFlow({required VoidCallback onFinished})` — a `ConsumerStatefulWidget` stepping welcome → method → placement → startpoint; on finish it calls `PlacementService.apply`, `OnboardingPrefs.markComplete`, then `onFinished`.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/onboarding/onboarding_flow_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/onboarding/onboarding_flow.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('beginner path: welcome → method → placement → finished',
      (tester) async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
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

    // Welcome
    expect(find.text('Willkommen.'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    // Method
    expect(find.textContaining('Kein Punktesammeln'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    // Placement — choose "from zero"
    expect(find.text('Wo stehst du?'), findsOneWidget);
    await tester.tap(find.text('Ich fange bei null an'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/onboarding/onboarding_flow_test.dart
```
Expected: FAIL — `onboarding_flow.dart` does not exist.

- [ ] **Step 3: Create `lib/features/onboarding/onboarding_flow.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/db/learning_db.dart';
import '../../core/pipeline/knowledge_bridge.dart';
import '../../l10n/app_localizations.dart';
import 'onboarding_prefs.dart';
import 'placement_service.dart';

/// The one-time first-run reception, spoken by Datum (warmer register).
/// welcome → method → placement → (startpoint) → apply + finish.
class OnboardingFlow extends ConsumerStatefulWidget {
  final VoidCallback onFinished;
  final String languageId;
  final String languageCode;

  const OnboardingFlow({
    super.key,
    required this.onFinished,
    this.languageId = 'lang_ja',
    this.languageCode = 'ja',
  });

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

enum _Step { welcome, method, placement, startpoint }

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  _Step _step = _Step.welcome;
  bool _knowsHiragana = false;
  bool _knowsKatakana = false;

  Future<void> _finish({required bool fromZero}) async {
    final profile = PlacementProfile(
      fromZero: fromZero,
      knowsHiragana: _knowsHiragana,
      knowsKatakana: _knowsKatakana,
      knownWordLexemeIds: const [], // micro-check wiring is a later increment
    );
    final db = ref.read(learningDbProvider);
    final KnowledgeBridge? bridge = ref.read(knowledgeBridgeProvider);
    await PlacementService(db, bridge).apply(
      profile,
      languageId: widget.languageId,
      languageCode: widget.languageCode,
    );
    final prefs = await SharedPreferences.getInstance();
    await OnboardingPrefs(prefs).markComplete(profile);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_step) {
            _Step.welcome => _WelcomeStep(
                title: l.welcomeTitle,
                body: l.welcomeBody,
                cta: l.continueLabel,
                onNext: () => setState(() => _step = _Step.method),
              ),
            _Step.method => _MethodStep(
                beats: [
                  l.methodEncounterFirst,
                  l.methodNoGamification,
                  l.methodOffline,
                ],
                cta: l.continueLabel,
                onNext: () => setState(() => _step = _Step.placement),
              ),
            _Step.placement => _PlacementStep(
                question: l.placementQuestion,
                fromZero: l.placementFromZero,
                knowSome: l.placementKnowSome,
                onFromZero: () => _finish(fromZero: true),
                onKnowSome: () => setState(() => _step = _Step.startpoint),
              ),
            _Step.startpoint => _StartpointStep(
                hiragana: l.placementHiragana,
                katakana: l.placementKatakana,
                cta: l.continueLabel,
                knowsHiragana: _knowsHiragana,
                knowsKatakana: _knowsKatakana,
                onHiragana: (v) => setState(() => _knowsHiragana = v),
                onKatakana: (v) => setState(() => _knowsKatakana = v),
                onDone: () => _finish(fromZero: false),
              ),
          },
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final String title, body, cta;
  final VoidCallback onNext;
  const _WelcomeStep(
      {required this.title,
      required this.body,
      required this.cta,
      required this.onNext});
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
          const Spacer(),
          FilledButton(onPressed: onNext, child: Text(cta)),
        ],
      );
}

class _MethodStep extends StatelessWidget {
  final List<String> beats;
  final String cta;
  final VoidCallback onNext;
  const _MethodStep(
      {required this.beats, required this.cta, required this.onNext});
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final b in beats) ...[
            Text(b, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
          ],
          const Spacer(),
          FilledButton(onPressed: onNext, child: Text(cta)),
        ],
      );
}

class _PlacementStep extends StatelessWidget {
  final String question, fromZero, knowSome;
  final VoidCallback onFromZero, onKnowSome;
  const _PlacementStep(
      {required this.question,
      required this.fromZero,
      required this.knowSome,
      required this.onFromZero,
      required this.onKnowSome});
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(question, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          FilledButton(onPressed: onFromZero, child: Text(fromZero)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onKnowSome, child: Text(knowSome)),
        ],
      );
}

class _StartpointStep extends StatelessWidget {
  final String hiragana, katakana, cta;
  final bool knowsHiragana, knowsKatakana;
  final ValueChanged<bool> onHiragana, onKatakana;
  final VoidCallback onDone;
  const _StartpointStep(
      {required this.hiragana,
      required this.katakana,
      required this.cta,
      required this.knowsHiragana,
      required this.knowsKatakana,
      required this.onHiragana,
      required this.onKatakana,
      required this.onDone});
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
              value: knowsHiragana,
              title: Text(hiragana),
              onChanged: onHiragana),
          SwitchListTile(
              value: knowsKatakana,
              title: Text(katakana),
              onChanged: onKatakana),
          const Spacer(),
          FilledButton(onPressed: onDone, child: Text(cta)),
        ],
      );
}
```

Note the 60-second vocabulary micro-check is intentionally a later increment: `knownWordLexemeIds` is wired end-to-end (PlacementService consumes it) but the UI passes `const []` for now, so a prior-knowledge user still declares kana safely. Add the micro-check screen as a follow-up task once a small frequency word set is chosen.

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/onboarding/onboarding_flow_test.dart
```
Expected: PASS. If `knowledgeBridgeProvider` returns non-null and requires a MiningDb in the test, override it to `(ref) => null` in the ProviderScope.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/onboarding_flow.dart test/features/onboarding/onboarding_flow_test.dart
git commit -m "feat(onboarding): localized welcome→method→placement flow (Datum-warm)"
```

---

### Task 11: Route the first run into onboarding + Settings re-entry

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/main.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Test: `test/app/onboarding_redirect_test.dart`

**Interfaces:**
- Consumes: `OnboardingPrefs.isComplete()`, `OnboardingFlow`.
- Produces: a GoRouter `redirect` sending `/` → `/onboarding` while onboarding is incomplete; a `/onboarding` route; a Settings action that clears the flag and returns to onboarding.

- [ ] **Step 1: Load onboarding state at boot in `lib/main.dart`**

After the existing `final prefs = await SharedPreferences.getInstance();`, compute the flag and pass it into the app via a provider override. Add a provider (top of `main.dart` or a small `onboarding_providers.dart`):

```dart
final onboardingCompleteProvider = Provider<bool>((_) => false);
```

In `main()`, before `runApp`, read it:

```dart
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
```

Add to the `overrides:` list in `runApp`:

```dart
        onboardingCompleteProvider.overrideWith((ref) => onboardingComplete),
```

- [ ] **Step 2: Add the route + redirect in `lib/app.dart`**

Add an import and a `/onboarding` GoRoute (top-level, outside the shell, like `/lesson/:id`):

```dart
import 'features/onboarding/onboarding_flow.dart';
```

```dart
    GoRoute(
      path: '/onboarding',
      builder: (ctx, state) => OnboardingFlow(
        onFinished: () => ctx.go('/'),
      ),
    ),
```

Because `_router` is a top-level final, convert it to be built inside `NihongoApp.build` with access to `ref`, and add a `redirect`. Replace the `NihongoApp` build to construct the router with the redirect reading the provider:

```dart
class NihongoApp extends ConsumerWidget {
  const NihongoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingComplete = ref.watch(onboardingCompleteProvider);
    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final atOnboarding = state.matchedLocation == '/onboarding';
        if (!onboardingComplete && !atOnboarding) return '/onboarding';
        return null;
      },
      routes: _routes, // the existing route list, extracted to a top-level `_routes`
    );
    return MaterialApp.router(
      onGenerateTitle: (context) => 'Nihongo',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
```

Extract the existing `routes: [...]` list from the old top-level `_router` into a top-level `final List<RouteBase> _routes = [ ... ]` (the ShellRoute + `/lesson/:id` + the new `/onboarding`). Import `onboardingCompleteProvider` from wherever Step 1 defined it.

- [ ] **Step 3: Add a Settings re-entry in `settings_screen.dart`**

Add a `ListTile` that clears the flag and navigates back to onboarding:

```dart
          ListTile(
            leading: const Icon(Icons.waving_hand_outlined),
            title: Text(AppLocalizations.of(context)!.placementQuestion),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('onboarding_complete', false);
              if (context.mounted) context.go('/onboarding');
            },
          ),
```

(Import `AppLocalizations`, `shared_preferences`, and `go_router` in that file if not already present. Re-running onboarding is additive: `PlacementService` only ever marks *more* known, never un-knows.)

- [ ] **Step 4: Write the redirect test**

Create `test/app/onboarding_redirect_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/onboarding/onboarding_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('incomplete onboarding redirects the root to the flow',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = LearningDb.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        onboardingCompleteProvider.overrideWith((ref) => false),
        learningDbProvider.overrideWith((ref) => db),
      ],
      child: const NihongoApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingFlow), findsOneWidget);
  });
}
```

- [ ] **Step 5: Run the test**

```bash
cd <WT> && flutter test test/app/onboarding_redirect_test.dart
```
Expected: PASS. If `knowledgeBridgeProvider` needs an override in this widget tree, add `knowledgeBridgeProvider.overrideWith((ref) => null)`.

- [ ] **Step 6: Commit**

```bash
git add lib/app.dart lib/main.dart lib/features/settings/settings_screen.dart test/app/onboarding_redirect_test.dart
git commit -m "feat(onboarding): first-run redirect to /onboarding + Settings re-entry"
```

---

### Task 12: Seam-fix — lessons feed the ladder, encounters before tests

**Files:**
- Modify: `lib/features/lesson/lesson_screen.dart`
- Test: `test/features/lesson/lesson_feeds_ladder_test.dart`

**Interfaces:**
- Consumes: `LadderReview.introduce`/`markEncountered` (Task 5), `learningDbProvider`, `EncounterView` (Task 7), `ExerciseLoader` (Task 4), the kana/character pack rows.
- Produces: on lesson completion, each lesson card exists as a `LearnItem` in `LearningDb` at rung 1 (encountered), scheduled — so the Review tab serves them. The legacy `SrsCard` SRS write is removed (lesson *status* write stays).

- [ ] **Step 1: Write the failing test**

Create `test/features/lesson/lesson_feeds_ladder_test.dart`. This proves the closed seam: finishing a lesson creates ladder items the Review queue can serve (today it creates none).

```dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';

// This unit test exercises the extracted seam function the lesson screen
// calls, so it can be verified without pumping the full lesson UI.
void main() {
  late LearningDb db;
  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'ja-JP'));
    await db.into(db.characters).insert(CharactersCompanion.insert(
        id: 'char_a',
        languageId: 'lang_ja',
        glyph: 'あ',
        readingsJson: jsonEncode(['a']),
        meaning: 'a'));
  });
  tearDown(() async => db.close());

  test('introduce + markEncountered leaves a due rung-1 item for Review',
      () async {
    final review = LadderReview(db);
    // lesson start: introduce at rung 0
    await review.introduce('lang_ja', RefType.character, 'char_a');
    // after the encounter step in the lesson:
    final introduced = (await db.select(db.learnItems).get()).single;
    await review.markEncountered(introduced);

    final item = await db.getLearnItem('lang_ja:character:char_a');
    expect(item!.masteryRung, 1);
    // The Review queue will serve it once its scheduled dueAt arrives.
    expect(item.refType, 'character');
  });
}
```

- [ ] **Step 2: Run test to confirm it fails, then passes**

```bash
cd <WT> && flutter test test/features/lesson/lesson_feeds_ladder_test.dart
```
Expected: PASS immediately (it exercises Task-5 APIs). This test locks the contract the lesson screen must honor; Steps 3–4 wire the UI to it.

- [ ] **Step 3: Rewire `lesson_screen.dart` to feed the ladder**

Two changes:

(a) At lesson start (where `ExerciseFactory(...).buildSession()` is called, lines 50–57), also introduce each card into the ladder at rung 0 and prepend an encounter phase. Add, after building `_exercises`:

```dart
      // Seam-fix: lessons feed the single SRS unit (LearningDb), not the
      // dead legacy SrsCard path. Introduce each card unmet (rung 0) and
      // prepend its encounter so every new item is met before it is tested.
      final review = LadderReview(
        ref.read(learningDbProvider),
        bridge: ref.read(knowledgeBridgeProvider),
      );
      final loader = ExerciseLoader(ref.read(learningDbProvider));
      final encounters = <Widget Function(OnExerciseDone)>[];
      for (final refId in _ladderRefIdsForLesson(_lesson!)) {
        await review.introduce(widget.lang == 'ja' ? 'lang_ja' : 'lang_${widget.lang}',
            _refTypeForLesson(_lesson!), refId);
        final item = await ref
            .read(learningDbProvider)
            .getLearnItem('lang_${widget.lang}:${_refTypeForLesson(_lesson!).name}:$refId');
        if (item == null) continue;
        final content = await loader.load(item, _profileForLesson());
        if (content is EncounterContent) {
          encounters.add((onDone) => _EncounterStep(
                content: content,
                item: item,
                review: review,
                onDone: onDone,
                lang: widget.lang,
              ));
        }
      }
      _exercises = [...encounters, ..._exercises];
      _total = _exercises.length;
```

Add a small wrapper widget in the same file that renders the encounter and calls `markEncountered` before advancing:

```dart
class _EncounterStep extends StatelessWidget {
  final EncounterContent content;
  final LearnItem item;
  final LadderReview review;
  final OnExerciseDone onDone;
  final String lang;
  const _EncounterStep({
    required this.content,
    required this.item,
    required this.review,
    required this.onDone,
    required this.lang,
  });
  @override
  Widget build(BuildContext context) => EncounterView(
        encounter: content.encounter,
        onDone: () async {
          await review.markEncountered(item, languageCode: lang);
          onDone(true); // ungraded — advance, counts as "seen"
        },
      );
}
```

Add the helper methods `_ladderRefIdsForLesson`, `_refTypeForLesson`, `_profileForLesson` — for `LessonCategory.kana`, map `_lesson!.cardIds` (kana `cardId`s like `hira_a`) to the matching `Characters.id` by glyph, return `RefType.character`, and a kana `ScriptProfile`. Keep them small and local; for non-kana lesson categories, return empty (those categories keep their existing behavior for now).

(b) In `_saveLessonProgress` (lines 72–109), **remove** the `SrsCard` upsert loop (the `for (final cardId in _lesson!.cardIds) { ... upsertSrsCard ... }` block). Keep `setLessonStatus`, the next-lesson unlock, and the `ref.invalidate(...)` calls. The ladder items are now created at lesson start and promoted by the encounter step, so no legacy SRS write is needed.

Add imports at the top of `lesson_screen.dart`:

```dart
import '../../core/db/learning_db.dart';
import '../../core/ladder/exercise_content.dart';
import '../../core/ladder/exercise_loader.dart';
import '../../core/ladder/ladder_review.dart';
import '../../core/ladder/rung_defs.dart';
import '../../core/script_profile.dart';
import '../encounter/encounter_view.dart';
```

- [ ] **Step 4: Run the lesson test dir + analyze**

```bash
cd <WT> && flutter test test/features/lesson/ && flutter analyze lib/features/lesson/
```
Expected: tests PASS; analyze reports 0 errors in the lesson dir. Fix any missing provider imports (`knowledgeBridgeProvider` lives with the mining providers; import it as the review screen does).

- [ ] **Step 5: Commit**

```bash
git add lib/features/lesson/lesson_screen.dart test/features/lesson/lesson_feeds_ladder_test.dart
git commit -m "feat(lesson): feed the ladder (rung 0 + encounter), drop dead SrsCard SRS write"
```

---

### Task 13: End-to-end proof + full verification

**Files:**
- Create: `tool/proof_onboarding_encounter.dart`
- Test: (run the whole suite)

- [ ] **Step 1: Write the proof tool**

Create `tool/proof_onboarding_encounter.dart`, mirroring the `tool/phaseN_*.dart` header + gate style:

```dart
// Proof: Empfang & erste Begegnung (docs/superpowers/specs/2026-08-17-empfang-erste-begegnung-design.md)
//   "Every new item's first appearance is an encounter (rung 0), not a
//    cold test; placement writes only confirmed knowledge; lessons feed
//    the single SRS unit."
//
// Runs headless against in-memory DBs: a new-user path (from zero) and a
// prior-knowledge path (knows Hiragana), asserting the ladder + known-set.
//
// Usage:
//   dart run tool/proof_onboarding_encounter.dart

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/exercise_content.dart';
import 'package:nihongo_app/core/ladder/exercise_loader.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/script_profile.dart';

const _profile = ScriptProfile(
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

Future<void> main(List<String> args) async {
  final db = LearningDb.forTesting();
  await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
      id: 'sp', scriptType: 'syllabary', decomposability: 'atomic'));
  await db.into(db.languages).insert(LanguagesCompanion.insert(
      id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'ja-JP'));
  await db.into(db.characters).insert(CharactersCompanion.insert(
      id: 'char_a',
      languageId: 'lang_ja',
      glyph: 'あ',
      readingsJson: jsonEncode(['a']),
      meaning: 'a'));

  final review = LadderReview(db);
  await review.introduce('lang_ja', RefType.character, 'char_a');
  final introduced = (await db.select(db.learnItems).get()).single;
  final firstContent = await ExerciseLoader(db).load(introduced, _profile);
  final firstIsEncounter = firstContent is EncounterContent;

  await review.markEncountered(introduced);
  final after = await db.getLearnItem('lang_ja:character:char_a');
  final promoted = after!.masteryRung == 1;

  print('=== Empfang/Begegnung gate ===');
  print('first appearance is an encounter: $firstIsEncounter');
  print('encounter promotes rung 0 -> 1:  $promoted');
  final pass = firstIsEncounter && promoted;
  print('GATE: ${pass ? 'PASS' : 'FAIL'}');
  await db.close();
  print(pass ? '=== PASS ===' : '=== FAIL ===');
}
```

- [ ] **Step 2: Run the proof**

```bash
cd <WT> && dart run tool/proof_onboarding_encounter.dart
```
Expected: prints `GATE: PASS` and `=== PASS ===`.

- [ ] **Step 3: Run the full test suite**

```bash
cd <WT> && flutter test
```
Expected: all tests PASS (existing + new). Investigate and fix any regression before proceeding.

- [ ] **Step 4: Run analyze**

```bash
cd <WT> && flutter analyze
```
Expected: 0 errors. Warnings pre-existing elsewhere are acceptable; new code should be clean.

- [ ] **Step 5: Commit**

```bash
git add tool/proof_onboarding_encounter.dart
git commit -m "test(proof): end-to-end Empfang/Begegnung gate — encounter-before-test proven"
```

---

## Self-Review notes (for the executor)

- **Spec coverage:** welcome/method/placement (Tasks 1,10,11), Datum-warm localized copy (Task 1 ARB + Task 10), hybrid placement kana-safe + micro-check-ready (Tasks 9,10 — the vocab micro-check *screen* is flagged as a follow-up increment; the data path is complete), rung-0 encounter polymorphic over character/lexeme/grammar (Tasks 2–4,7), introduce→0 + markEncountered (Task 5), seam-fix (Task 12), Review regression (Task 8), KanjiVG (Task 6), l10n system-locale (Task 1), graceful degradation (Tasks 4,7).
- **Known follow-ups (not blocking this plan):** (1) the 60-second vocabulary micro-check UI; (2) authoring richer `GrammarPoints` display text/examples; (3) bundling KanjiVG SVGs for all on-ramp kana/kanji, not just the vowels; (4) the one-time `SrsCard → LearnItem` backfill for existing users (spec default: backfill if legacy data present) — add as a `KnowledgeBoot`-style migration if real user data exists.
- **Verify before coding each UI task:** confirm the exact current constructor signatures of `ReviewScreen`, the four `_*Exercise` widgets, and `SettingsScreen` in the live files; this plan quotes them from the reference dossier but the executor should match whatever is on disk.
