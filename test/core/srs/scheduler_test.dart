import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/srs/scheduler.dart';

void main() {
  const base = ScheduleInput(ease: 2.5, intervalDays: 0, reps: 0);

  test('again resets interval and reduces ease', () {
    final out = schedule(base, ReviewResult.again);
    expect(out.intervalDays, 0);
    expect(out.ease, closeTo(2.3, 0.01));
    expect(out.reps, 0);
    expect(out.dueAt.isAfter(DateTime.now()), isTrue);
    expect(
      out.dueAt.isBefore(DateTime.now().add(const Duration(minutes: 2))),
      isTrue,
    );
  });

  test('good on first rep gives interval=1', () {
    final out = schedule(base, ReviewResult.good);
    expect(out.intervalDays, 1);
    expect(out.reps, 1);
    expect(out.ease, closeTo(2.5, 0.01));
  });

  test('good on second rep gives interval=4', () {
    final out = schedule(
      const ScheduleInput(ease: 2.5, intervalDays: 1, reps: 1),
      ReviewResult.good,
    );
    expect(out.intervalDays, 4);
    expect(out.reps, 2);
  });

  test('good on third rep multiplies interval by ease', () {
    final out = schedule(
      const ScheduleInput(ease: 2.5, intervalDays: 4, reps: 2),
      ReviewResult.good,
    );
    expect(out.intervalDays, 10); // 4 * 2.5 = 10
    expect(out.reps, 3);
  });

  test('easy on first rep gives interval=4 and increases ease', () {
    final out = schedule(base, ReviewResult.easy);
    expect(out.intervalDays, 4);
    expect(out.ease, closeTo(2.6, 0.01));
    expect(out.reps, 1);
  });

  test('hard increases interval slightly and reduces ease', () {
    final out = schedule(
      const ScheduleInput(ease: 2.5, intervalDays: 4, reps: 2),
      ReviewResult.hard,
    );
    expect(out.ease, closeTo(2.35, 0.01));
    expect(out.intervalDays, 5); // ceil(4 * 1.2) = 5
    expect(out.reps, 2); // reps unchanged on hard
  });

  test('hard on new card gives interval=1', () {
    final out = schedule(base, ReviewResult.hard);
    expect(out.intervalDays, 1);
  });

  test('ease never drops below 1.3', () {
    final out = schedule(
      const ScheduleInput(ease: 1.35, intervalDays: 1, reps: 1),
      ReviewResult.again,
    );
    expect(out.ease, closeTo(1.3, 0.01));
  });

  test('ease never exceeds 3.0', () {
    final out = schedule(
      const ScheduleInput(ease: 2.95, intervalDays: 4, reps: 2),
      ReviewResult.easy,
    );
    expect(out.ease, closeTo(3.0, 0.01));
  });
}
