import '../../core/language_pack/language_pack.dart';

/// The Spanish `Tokenizer`: §2.2's "whitespace-language implementation"
/// (ICU word-break, simplified to a Unicode word regex). No FFI, no
/// dictionary, no toolchain — exactly the cheap seam the four-seam
/// design promised for whitespace languages, in contrast to JA's
/// Lindera FFI. The lemma is the lowercased surface; real ES
/// lemmatisation (conjugation → infinitive) would be a pack-quality
/// improvement, not an architecture change — the seam contract is
/// unaffected.
class EsWhitespaceTokenizer implements Tokenizer {
  const EsWhitespaceTokenizer();

  // A run of letters (incl. accented Latin) and apostrophes/hyphens
  // within a word. Punctuation and whitespace are delimiters.
  static final _word = RegExp(r"[\p{L}\p{M}]+(?:['\-][\p{L}\p{M}]+)*", unicode: true);

  @override
  List<Token> tokenize(String text) {
    return _word.allMatches(text).map((m) {
      final surface = m.group(0)!;
      return Token(
        surface: surface,
        lemma: surface.toLowerCase(),
        pos: 'X', // no POS tagger for the whitespace seam
        charStart: m.start,
        charEnd: m.end,
      );
    }).toList();
  }
}
