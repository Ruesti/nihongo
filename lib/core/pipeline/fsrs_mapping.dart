import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../db/mining_db.dart';

/// Translation between the persisted [Cards] row and the `fsrs`
/// package's in-memory `Card`. The schema field names deliberately
/// mirror the package (§0.4.12), so this is a mechanical 1:1 mapping —
/// its only real job is the `state` enum ⇄ string conversion, kept in
/// one place so the grading write-path (`review_scheduler.dart`) and
/// the read-path (`fsrs_knowledge_source.dart`, `fsrs_bootstrap_
/// import.dart`) can't drift out of sync.
class FsrsMapping {
  const FsrsMapping._();

  static String stateToText(fsrs.State s) => switch (s) {
        fsrs.State.newState => 'newState',
        fsrs.State.learning => 'learning',
        fsrs.State.review => 'review',
        fsrs.State.relearning => 'relearning',
      };

  static fsrs.State stateFromText(String s) => switch (s) {
        'newState' => fsrs.State.newState,
        'learning' => fsrs.State.learning,
        'review' => fsrs.State.review,
        'relearning' => fsrs.State.relearning,
        _ => throw ArgumentError('Unknown FSRS state "$s"'),
      };

  static String ratingToText(fsrs.Rating r) => switch (r) {
        fsrs.Rating.again => 'again',
        fsrs.Rating.hard => 'hard',
        fsrs.Rating.good => 'good',
        fsrs.Rating.easy => 'easy',
      };

  /// Reads a persisted [Card] row into an `fsrs.Card` ready for
  /// `FSRS.repeat`.
  static fsrs.Card toFsrsCard(Card row) => fsrs.Card.def(
        row.due.toUtc(),
        row.lastReview.toUtc(),
        row.stability,
        row.difficulty,
        row.elapsedDays,
        row.scheduledDays,
        row.reps,
        row.lapses,
        stateFromText(row.state),
      );

  /// A [CardsCompanion] carrying an `fsrs.Card`'s scheduling fields —
  /// for writing an updated card back after a review. Identity fields
  /// (`id`, `vocabItemId`, `contextTextSpanId`) are left absent so the
  /// caller decides them.
  static CardsCompanion toCompanion(fsrs.Card card) => CardsCompanion(
        state: Value(stateToText(card.state)),
        stability: Value(card.stability),
        difficulty: Value(card.difficulty),
        elapsedDays: Value(card.elapsedDays),
        scheduledDays: Value(card.scheduledDays),
        reps: Value(card.reps),
        lapses: Value(card.lapses),
        due: Value(card.due.toUtc()),
        lastReview: Value(card.lastReview.toUtc()),
      );
}
