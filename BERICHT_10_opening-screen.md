# BERICHT 10 — The Opening Screen (A Proof, Not a Menu)

**Phase:** 10 — Opening screen (SPEC_MINING_PIPELINE.md §10)
**Gate criterion:** Then/Now proof renders from real history; graceful empty state verified.
**Verdict: PASS.**

---

## What was built

§8's opening screen is "a proof, not a menu" — exactly one artifact, the
Then/Now re-presentation of the most recently read passage, with a Datum
line beneath it and navigation below the fold. This phase composes
existing pieces (Phase 8's `RePresentationView`, Phase 9's `DatumLine`)
into that screen, driven by real history.

### Opening state from real history (`features/opening/opening_state.dart`)

`loadOpeningState(db)` derives what to show purely from passage-snapshot
history: the globally most-recent snapshot picks "the most recently read
passage" (§8), and that passage's snapshot count decides a sealed
`OpeningState`:

- **`RePresentationState`** — read ≥ 2 times → a Then/Now delta to prove.
- **`FirstReadingState`** — read exactly once → no delta yet (the empty
  state).
- **`BlankSlateState`** — nothing read → an entry point, not a fabricated
  proof.

No task counts, no due numbers, no streaks are read or computed anywhere
in this loader — the opening screen is a proof, not a dashboard.

`openingDatumObservation(state)` builds the matching Datum observation
from *measured* values only: a `deltaMeasured` comparison when there's a
delta, a plain `firstReading` note ("read once, no comparison yet") for
the empty state, and nothing for a blank slate. Phase 9's `DatumVoice`
still independently refuses any line whose facts aren't all present.

### The screen (`features/opening/opening_screen.dart`)

`OpeningScreen` renders the proof (Then/Now, the single first-reading
value, or a blank-slate entry point), the Datum line beneath it, and
Continue/Library navigation at the bottom. §8's hard rules are
structural: it renders no task/due/streak numbers (nothing feeds it
any), it falls back gracefully to the empty states, and navigation is
always below the proof.

### A new Datum template (`firstReading`)

The empty state needs Datum to "say so plainly" (§8), so
`ObservationKind.firstReading` and its template ("{chapter} einmal
gelesen. Noch kein Vergleich möglich.") were added. Being a data change
to Phase 9's registry, it's automatically covered by that phase's
generic gate test — the no-unmeasured-fact guard and the §6.2 voice
rules already apply to it with no new test needed.

## Measured evidence

### The UI half — enforced by widget tests

`opening_screen_test.dart` verifies on the real widget:
- The Then/Now proof renders from a delta (41% → 8%, both shown).
- **No task count, due-card number, or streak** appears — a regex over
  every `Text` widget on screen asserts none of `fällig|due|streak|
  serie|in folge|aufgaben|N karten/cards/tasks` is present (§8, I3).
- Navigation is below the fold (asserted: the Continue button sits
  *below* the proof vertically).
- The graceful empty state: a passage read once shows that passage's
  own value and Datum's plain "no comparison yet" line — no fabricated
  Then/Now.
- Blank slate shows an entry point, no proof, no Datum line.
- With Datum disabled (null line), the proof still renders untouched
  (§0.24).

### The data half — on real content

`tool/phase10_opening_screen.dart` derives the opening state from
**real** passage history measured off the 羅生門 EPUB, for all three
cases:

```
=== Opening screen from real history ===
A (read twice):  RePresentation: DAMALS 55% → JETZT 9%
   Datum: "Kapitel 2. Vor 6 Wochen: 55 Prozent unbekannt. Heute: 9."
B (read once):   FirstReading (empty state): JETZT 55% unbekannt, kein Vergleich
   Datum: "Kapitel 2 einmal gelesen. Noch kein Vergleich möglich."
C (never read):  BlankSlate: nothing read yet
   Datum: (none — nothing to prove)

=== Phase 10 gate ===
Then/Now proof from real history:  true
empty state (read once) graceful:  true
blank slate (never read) handled:  true
GATE: PASS
```

The Then/Now proof (A) is computed from an actual two-reading
measurement of the 羅生門 text — 55% → 9% unknown, voiced by Datum with
those exact numbers. The empty state (B) — a passage read exactly once —
shows that reading's value and Datum saying plainly there's no
comparison yet, never inventing one. And the blank slate (C) is handled
without a fabricated proof.

## Gate verdict

**PASS.** The Then/Now proof renders from real measured history; the
graceful empty state (read once, and never read) is verified in both
the widget and on real data; and §8's structural rules — no
task/due/streak numbers, navigation below the fold — are enforced by
test. The opening screen is a proof, not a menu. Proceed to Phase 11.

---
*Softbrew Studio — Phase 10 proof report — 2026-08-03.*
