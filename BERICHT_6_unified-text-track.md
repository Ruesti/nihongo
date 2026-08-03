# BERICHT 6 — Unified Text Track + One Renderer (KILL GATE)

**Phase:** 6 — Unified text track + one renderer (SPEC_MINING_PIPELINE.md §10)
**Gate criterion:** EPUB and SRT both reduce to `TextSpan_`; tapping a word behaves identically in both; renderer contains zero vocabulary logic — verified by inspection.
**This is the second kill gate** (§10): "if the unified text track does not hold — if the renderer starts needing to know about medium-specific vocabulary behaviour — then Part B's core premise is wrong and the product splits into two apps or drops one medium."
**Verdict: PASS.** The premise holds.

---

## What was built

### The unified track (`core/text_track/anchor.dart`)

§5's model, typed: a `sealed class Anchor` with `FlowAnchor` (char
offset), `TimeAnchor` (time interval), and `SpatialAnchor` (page + box,
Phase 12). `PositionedSpan` is §5's `TextSpan_` — the in-memory,
medium-independent view a renderer consumes, decoupled from storage
(named to avoid colliding with both Drift's generated `TextSpan` row
and Flutter's own `TextSpan`).

`PositionedSpan.fromRow` **is the reduction**: it is the single place
in the codebase that reads a stored span's `anchorType` discriminator
and its medium-specific columns, collapsing any stored `TextSpan` row —
SRT-sourced, EPUB-sourced, eventually OCR-sourced — to one typed
`PositionedSpan`. Everything downstream sees only the typed `Anchor`,
never the storage discriminator. The exhaustive `switch` over `sealed
Anchor` is the compiler enforcing that every medium is handled.

### EPUB source adapter (`core/sources/epub_parser.dart` + `epub_source_adapter.dart`)

The exact counterpart of Phase 3's `SrtSourceAdapter`: identical
`Works`/`Sources`/`TextSpans` output shape, differing only in the
positioning axis (`charStart`/`charEnd` instead of `tStartMs`/
`tEndMs`) — which is precisely the unified-track claim made concrete.

`parseEpub` follows the standard container → OPF → spine chain (real
EPUB structure, via `archive` for the ZIP + `html` for tolerant XHTML
parsing), extracts block-level text per spine document in reading
order, then splits each block at **Unicode sentence terminators**
(｡．！？!?…). That last step is language-blind on purpose — it keys on a
*script* property, the same discipline `sentence_scoring.dart` uses to
detect punctuation via `\p{P}` rather than an IPADIC POS tag. Without
it, a Gutenberg/Aozora conversion that dumps a whole story into one
`<p>` would yield a single 6000-character span; with it, 羅生門's famous
opening「或日の暮方の事である。」becomes its own 11-character segment.

### The renderer (`features/reader/span_reader.dart`) + interaction (`core/text_track/word_tap.dart`)

`SpanReader` is a thin Flutter widget: it renders a span's tokens as
tappable words (with optional furigana above), and calls `onWordTap`.
`WordTapHandler` is the one interaction model (§5): tap a `Token` →
`Dictionary.lookup`. It operates only on a `Token` (already
medium-independent — the tokenizer produces the same `Token` whether
the span came from EPUB flow or SRT time track), so it *cannot observe*
which medium a tap came from. That's the whole point.

## Measured evidence

`tool/phase6_unified_track.dart` runs a **real EPUB** (Project
Gutenberg's 羅生門 by Akutagawa — public domain, downloaded as-is, a
genuine in-the-wild EPUB3 not a hand-built fixture) and a real SRT
through the two adapters against the real, full JMdict:

```
=== Both media reduce to the unified PositionedSpan track ===
EPUB (羅生門): 416 spans, anchor type: FlowAnchor
SRT (episode): 312 spans, anchor type: TimeAnchor
EPUB spans all FlowAnchor: true
SRT spans all TimeAnchor:  true

=== A word tap behaves identically regardless of medium ===
shared lemma tapped in both: 「日」
  from EPUB span (FlowAnchor) -> [day, days]
  from SRT span  (TimeAnchor) -> [day, days]
  identical lookup result: true

=== Renderer contains zero vocabulary logic (by inspection) ===
renderer imports: 2
  import 'package:flutter/material.dart';
  import '../../core/language_pack/language_pack.dart';
renderer free of vocabulary/scheduling/db/Datum imports: true

GATE: PASS
```

All three gate clauses, demonstrated on real data:

1. **Both reduce to `TextSpan_`.** 416 EPUB spans (all FlowAnchor) and
   312 SRT spans (all TimeAnchor) both collapse to `PositionedSpan`,
   differing only in anchor type.
2. **Tapping a word behaves identically.** The lemma 「日」occurs in a
   real span of *both* works; tapped from the EPUB's FlowAnchor span
   and from the SRT's TimeAnchor span, `WordTapHandler` returns the
   identical dictionary result `[day, days]`.
3. **Renderer contains zero vocabulary logic.** Made mechanically
   checkable, not asserted: the renderer's entire import list is
   `flutter/material` + the `Token` type — nothing from `db/`,
   `pipeline/` (scoring/FSRS/card-assembly/knowledge), `mining_packs/`,
   or Datum. A dedicated test (`renderer_purity_test.dart`) enforces
   this so a future wiring mistake fails CI, not just a code review.

## A real inconsistency the kill-gate surfaced

Writing the "both media produce the same span shape" test exposed that
the SRT adapter (Phase 3) uses the SRT cue number as `ordinal`
(1-based, from the file) while the EPUB adapter counts blocks
(0-based). Both are valid monotonic reading orders — `ordinal`'s
contract (§2.3: "reading order, medium-independent") only requires
monotonicity within a work, not a shared base across media — so this
is cosmetic, not a defect, and the test was tightened to assert the
real claim ("differ only in the anchor axis") rather than an
over-strict ordinal equality. Noted here rather than silently papered
over; if a cross-medium canonical ordinal is ever needed, it's a small
follow-up, not a redesign.

## Gate verdict

**PASS — kill gate cleared.** The unified text track holds: two very
different media reduce to one positioned-span type differing only in
their anchor, a word tap resolves identically through a renderer and
handler that are provably blind to medium, and the renderer's purity is
enforced by a test rather than a promise. Part B does not split into
two apps. Proceed to Phase 7.

---
*Softbrew Studio — Phase 6 proof report — 2026-08-03.*
