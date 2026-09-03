# Story-Engine P7 — Café scaffold (occupancy = due indicator) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the scaffold of the brief's phase P7 — the Café, the repetition mode that replaces the bare SRS feed (brief §4). P7 delivers exactly the **occupancy mechanic**: SM-2 supplies which items are due, and the guest a learner sits with picks the rung (§4.2 "Gäste sind Rungs"). A guest is present **iff** there is at least one due item in their rung band; nothing due → the café is calmly empty, **no count, no "0 due" message** (§4.3 — that empty state is the whole acceptance bar for P7). P7 renders presence only; the guests' actual dialogue turns are P8 (rung 1–3) and P9 (rung 4–5).

**Architecture:** Two pieces, mirroring the story engine's injected-dependency style (not Riverpod providers, so both are testable against `LearningDb.forTesting()`):
- `CafeOccupancy` — pure logic: given the due `LearnItem`s, compute which of the four guests are present (`guestForRung` maps a mastery rung to a guest band). No DB, no UI.
- `CafeScreen` — a plain `StatefulWidget` taking an injected `LearningDb` + `languageId`. It computes occupancy **once on entry** (in `initState`, stable for the session per PHASE_0 §7) from `db.getDueItems(...)`, and renders either the present guests (as scaffold placeholders — tapping is a deliberate no-op until P8/P9) or the calm empty state. It reads only; it introduces nothing (INV-8) and shows no progress/level/currency (INV-10). App-wiring — routing the café in to replace `lib/features/review/review_screen.dart` — is deferred to a later integration phase, consistent with the still-unrouted reader.

**Tech Stack:** Dart 3.11 / Flutter, Drift/SQLite (`LearningDb.forTesting()`), `flutter_test`. Reuses `LearningDb.getDueItems` / `addLearnItemAtRung` and the `RefType` enum. No new packages.

## Global Constraints

- Base branch: `origin/main` (`d1d988d`) — all of P0–P6.
- **Guest ↔ rung band (brief §4.2):** Wirtin → rung 1–2, Schulkind → rung 3, Vielredner → rung 4, Gleichaltrige → rung 5. **Rung 0** (an item freshly introduced but not yet encountered — P5b introduces at rung 0, and such items are immediately due since `introduce` sets `dueAt = now`) folds into the **Wirtin's** band: she "zeigt und benennt Dinge", the right home for a word's first café encounter. So `guestForRung`: `rung <= 2 → Wirtin`, `3 → Schulkind`, `4 → Vielredner`, else (`5`+) → `Gleichaltrige`.
- **Occupancy IS the due indicator (§4.3):** present iff ≥1 due item in the band. NOTHING is rendered as a number: no due count, no progress bar, no "0 Karten fällig" message. Nothing due → an empty set → the screen shows only the calm empty state (the Wirtin wiping the counter). A test explicitly asserts no due-count text leaks.
- **INV-8:** the café introduces no new items. `CafeScreen` only *reads* `getDueItems`; it must never insert/promote a learn_item. **INV-10:** the café has no progress of its own — no level, no currency, no unlock, no streak. Render neither.
- **Fix pro Sitzung (PHASE_0 §7):** occupancy is computed once, in `initState`. Re-querying on every rebuild is wrong — a test asserts that due items added *after* entry do not change this session's café.
- **Occupancy needs the whole due set, not a page.** `getDueItems` defaults to `limit: 20`; call it with a generous limit (`limit: 500`) so a band isn't missed when many items are due. (A dedicated per-rung COUNT query is a future optimization, not this slice.)
- Guests are referred to by the brief's **role names** (Wirtin/Schulkind/Vielredner/Gleichaltrige) — final character names and the A7 café-interior + four figure assets are the deferred asset pipeline, not P7.
- Widget keys: `cafe-screen`, `cafe-empty`, `cafe-guest-list`, `cafe-guest-wirtin`, `cafe-guest-schulkind`, `cafe-guest-vielredner`, `cafe-guest-gleichaltrige`.
- Run tests with `flutter test <path>`. The full suite has 8 pre-existing `test/mining_packs/ja/` native-tokenizer failures, unrelated — "green" means those 8 and no others.

---

### Task 1: `CafeOccupancy` — due items → present guests

**Files:**
- Create: `lib/features/cafe/cafe_occupancy.dart`
- Test: `test/features/cafe/cafe_occupancy_test.dart`

**Interfaces:**
- Produces (used by Task 2): `enum CafeGuest { wirtin, schulkind, vielredner, gleichaltrige }`; `CafeGuest guestForRung(int rung)`; `class CafeOccupancy { const CafeOccupancy(Set<CafeGuest> present); bool get isEmpty; factory CafeOccupancy.fromDueItems(List<LearnItem> dueItems); }`.

- [ ] **Step 1: Write the failing test**

Create `test/features/cafe/cafe_occupancy_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';

void main() {
  group('guestForRung', () {
    test('maps rung bands to guests, folding rung 0 into the Wirtin', () {
      expect(guestForRung(0), CafeGuest.wirtin);
      expect(guestForRung(1), CafeGuest.wirtin);
      expect(guestForRung(2), CafeGuest.wirtin);
      expect(guestForRung(3), CafeGuest.schulkind);
      expect(guestForRung(4), CafeGuest.vielredner);
      expect(guestForRung(5), CafeGuest.gleichaltrige);
    });
  });

  group('CafeOccupancy.fromDueItems (via a real due queue)', () {
    late LearningDb db;
    setUp(() => db = LearningDb.forTesting());
    tearDown(() async => db.close());

    Future<void> seedDue(String id, int rung) =>
        db.addLearnItemAtRung('lang_ja', RefType.lexeme, id, rung: rung);

    test('nothing due → empty café (no guests)', () async {
      final due = await db.getDueItems('lang_ja', limit: 500);
      expect(CafeOccupancy.fromDueItems(due).isEmpty, isTrue);
    });

    test('one due item at rung 3 → only the Schulkind is present', () async {
      await seedDue('lex_a', 3);
      final due = await db.getDueItems('lang_ja', limit: 500);
      expect(CafeOccupancy.fromDueItems(due).present, {CafeGuest.schulkind});
    });

    test('due items across rungs → exactly the matching guests present',
        () async {
      await seedDue('lex_a', 1); // Wirtin
      await seedDue('lex_b', 3); // Schulkind
      await seedDue('lex_c', 5); // Gleichaltrige
      final due = await db.getDueItems('lang_ja', limit: 500);
      final occ = CafeOccupancy.fromDueItems(due);
      expect(occ.present,
          {CafeGuest.wirtin, CafeGuest.schulkind, CafeGuest.gleichaltrige});
      expect(occ.present.contains(CafeGuest.vielredner), isFalse);
    });

    test('a rung-0 item (freshly introduced) puts the Wirtin in the café',
        () async {
      await seedDue('lex_new', 0);
      final due = await db.getDueItems('lang_ja', limit: 500);
      expect(CafeOccupancy.fromDueItems(due).present, {CafeGuest.wirtin});
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/cafe/cafe_occupancy_test.dart`
Expected: FAIL — `cafe_occupancy.dart` does not exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/features/cafe/cafe_occupancy.dart`:

```dart
import '../../core/db/learning_db.dart';

/// The four café guests. Choosing a guest is choosing the difficulty rung
/// (brief §4.2): SM-2 picks the items, the guest picks the rung. Declared in
/// ascending-rung order so `CafeGuest.values` is a stable render order.
enum CafeGuest { wirtin, schulkind, vielredner, gleichaltrige }

/// Maps a due item's mastery rung to the guest who handles that band
/// (brief §4.2). Rung 0 (freshly introduced, not yet encountered) folds into
/// the Wirtin's gentle 1–2 band — she "zeigt und benennt Dinge", the right
/// home for a word's first café encounter.
CafeGuest guestForRung(int rung) {
  if (rung <= 2) return CafeGuest.wirtin;
  if (rung == 3) return CafeGuest.schulkind;
  if (rung == 4) return CafeGuest.vielredner;
  return CafeGuest.gleichaltrige; // rung 5 (and, defensively, any higher)
}

/// Who is present in the café right now. Occupancy IS the due indicator
/// (brief §4.3): a guest is present iff there is at least one due item in
/// their rung band. Nothing due → an empty [present] set → the café is calmly
/// empty (no count, no "0 due" message — that's the screen's job to render as
/// quiet emptiness, never a number).
class CafeOccupancy {
  final Set<CafeGuest> present;

  const CafeOccupancy(this.present);

  bool get isEmpty => present.isEmpty;

  factory CafeOccupancy.fromDueItems(List<LearnItem> dueItems) {
    return CafeOccupancy({
      for (final item in dueItems) guestForRung(item.masteryRung),
    });
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/cafe/cafe_occupancy_test.dart`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_occupancy.dart test/features/cafe/cafe_occupancy_test.dart
git commit -m "feat(cafe): add CafeOccupancy — due items map to present guests by rung (P7)"
```

---

### Task 2: `CafeScreen` — render occupancy (or calm emptiness)

**Files:**
- Create: `lib/features/cafe/cafe_screen.dart`
- Test: `test/features/cafe/cafe_screen_test.dart`

**Interfaces:**
- Consumes: `CafeOccupancy`/`CafeGuest` (Task 1), `LearningDb` (`getDueItems`).
- Produces: `class CafeScreen extends StatefulWidget { const CafeScreen({required LearningDb db, String languageId = 'lang_ja'}); }`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/cafe/cafe_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_screen.dart';

void main() {
  late LearningDb db;
  setUp(() => db = LearningDb.forTesting());
  tearDown(() async => db.close());

  testWidgets('nothing due → the café is calmly empty, with no count or '
      '"0 due" message', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-guest-list')), findsNothing);
    // Nothing that reads like a due count leaks into the empty state.
    expect(find.textContaining('0'), findsNothing);
    expect(find.textContaining('fällig'), findsNothing);
  });

  testWidgets('due items at rung 1 and 3 → only the Wirtin and Schulkind '
      'are present', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_a', rung: 1);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_b', rung: 3);

    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-empty')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-guest-wirtin')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-guest-schulkind')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-guest-vielredner')), findsNothing);
    expect(
        find.byKey(const ValueKey('cafe-guest-gleichaltrige')), findsNothing);
  });

  testWidgets('occupancy is computed once on entry (stable for the session)',
      (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_a', rung: 3);
    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-guest-schulkind')), findsOneWidget);

    // Adding more due items after entry does NOT change this session's café.
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_b', rung: 5);
    await tester.pump();
    expect(
        find.byKey(const ValueKey('cafe-guest-gleichaltrige')), findsNothing);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/cafe/cafe_screen_test.dart`
Expected: FAIL — `cafe_screen.dart` does not exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/features/cafe/cafe_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/db/learning_db.dart';
import 'cafe_occupancy.dart';

/// The café — the repetition mode that replaces the bare SRS feed (brief §4).
/// Occupancy is the due indicator: who is present depends on what is due,
/// computed ONCE on entry and stable for the session (PHASE_0 §7). Nothing
/// due → the café is calmly empty, no count, no "0 due" message (§4.3). The
/// café introduces nothing (INV-8) and has no progress of its own — no level,
/// no currency, no unlocks (INV-10). This scaffold (P7) renders presence only;
/// the guests' turns are P8/P9, so tapping a guest is a deliberate no-op.
class CafeScreen extends StatefulWidget {
  final LearningDb db;
  final String languageId;

  const CafeScreen({super.key, required this.db, this.languageId = 'lang_ja'});

  @override
  State<CafeScreen> createState() => _CafeScreenState();
}

class _CafeScreenState extends State<CafeScreen> {
  CafeOccupancy? _occupancy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final due = await widget.db.getDueItems(widget.languageId, limit: 500);
    if (!mounted) return;
    setState(() => _occupancy = CafeOccupancy.fromDueItems(due));
  }

  static const _labels = {
    CafeGuest.wirtin: 'Die Wirtin',
    CafeGuest.schulkind: 'Das Schulkind',
    CafeGuest.vielredner: 'Der Vielredner',
    CafeGuest.gleichaltrige: 'Die Gleichaltrige',
  };

  static const _keys = {
    CafeGuest.wirtin: 'cafe-guest-wirtin',
    CafeGuest.schulkind: 'cafe-guest-schulkind',
    CafeGuest.vielredner: 'cafe-guest-vielredner',
    CafeGuest.gleichaltrige: 'cafe-guest-gleichaltrige',
  };

  @override
  Widget build(BuildContext context) {
    final occupancy = _occupancy;
    return Scaffold(
      key: const ValueKey('cafe-screen'),
      appBar: AppBar(title: const Text('Café')),
      body: occupancy == null
          ? const Center(child: CircularProgressIndicator())
          : occupancy.isEmpty
              ? const Center(
                  key: ValueKey('cafe-empty'),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Die Wirtin wischt den Tresen und nickt dir zu.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  key: const ValueKey('cafe-guest-list'),
                  children: [
                    for (final guest in CafeGuest.values)
                      if (occupancy.present.contains(guest))
                        ListTile(
                          key: ValueKey(_keys[guest]),
                          title: Text(_labels[guest]!),
                          // Scaffold only — a guest's turn is P8/P9.
                          onTap: null,
                        ),
                  ],
                ),
    );
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/cafe/cafe_screen_test.dart`
Expected: PASS (all 3 tests).

- [ ] **Step 5: Run the cafe-feature suite together**

Run: `flutter test test/features/cafe/`
Expected: PASS (Task 1 + Task 2 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/cafe/cafe_screen.dart test/features/cafe/cafe_screen_test.dart
git commit -m "feat(cafe): render café occupancy, calm-empty when nothing is due (P7)"
```
