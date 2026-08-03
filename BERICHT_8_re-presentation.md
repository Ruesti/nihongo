# BERICHT 8 — Passage Snapshot + Re-Presentation

**Phase:** 8 — passage_snapshot + re-presentation (SPEC_MINING_PIPELINE.md §10)
**Gate criterion:** A passage read in Phase 6 is re-offered and a real delta is computed and displayed, including a negative one.
**Verdict: PASS.**

---

## What was built

### Snapshot capture + delta (`core/pipeline/passage_snapshot.dart`)

- **`computeUnknownRatio(tokens, knowledgeOf)`** — §7's primary
  re-presentation metric: the fraction of a passage's *content* tokens
  (punctuation excluded, reusing Phase 3's `isContentToken` — made
  public this phase so the two definitions can't diverge, already
  covered by the punctuation-exclusion tests) whose lemma is `unknown`.
- **`recordPassageSnapshot(...)`** — appends one immutable
  `PassageSnapshots` row per reading (§7: "written as an immutable
  passage_snapshot"). Every read appends; snapshots are never updated,
  so a delta between two of them is always traceable to records that
  can't have been altered afterward (§4, same discipline as
  `review_log`).
- **`PassageDelta`** — the measured change between two readings. Carries
  the raw before/after values and names the direction *honestly*:
  `isImprovement` (unknown ratio dropped) and `isRegression` (it rose)
  are equally real; there is no path that hides a regression.
- **`latestPassageDelta(...)`** — the delta between a passage's two most
  recent readings, or `null` if it hasn't been read twice yet (§8's
  graceful "no delta exists" empty state).

### The Then/Now display (`features/reader/re_presentation.dart`)

`RePresentationView` renders the delta: the unknown-ratio Then→Now as
the headline, lookups and dwell as secondary signals (dwell shown with
less weight and omitted entirely when either reading lacks it, per §7's
"dwell is noisy"). Critically, a **regression is displayed plainly** —
an upward arrow, the harder-now percentages, and a headline that says
so ("schwerer geworden"). There is no "hide if negative" branch: §0.9.29
says "the whole credibility of the instrument rests on this," so the
widget cannot suppress it. No score, no streak (I3) — these are real
retention measurements, not invented currency.

## Measured evidence

### The display half — enforced by test

`re_presentation_test.dart` verifies both directions on the widget: an
improvement shows a downward arrow and the dropped percentages; a
**regression shows an upward arrow, the risen percentages, and the
"schwerer geworden" headline** — asserted present, not hidden. Plus:
lookups shown as a secondary line, dwell shown only when both readings
recorded it.

### The data round-trip half — on real content

`tool/phase8_re_presentation.dart` reads a real passage from the 羅生門
EPUB twice with a changed knowledge state between readings, records an
immutable snapshot each time, and computes the delta — for both an
improvement and a regression:

```
passage: 12 spans, 106 distinct dictionary lemmas

=== Re-presentation — improvement ===
  DAMALS 55%   →   JETZT 9%   ↓ leichter
  isImprovement=true  isRegression=false  Δ=-46pp

=== Re-presentation — REGRESSION (shown, not hidden) ===
  DAMALS 11%   →   JETZT 38%   ↑ schwerer geworden
  isImprovement=false  isRegression=true  Δ=27pp

=== Phase 8 gate ===
immutable snapshots recorded: 4
improvement delta computed:   true
regression delta shown:       true (Δ +27pp)
GATE: PASS
```

A real 12-span passage of 羅生門, read first as a novice (55% of its
content unknown) then after learning (9% unknown) → a −46pp
improvement. And the same passage read first while known (11% unknown)
then after forgetting over months (38% unknown) → a +27pp regression,
computed and surfaced honestly. Four immutable snapshots on disk, two
real deltas, one of them negative and shown — exactly the gate
criterion.

## A note on the knowledge model in the proof

The tool models "the reader's vocabulary at a point in time" as "the N
most frequent lemmas in the passage are known" (common words learned
first), varying N up to model learning and down to model forgetting.
That's a stand-in for the real FSRS-derived knowledge state (Phase 4/7)
— appropriate here because Phase 8's gate is about snapshot capture and
delta computation, not about *how* knowledge is determined, which is
already its own proven layer. The snapshots and deltas themselves use
the exact production code paths.

## Gate verdict

**PASS.** Passages are snapshotted immutably on each reading, the delta
between two readings is computed from those records, and it is
displayed honestly in both directions — the negative case demonstrated
on real 羅生門 text (a +27pp regression, surfaced not suppressed) and
enforced by a widget test. The instrument's credibility clause (§0.9.29)
holds. Proceed to Phase 9.

---
*Softbrew Studio — Phase 8 proof report — 2026-08-03.*
