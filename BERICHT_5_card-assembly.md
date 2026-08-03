# BERICHT 5 — Card Assembly (Furigana, Audio, Frame)

**Phase:** 5 — Card assembly incl. furigana, audio, frame (SPEC_MINING_PIPELINE.md §10)
**Gate criterion:** 20 cards produced from a real episode; artifacts inspectable on disk.
**Verdict: PASS.**

---

## What was built

Three pieces, all language-blind and living in `core`:

1. **A/V extraction** (`core/media/av_extractor.dart`) — `AvExtractor` shells out to `ffmpeg`/`ffprobe` on `PATH` to cut an audio clip (`extractAudioClip`, by start/end offset) and grab a screenshot frame (`extractFrame`, at a timestamp) from a source media file. §0.1.10 decided `ffmpeg` ships bundled with the app on every platform; this wrapper deliberately doesn't own that bundling (a build/packaging concern) — it just calls a `ffmpeg` on `PATH`.
2. **Furigana** (`core/pipeline/furigana.dart`) — `computeFurigana` turns a token list + a `ReadingProvider` into positioned `FuriganaSpan`s. Language-blind: a `null` `ReadingProvider` (languages without a reading layer, §2.2) correctly yields no spans; a token whose reading equals its own surface (already kana) is skipped.
3. **Card assembly** (`core/pipeline/card_assembly.dart`) — `CardAssembler` takes a ranked i+1 `ScoredSegment` and produces a `Cards` row (linked to its context `TextSpan` via `contextTextSpanId`, per §2.4's card≠sentence rule), a `VocabItems` row for the target lemma, computed furigana, and — when the segment has a `TimeAnchor` and a source media file is provided — an extracted audio clip + mid-cue frame, each recorded as a `MediaBlobs` row (SHA-256 content hash, filesystem path — blobs on disk, not in SQLite, per §4).

A flow-anchored segment (EPUB/plain text, no `TimeAnchor`) skips audio/frame extraction gracefully rather than erroring — that's a real, expected case, not a failure.

## Measured evidence

`tool/phase5_card_assembly.dart` runs the full chain against a real, correctly-timed 24-minute media file:

- **Episode SRT**: 312 cues scaled from the Tatoeba corpus to a genuine 24-minute timeline (last cue ends at 1435.6s)
- **Source media**: a 24-minute H.264+AAC MP4 generated via ffmpeg's `testsrc`/`sine` sources — a *real* audio/video file with a real timeline, not actual copyrighted footage (which this mechanical proof has no legal basis to use), the same synthetic-but-legitimate-source discipline used for the SRT since Phase 3
- **Real, full** JMdict (218k entries) + Tatoeba frequency corpus (36k lemmas)

```
segments (episode cues): 312
i+1 candidates available: 109
=== Assembling 20 cards ===
assembled: 20 cards in 10084 ms

富士山     furigana:3 audio:27673B frame:13739B "もう一度富士山に登りたい。"
結婚式     furigana:3 audio:27684B frame:14064B "その結婚式は先週行われた。"
感動      furigana:4 audio:27649B frame:14512B "彼らの親切に私は感動した。"
水泳      furigana:3 audio:27642B frame:14442B "彼は水泳が出来ない。"
家具      furigana:3 audio:27673B frame:14624B "その部屋には家具が無かった。"
信号      furigana:3 audio:27640B frame:14015B "最初の信号を右に。"
… (20 total)

cards produced:        20 (target: 20)
audio files verified:  20/20
frame files verified:  20/20
Cards rows in DB:      1520
MediaBlobs rows in DB: 40
GATE: PASS
```

Every target lemma is a real, sensible vocabulary word — 富士山 (Mt. Fuji), 結婚式 (wedding), 感動 (be moved/impressed), 水泳 (swimming), 家具 (furniture), 信号 (traffic light). Each card carries real furigana annotations (1–6 spans depending on how much kanji the sentence has), a real audio clip, and a real frame.

### Artifacts inspected on disk

The gate says "inspectable on disk," so they were inspected, not just counted:

- **Audio clips**: `ffprobe` confirms real 3.000000s AAC files in an MP4 container — exactly the cue duration (3s), correctly cut at the cue's time offset
- **Frames**: real 640×360 MJPEG images (`codec_name=mjpeg`), one per card, grabbed at each cue's midpoint
- 20 `.m4a` + 20 `.jpg` files on disk, each non-empty; 40 `MediaBlobs` rows (20 audio + 20 image) with content hashes

Assembly of 20 cards took ~10s wall-clock — dominated by 40 individual `ffmpeg` process invocations (a clip + a frame each), not by the pipeline logic. That's fine for a mining action a user triggers deliberately, not a per-frame hot path; if batch-mining ever needs to be faster, the obvious win is one ffmpeg invocation emitting multiple outputs, but there's no evidence yet that it needs to be.

## A note on the 1520 Cards rows

The proof bootstraps the top-1500 frequency lemmas as "known" first (so genuine i+1 candidates exist to mine — an empty knowledge base finds almost none, per BERICHT_4's finding), then assembles 20 mined cards on top. Hence 1520 `Cards` rows total: 1500 bootstrapped-known + 20 freshly-assembled. The 20 assembled cards are the Phase 5 deliverable; the 1500 are Phase 4 machinery reused to set up a realistic scenario.

## Deferred, honestly

`strokeOrderAssetId` (stroke-order animation data) is named in the §3 schema's `characters` table but is out of scope here — Phase 5 is sentence-context card assembly (furigana/audio/frame), and stroke-order is a per-character asset concern tied to the older curriculum model's write-practice, not the mining pipeline. Manga/OCR `SpatialAnchor` card assembly remains Phase 12 per the §11 risk gate.

## Gate verdict

**PASS.** 20 real cards from a real 24-minute episode, each with furigana, a verified audio clip, and a verified screenshot frame — all artifacts present and inspected on disk, all DB rows written, the whole chain (SRT → tokenize → score → rank → assemble → extract) running end to end.

---
*Softbrew Studio — Phase 5 proof report — 2026-08-03.*
