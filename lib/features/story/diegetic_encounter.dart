import '../../core/ladder/ladder_review.dart';
import '../../core/ladder/rung_defs.dart';

/// The SRS effect of a *successful* diegetic speak/trace moment (brief P6):
/// the produced item is introduced if new, then marked *encountered* — it
/// reaches rung 1 and no further. Rung 1 is not a productive rung (3–5), so
/// this honours INV-6 (only the diegetic activity itself is the exception,
/// not a productive rung), and rung 1 ≤ 2 keeps INV-5 intact even mid-episode.
///
/// [encounter] only ever promotes an item that is *currently at rung 0*, so
/// it never demotes a word the learner has already advanced (e.g. via a prior
/// episode), and it composes safely with P5b's episode-end batch introduce
/// (which is likewise idempotent). Speaking a word at both P07 and P22 leaves
/// it at rung 1.
///
/// [languageId] is the pack id (e.g. `'lang_ja'`), not an episode locale.
class DiegeticEncounter {
  final LadderReview ladder;
  final String languageId;

  const DiegeticEncounter({required this.ladder, required this.languageId});

  Future<void> encounter(RefType refType, String refId) async {
    await ladder.introduce(languageId, refType, refId);
    final id = '$languageId:${refType.name}:$refId';
    final item = await ladder.learning.getLearnItem(id);
    if (item != null && item.masteryRung == 0) {
      await ladder.markEncountered(item);
    }
  }
}
