# App-Wiring W1 — concept → German meaning (runtime source) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the app-wide "meaning is English" gap — the first of three app-wiring slices for the now-code-complete story engine. Today the only runtime meaning a `concept` exposes is its **English** `glossKey` (`'rain'`, `'sorry'`, …), shown as-is by the live `ReviewScreen`/`ExerciseLoader` and by the café's `CafeTurnContent`. This builds a real **concept → German meaning** runtime source (a small gloss map + a lookup helper with a safe fallback) and routes both consumers through it, so the review feed and the café show German (`'Regen'`, `'Entschuldigung'`, …) while any concept without a German gloss still falls back to its English `glossKey`. No Drift schema change — the German glosses live in a plain, testable Dart map, decoupled from the language-neutral `concepts` table (invariant I4: the concept stays language-neutral; German is a localization on top).

**Architecture:** One new file `lib/core/i18n/concept_meaning.dart` — a `const Map<String,String> conceptGlossDe` (concept id → German) plus `String meaningForConcept(String conceptId, {required String fallback})` returning the German gloss when present, else `fallback` (the caller passes the concept's English `glossKey`). Two consumers change one/four call sites each to route through it: `ExerciseLoader._loadLexeme` (the shipped review feed) and `CafeTurnContent.forItem` (the café). Nothing else moves.

**Tech Stack:** Dart 3.11 / Flutter, `flutter_test`. No DB migration, no new packages.

## Global Constraints

- Base branch: `origin/main` (`be0bcf8`) — the full P0–P9 story engine.
- **No schema change.** The `Concepts` table keeps only `glossKey` (English, language-neutral per I4). German meanings are a data map in `lib/core/i18n/concept_meaning.dart`, not a new column — avoids a risky Drift migration for what is content localization.
- **Fallback is mandatory.** `meaningForConcept(id, fallback: glossKey)` returns the German gloss if the id is in the map, else the passed `fallback` (the English `glossKey`). A concept with no German entry must degrade to exactly today's behavior (the English key), never to null/empty/crash.
- **German glosses for the 13 seeded concepts** (`lib/packs/ja/ja_seed.dart`), matching the P4a dictionary fixture where they overlap: `concept_dog`→'Hund', `concept_cat`→'Katze', `concept_water`→'Wasser', `concept_eat`→'essen', `concept_what`→'was', `concept_sorry`→'Entschuldigung', `concept_rain`→'Regen', `concept_umbrella`→'Schirm', `concept_this`→'das hier', `concept_broken`→'kaputt', `concept_yes`→'ja', `concept_here_you_go`→'bitte', `concept_thanks`→'danke'. Preserve German characters exactly (ä/ö/ü/ß — none needed here, but do not ASCII-fold if you add more).
- **Both consumers route through the helper.** `ExerciseLoader._loadLexeme` uses `concept.glossKey` at four sites (EncounterContent.meaning, RecognitionContent.answer, and ProductionInputContent.prompt for `productionInput` AND `writeTrace`); all four become `meaningForConcept(concept.id, fallback: concept.glossKey)`. `CafeTurnContent.forItem`'s `final meaning = concept.glossKey;` becomes `final meaning = meaningForConcept(concept.id, fallback: concept.glossKey);`.
- **Existing tests that assert the English meaning must be updated to German** (e.g. the café's `CafeTurnContent` test asserts `'rain'`; after wiring it is `'Regen'`). This is a legitimate consequence of the change — update those assertions in the same task, do not weaken them.
- Run tests with `flutter test <path>`. The full suite has 8 pre-existing `test/mining_packs/ja/` native-tokenizer failures, unrelated — "green" means those 8 and no others.

---

### Task 1: the concept → German meaning source

**Files:**
- Create: `lib/core/i18n/concept_meaning.dart`
- Test: `test/core/i18n/concept_meaning_test.dart`

**Interfaces:** `const Map<String, String> conceptGlossDe`; `String meaningForConcept(String conceptId, {required String fallback})`.

- [ ] **Step 1: Write the failing test**

Create `test/core/i18n/concept_meaning_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/i18n/concept_meaning.dart';

void main() {
  test('returns the German gloss for a known concept', () {
    expect(meaningForConcept('concept_rain', fallback: 'rain'), 'Regen');
    expect(meaningForConcept('concept_sorry', fallback: 'sorry'),
        'Entschuldigung');
    expect(meaningForConcept('concept_dog', fallback: 'dog'), 'Hund');
  });

  test('falls back to the passed English glossKey for an unknown concept', () {
    expect(meaningForConcept('concept_unknown', fallback: 'whatever'),
        'whatever');
  });

  test('covers all 13 seeded concepts', () {
    const seeded = [
      'concept_dog', 'concept_cat', 'concept_water', 'concept_eat',
      'concept_what', 'concept_sorry', 'concept_rain', 'concept_umbrella',
      'concept_this', 'concept_broken', 'concept_yes', 'concept_here_you_go',
      'concept_thanks',
    ];
    for (final id in seeded) {
      expect(conceptGlossDe.containsKey(id), isTrue,
          reason: '$id has no German gloss');
      expect(conceptGlossDe[id]!, isNotEmpty);
    }
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/i18n/concept_meaning_test.dart`
Expected: FAIL — `concept_meaning.dart` does not exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/core/i18n/concept_meaning.dart`:

```dart
/// German meanings for concepts, keyed by concept id — the runtime source of
/// the meaning shown to the (German-speaking) learner. The `concepts` table
/// itself keeps only the language-neutral English `glossKey` (invariant I4);
/// this map is the localization on top. Concepts absent here fall back to
/// their English `glossKey` via [meaningForConcept], so partial coverage is
/// safe (exactly today's behavior for anything not yet translated).
const Map<String, String> conceptGlossDe = {
  'concept_dog': 'Hund',
  'concept_cat': 'Katze',
  'concept_water': 'Wasser',
  'concept_eat': 'essen',
  'concept_what': 'was',
  'concept_sorry': 'Entschuldigung',
  'concept_rain': 'Regen',
  'concept_umbrella': 'Schirm',
  'concept_this': 'das hier',
  'concept_broken': 'kaputt',
  'concept_yes': 'ja',
  'concept_here_you_go': 'bitte',
  'concept_thanks': 'danke',
};

/// The meaning to show for [conceptId]: the German gloss if known, else
/// [fallback] (the caller passes the concept's English `glossKey`).
String meaningForConcept(String conceptId, {required String fallback}) =>
    conceptGlossDe[conceptId] ?? fallback;
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/core/i18n/concept_meaning_test.dart`
Expected: PASS (all 3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/i18n/concept_meaning.dart test/core/i18n/concept_meaning_test.dart
git commit -m "feat(i18n): add concept → German meaning source with English fallback (W1)"
```

---

### Task 2: route ExerciseLoader + CafeTurnContent through the German meaning

**Files:**
- Modify: `lib/core/ladder/exercise_loader.dart`
- Modify: `lib/features/cafe/cafe_turn.dart`
- Modify: existing tests that asserted the English meaning (at least `test/features/cafe/cafe_turn_test.dart`; and any `ExerciseLoader`/review test that asserts a `glossKey` value — find them)

**Interfaces:** no signature changes. Both consumers now return the German meaning (with English fallback).

- [ ] **Step 1: Update the failing tests first (they now expect German)**

In `test/features/cafe/cafe_turn_test.dart`, the `CafeTurnContent.forItem` group seeds `concept_rain`/`lex_ja_ame` and asserts the English meaning. Change those expectations to German:
- rung-3 (production) test: `expect(content.promptText, 'rain')` → `'Regen'`; `expect(content.meaning, 'rain')` → `'Regen'`.
- rung-1 (recognition) test: `expect(content.expectedAnswer, 'rain')` → `'Regen'`.
- rung-4 (comprehension) test: `expect(content.expectedAnswer, 'rain')` → `'Regen'`.
(The rung-5 free-production test's `expectedAnswer` is `''` — unchanged.)

Then GREP for other tests asserting an English gloss value that will now be German, and fix them the same way:
- Run `grep -rn "'rain'\|'sorry'\|glossKey" test/` and inspect the café/ladder/review tests. Update any assertion that reads the *displayed meaning* of a seeded concept (e.g. a `RecognitionContent.answer`/`ProductionInputContent.prompt`/`EncounterContent...meaning` expected to equal `'rain'`/`'dog'`/etc.) to the German gloss. Do NOT change assertions about the `glossKey` column value itself (that stays English) or about `writtenForm`/`reading`.
- Also check `test/features/cafe/cafe_turn_screen_test.dart`: its rung-3 test enters `'あめ'` (the word) and asserts the persisted grade — the displayed *prompt* is now `'Regen'` but the test doesn't assert the prompt text, so it likely needs no change; confirm by running it.

Run the touched test files → they should FAIL now (production code still returns English).

- [ ] **Step 2: Write the implementation**

In `lib/features/cafe/cafe_turn.dart` — add the import and route the meaning:
```dart
import '../../core/i18n/concept_meaning.dart';
```
Change:
```dart
    final meaning = concept.glossKey;
```
to:
```dart
    final meaning = meaningForConcept(concept.id, fallback: concept.glossKey);
```
(Update the `meaning` field's doc comment if it still says "the English key".)

In `lib/core/ladder/exercise_loader.dart` — add the import and replace all four `concept.glossKey` reads in `_loadLexeme` with `meaningForConcept(concept.id, fallback: concept.glossKey)`:
```dart
import '../i18n/concept_meaning.dart';
```
- `EncounterContent(... meaning: concept.glossKey ...)` → `meaning: meaningForConcept(concept.id, fallback: concept.glossKey)`
- `RecognitionContent(displayForm: ..., answer: concept.glossKey)` → `answer: meaningForConcept(concept.id, fallback: concept.glossKey)`
- `ProductionInputContent(prompt: concept.glossKey, ...)` (the `productionInput` arm) → `prompt: meaningForConcept(concept.id, fallback: concept.glossKey)`
- `ProductionInputContent(prompt: concept.glossKey, ...)` (the `writeTrace` arm) → same.
Leave `_loadCharacter`/`_loadGrammar` unchanged (this slice is concept/lexeme meaning; characters use their own `meaning` column, grammar its own).

- [ ] **Step 3: Run the touched tests, then the affected suites**

Run: `flutter test test/features/cafe/ test/core/ladder/ test/core/i18n/`
Expected: PASS (café turns now show German; the updated assertions match; exercise-loader tests updated).
Then run any review/exercise test directory the grep flagged. Fix any remaining English-meaning assertion the same way.

- [ ] **Step 4: Run the full suite**

Run: `flutter test`
Expected: green apart from the 8 pre-existing `mining_packs/ja` failures. If any other test asserts an English gloss that is now German, update it (reflect the real German meaning; never weaken). This is the backstop that finds every consumer of the changed meaning.

- [ ] **Step 5: Commit**

```bash
git add lib/core/ladder/exercise_loader.dart lib/features/cafe/cafe_turn.dart test/
git commit -m "feat(cafe,review): show German meanings via meaningForConcept, English fallback (W1)"
```
