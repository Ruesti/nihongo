# Phase 3: Script Games — Flag-Driven, SRS-Queue-Fed

**Goal:** Implement `core/games/` module: `GameType` enum, `GameSpec` record, `gameAvailability(scriptProfile)` pure function, and `GameQueue` DB service. Prove with JA kana tests.

**Architecture:**
- `game_availability.dart` — pure function, no DB. Maps `ScriptProfile` → `List<GameSpec>` via flag table from spec §5.
- `game_queue.dart` — DB-backed. `getDue(spec, langId)` queries `learn_items` by rung and due date.
- `GameSpec` is a Dart record `({GameType type, int rung})`. `rung=0` = toneVowelMatch (any rung).

**Spec §5 mapping (flag → game → rung):**
```
mnemonicMatch  rung1   isDecomposable
readingBlitz   rung2   always
componentBuild rung3   isDecomposable && scriptType != alphabet
wordBuild      rung3   scriptType == alphabet
positionalForm rung3   positionalForms
positionalForm rung4   positionalForms
writeTrace     rung4   always
kanjiCompound  rung5   logographic
wordBuild      rung5   !logographic
toneVowelMatch rung0   hasToneSystem
```

---

## File Map

| File | Action |
|---|---|
| `lib/core/games/game_availability.dart` | Create — `GameType` enum, `GameSpec` typedef, `gameAvailability()` |
| `lib/core/games/game_queue.dart` | Create — `GameQueue` service |
| `test/core/games/game_availability_test.dart` | Create — pure function tests (4 profiles) |
| `test/core/games/game_queue_test.dart` | Create — DB integration tests |

---

### Task 1: game_availability.dart + tests

- [ ] Write failing tests (game_availability_test.dart)
- [ ] Implement game_availability.dart
- [ ] Confirm tests pass + no regressions
- [ ] Commit: `feat(phase3): GameType enum + gameAvailability — flag-driven per spec §5`

### Task 2: game_queue.dart + tests

- [ ] Write failing tests (game_queue_test.dart)
- [ ] Implement game_queue.dart
- [ ] Confirm all tests pass + flutter analyze clean
- [ ] Commit: `feat(phase3): GameQueue — SRS-queue-fed item fetching per game spec`

### Task 3: Final verification

- [ ] `flutter test` → expected: 54 + N new tests PASS
- [ ] `flutter analyze` → 0 errors
- [ ] `git log --oneline -5`
