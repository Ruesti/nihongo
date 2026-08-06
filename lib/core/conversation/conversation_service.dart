import 'package:drift/drift.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/pipeline/knowledge_bridge.dart';
import 'package:nihongo_app/core/srs/scheduler.dart';
import 'error_span.dart';

/// I7 — Error in AI conversation → create or demote LearnItem.
///
/// Goes through [LadderReview] so that, under architecture C, the same
/// error that touches the on-ramp also projects the lexeme into the
/// shared mining knowledge state (when a [KnowledgeBridge] is wired).
class ConversationService {
  final LearningDb _db;
  final KnowledgeBridge? bridge;

  ConversationService(this._db, {this.bridge});

  /// New item: created at rung 1, due immediately (no review_log entry),
  /// projected as `learning`. Existing item: processed as
  /// ReviewResult.again — rung demoted, SRS reset, lapses incremented,
  /// logged to review_log, and re-projected.
  Future<void> onError(ErrorSpan span) async {
    final review = LadderReview(_db, bridge: bridge);
    final existing = await _findItem(span);
    if (existing == null) {
      await review.introduce(span.languageId, span.refType, span.refId);
      return;
    }
    await review.submit(existing, ReviewResult.again);
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
