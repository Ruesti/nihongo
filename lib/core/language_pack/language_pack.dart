/// The four seams (SPEC_MINING_PIPELINE.md §2.2). All language-specific
/// behaviour must live behind these interfaces — adding a language is a
/// data package plus one adapter registration, never a branch in
/// pipeline code.
///
/// Seam discipline rule: if pipeline code ever needs `if (lang == 'ja')`,
/// the seam is wrong and the design is reopened.
library;

/// A tokenizer hit: one morpheme/word within a piece of text.
///
/// [pos] is the raw part-of-speech tag from the source tokenizer/
/// dictionary (e.g. IPADIC's `名詞,固有名詞,組織`) rather than a
/// unified enum — different languages' tag sets don't collapse onto a
/// shared vocabulary cleanly, and the pipeline (§3 scoring) only ever
/// needs to compare tags for equality, never interpret their meaning.
class Token {
  final String surface; // as it appears in the text
  final String lemma; // normalised dictionary form
  final String? reading; // kana for JA, null elsewhere
  final String pos;
  final int charStart;
  final int charEnd; // span into the source text — furigana + highlight

  const Token({
    required this.surface,
    required this.lemma,
    this.reading,
    required this.pos,
    required this.charStart,
    required this.charEnd,
  });
}

/// One dictionary sense for a looked-up lemma.
class Sense {
  final String pos;
  final List<String> glosses;

  const Sense({required this.pos, required this.glosses});
}

/// The reading (pronunciation) of a single token, where the script has
/// a reading layer (kana for JA, pinyin for ZH, ...). `null` for
/// languages without one (§2.2's ReadingProvider is nullable on
/// [LanguagePack] for exactly this reason).
class Reading {
  final String text;

  const Reading(this.text);
}

abstract interface class Tokenizer {
  List<Token> tokenize(String text);
}

abstract interface class Dictionary {
  List<Sense> lookup(String lemma, String pos);
}

abstract interface class FrequencyList {
  /// Lower rank = more common. `null` if the lemma isn't in the list.
  int? rank(String lemma);

  /// The [n] most common lemmas, most common first. Added in Phase 4
  /// for knowledge-bootstrap import (§0.4.14: "mark first N of
  /// frequency list as known") — a single lemma lookup can't answer
  /// "what are the N most common words," so the seam needed this to
  /// support that decided bootstrap path.
  List<String> topLemmas(int n);
}

abstract interface class ReadingProvider {
  Reading? reading(Token token);
}

/// A language pack: everything the mining pipeline needs to process one
/// language, resolved by [code] through a registry (Phase 2 proves the
/// registry generalizes via a second, data-free stub pack).
abstract interface class LanguagePack {
  String get code; // BCP-47
  Tokenizer get tokenizer;
  Dictionary get dictionary;
  FrequencyList get frequency;
  ReadingProvider? get readings; // null for languages without a reading layer
}
