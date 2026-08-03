import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../db/mining_db.dart';
import 'fsrs_mapping.dart';

/// The outcome of grading one card — enough for the caller (the reader,
/// §7) to show what happened without re-querying.
class GradeOutcome {
  final String cardId;
  final DateTime newDue;
  final double stabilityBefore;
  final double stabilityAfter;
  final String newState;

  const GradeOutcome({
    required this.cardId,
    required this.newDue,
    required this.stabilityBefore,
    required this.stabilityAfter,
    required this.newState,
  });
}

/// The grading write-path (§7 "graded without leaving the reader"): run
/// the real FSRS algorithm forward on a card, persist the updated
/// scheduling state, and append an immutable review-log row. Phase 4
/// only ever *read* FSRS state (knowledge lookup) or seeded it
/// (bootstrap); this is the first place a real user review mutates a
/// card.
class ReviewScheduler {
  final MiningDb db;
  final fsrs.FSRS _scheduler;

  ReviewScheduler(this.db) : _scheduler = fsrs.FSRS();

  Future<GradeOutcome> grade(
    String cardId,
    fsrs.Rating rating, {
    DateTime? now,
    int? reviewDurationMs,
  }) async {
    final reviewTime = (now ?? DateTime.now()).toUtc();

    final row = await (db.select(db.cards)
          ..where((c) => c.id.equals(cardId)))
        .getSingle();
    final before = FsrsMapping.toFsrsCard(row);
    final stabilityBefore = before.stability;

    final outcomes = _scheduler.repeat(before, reviewTime);
    final updated = outcomes[rating]!.card;

    await db.transaction(() async {
      await (db.update(db.cards)..where((c) => c.id.equals(cardId)))
          .write(FsrsMapping.toCompanion(updated));

      // ReviewLogs is append-only (§4) — insert, never update. The id
      // is deterministic from (card, review time) so a double-submit of
      // the same review can't create two log rows.
      await db.into(db.reviewLogs).insert(
            ReviewLogsCompanion.insert(
              id: 'log:$cardId:${reviewTime.microsecondsSinceEpoch}',
              cardId: cardId,
              rating: FsrsMapping.ratingToText(rating),
              reviewDateTime: reviewTime,
              reviewDurationMs: Value(reviewDurationMs),
              stabilityBefore: Value(stabilityBefore),
              stabilityAfter: Value(updated.stability),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    });

    return GradeOutcome(
      cardId: cardId,
      newDue: updated.due,
      stabilityBefore: stabilityBefore,
      stabilityAfter: updated.stability,
      newState: FsrsMapping.stateToText(updated.state),
    );
  }
}
