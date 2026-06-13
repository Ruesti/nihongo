import 'package:drift/drift.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_service.dart';
import 'package:nihongo_app/core/srs/scheduler.dart';
import 'error_span.dart';

/// I7 — Error in AI conversation → create or demote LearnItem.
class ConversationService {
  final LearningDb _db;

  ConversationService(this._db);

  /// New item: created at rung 1, due immediately (no review_log entry).
  /// Existing item: processed as ReviewResult.again — rung demoted, SRS reset,
  /// lapses incremented, logged to review_log.
  Future<void> onError(ErrorSpan span) async {
    final existing = await _findItem(span);
    if (existing == null) {
      await _db.addLearnItem(span.languageId, span.refType, span.refId);
      return;
    }

    final result = processResult(
      currentRung: existing.masteryRung,
      consecutiveCorrect: existing.consecutiveCorrect,
      scheduleInput: ScheduleInput(
        ease: existing.ease,
        intervalDays: existing.intervalDays,
        reps: existing.reps,
      ),
      result: ReviewResult.again,
    );
    await _db.applyReviewResult(existing, result, ReviewResult.again);
  }

  Future<LearnItem?> _findItem(ErrorSpan span) async {
    final rows = await (_db.select(_db.learnItems)
          ..where((t) =>
              t.languageId.equals(span.languageId) &
              t.refType.equals(span.refType.name) &
              t.refId.equals(span.refId)))
        .get();
    return rows.isEmpty ? null : rows.first;
  }
}
