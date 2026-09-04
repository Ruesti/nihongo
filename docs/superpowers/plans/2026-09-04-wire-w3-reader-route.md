# App-Wiring W3 — the reader is reachable (final slice) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The last app-wiring slice — make the story reader reachable in the running app, so the whole engine is experienceable end to end. The reader (`StoryReaderScreen`) + all its services exist and are tested but are only constructed in tests today. This slice: (1) promotes the pilot episode + its German dictionary out of `test/` into `lib/` so the app can load them (the fixtures become re-exports, so every test keeps compiling); (2) fixes the two remaining "mining languageCode defaults to the pack id" bugs (the reader's `DiegeticEncounter` and the conversation error path), so all projections land in the canonical `'ja'` bucket like the café now does; (3) adds a Home "read episode" banner, a top-level `/story` route, and a `StoryRoute` wrapper that pulls the db/bridge/language from providers, resolves `SharedPreferences` + a `knownIds` query, and builds the reader with every service wired (TTS, speak/trace evaluators, and the SRS handoff/encounter callbacks). After this, tapping the Home banner opens Folge 01 with working audio, dictionary, speak/trace moments, and SRS handoff.

**Architecture:** Mirror the `CafeRoute` pattern (W2). Promotion is a pure code move (const map + const list) with re-exports. The two languageCode fixes are one-line derivations (`languageId.replaceFirst('lang_', '')` → `'ja'`), no constructor changes. `StoryRoute` is a `ConsumerWidget` that reads `learningDbProvider` + `knowledgeBridgeProvider` + `activeLanguageProvider`, then uses a `FutureBuilder` to resolve the async deps (`SharedPreferences` for `StoryProgressStore`, and the `knownIds` query) before building `StoryReaderScreen`. The SRS callbacks (`onEpisodeComplete` → `EpisodeSrsHandoff`, `onDiegeticSpeakSuccess`/`onDiegeticTraceSuccess` → `DiegeticEncounter`) are fire-and-forget with a `.catchError` guard (the deferred-flag concern from earlier phases). The `/story` route is a **top-level pushed** `GoRoute` (outside the shell, no bottom nav — reading is immersive, like `/lesson/:id`).

**Tech Stack:** Dart 3.11 / Flutter, Riverpod, go_router, Drift/SQLite, `shared_preferences`, `flutter_test`. Reuses all P0–P9 story services + W1/W2. No new packages.

## Global Constraints

- Base branch: `origin/main` (`a2423d9`) — P0–P9 + W1 (German meanings) + W2 (café route).
- **Promotion keeps every importer working.** Move `pilot01RegenJson` (from `test/fixtures/story/pilot_01_regen_fixture.dart`, a self-contained `const Map<String,dynamic>` with no imports) into `lib/packs/ja/pilot_01_regen.dart`, and `folge01DictionaryEntries` (from `test/fixtures/story/folge_01_dictionary_fixture.dart`, imports `DictionaryEntry` from lib) into `lib/packs/ja/folge_01_dictionary.dart`. Then replace each `test/fixtures/story/*.dart` file's body with a single `export 'package:nihongo_app/packs/ja/<name>.dart';`. The symbols keep their names, so all 5+4 importing test files compile unchanged. Do NOT change any importing test.
- **languageId vs languageCode (the convention this app uses everywhere):** `languageId` = the on-ramp pack id `'lang_ja'` (used for `getDueItems`, `introduce`, `learn_items.languageId`); `languageCode` = the BCP-47 mining code `'ja'` (used by `KnowledgeBridge` to key `vocab:$code:$lemma`). Derive one from the other by `'lang_'`-prefix. This is the same fix W2 applied to the café; W3 applies it to `DiegeticEncounter` + the conversation path.
- **`DiegeticEncounter` fix must not break its callers.** Do NOT add a required ctor field. In `encounter`, change `ladder.markEncountered(item)` → `ladder.markEncountered(item, languageCode: languageId.replaceFirst('lang_', ''))`. Existing `DiegeticEncounter(ladder:, languageId:)` construction stays valid.
- **`knownIds` = every introduced item.** `(db.select(db.learnItems)..where((t) => t.languageId.equals('lang_ja'))).get()` mapped to `refId` as a `Set<String>` (any rung — an introduced item is "known" for the dictionary's meaning display; `DictionaryEntry.id` matches `learn_items.refId`, e.g. `lex_ja_ame`).
- **`StoryRoute` reads the active language.** `languageCode = ref.watch(activeLanguageProvider)` (a `StateProvider<String>` defaulting `'ja'`, `lib/features/language_select/language_select_screen.dart`); `languageId = 'lang_$languageCode'`. `EpisodeSrsHandoff`/`DiegeticEncounter` take `languageId`; the reader's `speakEvaluator` is `SttSpeakEvaluator()` (default `ja_JP`), `traceEvaluator` is `const KanaTraceEvaluator()`, `speak` is `TtsService.instance.speak`.
- **`/story` is a top-level pushed route** (outside the `ShellRoute`), like `/lesson/:id` — no bottom nav. Reached via a new Home banner (`context.push('/story')`), mirroring `_TravelBanner`.
- **Fire-and-forget SRS callbacks get `.catchError`** so a DB error in the handoff/encounter doesn't become an unhandled zone error (the deferred concern from P5b/P6).
- Run tests with `flutter test <path>`. The full suite has 8 pre-existing `test/mining_packs/ja/` native-tokenizer failures, unrelated — "green" means those 8 and no others. A full-suite run is the backstop that the promotion re-exports keep every fixture importer compiling.

---

### Task 1: promote the pilot episode + dictionary into `lib/`

**Files:**
- Create: `lib/packs/ja/pilot_01_regen.dart` (holds `const Map<String, dynamic> pilot01RegenJson`)
- Create: `lib/packs/ja/folge_01_dictionary.dart` (holds `const List<DictionaryEntry> folge01DictionaryEntries`)
- Modify: `test/fixtures/story/pilot_01_regen_fixture.dart` → one-line re-export
- Modify: `test/fixtures/story/folge_01_dictionary_fixture.dart` → one-line re-export

- [ ] **Step 1: Move the content**

Copy the ENTIRE current body of `test/fixtures/story/pilot_01_regen_fixture.dart` (the `const Map<String, dynamic> pilot01RegenJson = {...};`, verbatim, including any leading doc comment) into a new `lib/packs/ja/pilot_01_regen.dart`. It has no imports, so nothing else moves.

Copy the ENTIRE current body of `test/fixtures/story/folge_01_dictionary_fixture.dart` (its `import 'package:nihongo_app/features/story/dictionary.dart';` + `const List<DictionaryEntry> folge01DictionaryEntries = [...];`, verbatim) into a new `lib/packs/ja/folge_01_dictionary.dart`.

- [ ] **Step 2: Replace the fixtures with re-exports**

Replace the whole body of `test/fixtures/story/pilot_01_regen_fixture.dart` with:
```dart
// The pilot episode content lives in lib/ so the app can load it (W3).
// This fixture path is kept as a re-export so existing test importers are
// unchanged.
export 'package:nihongo_app/packs/ja/pilot_01_regen.dart';
```
Replace the whole body of `test/fixtures/story/folge_01_dictionary_fixture.dart` with:
```dart
export 'package:nihongo_app/packs/ja/folge_01_dictionary.dart';
```

- [ ] **Step 3: Verify every importer still compiles**

Run: `flutter test test/features/story/ test/fixtures/story/`
Expected: PASS — every test that imports `pilot01RegenJson` / `folge01DictionaryEntries` (via the fixture path) resolves the symbol through the re-export unchanged. Then run the full suite `flutter test` — green apart from the 8 pre-existing `mining_packs/ja` failures.

- [ ] **Step 4: Commit**

```bash
git add lib/packs/ja/pilot_01_regen.dart lib/packs/ja/folge_01_dictionary.dart test/fixtures/story/pilot_01_regen_fixture.dart test/fixtures/story/folge_01_dictionary_fixture.dart
git commit -m "refactor(story): promote pilot episode + dictionary into lib/ (re-export from fixtures) (W3)"
```

---

### Task 2: fix the two remaining mining-languageCode defaults

**Files:**
- Modify: `lib/features/story/diegetic_encounter.dart`
- Modify: `lib/core/conversation/conversation_service.dart`
- Test: `test/features/story/diegetic_encounter_bridge_test.dart` (new)

- [ ] **Step 1: Write the failing test** (proves the reader's diegetic encounter projects under `'ja'`)

Create `test/features/story/diegetic_encounter_bridge_test.dart` — model it on `test/features/cafe/cafe_bridge_test.dart` (read that file for the exact `MiningDb` read pattern, e.g. `FsrsKnowledgeSource.load` or the `_knows` helper it uses):

```dart
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/pipeline/knowledge_bridge.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart' show Knowledge;
import 'package:nihongo_app/features/story/diegetic_encounter.dart';

// COPY the exact mining-knowledge read helper from cafe_bridge_test.dart here
// (same VocabItems⋈Cards / FsrsKnowledgeSource pattern), named _knows.

void main() {
  test('a diegetic encounter projects the item into mining under "ja", not '
      '"lang_ja"', () async {
    final learning = LearningDb.forTesting();
    final mining = MiningDb.forTesting();
    addTearDown(() async {
      await learning.close();
      await mining.close();
    });
    await learning.into(learning.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_rain', glossKey: 'rain', partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await learning.into(learning.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ame', languageId: 'lang_ja', conceptId: 'concept_rain',
        writtenForm: 'あめ', reading: 'あめ'));

    final enc = DiegeticEncounter(
      ladder: LadderReview(learning, bridge: KnowledgeBridge(mining)),
      languageId: 'lang_ja',
    );
    await enc.encounter(RefType.lexeme, 'lex_ja_ame');

    // markEncountered → rung 1 → Knowledge.learning, projected under 'ja'.
    expect(await _knows(mining, 'あめ', 'ja'), Knowledge.learning);
    // Nothing under the wrong 'lang_ja' bucket.
    final wrong = await (mining.select(mining.vocabItems)
          ..where((t) => t.languageCode.equals('lang_ja')))
        .get();
    expect(wrong, isEmpty);
  });
}
```
(Adjust `_knows`'s signature/columns to match whatever `cafe_bridge_test.dart` actually uses — copy it exactly, including how it scopes by languageCode.)

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/story/diegetic_encounter_bridge_test.dart`
Expected: FAIL — `DiegeticEncounter.encounter` calls `markEncountered(item)` with no languageCode, so the projection lands under `'lang_ja'` (the negative assertion fails / the positive under `'ja'` is empty).

- [ ] **Step 3: Implement the two fixes**

In `lib/features/story/diegetic_encounter.dart`, `encounter`: change
```dart
      await ladder.markEncountered(item);
```
to
```dart
      // Mining keys by BCP-47 code ('ja'), not the pack id ('lang_ja') —
      // same convention as ReviewScreen/KnowledgeBoot/the café.
      await ladder.markEncountered(item,
          languageCode: languageId.replaceFirst('lang_', ''));
```

In `lib/core/conversation/conversation_service.dart`, `onError`: change
```dart
    await review.submit(existing, ReviewResult.again);
```
to
```dart
    await review.submit(existing, ReviewResult.again,
        languageCode: span.languageId.replaceFirst('lang_', ''));
```
(Check `ErrorSpan` — if it already exposes a BCP-47 `languageCode` field, use that instead of stripping; otherwise the strip matches the app-wide convention.)

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/story/diegetic_encounter_bridge_test.dart test/core/conversation/`
Expected: PASS (the diegetic projection now under `'ja'`; existing conversation tests still green — if a conversation test asserted a mining projection under `'lang_ja'`, update it to `'ja'`). Then the full suite `flutter test` — green apart from the 8 pre-existing failures.

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/diegetic_encounter.dart lib/core/conversation/conversation_service.dart test/features/story/diegetic_encounter_bridge_test.dart
git commit -m "fix(story,conversation): project reviews under BCP-47 'ja', not the pack id 'lang_ja' (W3)"
```

---

### Task 3: `StoryRoute` + Home banner + `/story` route

**Files:**
- Create: `lib/features/story/story_route.dart`
- Modify: `lib/features/home/home_screen.dart` (add a story banner)
- Modify: `lib/app.dart` (register `/story`)
- Test: `test/features/story/story_route_test.dart` (new)

**Interfaces:** `class StoryRoute extends ConsumerWidget` (no params). `/story` renders it; a Home banner pushes it.

- [ ] **Step 1: Write the failing test**

Create `test/features/story/story_route_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/story/story_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('StoryRoute wires the pilot reader from the on-ramp providers',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = LearningDb.forTesting();
    addTearDown(() async => db.close());

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWithValue(db)],
      child: const MaterialApp(home: StoryRoute()),
    ));
    await tester.pumpAndSettle();

    // The reader mounted (its tap-to-advance panel is present).
    expect(find.byKey(const ValueKey('story-reader-panel')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/story/story_route_test.dart`
Expected: FAIL — `story_route.dart` does not exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/features/story/story_route.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/knowledge_providers.dart';
import '../../core/db/learning_db.dart';
import '../../core/ladder/ladder_review.dart';
import '../../core/ladder/rung_defs.dart';
import '../../core/tts_service.dart';
import '../../packs/ja/folge_01_dictionary.dart';
import '../../packs/ja/pilot_01_regen.dart';
import '../language_select/language_select_screen.dart' show activeLanguageProvider;
import 'diegetic_encounter.dart';
import 'episode.dart';
import 'episode_srs_handoff.dart';
import 'speak_evaluator.dart';
import 'story_progress_store.dart';
import 'story_reader_screen.dart';
import 'trace_evaluator.dart';

/// Routes the story reader into the app (W3). Pulls the on-ramp db, the
/// optional knowledge bridge, and the active language from providers,
/// resolves SharedPreferences + the learner's introduced-item ids, and builds
/// the reader with every service wired: TTS, the speak/trace evaluators, the
/// episode-complete SRS handoff, and the diegetic speak/trace encounters. A
/// full-screen pushed route (no bottom nav) — reading is immersive.
class StoryRoute extends ConsumerWidget {
  const StoryRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(learningDbProvider);
    final bridge = ref.watch(knowledgeBridgeProvider);
    final code = ref.watch(activeLanguageProvider); // BCP-47, e.g. 'ja'
    final languageId = 'lang_$code';
    final episode = Episode.fromJson(pilot01RegenJson);

    return FutureBuilder<(SharedPreferences, Set<String>)>(
      future: _load(db, languageId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final (prefs, knownIds) = snap.data!;
        final ladder = LadderReview(db, bridge: bridge);
        final handoff =
            EpisodeSrsHandoff(ladder: ladder, languageId: languageId);
        final encounter =
            DiegeticEncounter(ladder: ladder, languageId: languageId);

        Future<void> encounterAll(List<String> itemIds) async {
          for (final id in itemIds) {
            await encounter.encounter(RefType.lexeme, id);
          }
        }

        return StoryReaderScreen(
          episode: episode,
          progressStore: StoryProgressStore(prefs),
          speak: TtsService.instance.speak,
          dictionaryEntries: folge01DictionaryEntries,
          knownIds: knownIds,
          onEpisodeComplete: () =>
              handoff.introduceEpisode(episode).catchError((_) {}),
          speakEvaluator: SttSpeakEvaluator(),
          onDiegeticSpeakSuccess: (ids) => encounterAll(ids).catchError((_) {}),
          traceEvaluator: const KanaTraceEvaluator(),
          onDiegeticTraceSuccess: (ids) => encounterAll(ids).catchError((_) {}),
        );
      },
    );
  }

  Future<(SharedPreferences, Set<String>)> _load(
      LearningDb db, String languageId) async {
    final prefs = await SharedPreferences.getInstance();
    final rows = await (db.select(db.learnItems)
          ..where((t) => t.languageId.equals(languageId)))
        .get();
    return (prefs, rows.map((r) => r.refId).toSet());
  }
}
```

Edit `lib/app.dart` — add a top-level `GoRoute` for `/story` (outside the `ShellRoute`, next to `/lesson/:id`):
```dart
import 'features/story/story_route.dart';
```
```dart
      GoRoute(
        path: '/story',
        builder: (ctx, state) => const StoryRoute(),
      ),
```

Edit `lib/features/home/home_screen.dart` — add a `_StoryBanner` mirroring `_TravelBanner` (its own `InkWell` → `context.push('/story')`, e.g. text "Folge 01 — Regen" / "Die erste Manga-Folge lesen"), and place it in the Home `Column` near the travel banner. Keep `_TravelBanner` unchanged; just add the sibling.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/story/story_route_test.dart`
Expected: PASS — after the FutureBuilder resolves, the reader's `story-reader-panel` is present.

- [ ] **Step 5: Run the full suite**

Run: `flutter test`
Expected: green apart from the 8 pre-existing `mining_packs/ja` failures. If a Home-screen test asserted the exact banner set, update it to include the story banner (reflect the new entry; never weaken). If a failure is unrelated to W3, STOP and report.

- [ ] **Step 6: Commit**

```bash
git add lib/features/story/story_route.dart lib/app.dart lib/features/home/home_screen.dart test/features/story/story_route_test.dart
git commit -m "feat(app): the reader is reachable — Home banner + /story route wiring Folge 01 (W3)"
```
