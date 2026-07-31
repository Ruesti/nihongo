import '../language_pack/language_pack.dart';
import 'sentence_scoring.dart';

/// The default `known`-set bootstrap decided in §0.4.14: "mark first N
/// of frequency list as known." Language-blind — works against any
/// [FrequencyList], not just JA's. A lemma with no rank in the corpus
/// (i.e. [FrequencyList.rank] returns `null`) is `unknown`, not
/// `learning`: `learning` means "has real review history," which
/// nothing produces yet without the FSRS/Cards integration (deferred,
/// same as noted in `ja_language_pack.dart`'s tokenizer docs before
/// PR #6 wired that seam up).
class FrequencyBootstrapKnowledge {
  final FrequencyList frequency;
  final int knownRankThreshold;

  const FrequencyBootstrapKnowledge(
    this.frequency, {
    required this.knownRankThreshold,
  });

  Knowledge call(String lemma) {
    final rank = frequency.rank(lemma);
    if (rank == null) return Knowledge.unknown;
    return rank <= knownRankThreshold ? Knowledge.known : Knowledge.unknown;
  }
}
