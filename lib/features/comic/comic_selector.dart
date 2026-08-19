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
/// language branch. `rankByIPlusOne` already returns its list fully
/// ordered by fit priority (ideal, then too-hard least-hard-first,
/// then too-easy closest-to-mineable-first), so the first entry is
/// exactly the page we want.
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
  return ranked.isEmpty ? null : ranked.first.passage;
}
