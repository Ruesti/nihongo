import '../../core/language_pack/language_pack.dart';
import '../../core/pipeline/content_selector.dart';
import '../../core/pipeline/sentence_scoring.dart';
import 'comic_pack.dart';

/// All L2 tokens on a page (L1 bubbles carry none → never mined/tested).
List<Token> l2TokensOf(ComicPage page) => [
      for (final b in page.bubbles)
        if (b.lang == BubbleLang.l2) ...b.tokens,
    ];

/// The next comic page for this learner: prefer an i+1 "ideal" fit,
/// else the page nearest the window band. Reuses the shared
/// `rankByIPlusOne` ranker — no comic-specific scoring, and no
/// language branch.
///
/// "Nearest" respects fit category before raw distance: a too-hard
/// page still has something new to mine, a too-easy page has nothing,
/// so an overshoot beats an undershoot even when the undershoot's
/// numeric gap to the band is smaller (matches `rankByIPlusOne`'s own
/// priority — ideal, then too-hard, then too-easy last).
ComicPage? nextComicPage(
  Iterable<ComicPage> pages,
  KnowledgeSource knowledgeOf, {
  IPlusOneWindow window = const IPlusOneWindow(),
}) {
  final ranked = rankByIPlusOne<ComicPage>(
    pages,
    l2TokensOf,
    knowledgeOf,
    window: window,
  );
  if (ranked.isEmpty) return null;
  final ideal = ranked.where((r) => r.fit == Fit.ideal).toList();
  if (ideal.isNotEmpty) return ideal.first.passage;

  final rest = ranked.toList()
    ..sort((a, b) {
      final byFit = _fitPriority(a.fit).compareTo(_fitPriority(b.fit));
      if (byFit != 0) return byFit;
      return _distance(a.unknownRatio, window)
          .compareTo(_distance(b.unknownRatio, window));
    });
  return rest.first.passage;
}

// Too-hard candidates (still something new to mine) rank ahead of
// too-easy ones (nothing new) once neither is an ideal fit.
int _fitPriority(Fit fit) => fit == Fit.tooHard ? 0 : 1;

/// Distance of [ratio] outside the `[lower, upper]` i+1 band — 0 inside it.
double _distance(double ratio, IPlusOneWindow w) {
  if (ratio < w.lower) return w.lower - ratio;
  if (ratio > w.upper) return ratio - w.upper;
  return 0;
}
