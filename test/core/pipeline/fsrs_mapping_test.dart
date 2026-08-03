import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/pipeline/fsrs_mapping.dart';

void main() {
  group('FsrsMapping', () {
    test('state round-trips through text', () {
      for (final s in fsrs.State.values) {
        expect(FsrsMapping.stateFromText(FsrsMapping.stateToText(s)), s);
      }
    });

    test('stateFromText rejects an unknown string', () {
      expect(() => FsrsMapping.stateFromText('bogus'), throwsArgumentError);
    });

    test('ratingToText covers every rating', () {
      expect(FsrsMapping.ratingToText(fsrs.Rating.again), 'again');
      expect(FsrsMapping.ratingToText(fsrs.Rating.hard), 'hard');
      expect(FsrsMapping.ratingToText(fsrs.Rating.good), 'good');
      expect(FsrsMapping.ratingToText(fsrs.Rating.easy), 'easy');
    });

    test('toFsrsCard reads all scheduling fields from a row', () {
      final row = Card(
        id: 'c1',
        vocabItemId: 'v1',
        state: 'review',
        stability: 12.5,
        difficulty: 6.0,
        elapsedDays: 3,
        scheduledDays: 10,
        reps: 4,
        lapses: 1,
        due: DateTime.utc(2026, 6, 1),
        lastReview: DateTime.utc(2026, 5, 22),
      );

      final card = FsrsMapping.toFsrsCard(row);

      expect(card.state, fsrs.State.review);
      expect(card.stability, 12.5);
      expect(card.difficulty, 6.0);
      expect(card.reps, 4);
      expect(card.lapses, 1);
    });

    test('toCompanion carries scheduling fields but leaves identity absent',
        () {
      final card = fsrs.Card.def(
        DateTime.utc(2026, 6, 1),
        DateTime.utc(2026, 5, 22),
        9.0,
        5.0,
        2,
        8,
        3,
        0,
        fsrs.State.review,
      );

      final companion = FsrsMapping.toCompanion(card);

      expect(companion.stability.value, 9.0);
      expect(companion.state.value, 'review');
      // Identity fields are the caller's to set.
      expect(companion.id.present, isFalse);
      expect(companion.vocabItemId.present, isFalse);
    });
  });
}
