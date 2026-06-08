import '../models/srs_card.dart';

// SM-2 Spaced Repetition Algorithm
// Grade 0: Again, Grade 1: Hard, Grade 2: Good, Grade 3: Easy
SrsCard srsGrade(SrsCard card, int grade) {
  assert(grade >= 0 && grade <= 3);

  final now = DateTime.now().millisecondsSinceEpoch;
  double ease = card.ease;
  int interval = card.interval;
  int reps = card.reps;

  switch (grade) {
    case 0: // Again
      interval = 0;
      ease = (ease - 0.2).clamp(1.3, 3.0);
      reps = 0;
    case 1: // Hard
      interval = (interval * 0.8).round().clamp(1, 999);
      ease = (ease - 0.15).clamp(1.3, 3.0);
      reps = reps > 0 ? reps : 0;
    case 2: // Good
      if (reps == 0) {
        interval = 1;
      } else if (reps == 1) {
        interval = 4;
      } else {
        interval = (interval * ease).round().clamp(1, 999);
      }
      reps++;
    case 3: // Easy
      if (reps == 0) {
        interval = 4;
      } else if (reps == 1) {
        interval = 7;
      } else {
        interval = (interval * ease * 1.3).round().clamp(1, 999);
      }
      ease = (ease + 0.1).clamp(1.3, 3.0);
      reps++;
  }

  final dueAt = grade == 0
      ? now + 60 * 1000 // 1 minute for "Again"
      : now + interval * 24 * 60 * 60 * 1000;

  return card.copyWith(
    ease: ease,
    interval: interval,
    reps: reps,
    dueAt: dueAt,
  );
}

bool isDue(SrsCard card) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return card.dueAt <= now;
}

int dueSoonCount(List<SrsCard> cards) {
  return cards.where(isDue).length;
}
