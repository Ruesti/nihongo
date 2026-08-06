import '../db/learning_db.dart';
import '../pipeline/knowledge_bridge.dart';
import '../srs/scheduler.dart';
import 'ladder_service.dart';
import 'rung_defs.dart';

/// The one place a graded on-ramp review (or a new-item introduction) is
/// applied. It runs the ladder (promote/demote), persists to
/// [LearningDb], and — architecture C (DESIGN_ONRAMP_BRIDGE.md) —
/// projects the lexeme's new mastery into the shared mining knowledge
/// state through [bridge].
///
/// Both the review screen and the conversation-error path (I7) go
/// through here, so the projection can't be forgotten at one call site
/// and re-added at another. [bridge] is null until the running app holds
/// both databases (the boot-unification step); with it null this behaves
/// exactly as the on-ramp did before — the seam is in place, dormant.
class LadderReview {
  final LearningDb learning;
  final KnowledgeBridge? bridge;

  const LadderReview(this.learning, {this.bridge});

  /// Grade an existing item: run the ladder, persist, project.
  Future<LadderResult> submit(
    LearnItem item,
    ReviewResult result, {
    String? languageCode,
  }) async {
    final ladderResult = processResult(
      currentRung: item.masteryRung,
      consecutiveCorrect: item.consecutiveCorrect,
      scheduleInput: ScheduleInput(
        ease: item.ease,
        intervalDays: item.intervalDays,
        reps: item.reps,
      ),
      result: result,
    );
    await learning.applyReviewResult(item, ladderResult, result);
    await bridge?.onLearnItemReviewed(
      learning,
      languageId: item.languageId,
      refType: item.refType,
      refId: item.refId,
      newMasteryRung: ladderResult.newMasteryRung,
      languageCode: languageCode,
    );
    return ladderResult;
  }

  /// Introduce a brand-new item at rung 1 (I7's "new error" path) and
  /// project it as `learning` — a just-met word is introduced, not
  /// unknown, in the shared state.
  Future<void> introduce(
    String languageId,
    RefType refType,
    String refId, {
    String? languageCode,
  }) async {
    await learning.addLearnItem(languageId, refType, refId);
    await bridge?.onLearnItemReviewed(
      learning,
      languageId: languageId,
      refType: refType.name,
      refId: refId,
      newMasteryRung: 1,
      languageCode: languageCode,
    );
  }
}
