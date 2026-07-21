# Phase 1 — Lindera FFI Spike Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove or kill Lindera as the Japanese tokenizer for the mining pipeline by measuring its real behavior on a physical Android device — cold-start time, per-sentence tokenize latency (p50/p99), dictionary size on disk, and APK size impact — over a 10k-sentence Japanese corpus.

**Architecture:** A standalone Rust crate (`spikes/lindera_ffi_spike/rust/`) wraps Lindera 4.0.1 behind a small stateful C-ABI (`lindera_init` loads the dictionary once and returns an opaque handle; `lindera_tokenize_json` reuses that handle per call — this split is what lets cold-start and per-call latency be measured as genuinely separate numbers instead of conflating "reload dictionary" into every call). It's cross-compiled for `arm64-v8a` via `cargo-ndk`. A throwaway Flutter app (`spikes/lindera_ffi_spike/harness/`) loads the `.so` via hand-rolled `dart:ffi` (no `flutter_rust_bridge` — this is a 4-function spike, not worth its codegen/Cargokit overhead), tokenizes a bundled 10k-sentence Tatoeba Japanese corpus, times every call, and writes a JSON report to app-private storage. Fixtures (dictionary + corpus) are pushed onto the device via `adb push` + `run-as` rather than bundled as Flutter assets, sidestepping Flutter's directory-asset bundling of an unconfirmed nested binary layout.

**Tech Stack:** Rust (`lindera` 4.0.1, `serde_json`), `cargo-ndk`, Android NDK, Flutter/Dart (`dart:ffi`, `ffi`, `path_provider`), physical Android device via `adb`.

## Global Constraints

- **Kill gate:** if Lindera proves non-viable on-device, the whole product direction is re-planned before any schema exists — do not let this spike leak into `lib/` or touch the Drift schema. (`SPEC_MINING_PIPELINE.md` §11)
- **Isolation:** Phase 1 is explicitly "isolated, no app" — all spike code lives under `spikes/lindera_ffi_spike/`, never under `lib/core/`. (`SPEC_MINING_PIPELINE.md` §10, Phase 1 row)
- **Required measurements:** cold-start time, per-sentence latency p50/p99, dictionary size on disk, APK size impact — all four must appear in the final report, not a subset. (`SPEC_MINING_PIPELINE.md` §10, Phase 1 row)
- **Corpus size:** 10,000 Japanese sentences. (`SPEC_MINING_PIPELINE.md` §10, Phase 1 row)
- **Device:** a physical Android device, not an emulator — emulator numbers are not an acceptable substitute for this gate. (`SPEC_MINING_PIPELINE.md` §10, Phase 1 row)
- **This repo is mid-pivot:** `SPEC_MINING_PIPELINE.md` is now `SPEC FROZEN v1` and fully replaces the old `CLAUDE.md`/`PHASES.md` app. Don't reuse or reference the old app's patterns (Concept/Asset model, Tamago-chan, SM-2 ladder) — they're superseded, not parallel.
- **Verified-API discipline:** every Rust/Lindera API call in this plan was confirmed against `lindera` 4.0.1's actual docs.rs source and the `lindera-cli` source at git tag `v4.0.1` — not guessed from older Lindera tutorials, which use a different, incompatible API.

## Hardware dependency note

Tasks 1–7 build, cross-compile, and unit-test everything without a device attached. **Tasks 8–9 require a physical Android device connected via `adb` with USB debugging enabled** and the app installed as a debug build (so `run-as` works). If you're executing this plan in an environment without device access, complete Tasks 1–7, then hand off Tasks 8–9 to whoever has the device.

---

### Task 1: Rust spike crate — dictionary build + tokenizer correctness

**Files:**
- Create: `spikes/lindera_ffi_spike/scripts/build_dict.sh`
- Create: `spikes/lindera_ffi_spike/rust/Cargo.toml`
- Create: `spikes/lindera_ffi_spike/rust/src/lib.rs`
- Create: `spikes/lindera_ffi_spike/rust/tests/tokenize_test.rs`
- Create: `spikes/lindera_ffi_spike/.gitignore`

**Interfaces:**
- Produces: `pub fn tokenize_surfaces(dict_path: &str, text: &str) -> Result<Vec<String>, String>` — consumed by Task 2's FFI layer and Task 1's own test.

- [ ] **Step 1: Add the spike's `.gitignore`**

```gitignore
# spikes/lindera_ffi_spike/.gitignore
/dict/
/rust/target/
/harness/build/
/harness/android/app/src/main/jniLibs/
/harness/.dart_tool/
*.apk
```

- [ ] **Step 2: Write the dictionary build script**

```bash
#!/usr/bin/env bash
# spikes/lindera_ffi_spike/scripts/build_dict.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v lindera >/dev/null 2>&1; then
  cargo install lindera-cli --version 4.0.1
fi

curl -L -o /tmp/mecab-ipadic-2.7.0-20250920.tar.gz \
  "https://lindera.dev/mecab-ipadic-2.7.0-20250920.tar.gz"
rm -rf /tmp/mecab-ipadic-2.7.0-20250920
mkdir -p /tmp/mecab-ipadic-2.7.0-20250920
tar zxf /tmp/mecab-ipadic-2.7.0-20250920.tar.gz -C /tmp/mecab-ipadic-2.7.0-20250920 --strip-components=1

curl -L -o /tmp/ipadic-metadata.json \
  "https://raw.githubusercontent.com/lindera/lindera/main/lindera-ipadic/metadata.json"

mkdir -p dict
lindera build \
  --src /tmp/mecab-ipadic-2.7.0-20250920 \
  --dest dict/lindera-ipadic-2.7.0-20250920 \
  --metadata /tmp/ipadic-metadata.json

echo "Dictionary built at dict/lindera-ipadic-2.7.0-20250920"
du -sh dict/lindera-ipadic-2.7.0-20250920
```

*(Note: the `tar` archive's top-level directory name inside the tarball wasn't independently confirmed, hence `--strip-components=1` into a directory we control — if `lindera build --src` complains the source layout is wrong, `tar tzf` the archive first and adjust.)*

- [ ] **Step 3: Run the build script and verify the dictionary exists**

```bash
chmod +x spikes/lindera_ffi_spike/scripts/build_dict.sh
spikes/lindera_ffi_spike/scripts/build_dict.sh
```
Expected: script prints a `du -sh` size for `dict/lindera-ipadic-2.7.0-20250920` (a directory of a few tens of MB is the sane range for IPADIC — record this number, it's the "dictionary size on disk" metric the final report needs from Task 9).

- [ ] **Step 4: Scaffold the Rust crate**

```toml
# spikes/lindera_ffi_spike/rust/Cargo.toml
[package]
name = "lindera_ffi_spike"
version = "0.1.0"
edition = "2021"

[lib]
name = "lindera_ffi_spike"
crate-type = ["cdylib", "rlib"]

[dependencies]
lindera = "4.0.1"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
```

```rust
// spikes/lindera_ffi_spike/rust/src/lib.rs
// Intentionally empty — Task 1 Step 5 adds the failing test first.
```

- [ ] **Step 5: Write the failing correctness test**

```rust
// spikes/lindera_ffi_spike/rust/tests/tokenize_test.rs
use lindera_ffi_spike::tokenize_surfaces;

fn dict_path() -> String {
    format!("{}/../dict/lindera-ipadic-2.7.0-20250920", env!("CARGO_MANIFEST_DIR"))
}

#[test]
fn tokenizes_known_sentence_and_reconstructs_original_text() {
    let text = "東京都に住んでいます。";
    let surfaces = tokenize_surfaces(&dict_path(), text).expect("tokenize should succeed");

    // Structural invariant: concatenating every surface must reconstruct the input
    // exactly — this holds for any correct tokenizer regardless of exact segmentation.
    assert_eq!(surfaces.concat(), text);
    // Sanity bound: a real tokenizer splits this into several tokens, not one blob.
    assert!(surfaces.len() >= 5, "expected several tokens, got {:?}", surfaces);
    // "東京都" (Tokyo) is a proper noun IPADIC keeps as a single segment.
    assert_eq!(surfaces[0], "東京都");
}
```

- [ ] **Step 6: Run the test and confirm it fails to compile**

```bash
cd spikes/lindera_ffi_spike/rust && cargo test tokenizes_known_sentence
```
Expected: `error[E0425]: cannot find function \`tokenize_surfaces\`` (or similar — `lib.rs` is still empty).

- [ ] **Step 7: Implement `tokenize_surfaces`**

```rust
// spikes/lindera_ffi_spike/rust/src/lib.rs
use lindera::dictionary::load_dictionary;
use lindera::mode::Mode;
use lindera::segmenter::Segmenter;
use lindera::tokenizer::Tokenizer;

pub fn tokenize_surfaces(dict_path: &str, text: &str) -> Result<Vec<String>, String> {
    let dictionary = load_dictionary(dict_path).map_err(|e| e.to_string())?;
    let segmenter = Segmenter::new(Mode::Normal, dictionary, None);
    let tokenizer = Tokenizer::new(segmenter);
    let tokens = tokenizer.tokenize(text).map_err(|e| e.to_string())?;
    Ok(tokens.into_iter().map(|t| t.surface.to_string()).collect())
}
```

- [ ] **Step 8: Run the test and confirm it passes**

```bash
cd spikes/lindera_ffi_spike/rust && cargo test tokenizes_known_sentence
```
Expected: `test tokenizes_known_sentence_and_reconstructs_original_text ... ok`. If it fails on the `surfaces[0] == "東京都"` assertion specifically (not the reconstruction or count checks), print `surfaces` and confirm the actual first token is still a sane proper-noun segment before adjusting the assertion — don't loosen it reflexively.

- [ ] **Step 9: Commit**

```bash
git add spikes/lindera_ffi_spike/.gitignore spikes/lindera_ffi_spike/scripts/build_dict.sh \
        spikes/lindera_ffi_spike/rust/Cargo.toml spikes/lindera_ffi_spike/rust/src/lib.rs \
        spikes/lindera_ffi_spike/rust/tests/tokenize_test.rs
git commit -m "spike(lindera): scaffold Rust crate, verify tokenization correctness"
```

---

### Task 2: Stateful FFI surface (init/tokenize/free) + round-trip test

**Files:**
- Modify: `spikes/lindera_ffi_spike/rust/src/lib.rs`
- Create: `spikes/lindera_ffi_spike/rust/tests/ffi_test.rs`

**Interfaces:**
- Consumes: `tokenize_surfaces` is no longer called directly by the FFI layer — the FFI layer builds its own long-lived `Tokenizer` so dictionary loading happens once per `lindera_init`, not once per `lindera_tokenize_json` call. This split matters: without it, "cold start" and "per-sentence latency" would be the same number.
- Produces (extern "C", used by harness in Task 6):
  - `lindera_init(dict_path: *const c_char) -> *mut c_void` (opaque handle; null on failure)
  - `lindera_tokenize_json(handle: *mut c_void, text: *const c_char) -> *mut c_char` (JSON: `{"ok":bool,"surfaces":[string],"error":string|null}`)
  - `lindera_free_handle(handle: *mut c_void)`
  - `lindera_free_string(ptr: *mut c_char)`

- [ ] **Step 1: Write the failing FFI round-trip test**

```rust
// spikes/lindera_ffi_spike/rust/tests/ffi_test.rs
use std::ffi::{CStr, CString};
use lindera_ffi_spike::{lindera_init, lindera_tokenize_json, lindera_free_handle, lindera_free_string};

fn dict_path() -> CString {
    CString::new(format!("{}/../dict/lindera-ipadic-2.7.0-20250920", env!("CARGO_MANIFEST_DIR"))).unwrap()
}

#[test]
fn ffi_roundtrip_returns_valid_json_with_expected_surfaces() {
    let handle = lindera_init(dict_path().as_ptr());
    assert!(!handle.is_null(), "lindera_init should succeed with a valid dict path");

    let text = CString::new("東京都に住んでいます。").unwrap();
    let result_ptr = lindera_tokenize_json(handle, text.as_ptr());
    let json = unsafe { CStr::from_ptr(result_ptr) }.to_str().unwrap().to_owned();
    lindera_free_string(result_ptr);
    lindera_free_handle(handle);

    let parsed: serde_json::Value = serde_json::from_str(&json).expect("output must be valid JSON");
    assert_eq!(parsed["ok"], true);
    let surfaces: Vec<String> = parsed["surfaces"]
        .as_array()
        .unwrap()
        .iter()
        .map(|v| v.as_str().unwrap().to_string())
        .collect();
    assert_eq!(surfaces.concat(), "東京都に住んでいます。");
}

#[test]
fn lindera_init_returns_null_for_bad_dict_path() {
    let bad_path = CString::new("/does/not/exist").unwrap();
    let handle = lindera_init(bad_path.as_ptr());
    assert!(handle.is_null());
}
```

- [ ] **Step 2: Run the test and confirm it fails to compile**

```bash
cd spikes/lindera_ffi_spike/rust && cargo test ffi_roundtrip
```
Expected: compile error — `lindera_init` etc. don't exist yet.

- [ ] **Step 3: Implement the FFI surface**

```rust
// spikes/lindera_ffi_spike/rust/src/lib.rs (append to the file from Task 1)
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

pub struct TokenizerHandle {
    tokenizer: Tokenizer,
}

#[derive(serde::Serialize)]
struct TokenizeResult {
    ok: bool,
    surfaces: Vec<String>,
    error: Option<String>,
}

#[no_mangle]
pub extern "C" fn lindera_init(dict_path: *const c_char) -> *mut TokenizerHandle {
    let dict_path = unsafe { CStr::from_ptr(dict_path) }.to_string_lossy().into_owned();
    let dictionary = match load_dictionary(&dict_path) {
        Ok(d) => d,
        Err(_) => return std::ptr::null_mut(),
    };
    let segmenter = Segmenter::new(Mode::Normal, dictionary, None);
    let tokenizer = Tokenizer::new(segmenter);
    Box::into_raw(Box::new(TokenizerHandle { tokenizer }))
}

#[no_mangle]
pub extern "C" fn lindera_tokenize_json(
    handle: *mut TokenizerHandle,
    text: *const c_char,
) -> *mut c_char {
    let handle = unsafe { &*handle };
    let text = unsafe { CStr::from_ptr(text) }.to_string_lossy().into_owned();

    let result = match handle.tokenizer.tokenize(&text) {
        Ok(tokens) => TokenizeResult {
            ok: true,
            surfaces: tokens.into_iter().map(|t| t.surface.to_string()).collect(),
            error: None,
        },
        Err(e) => TokenizeResult { ok: false, surfaces: vec![], error: Some(e.to_string()) },
    };
    let json = serde_json::to_string(&result).expect("TokenizeResult serialization cannot fail");
    CString::new(json).expect("no interior NUL in generated JSON").into_raw()
}

#[no_mangle]
pub extern "C" fn lindera_free_handle(handle: *mut TokenizerHandle) {
    if handle.is_null() {
        return;
    }
    unsafe {
        drop(Box::from_raw(handle));
    }
}

#[no_mangle]
pub extern "C" fn lindera_free_string(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        drop(CString::from_raw(ptr));
    }
}
```

- [ ] **Step 4: Run the tests and confirm they pass**

```bash
cd spikes/lindera_ffi_spike/rust && cargo test
```
Expected: all tests pass, including both from Task 1 and both new ones.

- [ ] **Step 5: Commit**

```bash
git add spikes/lindera_ffi_spike/rust/src/lib.rs spikes/lindera_ffi_spike/rust/tests/ffi_test.rs
git commit -m "spike(lindera): add stateful FFI surface (init/tokenize/free)"
```

---

### Task 3: Flutter harness scaffold + baseline APK size

**Files:**
- Create: `spikes/lindera_ffi_spike/harness/` (via `flutter create`)
- Create: `spikes/lindera_ffi_spike/BASELINE_APK_SIZE.txt`

**Interfaces:**
- Produces: a `flutter create`-scaffolded app at `harness/`, package name `com.softbrew.lindera_ffi_harness`, and a recorded baseline APK size (no native lib yet) that Task 8 diffs against.

- [ ] **Step 1: Scaffold the Flutter app**

```bash
cd spikes/lindera_ffi_spike
flutter create --platforms=android --org com.softbrew --project-name lindera_ffi_harness harness
```
Expected: `harness/` now contains a standard Flutter app (`lib/main.dart`, `pubspec.yaml`, `android/`).

- [ ] **Step 2: Build a baseline release APK before any native code exists**

```bash
cd harness
flutter build apk --release
ls -la build/app/outputs/flutter-apk/app-release.apk
```

- [ ] **Step 3: Record the baseline size**

```bash
cd spikes/lindera_ffi_spike
du -h harness/build/app/outputs/flutter-apk/app-release.apk | tee BASELINE_APK_SIZE.txt
```
Expected: `BASELINE_APK_SIZE.txt` now contains one line like `18M  harness/build/app/outputs/flutter-apk/app-release.apk`. This is the "before" number Task 8 subtracts from.

- [ ] **Step 4: Commit the harness scaffold and baseline**

```bash
git add spikes/lindera_ffi_spike/harness spikes/lindera_ffi_spike/BASELINE_APK_SIZE.txt
git commit -m "spike(lindera): scaffold Flutter harness, record baseline APK size"
```

---

### Task 4: 10k-sentence Japanese corpus

**Files:**
- Create: `spikes/lindera_ffi_spike/scripts/fetch_corpus.sh`
- Produces (gitignored, not committed): `spikes/lindera_ffi_spike/harness/assets/corpus_10k.txt`

**Interfaces:**
- Produces: a plain-text file, one Japanese sentence per line, exactly 10,000 lines, UTF-8.

- [ ] **Step 1: Add the corpus output path to `.gitignore`**

```gitignore
# append to spikes/lindera_ffi_spike/.gitignore
/harness/assets/corpus_10k.txt
```
*(Tatoeba sentences are CC-BY and fine to use as spike input — the frozen spec's "user-material only" decision governs the shipped app's corpus, not this throwaway benchmark fixture.)*

- [ ] **Step 2: Write the fetch script**

```bash
#!/usr/bin/env bash
# spikes/lindera_ffi_spike/scripts/fetch_corpus.sh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p harness/assets

curl -L -o /tmp/tatoeba_sentences.csv "https://downloads.tatoeba.org/exports/sentences.csv"

# Tatoeba's export is TSV: id, lang (ISO 639-3), text. "jpn" = Japanese.
awk -F'\t' '$2 == "jpn" { print $3 }' /tmp/tatoeba_sentences.csv | head -n 10000 > harness/assets/corpus_10k.txt

wc -l harness/assets/corpus_10k.txt
```

- [ ] **Step 3: Run it and verify the line count and content**

```bash
chmod +x spikes/lindera_ffi_spike/scripts/fetch_corpus.sh
spikes/lindera_ffi_spike/scripts/fetch_corpus.sh
head -3 spikes/lindera_ffi_spike/harness/assets/corpus_10k.txt
```
Expected: `wc -l` reports exactly `10000`, and the first three lines are readable Japanese text. If Tatoeba's Japanese subset has fewer than 10k sentences (unlikely — it's a long-established, large public corpus, but verify rather than assume), `wc -l` will report less; if so, note the actual count in Task 9's report instead of silently treating it as 10k.

- [ ] **Step 4: Commit the script (not the corpus data)**

```bash
git add spikes/lindera_ffi_spike/scripts/fetch_corpus.sh spikes/lindera_ffi_spike/.gitignore
git commit -m "spike(lindera): add Tatoeba JA corpus fetch script"
```

---

### Task 5: Cross-compile to Android (arm64-v8a) via cargo-ndk

**Files:**
- Create: `spikes/lindera_ffi_spike/scripts/build_android.sh`

**Interfaces:**
- Produces: `harness/android/app/src/main/jniLibs/arm64-v8a/liblindera_ffi_spike.so`, consumed by `DynamicLibrary.open` in Task 6.

- [ ] **Step 1: One-time toolchain setup**

```bash
rustup target add aarch64-linux-android
cargo install cargo-ndk
```
This requires the Android NDK to be installed and `ANDROID_NDK_HOME` set to its path — if you don't have it, install it via Android Studio's SDK Manager (SDK Tools → NDK) first.

- [ ] **Step 2: Write the build script**

```bash
#!/usr/bin/env bash
# spikes/lindera_ffi_spike/scripts/build_android.sh
set -euo pipefail
cd "$(dirname "$0")/../rust"
: "${ANDROID_NDK_HOME:?Set ANDROID_NDK_HOME to your NDK installation}"

cargo ndk -o ../harness/android/app/src/main/jniLibs -t arm64-v8a build --release

SO_PATH=../harness/android/app/src/main/jniLibs/arm64-v8a/liblindera_ffi_spike.so
file "$SO_PATH"
du -h "$SO_PATH"
```

- [ ] **Step 3: Run it and verify the output**

```bash
chmod +x spikes/lindera_ffi_spike/scripts/build_android.sh
spikes/lindera_ffi_spike/scripts/build_android.sh
```
Expected: `file` reports `ELF 64-bit LSB shared object, ARM aarch64` (or `pie executable`/`shared object` — the key part is `ARM aarch64`, not x86); `du -h` prints the `.so` size — record it, it feeds Task 9's report alongside the APK-size delta.

- [ ] **Step 4: Commit the script**

```bash
git add spikes/lindera_ffi_spike/scripts/build_android.sh
git commit -m "spike(lindera): cross-compile FFI crate for arm64-v8a via cargo-ndk"
```

---

### Task 6: Dart FFI bindings + benchmark screen

**Files:**
- Create: `spikes/lindera_ffi_spike/harness/lib/ffi_bindings.dart`
- Modify: `spikes/lindera_ffi_spike/harness/lib/main.dart`
- Modify: `spikes/lindera_ffi_spike/harness/pubspec.yaml`

**Interfaces:**
- Consumes: the four `extern "C"` functions from Task 2, loaded from `liblindera_ffi_spike.so` (placed by Task 5).
- Produces: `benchmark_report.json` written to the app's files directory at runtime, consumed by Task 7's pull script.

- [ ] **Step 1: Add dependencies**

```yaml
# spikes/lindera_ffi_spike/harness/pubspec.yaml — add under dependencies:
  ffi: ^2.1.0
  path_provider: ^2.1.0
```
Run `flutter pub get` inside `harness/` after editing.

- [ ] **Step 2: Write the FFI bindings**

```dart
// spikes/lindera_ffi_spike/harness/lib/ffi_bindings.dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef _InitNative = Pointer<Void> Function(Pointer<Utf8> dictPath);
typedef _InitDart = Pointer<Void> Function(Pointer<Utf8> dictPath);

typedef _TokenizeJsonNative = Pointer<Utf8> Function(Pointer<Void> handle, Pointer<Utf8> text);
typedef _TokenizeJsonDart = Pointer<Utf8> Function(Pointer<Void> handle, Pointer<Utf8> text);

typedef _FreeHandleNative = Void Function(Pointer<Void> handle);
typedef _FreeHandleDart = void Function(Pointer<Void> handle);

typedef _FreeStringNative = Void Function(Pointer<Utf8> ptr);
typedef _FreeStringDart = void Function(Pointer<Utf8> ptr);

class LinderaFfi {
  LinderaFfi._(this._init, this._tokenizeJson, this._freeHandle, this._freeString);

  final _InitDart _init;
  final _TokenizeJsonDart _tokenizeJson;
  final _FreeHandleDart _freeHandle;
  final _FreeStringDart _freeString;

  factory LinderaFfi.load() {
    final lib = DynamicLibrary.open('liblindera_ffi_spike.so');
    return LinderaFfi._(
      lib.lookupFunction<_InitNative, _InitDart>('lindera_init'),
      lib.lookupFunction<_TokenizeJsonNative, _TokenizeJsonDart>('lindera_tokenize_json'),
      lib.lookupFunction<_FreeHandleNative, _FreeHandleDart>('lindera_free_handle'),
      lib.lookupFunction<_FreeStringNative, _FreeStringDart>('lindera_free_string'),
    );
  }

  Pointer<Void> init(String dictPath) {
    final pathPtr = dictPath.toNativeUtf8();
    final handle = _init(pathPtr);
    malloc.free(pathPtr);
    if (handle.address == 0) {
      throw StateError('lindera_init failed to load dictionary at $dictPath');
    }
    return handle;
  }

  String tokenizeJson(Pointer<Void> handle, String text) {
    final textPtr = text.toNativeUtf8();
    final resultPtr = _tokenizeJson(handle, textPtr);
    final result = resultPtr.toDartString();
    _freeString(resultPtr);
    malloc.free(textPtr);
    return result;
  }

  void freeHandle(Pointer<Void> handle) => _freeHandle(handle);
}
```

- [ ] **Step 3: Write the benchmark screen**

```dart
// spikes/lindera_ffi_spike/harness/lib/main.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'ffi_bindings.dart';

void main() => runApp(const BenchmarkApp());

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: BenchmarkScreen());
}

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    _runBenchmark();
  }

  Future<void> _runBenchmark() async {
    setState(() => _status = 'Locating fixtures...');
    final filesDir = await getApplicationDocumentsDirectory();
    final dictPath = '${filesDir.path}/lindera_dict';
    final corpusPath = '${filesDir.path}/corpus_10k.txt';

    if (!Directory(dictPath).existsSync()) {
      setState(() => _status =
          'Missing dictionary at $dictPath\nRun scripts/push_fixtures.sh first, then relaunch.');
      return;
    }
    if (!File(corpusPath).existsSync()) {
      setState(() => _status =
          'Missing corpus at $corpusPath\nRun scripts/push_fixtures.sh first, then relaunch.');
      return;
    }

    final sentences =
        File(corpusPath).readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
    final ffi = LinderaFfi.load();

    setState(() => _status = 'Loading dictionary (cold start)...');
    final coldStartWatch = Stopwatch()..start();
    final handle = ffi.init(dictPath);
    coldStartWatch.stop();
    final coldStartMs = coldStartWatch.elapsedMicroseconds / 1000.0;

    setState(() => _status = 'Tokenizing ${sentences.length} sentences...');
    final latenciesMicros = <int>[];
    for (final sentence in sentences) {
      final sw = Stopwatch()..start();
      final json = ffi.tokenizeJson(handle, sentence);
      sw.stop();
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      if (decoded['ok'] != true) {
        throw StateError('tokenize failed for "$sentence": ${decoded['error']}');
      }
      latenciesMicros.add(sw.elapsedMicroseconds);
    }
    ffi.freeHandle(handle);

    latenciesMicros.sort();
    final p50Ms = latenciesMicros[(latenciesMicros.length * 0.50).floor()] / 1000.0;
    final p99Ms = latenciesMicros[(latenciesMicros.length * 0.99).floor()] / 1000.0;
    final dictSizeBytes = _dirSizeBytes(Directory(dictPath));

    final report = {
      'sentenceCount': sentences.length,
      'coldStartMs': coldStartMs,
      'p50Ms': p50Ms,
      'p99Ms': p99Ms,
      'dictSizeBytes': dictSizeBytes,
    };
    final reportFile = File('${filesDir.path}/benchmark_report.json');
    reportFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

    setState(() => _status = 'Done. Report at ${reportFile.path}\n\n$report');
  }

  int _dirSizeBytes(Directory dir) {
    var total = 0;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File) total += entity.lengthSync();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lindera FFI Spike')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(child: Text(_status)),
      ),
    );
  }
}
```

*(Note on `getApplicationDocumentsDirectory()`: on Android, `path_provider` documents this as resolving to the app's internal files directory — the same directory `run-as`'s default working directory targets in Task 7. Verify this holds for the installed `path_provider` version with Step 4 below; if the path doesn't match what Task 7 pushed to, `adb shell run-as <pkg> ls files/` and adjust either the push destination or this lookup to match.)*

- [ ] **Step 4: Static-check the harness compiles**

```bash
cd spikes/lindera_ffi_spike/harness
flutter analyze
```
Expected: no errors (warnings about unused imports etc. are fine to ignore for a throwaway spike).

- [ ] **Step 5: Commit**

```bash
git add spikes/lindera_ffi_spike/harness/lib spikes/lindera_ffi_spike/harness/pubspec.yaml \
        spikes/lindera_ffi_spike/harness/pubspec.lock
git commit -m "spike(lindera): Dart FFI bindings + benchmark screen"
```

---

### Task 7: Fixture push / report pull scripts

**Files:**
- Create: `spikes/lindera_ffi_spike/scripts/push_fixtures.sh`
- Create: `spikes/lindera_ffi_spike/scripts/pull_report.sh`

**Interfaces:**
- Consumes: `dict/lindera-ipadic-2.7.0-20250920` (Task 1), `harness/assets/corpus_10k.txt` (Task 4).
- Produces: fixtures placed at `<app files dir>/lindera_dict` and `<app files dir>/corpus_10k.txt` on-device; `benchmark_report.json` pulled back to the repo.

- [ ] **Step 1: Write the push script**

```bash
#!/usr/bin/env bash
# spikes/lindera_ffi_spike/scripts/push_fixtures.sh
set -euo pipefail
cd "$(dirname "$0")/.."
PKG=com.softbrew.lindera_ffi_harness

adb push dict/lindera-ipadic-2.7.0-20250920 /data/local/tmp/lindera_dict
adb push harness/assets/corpus_10k.txt /data/local/tmp/corpus_10k.txt

# run-as lets the debuggable app's own uid copy out of shell-only /data/local/tmp
# into its private files dir, which shell/adb cannot write to directly.
adb shell run-as "$PKG" mkdir -p files
adb shell run-as "$PKG" cp -r /data/local/tmp/lindera_dict files/lindera_dict
adb shell run-as "$PKG" cp /data/local/tmp/corpus_10k.txt files/corpus_10k.txt

echo "Fixtures pushed into $PKG's private storage."
adb shell run-as "$PKG" ls -la files/
```

- [ ] **Step 2: Write the pull script**

```bash
#!/usr/bin/env bash
# spikes/lindera_ffi_spike/scripts/pull_report.sh
set -euo pipefail
cd "$(dirname "$0")/.."
PKG=com.softbrew.lindera_ffi_harness

adb shell run-as "$PKG" cat files/benchmark_report.json > benchmark_report.json
cat benchmark_report.json
```

- [ ] **Step 3: Make both executable and commit**

```bash
chmod +x spikes/lindera_ffi_spike/scripts/push_fixtures.sh spikes/lindera_ffi_spike/scripts/pull_report.sh
git add spikes/lindera_ffi_spike/scripts/push_fixtures.sh spikes/lindera_ffi_spike/scripts/pull_report.sh
git commit -m "spike(lindera): add device fixture push / report pull scripts"
```

---

### Task 8: Run on a physical Android device — **requires hardware, hand off if unavailable**

**Files:** none created — this task produces `spikes/lindera_ffi_spike/benchmark_report.json` (gitignored) and a recorded final APK size.

- [ ] **Step 1: Connect the device and confirm `adb` sees it**

```bash
adb devices
```
Expected: exactly one device listed as `device` (not `unauthorized` — if so, accept the USB debugging prompt on the phone).

- [ ] **Step 2: Build and install the debug APK**

```bash
cd spikes/lindera_ffi_spike/harness
flutter build apk --debug
flutter install --debug
```
*(A debug build is required for `run-as` to work in Task 7 — release builds aren't debuggable by default.)*

- [ ] **Step 3: Push fixtures**

```bash
cd spikes/lindera_ffi_spike
scripts/push_fixtures.sh
```
Expected: the final `ls -la files/` shows both `lindera_dict/` and `corpus_10k.txt` inside the app's private storage.

- [ ] **Step 4: Launch the app and wait for it to finish**

```bash
adb shell am start -n com.softbrew.lindera_ffi_harness/.MainActivity
```
Watch the device screen: status text should progress from "Loading dictionary..." through "Tokenizing 10000 sentences..." to "Done." If it instead shows a missing-fixture message, re-run Task 7's push script and confirm the `getApplicationDocumentsDirectory()` path note from Task 6 Step 3 — the two must agree.

- [ ] **Step 5: Pull the benchmark report**

```bash
scripts/pull_report.sh
```
Expected: valid JSON with `sentenceCount`, `coldStartMs`, `p50Ms`, `p99Ms`, `dictSizeBytes` populated with real numbers.

- [ ] **Step 6: Build the release APK and measure the size delta**

```bash
cd harness
flutter build apk --release
du -h build/app/outputs/flutter-apk/app-release.apk
```
Compare this against `BASELINE_APK_SIZE.txt` from Task 3 — the difference is the APK size impact of adding Lindera + the arm64-v8a `.so` (note: this release APK doesn't bundle the dictionary itself, since the dictionary is loaded from app-private storage rather than shipped in-APK for this spike; if the real app later ships the dictionary in-APK per the frozen spec's §0.5 answer, that adds the dictionary's on-disk size on top of this delta).

---

### Task 9: Write the proof report and freeze Phase 1

**Files:**
- Create: `BERICHT_1_lindera-ffi-spike.md` (repo root, matching the `BERICHT_<n>_<name>.md` convention from `SPEC_MINING_PIPELINE.md` §10)

- [ ] **Step 1: Write the report**

```markdown
# BERICHT 1 — Lindera FFI Spike

**Phase:** 1 (kill gate) · **Date:** <fill in actual run date>
**Device:** <fill in actual model, Android version, chipset>

## Measured results

| Metric | Value |
|---|---|
| Sentence count | <from benchmark_report.json: sentenceCount> |
| Cold start (dictionary load) | <coldStartMs> ms |
| Per-sentence latency p50 | <p50Ms> ms |
| Per-sentence latency p99 | <p99Ms> ms |
| Dictionary size on disk | <dictSizeBytes, converted to MB> |
| Baseline APK size (no native lib) | <from BASELINE_APK_SIZE.txt> |
| Release APK size (with Lindera + arm64-v8a .so) | <from Task 8 Step 6> |
| APK size delta | <difference> |

## Raw data

<paste the full contents of benchmark_report.json here>

## Verdict

<GO or KILL, with the reasoning tied to the numbers above — e.g. "p99 latency of Xms per sentence means tokenizing a full novel (~Y sentences) takes Zs, which is/isn't compatible with the <10s pipeline gate in §3">
```

- [ ] **Step 2: Fill in the template with the real numbers from Task 8** — do not leave any `<...>` placeholder in the committed file.

- [ ] **Step 3: Commit**

```bash
git add BERICHT_1_lindera-ffi-spike.md
git commit -m "docs(phase1): record Lindera FFI spike measurements and verdict"
```

## Self-Review

**Spec coverage:** all four required metrics (cold-start, p50/p99, dict size, APK impact) are captured (Task 9); 10k-sentence corpus (Task 4); physical device requirement (Tasks 8–9 hardware-gated); isolation from `lib/` (everything under `spikes/`).

**Placeholder scan:** the report template in Task 9 intentionally contains `<...>` fill-ins as a template — Step 2 explicitly requires removing all of them before commit; no other task has unresolved placeholders.

**Type consistency:** the FFI signatures match across Rust (`lindera_init`/`lindera_tokenize_json`/`lindera_free_handle`/`lindera_free_string`) and Dart (`_InitDart`/`_TokenizeJsonDart`/`_FreeHandleDart`/`_FreeStringDart` in `ffi_bindings.dart`) — same four names, same parameter order, checked in Task 6.

**Known verification points to watch during execution** (flagged rather than guessed away):
- `build_dict.sh`'s tarball layout assumption (Task 1, Step 2 note).
- `getApplicationDocumentsDirectory()` ↔ `run-as` files-dir path agreement (Task 6 Step 3 note, Task 8 Step 4).
- Tatoeba's Japanese subset actually containing ≥10k sentences (Task 4 Step 3 note).
