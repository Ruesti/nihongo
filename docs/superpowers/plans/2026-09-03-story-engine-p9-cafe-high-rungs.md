# Story-Engine P9 — Café turns rung 4–5 (Vielredner + Gleichaltrige) + free tap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The final phase (brief §5, P9) — the two higher-rung café guests and the free-tap rule, completing the roadmap P0–P9. The **Vielredner** (rung 4) delivers Comprehensible Input: a rambly German monologue that repeats the due Japanese word in context, then asks whether you got its core (a comprehension check). The **Gleichaltrige** (rung 5) is open conversation — free production, **no right/wrong** (§4.2). Meaning stays freely tappable as a hint (§4.4), and the café **provably never surfaces an item that wasn't introduced by a read episode** (INV-9). This extends P8's café-turn machinery; it does not rebuild it.

**Architecture:** Extend the four P8 files under `lib/features/cafe/`, plus one new content file and one new structural test:
- `cafe_turn.dart` — add two exercise kinds (`comprehension` rung 4, `freeProduction` rung 5), extend `kindForRung`, add a `freeProduced` outcome (grades **hard** — the user's choice: a free turn counts as a held repetition, no interval growth), and extend `CafeTurnContent.forItem` for the new kinds.
- `cafe_prompts.dart` (new) — the Vielredner's multi-line monologue templates and the Gleichaltrige's conversation openers, each rotating, each slotting the word (template-based per PHASE_0 §8, so they scale to any vocabulary and need no German meanings — the monologue builds context around the Japanese word, the meaning only appears on the comprehension reveal).
- `cafe_guest_script.dart` — replace the P9 placeholders: the Vielredner reacts to correct/wrong/hinted (chatty); the Gleichaltrige reacts to `freeProduced` (warm, never judging).
- `cafe_turn_screen.dart` — render the comprehension turn (monologue + reveal + gewusst/nicht) and the free-production turn (opener + free field + submit → always hard).
- A structural INV-9 test proving the café's only item source is `getDueItems`, which by construction returns only introduced items.

**Decisions taken with the user:** (1) **Rung 5 (Gleichaltrige) free production grades `hard`** — seen and held, no interval growth (there is no right/wrong to reward). (2) **Rich Vielredner monologue content** — realised as several multi-line, in-character German templates that slot the Japanese word and build context, rotating per turn (the "rich" is in the writing + variety; it stays template-based, so it needs no German meaning table).

**Tech Stack:** Dart 3.11 / Flutter, Drift/SQLite (`LearningDb.forTesting()`), `flutter_test`. Reuses P8's `CafeTurnScreen`/`LadderReview.submit`/`CafeGuest`/`guestForRung`. No new packages.

## Global Constraints

- Base branch: `origin/main` (`482607a`) — includes all of P0–P8 (P8's café turns for Wirtin + Schulkind).
- **The occupancy already routes rung 4/5.** P7's `guestForRung` maps rung 4 → Vielredner, rung 5 → Gleichaltrige, and P8's `CafeScreen` already renders every present guest and opens `CafeTurnScreen` on tap. So P9 needs NO new `CafeScreen` wiring — it only teaches the turn model + screen to handle the two new kinds. Do not touch `cafe_screen.dart`/`cafe_occupancy.dart`.
- **Rung 5 grades `hard`, always.** A free-production turn has no correctness check; it submits `ReviewResult.hard` (via a new `CafeOutcome.freeProduced`) regardless of what the learner typed. This is the user's decision ("gesehen, gehalten"). Do NOT grade it `good` or derive correctness.
- **Rung 4 is a comprehension check.** After the monologue, the learner self-reports gewusst/nicht (graded correct → good / wrong → again, like recognition). Revealing the meaning to check is the normal flow (as with recognition), not a dodge; there is no separate dodge-hint on a comprehension turn.
- **Free tap / §4.4 / INV-9.** Meaning-tapping remains the P8 `Bedeutung zeigen` hint on the typed (rung 2–3) turns; P9 adds no new free-tap surface beyond the comprehension reveal. INV-9's guarantee is **structural**: the café's only item source is `db.getDueItems`, which returns `learn_items` rows, every one of which was created by `introduce`/`markEncountered` (i.e. read/encountered). A P9 test proves an item that has **no** `learn_item` (never introduced) appears in **no** café turn for any guest — the "no path to an unread item" acceptance the brief says needs more than a unit test.
- **Meaning = the English `glossKey`** (unchanged from P8; German localization stays deferred). The Vielredner monologue never states the German meaning — it builds context around the Japanese word; the glossKey appears only on the comprehension reveal.
- **The `CafeOutcome` enum grows** (adds `freeProduced`). This ripples: P8's `cafe_guest_script_test.dart` iterates `CafeOutcome.values` for the Wirtin/Schulkind, who have no `freeProduced` lines. Task 2 updates that test to iterate each guest's **own** supported outcomes (`scriptFor(guest).lines.keys`) so the enum addition doesn't break it. Do not give the Wirtin/Schulkind `freeProduced` lines.
- INV-8/INV-10 continue to hold: the turns only read `getDueItems` and `submit` existing items; no new item, no café score.
- New widget keys: `cafe-turn-monologue`, `cafe-turn-free-input`, `cafe-turn-free-submit`. Reuse P8's keys otherwise (`cafe-turn-prompt`, `cafe-turn-reveal`, `cafe-turn-known`, `cafe-turn-unknown`, `cafe-turn-followup`, `cafe-turn-next`, `cafe-turn-done`, `cafe-turn-screen`).
- Run tests with `flutter test <path>`. The full suite has 8 pre-existing `test/mining_packs/ja/` native-tokenizer failures, unrelated — "green" means those 8 and no others.

---

### Task 1: extend `cafe_turn.dart` — comprehension + freeProduction

**Files:**
- Modify: `lib/features/cafe/cafe_turn.dart`
- Modify: `test/features/cafe/cafe_turn_test.dart` (add cases; keep existing)

**Interfaces:** `CafeExerciseKind` gains `comprehension`, `freeProduction`. `CafeOutcome` gains `freeProduced`. `kindForRung`: 4→comprehension, 5→freeProduction. `resultForOutcome(freeProduced)` = `ReviewResult.hard`. `CafeTurnContent.forItem` supports the new kinds.

- [ ] **Step 1: Add failing tests** to `test/features/cafe/cafe_turn_test.dart` (append inside the existing groups / add new `test`s):

```dart
  test('freeProduced grades hard (rung-5 free production is held, not graded)',
      () {
    expect(resultForOutcome(CafeOutcome.freeProduced), ReviewResult.hard);
  });

  test('kindForRung: rung 4 comprehension, rung 5 free production', () {
    expect(kindForRung(4), CafeExerciseKind.comprehension);
    expect(kindForRung(5), CafeExerciseKind.freeProduction);
  });
```

And inside the `CafeTurnContent.forItem` group (which already seeds `concept_rain`/`lex_ja_ame`):

```dart
    test('rung 4 (comprehension): the word carries, meaning is the check',
        () async {
      final content = await CafeTurnContent.forItem(db, await due(4));
      expect(content!.kind, CafeExerciseKind.comprehension);
      expect(content.writtenForm, 'あめ');
      expect(content.expectedAnswer, 'rain'); // the comprehension reveal
    });

    test('rung 5 (free production): no expected answer', () async {
      final content = await CafeTurnContent.forItem(db, await due(5));
      expect(content!.kind, CafeExerciseKind.freeProduction);
      expect(content.writtenForm, 'あめ');
      expect(content.expectedAnswer, '');
    });
```

Run `flutter test test/features/cafe/cafe_turn_test.dart` → FAIL (new enum values / mappings don't exist).

- [ ] **Step 2: Implement** — edit `lib/features/cafe/cafe_turn.dart`:

(a) Extend the outcome enum + its result map:
```dart
enum CafeOutcome { correct, wrong, hinted, freeProduced }
```
```dart
ReviewResult resultForOutcome(CafeOutcome outcome) => switch (outcome) {
      CafeOutcome.correct => ReviewResult.good,
      CafeOutcome.wrong => ReviewResult.again,
      CafeOutcome.hinted => ReviewResult.hard,
      CafeOutcome.freeProduced => ReviewResult.hard,
    };
```
(`outcomeFor` is unchanged — it only ever produces correct/wrong/hinted for the graded kinds; `freeProduced` is submitted directly by the screen.)

(b) Extend the kind enum + mapping:
```dart
enum CafeExerciseKind {
  recognition,
  readingInput,
  productionInput,
  comprehension,
  freeProduction,
}

CafeExerciseKind kindForRung(int rung) {
  if (rung <= 1) return CafeExerciseKind.recognition;
  if (rung == 2) return CafeExerciseKind.readingInput;
  if (rung == 3) return CafeExerciseKind.productionInput;
  if (rung == 4) return CafeExerciseKind.comprehension;
  return CafeExerciseKind.freeProduction; // rung 5 (and any higher)
}
```

(c) Extend `forItem`'s prompt/answer switch (the screen wraps the word in a monologue/opener for the new kinds, so here the word "carries"):
```dart
    final (promptText, expectedAnswer) = switch (kind) {
      CafeExerciseKind.recognition => (lex.writtenForm, meaning),
      CafeExerciseKind.readingInput => (lex.writtenForm, lex.reading),
      CafeExerciseKind.productionInput => (meaning, lex.writtenForm),
      CafeExerciseKind.comprehension => (lex.writtenForm, meaning),
      CafeExerciseKind.freeProduction => (lex.writtenForm, ''),
    };
```

- [ ] **Step 3: Run** `flutter test test/features/cafe/cafe_turn_test.dart` → PASS (existing + new).

- [ ] **Step 4: Commit**
```bash
git add lib/features/cafe/cafe_turn.dart test/features/cafe/cafe_turn_test.dart
git commit -m "feat(cafe): add comprehension (rung 4) + freeProduction (rung 5) turn kinds (P9)"
```

---

### Task 2: `cafe_prompts.dart` + Vielredner/Gleichaltrige scripts

**Files:**
- Create: `lib/features/cafe/cafe_prompts.dart`
- Modify: `lib/features/cafe/cafe_guest_script.dart` (real Vielredner + Gleichaltrige)
- Test: `test/features/cafe/cafe_prompts_test.dart`
- Modify: `test/features/cafe/cafe_guest_script_test.dart` (per-guest outcomes — see Global Constraints)

**Interfaces:** `String vielrednerMonologue(String word, int index)`; `String gleichaltrigeOpener(String word, int index)` (both rotating, both slot `word`). `scriptFor` returns real Vielredner + Gleichaltrige scripts.

- [ ] **Step 1: Write failing tests**

Create `test/features/cafe/cafe_prompts_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_prompts.dart';

void main() {
  test('the Vielredner monologue slots the word and rotates', () {
    final a = vielrednerMonologue('あめ', 0);
    final b = vielrednerMonologue('あめ', 1);
    expect(a, contains('あめ'));
    expect(b, contains('あめ'));
    expect(a, isNot(b)); // ≥2 distinct templates
    // Multi-line "rich" monologue: more than a one-liner.
    expect(a.trim().length, greaterThan(40));
    // Wraps around.
    expect(vielrednerMonologue('あめ', 3), isNotEmpty);
  });

  test('the Gleichaltrige opener slots the word and rotates', () {
    final a = gleichaltrigeOpener('あめ', 0);
    final b = gleichaltrigeOpener('あめ', 1);
    expect(a, contains('あめ'));
    expect(b, contains('あめ'));
    expect(a, isNot(b));
  });
}
```

Modify `test/features/cafe/cafe_guest_script_test.dart`: change the "≥3 lines per outcome" test so it iterates each guest's OWN outcomes (not all `CafeOutcome.values`), and extend it to all four guests:

```dart
  test('each guest has ≥3 distinct lines for every outcome it reacts to', () {
    for (final guest in CafeGuest.values) {
      final script = scriptFor(guest);
      for (final outcome in script.lines.keys) {
        final lines = {
          script.followUp(outcome, 0),
          script.followUp(outcome, 1),
          script.followUp(outcome, 2),
        };
        expect(lines.length, greaterThanOrEqualTo(3),
            reason: '$guest/$outcome has fewer than 3 lines');
      }
    }
  });

  test('the Gleichaltrige reacts to free production; the Vielredner to '
      'correct/wrong/hinted', () {
    expect(scriptFor(CafeGuest.gleichaltrige).lines.keys,
        contains(CafeOutcome.freeProduced));
    expect(scriptFor(CafeGuest.vielredner).lines.keys,
        containsAll([CafeOutcome.correct, CafeOutcome.wrong, CafeOutcome.hinted]));
  });
```
(Keep the existing "rotates deterministically" and "distinct content" tests; adjust the distinct-content test only if it referenced a now-changed placeholder.)

Run `flutter test test/features/cafe/cafe_prompts_test.dart test/features/cafe/cafe_guest_script_test.dart` → FAIL.

- [ ] **Step 2: Implement**

Create `lib/features/cafe/cafe_prompts.dart`:

```dart
/// Template-based café prompts (PHASE_0 §8): the Vielredner's rambling
/// Comprehensible-Input monologues and the Gleichaltrige's open conversation
/// starters. Each rotates by turn index and slots the due word. The German
/// scaffolding builds context AROUND the Japanese word — it never states the
/// meaning, so these need no German meaning table (the meaning surfaces only
/// on the comprehension reveal).
String vielrednerMonologue(String word, int index) {
  final templates = [
    'Ach, weißt du... neulich ging es die ganze Zeit um $word. '
        '$word hier, $word da — man kommt gar nicht drumherum. '
        'Und jetzt sag mir: $word — was war das noch gleich?',
    'Also, ich muss dir was erzählen. Gestern, mitten am Tag: $word. '
        'Ich sag dir, $word, überall $word. Kaum zu glauben. '
        'Du weißt schon, was $word bedeutet, oder?',
    'Kennst du das? Da sitzt man, und plötzlich — $word. '
        'Dann noch mal $word. Das halbe Viertel redet von nichts anderem. '
        'Aber $word, das hast du doch, hm?',
  ];
  return templates[index % templates.length];
}

String gleichaltrigeOpener(String word, int index) {
  final openers = [
    'Sag mal, $word — was fällt dir dazu ein? Einfach drauflos.',
    'Erzähl mir irgendwas mit $word. Muss nicht perfekt sein.',
    '$word. Los, ein Satz, egal welcher — ich hör zu.',
  ];
  return openers[index % openers.length];
}
```

Edit `lib/features/cafe/cafe_guest_script.dart` — replace the two placeholder mappings with real scripts:

```dart
/// The Vielredner (rung 4): erzählt viel, prüft freundlich, ob der Kern ankam.
const _vielredner = CafeGuestScript({
  CafeOutcome.correct: [
    'Ha, genau! Wusste ich, dass du es hast.',
    'Siehst du — du verstehst mehr, als du denkst.',
    'Genau das, ja. Bei so viel Gerede muss man ja was mitnehmen.',
  ],
  CafeOutcome.wrong: [
    'Kein Ding, das war auch viel Gerede. Nächstes.',
    'Ich rede halt zu viel — das hört sich noch ein.',
    'Macht nichts, das kriegst du beim nächsten Mal.',
  ],
  CafeOutcome.hinted: [
    'Nachgeschaut, auch gut — Hauptsache, es bleibt hängen.',
    'Klar, schau nach. Bei mir verliert man schon mal den Faden.',
    'Passt, so lernt man es auch.',
  ],
});

/// The Gleichaltrige (rung 5): offenes Gespräch, kein richtig/falsch —
/// reagiert warm auf alles, was du produzierst.
const _gleichaltrige = CafeGuestScript({
  CafeOutcome.freeProduced: [
    'Schön gesagt. Weiter geht es.',
    'Ja, so ungefähr würde ich es auch sagen.',
    'Gefällt mir. Nächstes?',
    'Cool, du traust dich was.',
  ],
});
```
And change `scriptFor`:
```dart
CafeGuestScript scriptFor(CafeGuest guest) => switch (guest) {
      CafeGuest.wirtin => _wirtin,
      CafeGuest.schulkind => _schulkind,
      CafeGuest.vielredner => _vielredner,
      CafeGuest.gleichaltrige => _gleichaltrige,
    };
```

- [ ] **Step 3: Run** `flutter test test/features/cafe/cafe_prompts_test.dart test/features/cafe/cafe_guest_script_test.dart` → PASS.

- [ ] **Step 4: Commit**
```bash
git add lib/features/cafe/cafe_prompts.dart lib/features/cafe/cafe_guest_script.dart test/features/cafe/cafe_prompts_test.dart test/features/cafe/cafe_guest_script_test.dart
git commit -m "feat(cafe): add Vielredner monologues + Gleichaltrige openers and their scripts (P9)"
```

---

### Task 3: `cafe_turn_screen.dart` — render comprehension + free production

**Files:**
- Modify: `lib/features/cafe/cafe_turn_screen.dart`
- Modify: `test/features/cafe/cafe_turn_screen_test.dart` (add rung-4/5 tests; keep existing)

**Interfaces:** no constructor change. The screen renders the two new kinds, using `cafe_prompts.dart` for the displayed text and submitting `freeProduced` for rung 5.

- [ ] **Step 1: Write failing tests** — add to `test/features/cafe/cafe_turn_screen_test.dart` (the setUp already seeds `concept_rain`/`lex_ja_ame`):

```dart
  testWidgets('the Vielredner (rung 4) tells a monologue; understanding it '
      'grades good and the guest reacts', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame',
        rung: 4);
    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(db: db, guest: CafeGuest.vielredner),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-turn-monologue')), findsOneWidget);
    expect(await reviewLogCount(), 0);

    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();

    final log = (await db.select(db.reviewLog).get()).single;
    expect(log.result, 'good');
    expect(find.byKey(const ValueKey('cafe-turn-followup')), findsOneWidget);
  });

  testWidgets('the Gleichaltrige (rung 5) is free production: any answer is '
      'held (graded hard), never wrong', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame',
        rung: 5);
    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(db: db, guest: CafeGuest.gleichaltrige),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('cafe-turn-free-input')), 'irgendwas');
    await tester.tap(find.byKey(const ValueKey('cafe-turn-free-submit')));
    await tester.pumpAndSettle();

    final log = (await db.select(db.reviewLog).get()).single;
    expect(log.result, 'hard'); // free production is held, never good/again
    expect(find.byKey(const ValueKey('cafe-turn-followup')), findsOneWidget);
  });
```

Run `flutter test test/features/cafe/cafe_turn_screen_test.dart` → FAIL (keys don't exist).

- [ ] **Step 2: Implement** — edit `lib/features/cafe/cafe_turn_screen.dart`:

(a) Add the import: `import 'cafe_prompts.dart';`

(b) Add a helper to submit an explicit outcome (refactor `_grade` to route through it), and a free-production submit:
```dart
  Future<void> _submitOutcome(CafeOutcome outcome) async {
    await _ladder.submit(_queue[_index], resultForOutcome(outcome),
        languageCode: widget.languageId);
    if (!mounted) return;
    setState(() => _followUp = _script.followUp(outcome, _index));
  }

  Future<void> _grade({required bool answerCorrect}) async {
    if (_content == null) return;
    await _submitOutcome(outcomeFor(hintUsed: _hintUsed, answerCorrect: answerCorrect));
  }

  Future<void> _gradeFree() async {
    if (_content == null) return;
    await _submitOutcome(CafeOutcome.freeProduced);
  }
```

(c) In `_buildTurn`, compute the displayed prompt per kind and branch the input UI. Replace the current prompt `Text(content.promptText, key: cafe-turn-prompt …)` and the input section so that:
- **comprehension**: show the monologue with key `cafe-turn-monologue` (via `vielrednerMonologue(content.writtenForm, _index)`), then the same reveal + gewusst/nicht controls the recognition kind uses (reuse `cafe-turn-reveal`/`cafe-turn-known`/`cafe-turn-unknown`, calling `_grade`). No dodge-hint.
- **freeProduction**: show the opener with key `cafe-turn-monologue` (via `gleichaltrigeOpener(content.writtenForm, _index)`), then a `TextField` keyed `cafe-turn-free-input` + a submit button keyed `cafe-turn-free-submit` calling `_gradeFree()`. No reveal, no correctness, no hint.
- **recognition / readingInput / productionInput**: unchanged from P8 (prompt keyed `cafe-turn-prompt`, the existing recognition or typed+hint controls).

Concretely, structure the top of `_buildTurn` as:
```dart
  Widget _buildTurn(CafeTurnContent content) {
    final followUp = _followUp;
    final isMonologue = content.kind == CafeExerciseKind.comprehension ||
        content.kind == CafeExerciseKind.freeProduction;
    final headerText = switch (content.kind) {
      CafeExerciseKind.comprehension =>
        vielrednerMonologue(content.writtenForm, _index),
      CafeExerciseKind.freeProduction =>
        gleichaltrigeOpener(content.writtenForm, _index),
      _ => content.promptText,
    };
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headerText,
              key: ValueKey(isMonologue ? 'cafe-turn-monologue' : 'cafe-turn-prompt'),
              style: TextStyle(fontSize: isMonologue ? 18 : 28)),
          const SizedBox(height: 16),
          if (_revealed)
            Text('→ ${content.expectedAnswer}',
                style: const TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          if (followUp == null)
            ..._buildAnswerControls(content)
          else ...[
            Text(followUp, key: const ValueKey('cafe-turn-followup')),
            const SizedBox(height: 12),
            TextButton(
              key: const ValueKey('cafe-turn-next'),
              onPressed: _next,
              child: const Text('weiter'),
            ),
          ],
        ],
      ),
    );
  }
```
and extract the answer controls into `List<Widget> _buildAnswerControls(CafeTurnContent content)` that returns, by kind:
- `recognition` OR `comprehension` → the reveal (`cafe-turn-reveal`) + gewusst (`cafe-turn-known` → `_grade(answerCorrect: true)`) + nicht (`cafe-turn-unknown` → `_grade(answerCorrect: false)`) row (exactly the P8 recognition controls).
- `freeProduction` → a `TextField` (`cafe-turn-free-input`, its own controller — reuse `_input`) + a submit button (`cafe-turn-free-submit` → `_gradeFree()`).
- else (`readingInput`/`productionInput`) → the P8 typed row (`cafe-turn-input` + `cafe-turn-submit` → `_grade(answerCorrect: _isCorrect(content))`) + the `cafe-turn-hint` dodge.

Keep every existing P8 key and behavior for rungs 1–3 intact.

- [ ] **Step 3: Run** `flutter test test/features/cafe/cafe_turn_screen_test.dart` → PASS (the 2 new + all P8 turn-screen tests). Then run the whole café suite: `flutter test test/features/cafe/` → PASS.

- [ ] **Step 4: Commit**
```bash
git add lib/features/cafe/cafe_turn_screen.dart test/features/cafe/cafe_turn_screen_test.dart
git commit -m "feat(cafe): render Vielredner comprehension + Gleichaltrige free-production turns (P9)"
```

---

### Task 4: INV-9 — prove the café surfaces no un-introduced item

**Files:**
- Test: `test/features/cafe/cafe_inv9_test.dart` (new)

**Interfaces:** none — a structural/behavioral test over the shipped café code.

- [ ] **Step 1: Write the test**

Create `test/features/cafe/cafe_inv9_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_screen.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';

void main() {
  late LearningDb db;
  setUp(() async {
    db = LearningDb.forTesting();
    // A lexeme + concept EXIST in the pack, but the learner has NEVER been
    // introduced to it — there is no learn_item for it. INV-9: it must never
    // surface in the café.
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_secret', glossKey: 'secret', partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_himitsu', languageId: 'lang_ja',
        conceptId: 'concept_secret', writtenForm: 'ひみつ', reading: 'ひみつ'));
  });
  tearDown(() async => db.close());

  test('an un-introduced item (no learn_item) is not due — the café has no '
      'source for it', () async {
    // The café's ONLY item source is getDueItems, which selects learn_items.
    final due = await db.getDueItems('lang_ja', limit: 500);
    expect(due.where((i) => i.refId == 'lex_ja_himitsu'), isEmpty);
    // Occupancy is empty: no guest is present for an item that was never read.
    expect(CafeOccupancy.fromDueItems(due).isEmpty, isTrue);
  });

  testWidgets('with only an un-introduced item in the pack, the café is empty '
      'and no guest turn can reach it (INV-9)', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();
    // No guest tiles at all — the un-introduced word never becomes a guest.
    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);

    // And even opening any guest's turn directly surfaces nothing to review.
    for (final guest in CafeGuest.values) {
      await tester.pumpWidget(MaterialApp(
        home: CafeTurnScreen(db: db, guest: guest),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('cafe-turn-done')), findsOneWidget,
          reason: '$guest surfaced a turn for an un-introduced item');
      expect(find.text('ひみつ'), findsNothing);
    }
  });

  test('once introduced (a learn_item exists), the SAME word becomes due — '
      'the café gate is exactly introduction, nothing else', () async {
    // Positive control: introduce it → now it is due → now it can appear.
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_himitsu',
        rung: 1);
    final due = await db.getDueItems('lang_ja', limit: 500);
    expect(due.where((i) => i.refId == 'lex_ja_himitsu'), isNotEmpty);
    expect(CafeOccupancy.fromDueItems(due).present, contains(CafeGuest.wirtin));
  });
}
```

- [ ] **Step 2: Run** `flutter test test/features/cafe/cafe_inv9_test.dart` → PASS. Then the whole café suite `flutter test test/features/cafe/` → PASS.

If any assertion fails, the café can surface an un-introduced item — a real INV-9 violation; investigate the item source, do not weaken the test.

- [ ] **Step 3: Commit**
```bash
git add test/features/cafe/cafe_inv9_test.dart
git commit -m "test(cafe): prove INV-9 — the café surfaces no un-introduced item (P9)"
```
