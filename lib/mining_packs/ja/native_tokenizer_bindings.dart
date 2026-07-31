import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _TokenizeJsonNative = Pointer<Utf8> Function(Pointer<Utf8> text);
typedef _TokenizeJsonDart = Pointer<Utf8> Function(Pointer<Utf8> text);

typedef _FreeStringNative = Void Function(Pointer<Utf8> s);
typedef _FreeStringDart = void Function(Pointer<Utf8> s);

/// Loads and binds `native/ja_tokenizer`'s compiled shared library.
/// Host-native only (no Android/iOS binding here — Phase 3 is headless;
/// see `native/ja_tokenizer/README.md`).
class NativeTokenizerBindings {
  final DynamicLibrary _lib;
  late final _TokenizeJsonDart _tokenizeJson;
  late final _FreeStringDart _freeString;

  NativeTokenizerBindings._(this._lib) {
    _tokenizeJson = _lib
        .lookupFunction<_TokenizeJsonNative, _TokenizeJsonDart>('ja_tokenize_json');
    _freeString =
        _lib.lookupFunction<_FreeStringNative, _FreeStringDart>('ja_free_string');
  }

  factory NativeTokenizerBindings.load({String? libraryPath}) {
    final path = libraryPath ?? _defaultLibraryPath();
    return NativeTokenizerBindings._(DynamicLibrary.open(path));
  }

  /// Tokenizes [text] and returns the raw JSON response from the
  /// native library. Freed internally — callers get a plain Dart
  /// String, never a native pointer.
  String tokenizeJson(String text) {
    final textPtr = text.toNativeUtf8();
    try {
      final resultPtr = _tokenizeJson(textPtr);
      try {
        return resultPtr.toDartString();
      } finally {
        _freeString(resultPtr);
      }
    } finally {
      malloc.free(textPtr);
    }
  }

  static String _defaultLibraryPath() {
    const relative = 'native/ja_tokenizer/target/release';
    if (Platform.isLinux) return '$relative/libja_tokenizer.so';
    if (Platform.isMacOS) return '$relative/libja_tokenizer.dylib';
    if (Platform.isWindows) return '$relative/ja_tokenizer.dll';
    throw UnsupportedError(
      'No prebuilt native ja_tokenizer library path known for '
      '${Platform.operatingSystem}. Android/iOS wiring is deferred '
      '(see JaLanguagePack\'s tokenizer docs) — this loader is for '
      'the Phase 3 headless CLI harness on desktop.',
    );
  }
}
