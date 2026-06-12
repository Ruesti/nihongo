enum ReviewResult { again, hard, good, easy }

class ScheduleInput {
  final double ease;
  final int intervalDays;
  final int reps;

  const ScheduleInput({
    required this.ease,
    required this.intervalDays,
    required this.reps,
  });
}

class ScheduleOutput {
  final double ease;
  final int intervalDays;
  final DateTime dueAt;
  final int reps;

  const ScheduleOutput({
    required this.ease,
    required this.intervalDays,
    required this.dueAt,
    required this.reps,
  });
}

ScheduleOutput schedule(ScheduleInput input, ReviewResult result) {
  final now = DateTime.now();
  double ease = input.ease.clamp(1.3, 3.0);
  int interval = input.intervalDays;
  int reps = input.reps;

  switch (result) {
    case ReviewResult.again:
      interval = 0;
      ease = (ease - 0.2).clamp(1.3, 3.0);
      reps = 0;
    case ReviewResult.hard:
      interval = interval == 0 ? 1 : (interval * 1.2).round().clamp(1, 999);
      ease = (ease - 0.15).clamp(1.3, 3.0);
    case ReviewResult.good:
      if (reps == 0) {
        interval = 1;
      } else if (reps == 1) {
        interval = 4;
      } else {
        interval = (interval * ease).round().clamp(1, 999);
      }
      reps++;
    case ReviewResult.easy:
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

  final dueAt = result == ReviewResult.again
      ? now.add(const Duration(minutes: 1))
      : now.add(Duration(days: interval));

  return ScheduleOutput(
    ease: ease,
    intervalDays: interval,
    dueAt: dueAt,
    reps: reps,
  );
}
