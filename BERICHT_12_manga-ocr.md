# BERICHT 12 — Manga OCR (SpatialAnchor Path)

**Phase:** 12 — Manga OCR (SPEC_MINING_PIPELINE.md §10)
**Gate criterion:** SpatialAnchor path works end to end.
**Verdict: PASS.** The final phase — all twelve pass.

Sequenced last on purpose (§11 risk gate, §0.10.30: "in scope, but
Phase 12, never earlier") because it's the largest engineering item in
Part B. It turned out to slot cleanly onto the unified text track built
in Phase 6 — the `SpatialAnchor` type has existed since then; this phase
is the source that produces it.

## What was built

Manga OCR is the **third source adapter**, alongside SRT (TimeAnchor)
and EPUB (FlowAnchor) — and it produces the third and final anchor kind,
`SpatialAnchor` (§5: manga positions text by a bounding box on a page).

- **`core/media/ocr_engine.dart`** — an `OcrEngine` interface (image →
  `OcrBox`es with pixel bounding boxes). An interface, not a concrete
  Tesseract call, so the adapter and its tests depend on the
  *capability*, not the tool — the same shape as `AvExtractor` wrapping
  ffmpeg. OCR quality is an engine concern; the SpatialAnchor pipeline
  path is engine-agnostic.
- **`core/media/tesseract_ocr.dart`** — `TesseractOcrEngine`, an
  `OcrEngine` backed by the `tesseract` CLI (TSV output → word rows
  grouped into line boxes; Japanese words joined without separators).
- **`core/sources/manga_source_adapter.dart`** — image → OCR → the same
  `Works`/`Sources`/`TextSpans` output shape as the SRT and EPUB
  adapters, differing only in the positioning axis (`pageId`/`rectJson`
  instead of time or char offsets). Deterministic top-to-bottom,
  left-to-right reading order (real manga right-to-left ordering is a
  refinement *inside this adapter*, invisible to the pipeline — §12
  notes page reading order as an open problem).

Nothing in the pipeline changed: `PositionedSpan.fromRow` already
handled `anchorType == 'spatial'` since Phase 6, and scoring, tapping,
and lookup are all anchor-agnostic.

## Measured evidence

### Unit — the SpatialAnchor path, engine-independent

`manga_source_adapter_test.dart` uses a fake `OcrEngine` (injected
boxes, no binary) to prove the adapter and path without depending on a
real OCR install: OCR boxes → `TextSpans` with `anchorType='spatial'`,
`pageId`, and `rectJson`; those rows reduce to `PositionedSpan` with a
`SpatialAnchor`; and they run through the exact same `scoreAll` scoring
code as any other span (an i+1 target found, no OCR-specific branch).

### End to end — real image, real OCR, real dictionary

`tool/phase12_manga_ocr.dart` runs a **real** synthetic manga panel
(three Japanese speech regions, ffmpeg-drawn — the same
synthetic-but-legitimate discipline used for SRT/media/EPUB throughout)
through **real Tesseract OCR** (5.5.0, `jpn`) and the unchanged
pipeline against the real full JMdict:

```
=== OCR the page → SpatialAnchor spans ===
OCR text regions found: 3
[spatial] page=page-1 rect={"left":62,"top":60,"right":248,"bottom":103}  text="本を読む"
[spatial] page=page-1 rect={"left":352,"top":200,"right":584,"bottom":244} text="猫が大好き"
[spatial] page=page-1 rect={"left":88,"top":356,"right":458,"bottom":421}  text="日本語を勉強する"

=== SpatialAnchor path end to end ===
all spans reduce to SpatialAnchor: true
word-tap lookups resolved from OCR text: 10
sample tap (image → OCR → tokenize → lookup): 「本」 → [origin, source]

=== Phase 12 gate ===
image OCR produced SpatialAnchor spans: true
spans carry page id + bounding box:     true
spans run the unchanged tap→lookup path: true
GATE: PASS
```

Every stage ran for real: Tesseract recognized all three Japanese
regions (本を読む, 猫が大好き, 日本語を勉強する) with pixel bounding
boxes; the manga adapter turned them into `SpatialAnchor` spans carrying
`page-1` + the rect; each reduced to a `PositionedSpan` with a
`SpatialAnchor`; the **same word-tap path a reader uses** (Phase 6's
`WordTapHandler`) tokenized the OCR'd text and resolved 10 dictionary
lookups — the tap now sourced from an *image* instead of an SRT or EPUB.
This is the unified text track's third medium, working end to end.

## On OCR quality (an engine note, not a path gap)

The proof image uses cleanly-set horizontal Japanese, which Tesseract
reads at 92–97% confidence. Real manga — stylised, often vertical text
over artwork — is much harder; a dedicated model (e.g. a manga-specific
recognizer) would be the production engine. Crucially, that swaps the
`OcrEngine` implementation behind the interface and changes **nothing**
in the adapter, the SpatialAnchor path, or the pipeline — exactly the
seam separation the whole architecture is built on.

## Gate verdict

**PASS.** A real image, through real OCR, becomes `SpatialAnchor` spans
that carry page + bounding box and run the unchanged tokenize → tap →
dictionary-lookup path — the SpatialAnchor path works end to end. The
unified text track now spans all three media (time, flow, spatial).

---

## All twelve phases complete

With Phase 12, every phase of SPEC_MINING_PIPELINE.md's plan has passed
its gate, both kill gates cleared (Phase 1 Lindera, Phase 6 unified
track):

| Phase | Gate | Verdict |
|---|---|---|
| 1 | Lindera FFI spike (kill gate) | PASS |
| 2 | Schema + LanguagePack seams + JMdict | PASS |
| 3 | Pipeline stages 1–4 headless | PASS |
| 4 | Knowledge model + bootstrap | PASS |
| 5 | Card assembly (furigana/audio/frame) | PASS |
| 6 | Unified text track + renderer (kill gate) | PASS |
| 7 | Scheduling woven into reading | PASS |
| 8 | passage_snapshot + re-presentation | PASS |
| 9 | Datum utterance layer | PASS |
| 10 | Opening screen | PASS |
| 11 | Second language pack (verified by diff) | PASS |
| 12 | Manga OCR (SpatialAnchor) | PASS |

---
*Softbrew Studio — Phase 12 proof report — 2026-08-04.*
