# BERICHT 1 — Lindera FFI Spike (Kill Gate)

**Phase:** 1 — Lindera FFI spike, isolated, no app (SPEC_MINING_PIPELINE.md §10)
**Gate criterion:** Tokenize 10k JA sentences on a physical Android device; report cold-start time, per-sentence latency p50/p99, dictionary size on disk, APK impact.
**Verdict: PASS.** Numbers below are measured, not estimated.

---

## Setup

- **Device:** Samsung SM S918B, Android 16 (API 36), arm64-v8a — physical hardware, connected via USB to a build machine (`laptop`), driven remotely.
- **Corpus:** 10,000 sentences drawn at random from the Tatoeba Japanese sentence export (`downloads.tatoeba.org/exports/per_language/jpn/jpn_sentences.tsv.bz2`, 248,821 sentences total) — a real corpus, not synthetic text. Tatoeba is an approved source per SPEC §0.5.17.
- **Tokenizer:** `lindera` 4.0.0 (Rust), `embed-ipadic` feature — IPADIC dictionary compiled into the binary, no on-device download or filesystem dictionary.
- **Bridge:** `flutter_rust_bridge` 2.12.0, scaffolded via `flutter_rust_bridge_codegen create`, native build via the bundled `cargokit` Gradle integration.
- **Location:** `spike/lindera_spike/` in this repo — an isolated Flutter+Rust project, not wired into `nihongo_app`. Driven via a `flutter_test` `integration_test` (`integration_test/benchmark_test.dart`), not the app's own UI, per "isolated, no app."
- **Methodology:** `initTokenizer()` loads the embedded dictionary and builds the tokenizer once, timed on the Rust side (`Instant::now()`). `benchmarkBatch()` then tokenizes all 10,000 sentences in a single FFI call, timing each sentence individually inside Rust to avoid Dart↔Rust round-trip overhead polluting per-sentence latency. Percentiles computed in Dart from the returned per-sentence timing array.

## Results

| Metric | Value |
|---|---|
| Cold start (dictionary load + tokenizer build) | **785 ms** |
| Sentences tokenized | 10,000 |
| Total tokenize time | 1,000.5 ms |
| Total tokens produced | 114,643 (≈11.5 tokens/sentence) |
| Per-sentence mean | 0.0998 ms |
| Per-sentence p50 | **0.091 ms** |
| Per-sentence p99 | **0.259 ms** |
| Per-sentence max | 0.975 ms |

Raw on-device test output:
```
PHASE1_BENCHMARK_RESULT {"coldStartMs":785.245938,"sentenceCount":10000,"totalTokenizeMs":1000.5023950000001,"totalTokens":114643,"perSentenceMeanMs":0.09984112170000002,"perSentenceP50Ms":0.09130300000000001,"perSentenceP99Ms":0.25875,"perSentenceMaxMs":0.9747910000000001}
All tests passed!
```

Spot-checked tokenization quality (host-side prototype, same lindera version, IPADIC):
```
関西国際空港限定トートバッグ
→ 関西国際空港  名詞,固有名詞,組織,...  (proper noun, correctly kept as one token)
→ 限定          名詞,サ変接続,...
→ トートバッグ  名詞,一般,...
```
Linguistically sound segmentation — no red flags on POS tagging or over/under-splitting for this sample.

## Dictionary size / APK impact

Measured via a **release, split-per-abi, arm64-only** build (`flutter build apk --release --split-per-abi --target-platform android-arm64`) — debug builds are not representative (they bundle 3 ABIs and are unoptimized; an earlier debug build was 200MB and is not a valid comparison point).

| Build | APK size (arm64-v8a release) |
|---|---|
| Baseline (FRB quickstart, no `lindera`) | 15.9 MB |
| With `lindera` + embedded IPADIC | 74.3 MB |
| **Delta attributable to lindera+IPADIC** | **≈58.4 MB** |

The delta is accounted for almost entirely by `lib/arm64-v8a/liblindera_spike_rust.so`, which is 59.1 MB in the release APK. There is no separate on-disk dictionary file to measure — with `embed-ipadic`, the dictionary is compiled directly into the native library, so "dictionary size on disk" and "native library size" are the same number for this integration approach.

**Assessment:** ~58 MB is a real, non-trivial APK size cost, but within the range of comparable IPADIC-based JA input/dictionary apps on the Play Store. Given SPEC §0.5.16 already decided the general-purpose dictionary (JMdict/KANJIDIC) ships via first-run download rather than in-APK, the same pattern is worth considering for the tokenizer dictionary if base install size becomes a concern later — `lindera` supports loading a dictionary from a filesystem path instead of the embedded one, so this is not a rearchitecture, just a delivery-mechanism choice deferred past this gate.

## Problems encountered and fixed (real findings, not friction to hide)

Three genuine defects surfaced during this spike, each fixed and documented so the workaround is reproducible:

1. **Upstream bug: `lindera-dictionary` 4.0.1's dictionary builder never creates its output directory.** `PrefixDictionaryBuilder::build()` calls `File::create(output_dir.join("dict.words"))` directly, but nothing in the build path calls `fs::create_dir_all(output_dir)` first — and the caller in `lindera-dictionary`'s `assets.rs` explicitly `fs::remove_dir_all`s that same directory immediately before invoking the builder. Result: `embed-ipadic` fails 100% of the time on 4.0.1 with "Failed to create dict.words file". **Workaround:** pinned `lindera = "=4.0.0"` in `rust/Cargo.toml`, which resolves a working version of the shared builder code. Not yet reported upstream — worth filing an issue before this dependency is relied on beyond a spike.
2. **`cargokit`'s Gradle plugin uses the removed `Project.exec {}` API, incompatible with Gradle 9.** This project's Flutter/AGP version (Android Gradle Plugin 9.0.1) pulls Gradle 9.1.0 via the wrapper, and Gradle 9 no longer exposes `exec()` directly on `Project` in this context (`Could not find method exec()`). **Fix:** patched `rust_builder/cargokit/gradle/plugin.gradle` to inject `org.gradle.process.ExecOperations` (`@Inject abstract ExecOperations getExecOperations()`) and call `execOperations.exec {}` instead of `project.exec {}` — the standard, Gradle-recommended migration. Patch is committed as part of this spike's vendored `cargokit` copy.
3. **`cargokit`'s bundled Android library template pins `compileSdkVersion 33`, too old for current androidx transitive dependencies** (several `androidx.lifecycle`/`androidx.core` versions require compileSdk ≥ 34). **Fix:** bumped to `compileSdkVersion 36` in `rust_builder/android/build.gradle`, matching the rest of the toolchain (Android SDK 36 already installed for `nihongo_app` itself).

None of these are exotic — all three would hit anyone doing this integration today with current tool versions. Phase 2 (JMdict import, real `LanguagePack` seam) inherits this fixed toolchain, so these are one-time costs.

## Gate verdict

**PASS.** Cold start under 1 second, sub-millisecond p99 per-sentence tokenization, and a real (if non-trivial) APK cost that has a known mitigation path if it matters later. Nothing here invalidates the product direction — proceed to Phase 2.

---
*Softbrew Studio — Phase 1 proof report — 2026-07-28.*
