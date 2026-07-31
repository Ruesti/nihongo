# BERICHT 3 — Pipeline Stages 1–4, Headless

**Phase:** 3 — Pipeline stages 1–4, headless (SPEC_MINING_PIPELINE.md §10)
**Gate criterion:** One SRT in → ranked `ScoredSegment` list out, as a CLI/test harness. Perf gate from §3 met (< 10s for a full novel).
**Verdict: PASS.**

---

## What was built

Four pieces, each landing as its own PR since three of them are independently useful and two turned out not to depend on each other at all:

1. **SRT source adapter** (`core/sources/`, PR #5) — the §2.1 "Segmentation" stage. Language-blind SRT parser + adapter producing `Works`/`Sources`/`TextSpans` rows with `TimeAnchor` data.
2. **Native JA tokenizer** (`native/ja_tokenizer/` + `mining_packs/ja/native_tokenizer*.dart`, PR #6) — the "Tokenizer" stage. Lindera 4.0.0 + embedded IPADIC (the exact setup proven on-device in Phase 1) via a plain `dart:ffi` binding to a host-compiled library, deliberately skipping the Android/Gradle/cargokit machinery this headless phase doesn't need.
3. **JA frequency list from Tatoeba** (`mining_packs/ja/frequency_*.dart`, PR #7) — feeds "Lemma normalisation"/"Knowledge lookup"'s frequency-rank input. BCCWJ/JPDB (§2.2's named JA sources) aren't cleared for a commercial product; Tatoeba is a legally uncomplicated, already-approved stand-in.
4. **Sentence scoring** (`core/pipeline/sentence_scoring.dart`, this PR) — the "Knowledge lookup → Sentence scoring" stages, implementing §3's formulas and candidate-ranking rules exactly.

## Sentence scoring, in detail

`scoreSegment` computes, per §3:
```
unknownCount = |{t : knowledge(t.lemma) == unknown}|
knownRatio   = |{t : knowledge == known}| / |tokens|
```
`rankCandidates` sorts the `unknownCount == 1` pool by the spec's descending-priority rules: lower frequency rank of the target lemma, then segment length within `[minLen, maxLen]`, then presence of a time anchor (audio available). `secondaryCandidates` collects the `unknownCount == 2` pool, per §3 "retained as a secondary pool, surfaced only when the i+1 pool is exhausted."

Kept fully language-blind, per the file's own seam-discipline rule — it takes a `Tokenizer`, a `FrequencyList`, and an injected `KnowledgeSource` (`Knowledge Function(String lemma)`) as parameters and never branches on language. `KnowledgeSource` is deliberately abstract: Phase 3 only needs *a* knowledge source to prove the formulas; how "known" gets determined for real (FSRS stability, per §0.4.13) is separate, later integration work with the `Cards`/`ReviewLogs` tables. For this phase, `FrequencyBootstrapKnowledge` implements the already-decided §0.4.14 bootstrap ("mark first N of frequency list as known") — the first concrete use of a decision made during the interview gate.

### A bug the pipeline caught on itself

The first end-to-end run surfaced real Japanese punctuation (`。`, `？`) as "the word to learn," because punctuation tokens have no frequency rank and were being counted as `unknown` — a sentence where every real word was already known but ended in a period had `unknownCount == 1` with the period as the "target." Fixed by excluding punctuation-only tokens (matched via Unicode `\p{P}`/`\p{S}` categories, not a tokenizer-specific POS tag — that would've leaked an IPADIC-specific convention into language-blind code) from the counting logic, while keeping them in `ScoredSegment.tokens` for rendering purposes. A second, related bug — a CLI display helper re-deriving "which token is the unknown one" by re-scanning the *unfiltered* token list — reintroduced the same failure mode for the printed label even after the counting fix; resolved by having `scoreSegment` expose `targetLemma` directly instead of leaving every consumer to rederive it.

## Measured evidence

`tool/phase3_pipeline_gate.dart` ties all four pieces together: imports an SRT, tokenizes and scores every cue, ranks candidates, reports timing. Run against:
- A synthetic 5,000-cue SRT generated from the Tatoeba JA corpus (CC-BY, already-approved source, §0.5.17) — not a real 24-minute episode transcript, to avoid any copyright question around actual show subtitles for what is explicitly a mechanical pipeline-proof, not the full v1 acceptance demo (§0.7, a separate later milestone using real content)
- The real, full JMdict_e (218,173 entries)
- The real, full Tatoeba frequency corpus (36,250 ranked lemmas)

```
=== Phase 3 gate: SRT -> ranked ScoredSegment list ===
segments (cues):      5000
i+1 candidates:        1662
secondary pool (i+2):   987
elapsed:                729 ms (gate: < 10000 ms)
PERF GATE: PASS

top 10 i+1 candidates:
[rank 1501] 職   <- "職探しはどうなったの？"
[rank 1502] 奪う <- "私は千円しか奪われなかった。"
[rank 1503] 案内 <- "彼はヨーロッパ旅行の案内をした。"
[rank 1503] 案内 <- "彼は私の案内をしてくれた。"
[rank 1507] 泳ぎ <- "トムって、あなたと一緒に泳ぎに行ったの？"
[rank 1507] 泳ぎ <- "雨が降ろうが、明日俺は泳ぎに行くからな。"
[rank 1514] 踊る <- "踊りましょうか。"
[rank 1514] 踊る <- "私と踊っていただけませんか。"
[rank 1514] 踊る <- "彼女は踊るのを見られました。"
[rank 1515] 富士山 <- "富士山にもう一度登れば４回登ったことになります。"
```

729ms for 5,000 segments — roughly two orders of magnitude inside the 10-second budget, and 5,000 cues is already a generous stand-in for "a full novel" (a 24-minute episode SRT is typically a few hundred cues; even a long novel rarely exceeds a few thousand sentences). Every target lemma in the sample is a real, sensible word — no punctuation, no artifacts.

## Another toolchain fix along the way

`dart run` on any tool importing both `core/db/mining_db.dart` (which imported `path_provider`/`flutter_riverpod`, Flutter-only) and the native-tokenizer FFI code crashed the kernel compiler outright (`Crash when compiling: type 'InvalidType' is not a subtype of type 'FunctionType' in type cast`, inside the FFI use-site transformer) rather than failing cleanly — mixing an unresolvable Flutter-only import with `dart:ffi` code in the same compilation unit apparently confuses that specific compiler pass. Fixed the same way `jmdict_db.dart` and `frequency_db.dart` already were in earlier phases: removed the `path_provider`/`flutter_riverpod` imports from `mining_db.dart` (nothing in the app used the affected constructor/provider yet) and added a `MiningDb.at(File)` constructor. Worth remembering for any future file that needs to work under both `flutter test` and plain `dart run`.

## Gate verdict

**PASS.** All four pipeline-stage prerequisites work individually and end-to-end; the perf gate is met with wide margin; a real correctness bug (punctuation as a false target) was caught by actually running the pipeline against real data rather than assumed away, and is fixed with a test guarding against regression. Proceed to Phase 4.

---
*Softbrew Studio — Phase 3 proof report — 2026-07-31.*
