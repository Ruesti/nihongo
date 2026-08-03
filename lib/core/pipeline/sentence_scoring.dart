/// Sentence scoring (SPEC_MINING_PIPELINE.md §3). Language-blind — the
/// whole point of the four-seam design is that this file never checks
/// which language it's scoring. Takes a [Tokenizer] and a
/// [FrequencyList] (both from `core/language_pack`) plus a knowledge
/// source as parameters, and knows nothing else about how either is
/// implemented.
library;

import '../db/mining_db.dart';
import '../language_pack/language_pack.dart';

enum Knowledge { unknown, learning, known }

/// A knowledge-state lookup, injected rather than hard-wired — Phase 3
/// only needs *a* Knowledge source to prove the scoring formulas work
/// end to end; how "known" is actually determined (FSRS stability,
/// review count, explicit mark — §0.4.13) is separate, later
/// integration work with the `Cards`/`ReviewLogs` tables.
typedef KnowledgeSource = Knowledge Function(String lemma);

// Matches a whole surface made only of Unicode punctuation/symbol
// characters (｡？！, ., ", (), ... — any script). Nobody "learns" a
// full stop; counting it toward unknownCount would let punctuation
// masquerade as the i+1 target lemma. Deliberately a Unicode-category
// check, not a tokenizer-specific POS tag comparison (e.g. IPADIC's
// `記号`) — that would leak a JA-specific convention into this
// language-blind file, violating the seam-discipline rule this file's
// own doc comment states.
final _punctuationOnlyPattern = RegExp(r'^[\p{P}\p{S}]+$', unicode: true);

/// True for a token that carries vocabulary (not a punctuation/symbol
/// mark). Public because the passage-snapshot metric (Phase 8) computes
/// unknown-token *ratio* over the same content-token notion — reusing
/// this keeps the two definitions from diverging, and it's already
/// covered by the punctuation-exclusion tests here.
bool isContentToken(Token t) => !_punctuationOnlyPattern.hasMatch(t.surface);

/// One scored segment: §2.3's `ScoredSegment`, built from a
/// [TextSpan] (this repo's name for §2.3's `Segment` — see
/// `core/db/mining_tables.dart`, "TextSpans... replaces standalone
/// `segment`" per §9. Reusing the Drift row type directly rather than
/// duplicating an identical `Segment` class).
class ScoredSegment {
  final TextSpan segment;
  final List<Token> tokens;
  final int unknownCount;
  final double knownRatio;

  /// Frequency rank of the single unknown lemma, only when
  /// [unknownCount] == 1 (§2.3).
  final int? targetRank;

  /// The single unknown lemma itself, only when [unknownCount] == 1.
  /// Exposed directly rather than making callers re-derive "which
  /// token is the unknown one" from [tokens] — that list still
  /// includes punctuation (kept for rendering), so re-filtering it
  /// without also excluding punctuation is an easy way to reintroduce
  /// exactly the bug [isContentToken] exists to prevent.
  final String? targetLemma;

  const ScoredSegment({
    required this.segment,
    required this.tokens,
    required this.unknownCount,
    required this.knownRatio,
    required this.targetRank,
    required this.targetLemma,
  });
}

/// Scores one [TextSpan] per §3's formulas:
/// ```
/// unknownCount = |{t : knowledge(t.lemma) == unknown}|
/// knownRatio   = |{t : knowledge == known}| / |tokens|
/// ```
/// Punctuation-only tokens (see [isContentToken]) are excluded from
/// both counts — they're still present in [ScoredSegment.tokens]
/// (needed for furigana/highlight rendering, §2.3), just not counted
/// as vocabulary.
ScoredSegment scoreSegment(
  TextSpan segment,
  Tokenizer tokenizer,
  FrequencyList frequency,
  KnowledgeSource knowledgeOf,
) {
  final tokens = tokenizer.tokenize(segment.content);
  final contentTokens = tokens.where(isContentToken).toList();
  final states = contentTokens.map((t) => knowledgeOf(t.lemma)).toList();

  final unknownCount = states.where((k) => k == Knowledge.unknown).length;
  final knownCount = states.where((k) => k == Knowledge.known).length;
  final knownRatio =
      contentTokens.isEmpty ? 0.0 : knownCount / contentTokens.length;

  int? targetRank;
  String? targetLemma;
  if (unknownCount == 1) {
    final unknownIndex = states.indexOf(Knowledge.unknown);
    targetLemma = contentTokens[unknownIndex].lemma;
    targetRank = frequency.rank(targetLemma);
  }

  return ScoredSegment(
    segment: segment,
    tokens: tokens,
    unknownCount: unknownCount,
    knownRatio: knownRatio,
    targetRank: targetRank,
    targetLemma: targetLemma,
  );
}

/// Scores every segment in [segments] — the "Segmentation -> Tokenizer
/// -> Lemma normalisation -> Knowledge lookup -> Sentence scoring"
/// stages of §2.1's pipeline, linear in total token count per §3's
/// complexity requirement.
List<ScoredSegment> scoreAll(
  Iterable<TextSpan> segments,
  Tokenizer tokenizer,
  FrequencyList frequency,
  KnowledgeSource knowledgeOf,
) =>
    segments
        .map((s) => scoreSegment(s, tokenizer, frequency, knowledgeOf))
        .toList();

/// The true i+1 candidate pool (`unknownCount == 1`), ranked per §3's
/// descending-priority rules:
/// 1. (pool membership itself: unknownCount == 1)
/// 2. Lower frequency rank of the target lemma (more common -> higher yield)
/// 3. Segment length within [minLen, maxLen]
/// 4. Presence of a time anchor (audio available)
List<ScoredSegment> rankCandidates(
  List<ScoredSegment> scored, {
  int minLen = 6,
  int maxLen = 60,
}) {
  final candidates = scored.where((s) => s.unknownCount == 1).toList();

  bool inLengthRange(ScoredSegment s) {
    final len = s.segment.content.length;
    return len >= minLen && len <= maxLen;
  }

  bool hasAudio(ScoredSegment s) => s.segment.tStartMs != null;

  candidates.sort((a, b) {
    // Rank 2: lower frequency rank first. An unranked lemma (not in
    // the corpus) is treated as worse than any ranked one, not better.
    final rankA = a.targetRank ?? 1 << 30;
    final rankB = b.targetRank ?? 1 << 30;
    if (rankA != rankB) return rankA.compareTo(rankB);

    // Rank 3: preferred length range wins ties.
    final aInRange = inLengthRange(a);
    final bInRange = inLengthRange(b);
    if (aInRange != bInRange) return aInRange ? -1 : 1;

    // Rank 4: audio-backed segments win remaining ties.
    final aAudio = hasAudio(a);
    final bAudio = hasAudio(b);
    if (aAudio != bAudio) return aAudio ? -1 : 1;

    return 0;
  });

  return candidates;
}

/// The secondary pool (`unknownCount == 2`) — per §3, "retained as a
/// secondary pool, surfaced only when the i+1 pool is exhausted."
/// Unranked (no frequency/length/audio ordering is specified for it in
/// the spec); callers draw from here only after [rankCandidates] runs
/// dry.
List<ScoredSegment> secondaryCandidates(List<ScoredSegment> scored) =>
    scored.where((s) => s.unknownCount == 2).toList();
