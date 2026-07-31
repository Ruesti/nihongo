import 'dart:convert';

import '../../core/language_pack/language_pack.dart';
import 'native_tokenizer_bindings.dart';

/// The real JA `Tokenizer`, backed by Lindera + embedded IPADIC via a
/// host-compiled native library (see native/ja_tokenizer). Supersedes
/// the `_JaTokenizerPendingIntegration` placeholder now that Phase 3
/// needs a working tokenizer in the pipeline loop.
///
/// Char offsets ([Token.charStart]/[charEnd]) are computed here, not
/// trusted from the native side: Lindera reports UTF-8 byte offsets,
/// but Dart strings index by UTF-16 code unit — translating one to the
/// other correctly for non-ASCII text is exactly the kind of subtle
/// bug that's easy to get wrong silently. Instead, tokens are located
/// by scanning the original Dart string sequentially for each returned
/// surface form, which is correct by construction in Dart's own index
/// space and requires no cross-representation math at all.
class NativeJaTokenizer implements Tokenizer {
  final NativeTokenizerBindings _bindings;

  NativeJaTokenizer({NativeTokenizerBindings? bindings})
      : _bindings = bindings ?? NativeTokenizerBindings.load();

  @override
  List<Token> tokenize(String text) {
    final json = _bindings.tokenizeJson(text);
    final decoded = jsonDecode(json) as List;

    var cursor = 0;
    final tokens = <Token>[];
    for (final raw in decoded) {
      final map = raw as Map<String, dynamic>;
      final surface = map['surface'] as String;
      if (surface.isEmpty) continue;

      final start = text.indexOf(surface, cursor);
      final charStart = start == -1 ? cursor : start;
      final charEnd = charStart + surface.length;

      tokens.add(Token(
        surface: surface,
        lemma: map['lemma'] as String,
        reading: map['reading'] as String?,
        pos: map['pos'] as String,
        charStart: charStart,
        charEnd: charEnd,
      ));
      cursor = charEnd;
    }
    return tokens;
  }
}
