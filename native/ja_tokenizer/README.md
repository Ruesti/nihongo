# ja_tokenizer

Host-native JA tokenizer library (Lindera 4.0.0 + embedded IPADIC),
loaded from Dart via plain `dart:ffi`. Backs `NativeJaTokenizer` in
`lib/mining_packs/ja/native_tokenizer.dart`.

Deliberately **not** using `flutter_rust_bridge`/`cargokit` — that
Android-focused toolchain lives at `spike/lindera_spike/` (Phase 1,
`BERICHT_1_lindera-spike.md`) and proved Lindera is viable on-device.
This crate reuses the same tokenizer configuration for a desktop/CLI
target, since Phase 3 ("Pipeline stages 1–4, headless") doesn't need
Android at all — a plain FFI cdylib is far less machinery.

## Building

```sh
cd native/ja_tokenizer
cargo build --release
```

Produces `target/release/libja_tokenizer.so` (Linux) /
`libja_tokenizer.dylib` (macOS) / `ja_tokenizer.dll` (Windows), which
`NativeTokenizerBindings` loads from a path relative to the repo root.
Not committed (build artifact) — rebuild after every `cargo clean` or
fresh checkout. Anything under `lib/mining_packs/ja/` or
`test/mining_packs/ja/native_tokenizer_test.dart` that touches the
tokenizer requires this build step first.

## Testing

Rust-level tests (no FFI, no Dart) run directly against the same
tokenizer code the FFI wrapper calls:

```sh
cargo test --release
```

Dart-level tests (`test/mining_packs/ja/native_tokenizer_test.dart`)
exercise the actual FFI boundary and require the release build above.

## Version pin

`lindera = "=4.0.0"` — `lindera-dictionary` 4.0.1's `embed-ipadic`
build is broken upstream (missing output-directory creation before
writing `dict.words`; see `BERICHT_1_lindera-spike.md` and
[lindera/lindera#835](https://github.com/lindera/lindera/issues/835)).
4.0.0 resolves working builder code even though `lindera-ipadic` itself
still resolves to 4.0.1 as a transitive dependency. Do not bump past
4.0.0 without re-verifying that issue is fixed.
