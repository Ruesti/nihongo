# Story-Engine P5a — Seed Folge 01 vocabulary into the JA pack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the 8 vocabulary words of Folge 01 "Regen" real rows in the JA language pack — a `Concept` + `Lexeme` per word, with lexeme ids matching the `itemId`s already used by the P1 episode fixture and the P4a dictionary fixture (`lex_ja_sumimasen`, `lex_ja_ame`, `lex_ja_kasa`, `lex_ja_kore`, `lex_ja_kowareta`, `lex_ja_hai`, `lex_ja_douzo`, `lex_ja_arigatou`). This is the first of two slices of the brief's phase P5 ("Auslauf + SRS-Übergabe", `docs/story/BRIEF_STORY_ENGINE.md` §5): P5a lays down the pack data the episode's budgeted items refer to, so that the second slice (P5b, not part of this plan) can hand those items to the real SRS ladder at episode completion (`LadderReview.introduce()` by lexeme id) and the dictionary can eventually resolve real meanings. P5a is provably correct on its own — it seeds data and asserts it's present; it wires nothing into the reader.

**Architecture:** Purely additive data in the existing `seedJaPack` (`lib/packs/ja/ja_seed.dart`), the one place the JA language pack's content lives — a data-only pack per CLAUDE.md §4 ("packs/ … rein datengetrieben, KEINE Logik"). The 5 existing Phase-0 demo words (dog/cat/water/eat/what) and the 5 vowel characters stay untouched and load-bearing for the wider SRS/games/assets test suite; the 8 Folge words are appended alongside them through the same `conceptRows`/`lexemeRows` loops, so no new code path is introduced. `glossKey` stays a language-neutral English lookup key into the shared concept pool (CLAUDE.md §3, invariant I4 "Assets an conceptId") — the German meanings shown to the reader already live in the P4a dictionary fixture (`folge01DictionaryEntries[].meaning`), not here.

**Tech Stack:** Dart 3.11 / Flutter, Drift/SQLite (in-memory `LearningDb.forTesting()`), `flutter_test`. No new packages.

## Global Constraints

- Base branch: `origin/main` — includes P1–P4a (the episode schema + Folge 01 episode fixture, the reader, the token tap, and the P4a dictionary object + `folge01DictionaryEntries`). This plan is independent of the still-open P4b PR (#32); it touches only `lib/packs/ja/ja_seed.dart` and its tests, which no reader/dictionary PR modifies.
- Lexeme ids **must** be exactly `lex_ja_sumimasen`, `lex_ja_ame`, `lex_ja_kasa`, `lex_ja_kore`, `lex_ja_kowareta`, `lex_ja_hai`, `lex_ja_douzo`, `lex_ja_arigatou` — these are the `itemId`s the P1 episode fixture already tags on its bubbles and the `id`s the P4a dictionary fixture already uses. A mismatch would silently break the future P5b handoff (which introduces items by these ids) and the dictionary's known-state lookup.
- `glossKey` values are language-neutral English keys (matching the existing `'dog'/'cat'/'water'/'eat'/'what'`), **not** German display strings. The German meanings are the dictionary fixture's job, already done in P4a.
- `writtenForm` and `reading` are both the word's hiragana form (Folge 01 is deliberately hiragana-only, per the episode fixture and dictionary headwords). This differs from the demo words, which have kanji `writtenForm` + kana `reading` — correct here because these words are written in kana in the pilot.
- `cefrBand` is `'A1'` for all 8 (matching the demo words and the episode's beginner level).
- **Cross-file consequence to handle in this task:** `test/core/db/learning_db_test.dart` asserts the JA pack has *exactly* 5 concepts (line 49), *exactly* 5 lexemes (line 55), and *exactly* 5 concepts after a double-seed (line 74). Appending 8 words makes those 13. These three assertions must be updated as part of this task, or the suite goes red. Every other `seedJaPack` consumer (games, assets, progress, conversation, sentences, review-loop, phase5) was checked and is decoupled from the pack's lexeme/concept *count* — they read `learn_items`, sentences, assets, or game-specs, none of which `seedJaPack` populates from the lexeme list. The full-suite run in Step 5 is the backstop that proves nothing else was missed.
- Run tests with `flutter test <path>` from the repo root; the full suite with `flutter test`.

---

### Task 1: Seed the 8 Folge 01 words + prove they're present

**Files:**
- Modify: `lib/packs/ja/ja_seed.dart` (append 8 concept + 8 lexeme tuples)
- Modify: `test/core/db/learning_db_test.dart` (update 3 exact-count assertions from 5 → 13)
- Create: `test/packs/ja/ja_seed_test.dart` (new — the JA pack is currently the only pack without a dedicated seed test)

**Interfaces:**
- No new symbols. `seedJaPack(LearningDb db)` keeps its signature; it just seeds 8 more `Concepts` and `Lexemes` rows. Consumers see additional rows with the ids listed above.

- [ ] **Step 1: Write the new failing test**

Create `test/packs/ja/ja_seed_test.dart` (mirrors the established `test/packs/es/es_seed_test.dart` convention — `setUp` seeds, `tearDown` closes, grouped assertions, an idempotency group):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

/// The 8 Folge 01 "Regen" words, keyed by the lexeme id the story fixtures
/// (P1 episode budget, P4a dictionary) already use, with the hiragana form
/// the pilot renders.
const _folge01 = <String, String>{
  'lex_ja_sumimasen': 'すみません',
  'lex_ja_ame': 'あめ',
  'lex_ja_kasa': 'かさ',
  'lex_ja_kore': 'これ',
  'lex_ja_kowareta': 'こわれた',
  'lex_ja_hai': 'はい',
  'lex_ja_douzo': 'どうぞ',
  'lex_ja_arigatou': 'ありがとう',
};

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedJaPack(db);
  });

  tearDown(() => db.close());

  group('JA seed — Folge 01 vocabulary', () {
    test('every Folge 01 word is a lexeme under lang_ja with its hiragana form',
        () async {
      final lexemes = await db.select(db.lexemes).get();
      final byId = {for (final l in lexemes) l.id: l};
      for (final entry in _folge01.entries) {
        final lex = byId[entry.key];
        expect(lex, isNotNull, reason: '${entry.key} missing from JA pack');
        expect(lex!.languageId, 'lang_ja');
        expect(lex.writtenForm, entry.value);
        expect(lex.reading, entry.value);
      }
    });

    test('every Folge 01 word has a concept with a neutral English glossKey',
        () async {
      final lexemes = await db.select(db.lexemes).get();
      final concepts = await db.select(db.concepts).get();
      final conceptById = {for (final c in concepts) c.id: c};
      for (final id in _folge01.keys) {
        final lex = lexemes.firstWhere((l) => l.id == id);
        final concept = conceptById[lex.conceptId];
        expect(concept, isNotNull,
            reason: '$id points at a concept that was not seeded');
        expect(concept!.glossKey, isNotEmpty);
        // glossKey is a lookup key, never a German display string — the
        // reader-facing meanings live in the P4a dictionary fixture.
        expect(RegExp(r'^[a-z_]+$').hasMatch(concept.glossKey), isTrue,
            reason: '${concept.glossKey} is not a lowercase English key');
      }
    });
  });

  group('JA seed — Folge 01 idempotency', () {
    test('re-seeding does not duplicate the Folge 01 words', () async {
      await seedJaPack(db);
      final lexemes = await db.select(db.lexemes).get();
      for (final id in _folge01.keys) {
        expect(lexemes.where((l) => l.id == id), hasLength(1),
            reason: '$id was duplicated on re-seed');
      }
    });
  });
}
```

- [ ] **Step 2: Run the new test to verify it fails**

Run: `flutter test test/packs/ja/ja_seed_test.dart`
Expected: FAIL — the 8 lexemes/concepts don't exist yet (`isNotNull` / `firstWhere` failures).

- [ ] **Step 3: Write the implementation**

In `lib/packs/ja/ja_seed.dart`, append the 8 Folge words to the two existing literal lists. The demo rows and the loops stay exactly as they are — only the list contents grow.

Append to `conceptRows` (after the `('concept_what', 'what', 'pronoun', 'none'),` line, before the closing `];`):

```dart
      // Folge 01 "Regen" vocabulary (docs/story/PILOT_01_REGEN.md).
      // glossKey stays a language-neutral English key (I4); the German
      // meanings shown to the reader live in the P4a dictionary fixture.
      ('concept_sorry', 'sorry', 'interjection', 'none'),
      ('concept_rain', 'rain', 'noun', 'image'),
      ('concept_umbrella', 'umbrella', 'noun', 'image'),
      ('concept_this', 'this', 'pronoun', 'none'),
      ('concept_broken', 'broken', 'verb', 'image'),
      ('concept_yes', 'yes', 'interjection', 'none'),
      ('concept_here_you_go', 'here_you_go', 'interjection', 'none'),
      ('concept_thanks', 'thanks', 'interjection', 'none'),
```

Append to `lexemeRows` (after the `('lex_ja_what', 'concept_what', '何', 'なに'),` line, before the closing `];`):

```dart
      // Folge 01 "Regen": hiragana form is both writtenForm and reading;
      // ids match the P1 episode budget and the P4a dictionary fixture.
      ('lex_ja_sumimasen', 'concept_sorry', 'すみません', 'すみません'),
      ('lex_ja_ame', 'concept_rain', 'あめ', 'あめ'),
      ('lex_ja_kasa', 'concept_umbrella', 'かさ', 'かさ'),
      ('lex_ja_kore', 'concept_this', 'これ', 'これ'),
      ('lex_ja_kowareta', 'concept_broken', 'こわれた', 'こわれた'),
      ('lex_ja_hai', 'concept_yes', 'はい', 'はい'),
      ('lex_ja_douzo', 'concept_here_you_go', 'どうぞ', 'どうぞ'),
      ('lex_ja_arigatou', 'concept_thanks', 'ありがとう', 'ありがとう'),
```

Then update `test/core/db/learning_db_test.dart` so its exact-count guards reflect the now-13 concepts/lexemes (and document the added content instead of just bumping a magic number):

- Line ~46–50, the `'creates 5 concepts'` test: rename to `'creates 13 concepts (5 demo + 8 Folge 01)'` and change `expect(rows.length, 5);` → `expect(rows.length, 13);`.
- Line ~52–58, the `'creates 5 lexemes with correct written forms'` test: rename to `'creates 13 lexemes (5 demo + 8 Folge 01)'`, change `expect(rows.length, 5);` → `expect(rows.length, 13);`, and extend the existing `containsAll` set to also require the Folge hiragana forms:
  ```dart
  expect(forms, containsAll({'犬', '猫', '水', '食べる', '何'}));
  expect(forms, containsAll(
      {'すみません', 'あめ', 'かさ', 'これ', 'こわれた', 'はい', 'どうぞ', 'ありがとう'}));
  ```
- Line ~68–75, the `'seeding twice is idempotent'` test: change `expect(concepts.length, 5);` → `expect(concepts.length, 13);`.

Leave the `'creates 5 hiragana vowel characters'` test unchanged — no characters are added.

- [ ] **Step 4: Run the new test and the touched existing test**

Run: `flutter test test/packs/ja/ja_seed_test.dart test/core/db/learning_db_test.dart`
Expected: PASS (new file's 3 tests green; `learning_db_test`'s updated counts green).

- [ ] **Step 5: Run the full suite**

Run: `flutter test`
Expected: PASS across the whole repo — this is the backstop proving no other `seedJaPack` consumer was silently coupled to the pack's concept/lexeme count. If anything else is red, fix its assertion the same honest way (reflect the real seeded content), do not weaken it to skip.

- [ ] **Step 6: Commit**

```bash
git add lib/packs/ja/ja_seed.dart test/packs/ja/ja_seed_test.dart test/core/db/learning_db_test.dart
git commit -m "feat(story): seed Folge 01 vocabulary into the JA pack (P5a)"
```
