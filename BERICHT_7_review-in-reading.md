# BERICHT 7 — Scheduling Woven Into Reading (No Review Screen)

**Phase:** 7 — Scheduling woven into reading, no review screen (SPEC_MINING_PIPELINE.md §10)
**Gate criterion:** A due item is surfaced in reading flow and graded without leaving the reader.
**Verdict: PASS.**

---

## What was built

### The grading write-path (`core/pipeline/`)

Phase 4 only ever *read* FSRS state (knowledge lookup) or *seeded* it
(bootstrap). This phase adds the first path where a real user review
*mutates* a card:

- **`fsrs_mapping.dart`** — the DB `Cards` row ⇄ `fsrs.Card`
  translation, both directions, in one place. Phase 4 had a private
  one-way `state → text` helper inside the bootstrap importer; the
  grading write-path needs the reverse too, so the conversion (and the
  `state`/`rating` enum ⇄ string mapping) is now shared, keeping the
  read-path and write-path from drifting apart.
- **`review_scheduler.dart`** — `ReviewScheduler.grade(cardId, rating)`
  runs the real FSRS algorithm forward, persists the updated scheduling
  state to the card, and *appends* an immutable review-log row
  (`ReviewLogs` is append-only per §4 — insert, never update; the log
  id is deterministic from card + review time so a double-submit can't
  duplicate history).

### The heart of §7: reviews come from the text, not a deck

- **`due_in_reading.dart`** — `DueInReading.dueInView(tokens)` returns
  the due cards whose lemma is present in the tokens the reader is
  *currently looking at*, most-overdue first. This is the structural
  core of "scheduling woven into reading, no review screen": the review
  opportunity is derived from the text in front of the user, not drawn
  from a separate due-queue they navigate to. **The text itself is the
  queue.**

### The reading surface (`features/reader/`)

- **`in_reading_review.dart`** — `InReadingReviewPanel`, an inline
  grading prompt (four FSRS ratings) that appears *below the text on
  the same screen*. Deliberately a panel, not a route — there is no
  review screen to push. It's kept separate from Phase 6's pure
  `SpanReader` precisely because it *is* scheduling-aware; the reader
  composes the two, so the renderer stays vocabulary-free (Phase 6's
  purity guard still holds).
- **`reading_view.dart`** — `ReadingView` composes the pure text
  renderer with the inline review panel: a due item whose word is in
  the current span is offered right under the text, graded in place,
  and dismissed — all without a route change. The reader *is* the
  review surface.

## Measured evidence

### The "no navigation" half — enforced by test

`reading_view_test.dart` drives the widget with a `NavigatorObserver`
counting route pushes, taps a grade button, and asserts:
- `onGrade` fired with the right card + rating,
- the prompt is gone (reviewed in place),
- the text is still present (we never left the reader),
- **`observer.pushes` is unchanged — zero navigation.**

That last assertion is the gate's "without leaving the reader" made
mechanical: if anyone later turns this into a pushed review screen, the
test fails.

### The data round-trip half — on real content

`tool/phase7_review_in_reading.dart` reads the real 羅生門 EPUB span by
span against real full JMdict, surfacing and grading due items in the
flow:

```
EPUB spans (reading order): 416
due cards this reader has: 30

=== Reading — reviews surface from the text, graded in flow ===
  reading 「或日の暮方の事である。」
    due word in view: 「ある」 → graded good → due 2026-08-17, stability 2.0→14.5
  reading 「一人の下人が、羅生門の下で雨やみを待っていた。」
    due word in view: 「いる」 → graded good → due 2026-08-17, stability 2.0→14.5
  ...

=== Phase 7 gate ===
spans where a review surfaced from the text: 30
items graded in the reading flow:            30
review-log rows appended:                    30
graded items still due (should be 0):        0
GATE: PASS
```

Reading the story's famous opening「或日の暮方の事である。」surfaces the
due word 「ある」 from that very sentence; grading it *good* advances its
FSRS stability 2.0 → 14.5 and pushes the due date two weeks out, so it
leaves the due set. Across the read, all 30 due items surfaced from the
text they appear in, were graded in the flow, produced exactly 30
appended review-log rows, and none of the graded items remained due —
the scheduling genuinely advanced, it wasn't just a UI gesture.

## On the invariants

CLAUDE.md's I3 ("no gamification — no streak, points, leaderboards")
holds: grading here is plain FSRS self-assessment of recall in context,
producing a schedule and a measurement, with no score or streak
anywhere. The four ratings are standard SRS grades, not a
multiple-choice recognition prompt — the word is read in its real
sentence context, which is the recall situation itself.

## Gate verdict

**PASS.** A due item is surfaced from the reading flow (not a deck),
graded inline with no route change (enforced by a NavigatorObserver
test), and the grade genuinely advances FSRS state (verified on the
real 羅生門 text: 30/30 items surfaced, graded, logged, and cleared from
the due set). There is no review screen. Proceed to Phase 8.

---
*Softbrew Studio — Phase 7 proof report — 2026-08-03.*
