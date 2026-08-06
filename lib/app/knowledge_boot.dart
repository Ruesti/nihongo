import '../core/db/learning_db.dart';
import '../core/pipeline/knowledge_bridge.dart';

/// One language's identity on both sides of the bridge: the on-ramp's
/// [languageId] (e.g. `lang_ja`) and mining's BCP-47 [languageCode]
/// (e.g. `ja`).
typedef BridgedLanguage = ({String languageId, String languageCode});

/// Initializes the shared mining knowledge state from the on-ramp at boot
/// — exactly once per language. This is the hand-off that makes the
/// bridge non-null in production actually mean something: the learner's
/// existing on-ramp mastery becomes mining's starting "known" set.
///
/// After the first backfill, live projection (`LadderReview`) keeps the
/// state current; re-running backfill would clobber reading progress
/// (last-write-wins overwrites cards that in-reading reviews advanced),
/// so [isDone]/[markDone] guard it to run only once. In the app these are
/// backed by shared_preferences; in tests, an in-memory set.
class KnowledgeBoot {
  final KnowledgeBridge bridge;

  const KnowledgeBoot(this.bridge);

  Future<void> ensureBackfilled(
    LearningDb learning, {
    required List<BridgedLanguage> languages,
    required Future<bool> Function(String key) isDone,
    required Future<void> Function(String key) markDone,
  }) async {
    for (final lang in languages) {
      final key = 'knowledge_backfill:${lang.languageCode}';
      if (await isDone(key)) continue;
      await bridge.backfill(
        learning,
        languageId: lang.languageId,
        languageCode: lang.languageCode,
      );
      await markDone(key);
    }
  }
}
