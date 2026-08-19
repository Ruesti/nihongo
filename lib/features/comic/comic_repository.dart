import '../../core/db/mining_db.dart';
import '../../core/language_pack/language_pack.dart';
import '../../core/pipeline/fsrs_knowledge_source.dart';
import '../../core/pipeline/passage_snapshot.dart';
import '../../core/text_track/word_tap.dart';
import 'comic_pack.dart';
import 'comic_selector.dart';

/// The single wiring seam from a [ComicPack] onto the real pipeline —
/// exactly parallel to SliceRepository, but for spatial comic pages.
/// Language-blind: all queries key on [pack.languageCode].
class ComicRepository {
  final MiningDb db;
  final ComicPack pack;
  final Dictionary dictionary;

  ComicRepository({
    required this.db,
    required this.pack,
    required this.dictionary,
  });

  late final String workId = 'comic:${pack.languageCode}:${pack.title}';

  Future<FsrsKnowledgeSource> _knowledge() =>
      FsrsKnowledgeSource.load(db, languageCode: pack.languageCode);

  /// The next i+1 page for the learner, or the first page if the ranker
  /// has nothing to prefer (e.g. brand-new known-set).
  Future<ComicPage?> nextPage() async {
    final know = await _knowledge();
    return nextComicPage(pack.pages, know.call) ??
        (pack.pages.isEmpty ? null : pack.pages.first);
  }

  WordTapResult tap(Token token) => WordTapHandler(dictionary).onTap(token);

  Future<void> finishPage(ComicPage page, {int lookups = 0}) async {
    final know = await _knowledge();
    await recordPassageSnapshot(
      db,
      workId: workId,
      passageRef: page.pageRef,
      tokens: l2TokensOf(page),
      knowledgeOf: know.call,
      metrics: PassageMetrics(lookupCount: lookups),
    );
  }
}
