# BERICHT 4 — Knowledge Model + Bootstrap Import

**Phase:** 4 — Knowledge model + bootstrap import (SPEC_MINING_PIPELINE.md §10)
**Gate criterion:** Existing knowledge importable; re-running Phase 3 over the same source yields a demonstrably different ranking.
**Verdict: PASS.**

---

## What was built

### Real FSRS integration (`lib/core/pipeline/`)

Phase 3's `FrequencyBootstrapKnowledge` checked frequency rank directly as a stand-in `KnowledgeSource` — useful to prove the scoring formulas, but not the real answer to "what counts as known" (§0.4.13 decided: FSRS stability threshold). This phase replaces it with the real thing:

- **`fsrs_knowledge_source.dart`**: `FsrsKnowledgeSource` loads `VocabItems` joined with `Cards` from `MiningDb`, builds an in-memory `lemma -> (state, stability)` map once (same synchronous-seam reasoning as `JaLanguagePack`'s dictionary/reading indexes), and classifies each lemma:
  - No `Cards` row at all -> `unknown` (never encountered)
  - `Cards.state == review` at/above a stability threshold -> `known`
  - Everything else (including `state == review` below threshold, or `learning`/`relearning`) -> `learning`
- **`fsrs_bootstrap_import.dart`**: implements §0.4.14's "mark first N of frequency list as known" bootstrap for real — creates `VocabItems` + `Cards` rows for the top-N most common lemmas via `FrequencyList.topLemmas(n)` (a new method; the seam only had single-lemma `rank()` lookup before, which can't answer "give me the N most common words").

### An honest choice: simulated review history, not a fabricated number

The naive way to mark a card "known" is to hand-set `stability: 999`. Instead, `simulateWellKnownCard()` runs the **real FSRS algorithm forward** — four straight `Rating.easy` reviews, each jumping to the card's own computed due date — and uses whatever stability that produces. This is what genuine review history for an already-mastered word actually looks like; it's FSRS run forward, not worked around. Measured trajectory (this session's FSRS parameters):

| Review # | Stability (days) | Next due |
|---|---|---|
| 1 | 5.8 | +7 days |
| 2 | 43.2 | +43 days |
| 3 | 270.8 | +271 days |
| 4 | 1497.1 | +1497 days |

The default known-threshold (`knownStabilityThreshold: 5.0`) is comfortably cleared after just the first simulated review, with three more reviews of margin baked into the bootstrap.

### `FrequencyList.topLemmas(n)` — a seam addition

The four-seam interfaces (§2.2) are meant to be stable, but this phase needed something the original design didn't anticipate: enumerating a frequency list's contents, not just looking up one lemma. Added `List<String> topLemmas(int n)` to `FrequencyList`, implemented in both `JaLanguagePack`'s real corpus-backed list and `StubLanguagePack`'s empty one (returns `[]`) — the second, data-free pack stays a genuine proof that the seam generalizes, not just JA's.

### `Cards` table: fixed to match the real `fsrs` package

Phase 2's `Cards` schema (`state, step, stability, difficulty, due, lastReview`) was designed against pub.dev's documentation page for the `fsrs` package — which, it turns out, describes a different/newer API shape than what `fsrs: ^1.0.0` actually resolves to (`1.1.1`, confirmed by reading the installed package source directly rather than trusting the fetched docs a second time). The real `Card` class has no `cardId`/`step`; it has `elapsedDays`, `scheduledDays`, `reps`, `lapses` instead. Schema updated to match reality — no migration needed, since nothing had shipped real data against the old shape yet.

## Measured evidence

`tool/phase4_bootstrap_and_rerank.dart` scores the **same** synthetic 5,000-cue SRT from Phase 3 twice — once against an empty knowledge base, once immediately after a real bootstrap import — and diffs the resulting i+1 candidate sets:

```
=== Pass 1: baseline (no knowledge imported) ===
i+1 candidates: 7

=== Bootstrap import ===
lemmas marked known: 1500
elapsed: 79 ms

=== Pass 2: after bootstrap import (same SRT, same source) ===
i+1 candidates: 1662

=== Phase 4 gate: demonstrably different ranking? ===
candidates only in baseline:        5
candidates only after import:       1660
top-10 identical before vs after:   false
GATE: PASS (ranking changed)

sample: a sentence whose status flipped from baseline to after:
"素晴らしい話だ！"
baseline unknownCount: 3 -> after: 0 (fully known now)
```

With nothing marked known, only 7 of 5,000 segments happen to have exactly one unknown word by chance — expected, since most sentences contain several words at all. After bootstrapping the top 1,500 most common lemmas as known (79ms), the i+1 pool grows to 1,662: sentences that previously had 2+ unknown words now have exactly one, becoming real i+1 candidates; a handful of previously-valid candidates (5) graduate out of the pool entirely because their one unknown word is now known too. Both directions of movement are exactly what the mechanism should do, not just "some numbers changed."

## Deferred, honestly

§0.4.14 decided three bootstrap paths for v1: frequency-list (built, above), Anki collection import (.apkg/AnkiConnect), and WaniKani level import. Only the frequency-list path is implemented this phase — it's the one the gate criterion actually requires ("existing knowledge importable," proven) and needs no external file-format parsing or API auth. Anki's `.apkg` format (a zip containing a specific SQLite schema) and WaniKani's API (requires a user API key) are each a real, separate integration effort with their own failure modes to design for properly — deferred rather than rushed, same discipline as the JA-tokenizer-in-Android deferral from Phase 2/3.

## Gate verdict

**PASS.** Real FSRS-backed knowledge state, a genuine (not fabricated) bootstrap import path, and a dramatic, clearly-attributable before/after ranking change on the same source — 7 candidates growing to 1,662, with concrete examples of sentences moving in and out of the pool for the right reason.

---
*Softbrew Studio — Phase 4 proof report — 2026-07-31.*
