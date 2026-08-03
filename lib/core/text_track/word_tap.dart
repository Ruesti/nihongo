import '../language_pack/language_pack.dart';

/// The one interaction model (SPEC_MINING_PIPELINE.md §5): "Tap a word
/// → same lookup, same mining action, regardless of medium." This is
/// that lookup, medium-agnostic by construction: it operates on a
/// [Token] (already medium-independent — the tokenizer produces the
/// same Token whether the source span came from an EPUB FlowAnchor or
/// an SRT TimeAnchor) and a [Dictionary] seam. Nothing here can even
/// observe which medium a tap came from, which is the whole point.
class WordTapResult {
  final Token token;
  final List<Sense> senses;

  const WordTapResult({required this.token, required this.senses});

  bool get isKnownWord => senses.isNotEmpty;
}

class WordTapHandler {
  final Dictionary dictionary;

  const WordTapHandler(this.dictionary);

  WordTapResult onTap(Token token) {
    return WordTapResult(
      token: token,
      senses: dictionary.lookup(token.lemma, ''),
    );
  }
}
