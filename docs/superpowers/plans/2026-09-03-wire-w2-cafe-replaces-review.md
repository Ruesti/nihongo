# App-Wiring W2 — the café replaces the review tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route the café into the running app, replacing the bare SRS review feed — the brief's §4 mandate ("Das Café … ersetzt den nackten SRS-Feed vollständig"). The café (`CafeScreen`/`CafeTurnScreen`, built + tested in P7–P9) is currently constructed only in tests. This slice (a) fixes a real gap found during scoping — `CafeTurnScreen` builds `LadderReview(db)` **without** the knowledge bridge, so café reviews would silently NOT project into the shared mining store the way the shipped `ReviewScreen` does; and (b) adds a `CafeRoute` wrapper that pulls the on-ramp `LearningDb` + knowledge bridge from providers, swaps the `/review` route from `ReviewScreen` to the café, and renames the "Review" nav tab to "Café". After this, tapping the bottom-nav Café tab opens the café for real.

**Architecture:** Thread an optional `KnowledgeBridge?` through `CafeScreen` → `CafeTurnScreen` → `LadderReview(db, bridge: …)` (default null keeps every existing café test valid and keeps projection dormant when mining isn't wired, mirroring `knowledgeBridgeProvider`'s own null-default contract). Add `lib/features/cafe/cafe_route.dart` — a tiny `ConsumerWidget` reading `learningDbProvider` + `knowledgeBridgeProvider` and building `CafeScreen`. Edit `lib/app.dart`: the `/review` GoRoute's child becomes `CafeRoute()`, and the nav destination label/icon become "Café". No café behavior changes beyond the bridge being passed.

**Tech Stack:** Dart 3.11 / Flutter, Riverpod, go_router, Drift/SQLite (`LearningDb.forTesting()`, `MiningDb.forTesting()`), `flutter_test`. No new packages.

## Global Constraints

- Base branch: `origin/main` (`f90304c`) — P0–P9 + W1 (German meanings).
- **The bridge param is optional (nullable), default null.** Every existing `CafeScreen(...)`/`CafeTurnScreen(...)` call (all in tests) omits it and must stay valid. `null` bridge → `LadderReview(db)` behaves exactly as today (projection dormant), matching `knowledgeBridgeProvider`'s deliberate null-default (`lib/app/knowledge_providers.dart`).
- **The projection must actually work when a bridge IS supplied.** `CafeTurnScreen` must construct `LadderReview(widget.db, bridge: widget.bridge)` (today it drops the bridge — `cafe_turn_screen.dart:32`). This is the parity fix with `review_screen.dart:118` (`LadderReview(_db, bridge: ref.read(knowledgeBridgeProvider))`). A test proves a café turn with a real `MiningDb`-backed bridge projects the reviewed lexeme into the mining store.
- **`languageId = 'lang_ja'`** in `CafeRoute` (the one seeded pack). The general active-language→pack-id mapping is a broader wiring concern already tracked as a follow-up; do not build a language switcher here.
- **The `/review` path stays** (nav + deep links keep working) — only its screen changes to the café. Do not rename the route path.
- **`ReviewScreen` is not deleted** — it just stops being routed. If removing its `/review` usage makes its `import` in `app.dart` unused, remove that import (analyzer-clean); leave the `review_screen.dart` file itself alone.
- Run tests with `flutter test <path>`. The full suite has 8 pre-existing `test/mining_packs/ja/` native-tokenizer failures, unrelated — "green" means those 8 and no others. A full-suite run in Task 2 is the backstop for any test that navigated to `/review` expecting `ReviewScreen`, or asserted the "Review" label.

---

### Task 1: thread the knowledge bridge through the café

**Files:**
- Modify: `lib/features/cafe/cafe_turn_screen.dart`
- Modify: `lib/features/cafe/cafe_screen.dart`
- Test: `test/features/cafe/cafe_bridge_test.dart` (new)

**Interfaces:** `CafeTurnScreen` + `CafeScreen` each gain `final KnowledgeBridge? bridge;` (optional). `CafeTurnScreen` uses it in `LadderReview`.

- [ ] **Step 1: Write the failing test**

Create `test/features/cafe/cafe_bridge_test.dart`:

```dart
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/pipeline/knowledge_bridge.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart' show Knowledge;
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';

Future<Knowledge> _knows(MiningDb db, String lemma) async {
  final rows = await db.select(db.vocabItems).get();
  final match = rows.where((r) => r.lemma == lemma);
  if (match.isEmpty) return Knowledge.unknown;
  return KnowledgeBridge.knowledgeForRung(match.first.masteryRung);
}

void main() {
  testWidgets('a café turn with a bridge projects the reviewed lexeme into '
      'the shared mining store', (tester) async {
    final learning = LearningDb.forTesting();
    final mining = MiningDb.forTesting();
    addTearDown(() async {
      await learning.close();
      await mining.close();
    });
    await learning.into(learning.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_dog', glossKey: 'dog', partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await learning.into(learning.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_dog', languageId: 'lang_ja', conceptId: 'concept_dog',
        writtenForm: '犬', reading: 'いぬ'));
    await learning.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog',
        rung: 3);

    // Before: mining knows nothing about 犬.
    expect(await _knows(mining, '犬'), Knowledge.unknown);

    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(
        db: learning,
        guest: CafeGuest.schulkind, // rung 3 → productionInput
        bridge: KnowledgeBridge(mining),
      ),
    ));
    await tester.pumpAndSettle();

    // Produce the word (rung-3 prompt is the meaning; answer is the form).
    await tester.enterText(
        find.byKey(const ValueKey('cafe-turn-input')), '犬');
    await tester.tap(find.byKey(const ValueKey('cafe-turn-submit')));
    await tester.pumpAndSettle();

    // After: the graded review projected into mining (rung 3 → known).
    expect(await _knows(mining, '犬'), Knowledge.known);
  });
}
```

Note: if `MiningDb.VocabItems`' column for the lemma is named differently than `lemma`, or `masteryRung` differently, adjust `_knows` to the real column names (check `test/core/ladder/ladder_review_test.dart`'s own `_knows` helper — copy its exact query).

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/cafe/cafe_bridge_test.dart`
Expected: FAIL to compile — `CafeTurnScreen` has no `bridge` parameter.

- [ ] **Step 3: Write the implementation**

In `lib/features/cafe/cafe_turn_screen.dart`:
- Add import: `import '../../core/pipeline/knowledge_bridge.dart';`
- Add the field + constructor param:
```dart
  final KnowledgeBridge? bridge;
```
(after `languageId`), and `this.bridge,` in the constructor.
- Change `late final LadderReview _ladder = LadderReview(widget.db);` to:
```dart
  late final LadderReview _ladder = LadderReview(widget.db, bridge: widget.bridge);
```

In `lib/features/cafe/cafe_screen.dart`:
- Add import: `import '../../core/pipeline/knowledge_bridge.dart';`
- Add the field + constructor param:
```dart
  final KnowledgeBridge? bridge;
```
and `this.bridge,` in the constructor.
- In the guest `ListTile.onTap` push, pass the bridge to the turn:
```dart
                builder: (_) => CafeTurnScreen(
                  db: widget.db,
                  guest: guest,
                  languageId: widget.languageId,
                  bridge: widget.bridge,
                ),
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/cafe/cafe_bridge_test.dart`
Expected: PASS. Then run the whole café suite `flutter test test/features/cafe/` — all existing café tests still pass (bridge defaults null; nothing else changed).

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_turn_screen.dart lib/features/cafe/cafe_screen.dart test/features/cafe/cafe_bridge_test.dart
git commit -m "feat(cafe): thread the knowledge bridge into café reviews (projection parity with ReviewScreen) (W2)"
```

---

### Task 2: `CafeRoute` + swap `/review` to the café

**Files:**
- Create: `lib/features/cafe/cafe_route.dart`
- Modify: `lib/app.dart`
- Test: `test/features/cafe/cafe_route_test.dart` (new)

**Interfaces:** `class CafeRoute extends ConsumerWidget` (no params). `/review` renders it. Nav tab reads "Café".

- [ ] **Step 1: Write the failing test**

Create `test/features/cafe/cafe_route_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/cafe/cafe_route.dart';

void main() {
  testWidgets('CafeRoute builds the café from the on-ramp providers',
      (tester) async {
    final db = LearningDb.forTesting();
    addTearDown(() async => db.close());

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWithValue(db)],
      child: const MaterialApp(home: CafeRoute()),
    ));
    await tester.pumpAndSettle();

    // Nothing due → the café's calm empty state, proving CafeScreen was built
    // from the provider-supplied db (miningDbProvider defaults null → no
    // bridge → still fine).
    expect(find.byKey(const ValueKey('cafe-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/cafe/cafe_route_test.dart`
Expected: FAIL — `cafe_route.dart` does not exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/features/cafe/cafe_route.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/knowledge_providers.dart';
import 'cafe_screen.dart';

/// Routes the café into the app in place of the bare SRS review feed
/// (brief §4 — the café replaces the review screen entirely). Pulls the
/// on-ramp [LearningDb] and the optional knowledge bridge from providers and
/// hands them to [CafeScreen], so café reviews project into the shared mining
/// store exactly as the old ReviewScreen did.
class CafeRoute extends ConsumerWidget {
  const CafeRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(learningDbProvider);
    final bridge = ref.watch(knowledgeBridgeProvider);
    return CafeScreen(db: db, bridge: bridge, languageId: 'lang_ja');
  }
}
```

Edit `lib/app.dart`:
- Add import: `import 'features/cafe/cafe_route.dart';`
- In the `/review` `GoRoute`, change the child from `ReviewScreen()` to `CafeRoute()`:
```dart
      GoRoute(
        path: '/review',
        pageBuilder: (ctx, state) => const NoTransitionPage(
            child: CafeRoute()),
      ),
```
- Rename the nav destination (the one labelled `'Review'`) to the café: change `label: 'Review'` → `label: 'Café'`, and its icons to a café glyph, e.g. `icon: Icon(Icons.local_cafe_outlined)`, `selectedIcon: Icon(Icons.local_cafe)`.
- Remove the now-unused `import 'features/review/review_screen.dart';` (only if `grep -n ReviewScreen lib/app.dart` shows no remaining use after the swap — it shouldn't).

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/cafe/cafe_route_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the full suite**

Run: `flutter test`
Expected: green apart from the 8 pre-existing `mining_packs/ja` failures. This catches any test that pumped the router and expected `ReviewScreen` at `/review`, or asserted the `'Review'` nav label — update such a test to expect the café / `'Café'` label (reflect the intended new behavior; never weaken). If a failure is NOT about the review→café swap, STOP and report it.

- [ ] **Step 6: Commit**

```bash
git add lib/features/cafe/cafe_route.dart lib/app.dart test/features/cafe/cafe_route_test.dart
git commit -m "feat(app): the Café tab replaces the review feed at /review (W2)"
```
