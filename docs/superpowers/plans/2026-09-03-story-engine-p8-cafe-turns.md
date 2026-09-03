# Story-Engine P8 — Café turns, rung 1–3 (Wirtin + Schulkind) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first real café dialogue turns (brief §4.5) for the two lower-rung guests — the **Wirtin** (rung 1–2) and the **Schulkind** (rung 3). Tapping a present guest in the café opens a turn driven by that guest's due SM-2 items: the guest shows a prompt, the learner answers, the answer is **auto-graded** (right / wrong / dodged-via-hint), the SM-2 ladder is updated (`LadderReview.submit`), and the guest reacts with a rotating in-character `followUp` line. Meaning may be freely tapped as a hint, and a tapped hint counts in the grade — it schedules like a `hard` result, so tapping through never extends intervals (§4.4). P7 gave the café its occupancy; P8 gives its lower guests their voices. (Vielredner rung 4 + Gleichaltrige rung 5 are P9.)

**Architecture:** Four pieces under `lib/features/cafe/`, in the story engine's injected-dependency style (testable against `LearningDb.forTesting()`), reusing the real SM-2/ladder machinery:
- `cafe_turn.dart` — the turn's data + grading logic: `CafeTurnContent` (built from a due `LearnItem` by a small café-scoped Lexemes+Concepts query — the same data `ExerciseLoader` reads, without the `ScriptProfile` dispatch P8 doesn't need), the exercise **kind** per rung (recognition / readingInput / productionInput), and the pure grading map `CafeOutcome → ReviewResult`.
- `cafe_guest_script.dart` — the Wirtin's and Schulkind's `followUp` lines (≥3 per outcome) + deterministic rotation.
- `cafe_turn_screen.dart` — the turn UI: guest prompt, answer input by kind, a free "meaning" hint, auto-grade → `LadderReview.submit` → rotating followUp → next due item, until the guest's queue is empty.
- `cafe_screen.dart` (modify) — wire the guest tile's `onTap` (currently `null`) to open the turn.

**Decisions taken with the user:** (1) **Meaning = the existing English `glossKey`** for now (exactly what `review_screen` shows today) — German-meaning localization is a pre-existing app-wide gap, deferred as a follow-up, NOT a P8 blocker. (2) **One PR, both guests** — no P8a/P8b split; Wirtin (rung 1–2) and Schulkind (rung 3) ship together.

**Tech Stack:** Dart 3.11 / Flutter, Drift/SQLite (`LearningDb.forTesting()`), `flutter_test`. Reuses `LadderReview.submit`, `ReviewResult`, `CafeGuest`/`guestForRung` (P7). No new packages.

## Global Constraints

- Base branch: `origin/main` (`04a7186`) — includes P7's café scaffold (`CafeOccupancy`/`CafeGuest`/`CafeScreen`).
- **Reuse the real grading, don't reinvent it.** A graded turn calls `LadderReview(db).submit(item, result)` (ladder_review.dart:27) — that runs the ladder (promote after 3 consecutive good/easy, demote on again), the SM-2 schedule, and the review log. Do NOT reimplement SM-2 or the rung ladder. The café derives the `ReviewResult` automatically from the answer; it does NOT show `review_screen`'s manual 4-grade self-assessment buttons.
- **Outcome → ReviewResult (§4.4):** correct → `good`; wrong → `again`; **hint used → `hard`** (a tapped meaning "counts, but doesn't extend intervals" — `hard` keeps the rung and does not grow the interval the way `good` would). Hint overrides correctness: if the learner peeked, the turn grades `hard` even if the typed/selected answer was right.
- **Exercise kind by rung (P8 = rung 1–3):** rung 1 → recognition (show word, recall meaning; reveal + self-report *gewusst/nicht*), rung 2 → readingInput (show word, type reading), rung 3 → productionInput (show meaning, type the word). This mirrors `resolveExercise` (rung_defs.dart) for these rungs; P8 inlines a `kindForRung` helper rather than pulling in `ScriptProfile` (which `resolveExercise` requires but does not use). No multiple-choice is built (I1 is upheld by omission — recognition is a reveal-then-self-report, not an option grid).
- **Meaning is the `glossKey`** (English, e.g. `rain`/`sorry`) — the same token `review_screen` displays today. Do not attempt German resolution in P8.
- **INV-8 / INV-9 / INV-10 (café rules):** the turn only reviews *already-due, already-introduced* items pulled from `getDueItems` — it introduces nothing new (INV-8), touches only existing items (INV-9), and awards no café-local score/level/currency (INV-10). The only persisted effect is the normal SM-2 update via `submit`.
- **Guest → due items:** P7's `CafeOccupancy` keeps only *which* guests are present, not their items. The turn re-queries `db.getDueItems(langId, limit: 500)` and filters to the tapped guest via `guestForRung(item.masteryRung) == guest`. (The `limit: 500` edge case is the P7-recorded follow-up; not addressed here.)
- **Do not change P7's café keys** (`cafe-screen`, `cafe-empty`, `cafe-guest-list`, `cafe-guest-<name>`) — `test/features/cafe/cafe_screen_test.dart` asserts them. Task 4 only turns `onTap: null` into an open-the-turn callback.
- New widget keys: `cafe-turn-screen`, `cafe-turn-prompt`, `cafe-turn-input`, `cafe-turn-submit`, `cafe-turn-reveal`, `cafe-turn-known`, `cafe-turn-unknown`, `cafe-turn-hint`, `cafe-turn-followup`, `cafe-turn-next`, `cafe-turn-done`.
- Run tests with `flutter test <path>`. The full suite has 8 pre-existing `test/mining_packs/ja/` native-tokenizer failures, unrelated — "green" means those 8 and no others.

---

### Task 1: `CafeTurnContent` + grading logic

**Files:**
- Create: `lib/features/cafe/cafe_turn.dart`
- Test: `test/features/cafe/cafe_turn_test.dart`

**Interfaces:**
- Produces (used by Tasks 2–4): `enum CafeOutcome { correct, wrong, hinted }`; `ReviewResult resultForOutcome(CafeOutcome)`; `CafeOutcome outcomeFor({required bool hintUsed, required bool answerCorrect})`; `enum CafeExerciseKind { recognition, readingInput, productionInput }`; `CafeExerciseKind kindForRung(int rung)`; `class CafeTurnContent { final CafeExerciseKind kind; final String promptText; final String expectedAnswer; final String meaning; final String writtenForm; final String reading; ... static Future<CafeTurnContent?> forItem(LearningDb db, LearnItem item); }`.

- [ ] **Step 1: Write the failing test**

Create `test/features/cafe/cafe_turn_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/srs/scheduler.dart';
import 'package:nihongo_app/features/cafe/cafe_turn.dart';

void main() {
  group('grading', () {
    test('outcome maps to the right ReviewResult (hint = hard, §4.4)', () {
      expect(resultForOutcome(CafeOutcome.correct), ReviewResult.good);
      expect(resultForOutcome(CafeOutcome.wrong), ReviewResult.again);
      expect(resultForOutcome(CafeOutcome.hinted), ReviewResult.hard);
    });

    test('a used hint dodges — hinted even when the answer was correct', () {
      expect(outcomeFor(hintUsed: true, answerCorrect: true),
          CafeOutcome.hinted);
      expect(outcomeFor(hintUsed: true, answerCorrect: false),
          CafeOutcome.hinted);
    });

    test('without a hint, correctness decides', () {
      expect(outcomeFor(hintUsed: false, answerCorrect: true),
          CafeOutcome.correct);
      expect(outcomeFor(hintUsed: false, answerCorrect: false),
          CafeOutcome.wrong);
    });
  });

  group('kindForRung', () {
    test('rung 1 recognition, rung 2 reading, rung 3 production', () {
      expect(kindForRung(1), CafeExerciseKind.recognition);
      expect(kindForRung(2), CafeExerciseKind.readingInput);
      expect(kindForRung(3), CafeExerciseKind.productionInput);
    });
  });

  group('CafeTurnContent.forItem', () {
    late LearningDb db;
    setUp(() async {
      db = LearningDb.forTesting();
      // A minimal lexeme + concept, as ja_seed lays them down.
      await db.into(db.concepts).insert(ConceptsCompanion.insert(
          id: 'concept_rain', glossKey: 'rain', partOfSpeech: 'noun',
          defaultAssetType: 'image'));
      await db.into(db.lexemes).insert(LexemesCompanion.insert(
          id: 'lex_ja_ame', languageId: 'lang_ja', conceptId: 'concept_rain',
          writtenForm: 'あめ', reading: 'あめ'));
    });
    tearDown(() async => db.close());

    Future<LearnItem> due(int rung) async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame',
          rung: rung);
      return (await db.getDueItems('lang_ja', limit: 500)).single;
    }

    test('rung 3 (production): prompt is the meaning, answer is the word',
        () async {
      final content = await CafeTurnContent.forItem(db, await due(3));
      expect(content!.kind, CafeExerciseKind.productionInput);
      expect(content.promptText, 'rain'); // glossKey (meaning) shown
      expect(content.expectedAnswer, 'あめ'); // learner produces the word
      expect(content.meaning, 'rain');
    });

    test('rung 1 (recognition): prompt is the word, answer is the meaning',
        () async {
      final content = await CafeTurnContent.forItem(db, await due(1));
      expect(content!.kind, CafeExerciseKind.recognition);
      expect(content.promptText, 'あめ');
      expect(content.expectedAnswer, 'rain');
    });

    test('a lexeme that is not in the DB yields null (skippable)', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_missing',
          rung: 3);
      final item = (await db.getDueItems('lang_ja', limit: 500))
          .firstWhere((i) => i.refId == 'lex_missing');
      expect(await CafeTurnContent.forItem(db, item), isNull);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/cafe/cafe_turn_test.dart`
Expected: FAIL — `cafe_turn.dart` does not exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/features/cafe/cafe_turn.dart`:

```dart
import 'package:drift/drift.dart';

import '../../core/db/learning_db.dart';
import '../../core/srs/scheduler.dart';

/// How a café turn ended (brief §4.4/§4.5): the learner answered correctly,
/// wrongly, or dodged by tapping the meaning as a hint.
enum CafeOutcome { correct, wrong, hinted }

/// Maps the café outcome to the SM-2 grade fed to [LadderReview.submit].
/// A tapped hint schedules like [ReviewResult.hard] — it counts, but does not
/// extend the interval the way a clean [ReviewResult.good] would (§4.4).
ReviewResult resultForOutcome(CafeOutcome outcome) => switch (outcome) {
      CafeOutcome.correct => ReviewResult.good,
      CafeOutcome.wrong => ReviewResult.again,
      CafeOutcome.hinted => ReviewResult.hard,
    };

/// A used hint dodges the turn: the outcome is [CafeOutcome.hinted] regardless
/// of whether the eventual answer was right. Otherwise correctness decides.
CafeOutcome outcomeFor({required bool hintUsed, required bool answerCorrect}) {
  if (hintUsed) return CafeOutcome.hinted;
  return answerCorrect ? CafeOutcome.correct : CafeOutcome.wrong;
}

/// The café turn's exercise shape for rungs 1–3 (P8). Mirrors
/// `resolveExercise` (rung_defs.dart) for these rungs without pulling in the
/// `ScriptProfile` it requires but does not use.
enum CafeExerciseKind { recognition, readingInput, productionInput }

CafeExerciseKind kindForRung(int rung) {
  if (rung <= 1) return CafeExerciseKind.recognition;
  if (rung == 2) return CafeExerciseKind.readingInput;
  return CafeExerciseKind.productionInput; // rung 3 (P8's top rung)
}

/// The content of one café turn, built from a due lexeme [LearnItem] by a
/// café-scoped Lexemes+Concepts query (the same data `ExerciseLoader` reads).
/// [meaning] is the concept's `glossKey` — the English key `review_screen`
/// also shows today; German localization is a deferred follow-up.
class CafeTurnContent {
  final CafeExerciseKind kind;

  /// What the guest shows: the word (recognition/reading) or the meaning
  /// (production).
  final String promptText;

  /// The answer the learner must give: the meaning (recognition), the reading
  /// (readingInput), or the written form (productionInput).
  final String expectedAnswer;

  final String meaning;
  final String writtenForm;
  final String reading;

  const CafeTurnContent({
    required this.kind,
    required this.promptText,
    required this.expectedAnswer,
    required this.meaning,
    required this.writtenForm,
    required this.reading,
  });

  /// Builds the turn content for [item] (a lexeme). Returns null if the
  /// lexeme or its concept is missing — the caller skips such an item rather
  /// than crashing the café.
  static Future<CafeTurnContent?> forItem(LearningDb db, LearnItem item) async {
    final lex = await (db.select(db.lexemes)
          ..where((t) => t.id.equals(item.refId)))
        .getSingleOrNull();
    if (lex == null) return null;
    final concept = await (db.select(db.concepts)
          ..where((t) => t.id.equals(lex.conceptId)))
        .getSingleOrNull();
    if (concept == null) return null;

    final kind = kindForRung(item.masteryRung);
    final meaning = concept.glossKey;
    final (promptText, expectedAnswer) = switch (kind) {
      CafeExerciseKind.recognition => (lex.writtenForm, meaning),
      CafeExerciseKind.readingInput => (lex.writtenForm, lex.reading),
      CafeExerciseKind.productionInput => (meaning, lex.writtenForm),
    };

    return CafeTurnContent(
      kind: kind,
      promptText: promptText,
      expectedAnswer: expectedAnswer,
      meaning: meaning,
      writtenForm: lex.writtenForm,
      reading: lex.reading,
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/cafe/cafe_turn_test.dart`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_turn.dart test/features/cafe/cafe_turn_test.dart
git commit -m "feat(cafe): add CafeTurnContent + auto-grading (hint = hard) for rung 1-3 (P8)"
```

---

### Task 2: `CafeGuestScript` — Wirtin & Schulkind followUp lines

**Files:**
- Create: `lib/features/cafe/cafe_guest_script.dart`
- Test: `test/features/cafe/cafe_guest_script_test.dart`

**Interfaces:**
- Consumes: `CafeOutcome` (Task 1), `CafeGuest` (P7, `cafe_occupancy.dart`).
- Produces: `class CafeGuestScript { const CafeGuestScript(Map<CafeOutcome, List<String>> lines); String followUp(CafeOutcome outcome, int turnIndex); }`; `CafeGuestScript scriptFor(CafeGuest guest)`.

- [ ] **Step 1: Write the failing test**

Create `test/features/cafe/cafe_guest_script_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_turn.dart';
import 'package:nihongo_app/features/cafe/cafe_guest_script.dart';

void main() {
  test('the Wirtin and the Schulkind each have ≥3 lines per outcome', () {
    for (final guest in [CafeGuest.wirtin, CafeGuest.schulkind]) {
      final script = scriptFor(guest);
      for (final outcome in CafeOutcome.values) {
        expect(script.followUp(outcome, 0), isNotEmpty);
        // ≥3 distinct lines → indices 0,1,2 don't all collapse to one.
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

  test('followUp rotates deterministically by turn index', () {
    final script = scriptFor(CafeGuest.schulkind);
    final a = script.followUp(CafeOutcome.correct, 0);
    final b = script.followUp(CafeOutcome.correct, 1);
    expect(a, isNot(b));
    // Wraps around.
    expect(script.followUp(CafeOutcome.correct, 0),
        script.followUp(CafeOutcome.correct, 0));
  });

  test('the Schulkind sounds nothing like the Wirtin (distinct content)', () {
    final wirtin = scriptFor(CafeGuest.wirtin).followUp(CafeOutcome.wrong, 0);
    final kind = scriptFor(CafeGuest.schulkind).followUp(CafeOutcome.wrong, 0);
    expect(wirtin, isNot(kind));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/cafe/cafe_guest_script_test.dart`
Expected: FAIL — `cafe_guest_script.dart` does not exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/features/cafe/cafe_guest_script.dart`:

```dart
import 'cafe_occupancy.dart';
import 'cafe_turn.dart';

/// A guest's reactions (brief §4.5): at least three lines per outcome, rotated
/// by turn index so a guest never sounds like a flashcard. `followUp` is the
/// part that carries the guest's character — the Wirtin patient and warm, the
/// Schulkind blunt and merciless.
class CafeGuestScript {
  final Map<CafeOutcome, List<String>> lines;

  const CafeGuestScript(this.lines);

  String followUp(CafeOutcome outcome, int turnIndex) {
    final options = lines[outcome]!;
    return options[turnIndex % options.length];
  }
}

/// The Wirtin (rung 1–2): geduldig, langsam, wiederholt gern.
const _wirtin = CafeGuestScript({
  CafeOutcome.correct: [
    'Genau so.',
    'Ja, richtig — du hörst gut zu.',
    'Schön. Das sitzt jetzt.',
  ],
  CafeOutcome.wrong: [
    'Nicht ganz. Wir sehen es uns zusammen an.',
    'Kein Problem, das wiederholen wir einfach.',
    'Fast. Ich zeige es dir gleich noch einmal.',
  ],
  CafeOutcome.hinted: [
    'Nachsehen ist erlaubt. Beim nächsten Mal von allein.',
    'Gut, dass du nachschaust — es prägt sich trotzdem ein.',
    'Schau ruhig nach. Langsam wird es deins.',
  ],
});

/// The Schulkind (rung 3): direkt, kein Keigo, korrigiert schonungslos.
const _schulkind = CafeGuestScript({
  CafeOutcome.correct: [
    'Ha, gewusst!',
    'Klar, easy.',
    'Siehst du, geht doch.',
  ],
  CafeOutcome.wrong: [
    'Nee. Falsch.',
    'Das heißt das gar nicht!',
    'Nochmal — aber richtig diesmal.',
  ],
  CafeOutcome.hinted: [
    'Spicken gilt nicht!',
    'Nachgucken? Schwach.',
    'Nächstes Mal ohne Buch, ja?',
  ],
});

/// The script for a guest. P8 covers only the Wirtin and the Schulkind;
/// Vielredner/Gleichaltrige (rung 4–5) arrive in P9.
CafeGuestScript scriptFor(CafeGuest guest) => switch (guest) {
      CafeGuest.wirtin => _wirtin,
      CafeGuest.schulkind => _schulkind,
      CafeGuest.vielredner => _wirtin, // placeholder until P9
      CafeGuest.gleichaltrige => _wirtin, // placeholder until P9
    };
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/cafe/cafe_guest_script_test.dart`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_guest_script.dart test/features/cafe/cafe_guest_script_test.dart
git commit -m "feat(cafe): add Wirtin & Schulkind followUp scripts with rotation (P8)"
```

---

### Task 3: `CafeTurnScreen` — drive a guest's due queue through turns

**Files:**
- Create: `lib/features/cafe/cafe_turn_screen.dart`
- Test: `test/features/cafe/cafe_turn_screen_test.dart`

**Interfaces:**
- Consumes: `CafeTurnContent`/`CafeOutcome`/`outcomeFor`/`resultForOutcome` (Task 1), `CafeGuestScript`/`scriptFor` (Task 2), `CafeGuest`/`guestForRung` (P7), `LadderReview.submit` (core).
- Produces: `class CafeTurnScreen extends StatefulWidget { const CafeTurnScreen({required LearningDb db, required CafeGuest guest, String languageId = 'lang_ja'}); }`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/cafe/cafe_turn_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_rain', glossKey: 'rain', partOfSpeech: 'noun',
        defaultAssetType: 'image'));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ame', languageId: 'lang_ja', conceptId: 'concept_rain',
        writtenForm: 'あめ', reading: 'あめ'));
  });
  tearDown(() async => db.close());

  Future<int> reviewLogCount() async =>
      (await db.select(db.reviewLog).get()).length;

  testWidgets('the Schulkind poses a rung-3 production turn; a correct answer '
      'grades it (a review is logged) and a followUp appears', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame',
        rung: 3);

    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(db: db, guest: CafeGuest.schulkind),
    ));
    await tester.pumpAndSettle();

    // The prompt is the meaning; the learner types the word.
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsOneWidget);
    expect(await reviewLogCount(), 0);

    await tester.enterText(
        find.byKey(const ValueKey('cafe-turn-input')), 'あめ');
    await tester.tap(find.byKey(const ValueKey('cafe-turn-submit')));
    await tester.pumpAndSettle();

    // A grade was submitted to the ladder, and the guest reacted.
    expect(await reviewLogCount(), 1);
    expect(find.byKey(const ValueKey('cafe-turn-followup')), findsOneWidget);
  });

  testWidgets('using the meaning hint dodges — still graded, and the guest '
      'reacts to a hinted turn', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame',
        rung: 3);

    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(db: db, guest: CafeGuest.schulkind),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cafe-turn-hint')));
    await tester.pumpAndSettle();
    // After a hint the word is revealed; typing it is still a dodge.
    await tester.enterText(
        find.byKey(const ValueKey('cafe-turn-input')), 'あめ');
    await tester.tap(find.byKey(const ValueKey('cafe-turn-submit')));
    await tester.pumpAndSettle();

    expect(await reviewLogCount(), 1);
    expect(find.byKey(const ValueKey('cafe-turn-followup')), findsOneWidget);
  });

  testWidgets('a guest with no due items shows the done/empty state',
      (tester) async {
    // Nothing seeded as due → the Schulkind has nobody to talk to.
    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(db: db, guest: CafeGuest.schulkind),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-turn-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsNothing);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/cafe/cafe_turn_screen_test.dart`
Expected: FAIL — `cafe_turn_screen.dart` does not exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/features/cafe/cafe_turn_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/db/learning_db.dart';
import '../../core/ladder/ladder_review.dart';
import 'cafe_guest_script.dart';
import 'cafe_occupancy.dart';
import 'cafe_turn.dart';

/// One guest's café turns (brief §4.5). Drives the guest's due SM-2 items:
/// show a prompt, take an answer, auto-grade (correct / wrong / hinted-via-tap,
/// §4.4), update the ladder ([LadderReview.submit]), and react with a rotating
/// followUp — until the queue is empty. Introduces nothing (INV-8), awards no
/// café score (INV-10).
class CafeTurnScreen extends StatefulWidget {
  final LearningDb db;
  final CafeGuest guest;
  final String languageId;

  const CafeTurnScreen({
    super.key,
    required this.db,
    required this.guest,
    this.languageId = 'lang_ja',
  });

  @override
  State<CafeTurnScreen> createState() => _CafeTurnScreenState();
}

class _CafeTurnScreenState extends State<CafeTurnScreen> {
  late final LadderReview _ladder = LadderReview(widget.db);
  late final CafeGuestScript _script = scriptFor(widget.guest);

  List<LearnItem> _queue = [];
  int _index = 0;
  bool _loading = true;

  CafeTurnContent? _content;
  final _input = TextEditingController();
  bool _hintUsed = false;
  bool _revealed = false;
  String? _followUp;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final due = await widget.db.getDueItems(widget.languageId, limit: 500);
    final mine =
        due.where((i) => guestForRung(i.masteryRung) == widget.guest).toList();
    if (!mounted) return;
    setState(() {
      _queue = mine;
      _loading = false;
    });
    await _prepareTurn();
  }

  Future<void> _prepareTurn() async {
    if (_index >= _queue.length) {
      if (mounted) setState(() => _content = null);
      return;
    }
    final content = await CafeTurnContent.forItem(widget.db, _queue[_index]);
    if (!mounted) return;
    if (content == null) {
      // Skip an item whose lexeme/concept is missing.
      _index++;
      await _prepareTurn();
      return;
    }
    setState(() {
      _content = content;
      _hintUsed = false;
      _revealed = false;
      _followUp = null;
      _input.clear();
    });
  }

  void _useHint() => setState(() {
        _hintUsed = true;
        _revealed = true;
      });

  // Only called for typed turns (recognition grades via the gewusst/nicht
  // self-report buttons, which pass an explicit flag to _grade).
  bool _isCorrect(CafeTurnContent content) =>
      _input.text.trim() == content.expectedAnswer.trim();

  Future<void> _grade({required bool answerCorrect}) async {
    final content = _content;
    if (content == null) return;
    final outcome =
        outcomeFor(hintUsed: _hintUsed, answerCorrect: answerCorrect);
    await _ladder.submit(_queue[_index], resultForOutcome(outcome),
        languageCode: widget.languageId);
    if (!mounted) return;
    setState(() => _followUp = _script.followUp(outcome, _index));
  }

  Future<void> _next() async {
    _index++;
    await _prepareTurn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('cafe-turn-screen'),
      appBar: AppBar(title: Text(_guestName(widget.guest))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _content == null
              ? Center(
                  key: const ValueKey('cafe-turn-done'),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Zurück ins Café'),
                  ),
                )
              : _buildTurn(_content!),
    );
  }

  Widget _buildTurn(CafeTurnContent content) {
    final followUp = _followUp;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content.promptText,
              key: const ValueKey('cafe-turn-prompt'),
              style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 16),
          if (_revealed)
            Text('→ ${content.expectedAnswer}',
                style: const TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          if (followUp == null) ...[
            if (content.kind == CafeExerciseKind.recognition)
              Row(
                children: [
                  TextButton(
                    key: const ValueKey('cafe-turn-reveal'),
                    onPressed: () => setState(() => _revealed = true),
                    child: const Text('zeigen'),
                  ),
                  const Spacer(),
                  TextButton(
                    key: const ValueKey('cafe-turn-known'),
                    onPressed: () => _grade(answerCorrect: true),
                    child: const Text('gewusst'),
                  ),
                  TextButton(
                    key: const ValueKey('cafe-turn-unknown'),
                    onPressed: () => _grade(answerCorrect: false),
                    child: const Text('nicht'),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('cafe-turn-input'),
                      controller: _input,
                      decoration: const InputDecoration(hintText: '…'),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('cafe-turn-submit'),
                    onPressed: () =>
                        _grade(answerCorrect: _isCorrect(content)),
                    child: const Text('sagen'),
                  ),
                ],
              ),
              // The meaning hint is a dodge only for a typed turn (where you
              // must PRODUCE something and could peek). Recognition's answer
              // IS the meaning, so revealing it there is the normal check via
              // "zeigen", not a dodge.
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey('cafe-turn-hint'),
                  onPressed: _hintUsed ? null : _useHint,
                  child: const Text('Bedeutung zeigen'),
                ),
              ),
            ],
          ] else ...[
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
}

String _guestName(CafeGuest guest) => switch (guest) {
      CafeGuest.wirtin => 'Die Wirtin',
      CafeGuest.schulkind => 'Das Schulkind',
      CafeGuest.vielredner => 'Der Vielredner',
      CafeGuest.gleichaltrige => 'Die Gleichaltrige',
    };
```

Note on the recognition hint: for a recognition turn, tapping "Bedeutung zeigen" sets `_hintUsed` (and reveals), so a subsequent "gewusst" still grades `hinted` via `outcomeFor` — the self-report cannot un-dodge a peek. For typed turns, `_isCorrect` compares the typed answer to `expectedAnswer` (trimmed).

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/cafe/cafe_turn_screen_test.dart`
Expected: PASS (all 3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_turn_screen.dart test/features/cafe/cafe_turn_screen_test.dart
git commit -m "feat(cafe): CafeTurnScreen drives a guest's due queue with auto-grading + followUp (P8)"
```

---

### Task 4: Wire the café guest tile to open the turn

**Files:**
- Modify: `lib/features/cafe/cafe_screen.dart`
- Modify: `test/features/cafe/cafe_screen_test.dart` (add one test; do not change existing tests/keys)

**Interfaces:**
- `CafeScreen` gains no new constructor params. Its guest `ListTile.onTap` (currently `null`) pushes a `CafeTurnScreen(db, guest, languageId)`.

- [ ] **Step 1: Write the failing test**

Add to `test/features/cafe/cafe_screen_test.dart`:

```dart
  testWidgets('tapping a present guest opens that guest\'s turn screen',
      (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_x', rung: 3);

    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cafe-guest-schulkind')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-turn-screen')), findsOneWidget);
  });
```

Add the import if not present: `import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';` (the test only needs the `cafe-turn-screen` key, which is a string literal — no import strictly required, but keep imports as the existing file has them).

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/cafe/cafe_screen_test.dart`
Expected: FAIL — tapping the tile does nothing (`onTap: null`), so `cafe-turn-screen` never appears.

- [ ] **Step 3: Write the implementation**

In `lib/features/cafe/cafe_screen.dart`:
- Add the import: `import 'cafe_turn_screen.dart';`
- Change the guest `ListTile`'s `onTap: null` to open the turn:
```dart
          ListTile(
            key: ValueKey(_keys[guest]!),
            title: Text(_labels[guest]!),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => CafeTurnScreen(
                  db: widget.db,
                  guest: guest,
                  languageId: widget.languageId,
                ),
              ));
              // On return, the due state may have changed — recompute this
              // session's occupancy (still once-per-visit, just refreshed
              // after a turn set).
              if (mounted) _load();
            },
          ),
```

Note: `_load()` already exists (P7) and recomputes occupancy from `getDueItems`. Calling it on return keeps the café honest after a batch of reviews without violating "fixed per session" (it refreshes only after the learner finishes a guest's turns, not on every rebuild).

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/cafe/cafe_screen_test.dart`
Expected: PASS — the four pre-existing café-screen tests plus the new tap-opens-turn test.

- [ ] **Step 5: Run the whole café suite together**

Run: `flutter test test/features/cafe/`
Expected: PASS across Tasks 1–4 and P7's tests.

- [ ] **Step 6: Commit**

```bash
git add lib/features/cafe/cafe_screen.dart test/features/cafe/cafe_screen_test.dart
git commit -m "feat(cafe): open a guest's turn when their café tile is tapped (P8)"
```
