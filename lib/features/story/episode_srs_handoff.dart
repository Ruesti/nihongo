import '../../core/ladder/ladder_review.dart';
import 'episode.dart';

/// Hands an episode's budgeted vocabulary to the SRS ladder once, at the
/// moment the reader finishes the episode (P5b). Every budgeted item is
/// *introduced* — created as a `learn_item` at rung 0 via
/// [LadderReview.introduce] — and never promoted to a productive rung, which
/// is how "kein produktiver Rung vor Lesende" (INV-5) holds by construction:
/// items enter the SRS only when reading ends, and only at the lowest rung.
///
/// Idempotent by construction: [LadderReview.introduce] skips any item that
/// already has a `learn_item`, so re-reading the episode never duplicates a
/// row nor disturbs an item the learner has already advanced beyond rung 0
/// (INV-6).
///
/// [languageId] is the pack's language id (e.g. `'lang_ja'`) — NOT an
/// episode's `locale`. Mapping a locale to a pack languageId is the caller's
/// concern; keeping it a parameter here leaves the handoff pack-agnostic.
class EpisodeSrsHandoff {
  final LadderReview ladder;
  final String languageId;

  const EpisodeSrsHandoff({required this.ladder, required this.languageId});

  Future<void> introduceEpisode(Episode episode) async {
    for (final item in episode.budget.items) {
      await ladder.introduce(languageId, item.refType, item.id);
    }
  }
}
