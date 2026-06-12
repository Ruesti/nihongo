import 'rung_defs.dart';
import '../srs/scheduler.dart';

class LadderResult {
  final ScheduleOutput scheduleOutput;
  final int newMasteryRung;
  final int newConsecutiveCorrect;

  const LadderResult({
    required this.scheduleOutput,
    required this.newMasteryRung,
    required this.newConsecutiveCorrect,
  });
}

LadderResult processResult({
  required int currentRung,
  required int consecutiveCorrect,
  required ScheduleInput scheduleInput,
  required ReviewResult result,
}) {
  final sched = schedule(scheduleInput, result);

  int newRung = currentRung;
  int newConsecutive;

  switch (result) {
    case ReviewResult.again:
      newRung = (currentRung - 1).clamp(1, 5);
      newConsecutive = 0;
    case ReviewResult.hard:
      newConsecutive = 0;
    case ReviewResult.good:
    case ReviewResult.easy:
      final proposed = consecutiveCorrect + 1;
      if (proposed >= promotionThreshold) {
        newRung = (currentRung + 1).clamp(1, 5);
        newConsecutive = 0;
      } else {
        newConsecutive = proposed;
      }
  }

  return LadderResult(
    scheduleOutput: sched,
    newMasteryRung: newRung,
    newConsecutiveCorrect: newConsecutive,
  );
}
