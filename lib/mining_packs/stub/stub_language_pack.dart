import '../../core/language_pack/language_pack.dart';

/// A whitespace-language stub pack with **no real data** — its whole
/// purpose is to prove the four-seam design (§2.2) genuinely
/// generalizes past JA, per Phase 2's gate: "second stub LanguagePack
/// (no real data) compiles and registers." Unlike the JA tokenizer,
/// this one actually runs — ICU-style whitespace/punctuation
/// word-breaking needs no FFI, no dictionary import, no toolchain.
///
/// Code `xx` is the ISO 639 reserved-for-testing/private-use language
/// tag — deliberately not a real language, so nobody mistakes this for
/// production coverage of an actual second language (§0.2 confirms no
/// real second pack ships in v1).
class StubLanguagePack implements LanguagePack {
  @override
  final String code = 'xx';

  @override
  final Tokenizer tokenizer = const _WhitespaceTokenizer();

  @override
  final Dictionary dictionary = const _EmptyDictionary();

  @override
  final FrequencyList frequency = const _EmptyFrequencyList();

  @override
  final ReadingProvider? readings = null; // no reading layer, per §2.2

  const StubLanguagePack();
}

final _wordPattern = RegExp(r"[^\s.,!?;:'‘’“”()\[\]]+");

class _WhitespaceTokenizer implements Tokenizer {
  const _WhitespaceTokenizer();

  @override
  List<Token> tokenize(String text) {
    return _wordPattern.allMatches(text).map((m) {
      final surface = m.group(0)!;
      return Token(
        surface: surface,
        lemma: surface.toLowerCase(),
        pos: 'X', // no POS tagger for the stub — unknown/other
        charStart: m.start,
        charEnd: m.end,
      );
    }).toList();
  }
}

class _EmptyDictionary implements Dictionary {
  const _EmptyDictionary();

  @override
  List<Sense> lookup(String lemma, String pos) => const [];
}

class _EmptyFrequencyList implements FrequencyList {
  const _EmptyFrequencyList();

  @override
  int? rank(String lemma) => null;

  @override
  List<String> topLemmas(int n) => const [];
}
