import '../language_pack/language_pack.dart';
import 'passage_snapshot.dart' show computeUnknownRatio;
import 'sentence_scoring.dart' show KnowledgeSource;

/// How a passage's unknown-token ratio sits relative to a learner: too
/// easy (nothing new to mine), ideal (comprehensible but with i+1 to
/// gain), or too hard (a wall).
enum Fit { tooEasy, ideal, tooHard }

/// The i+1 sweet spot (SPEC_MINING_PIPELINE.md §0 — comprehensible input
/// just above the learner's level). A passage whose unknown ratio falls
/// in `[lower, upper]` is worth reading now; below is nothing new, above
/// is overwhelming. Defaults ≈ 2–15 % unknown, tunable.
class IPlusOneWindow {
  final double lower;
  final double upper;

  const IPlusOneWindow({this.lower = 0.02, this.upper = 0.15});

  Fit classify(double unknownRatio) => unknownRatio < lower
      ? Fit.tooEasy
      : unknownRatio > upper
          ? Fit.tooHard
          : Fit.ideal;
}

/// A candidate passage scored for one learner.
class RankedPassage<T> {
  final T passage;
  final double unknownRatio;
  final Fit fit;

  const RankedPassage({
    required this.passage,
    required this.unknownRatio,
    required this.fit,
  });
}

/// Ranks candidate passages by i+1 suitability for a knowledge state —
/// so the reader starts a learner on gentle, comprehensible content
/// instead of a wall (no more throwing a beginner at Rashōmon).
///
/// Order: **ideal** first, easiest first, so the learner ramps up
/// gently; then **too hard**, least-hard first (the least-overwhelming
/// reach when nothing ideal exists); then **too easy** last
/// (comprehensible but with nothing new to mine), the most-challenging of
/// those first. Language-blind: it only consumes unknown ratios via the
/// shared [computeUnknownRatio].
List<RankedPassage<T>> rankByIPlusOne<T>(
  Iterable<T> passages,
  List<Token> Function(T) tokensOf,
  KnowledgeSource knowledgeOf, {
  IPlusOneWindow window = const IPlusOneWindow(),
}) {
  final ranked = <RankedPassage<T>>[];
  for (final p in passages) {
    final ratio = computeUnknownRatio(tokensOf(p), knowledgeOf);
    ranked.add(RankedPassage<T>(
        passage: p, unknownRatio: ratio, fit: window.classify(ratio)));
  }

  int priority(Fit f) => switch (f) {
        Fit.ideal => 0,
        Fit.tooHard => 1,
        Fit.tooEasy => 2,
      };

  ranked.sort((a, b) {
    final byFit = priority(a.fit).compareTo(priority(b.fit));
    if (byFit != 0) return byFit;
    // ideal & tooHard: ascending (easiest / least-hard first).
    // tooEasy: descending (closest to having something to mine first).
    return a.fit == Fit.tooEasy
        ? b.unknownRatio.compareTo(a.unknownRatio)
        : a.unknownRatio.compareTo(b.unknownRatio);
  });
  return ranked;
}
