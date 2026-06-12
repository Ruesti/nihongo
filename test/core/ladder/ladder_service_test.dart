import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/ladder_service.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/srs/scheduler.dart';

const _base = ScheduleInput(ease: 2.5, intervalDays: 0, reps: 0);

void main() {
  group('processResult — promotion', () {
    test('3 consecutive good results promote rung 1 → 2', () {
      var rung = 1;
      var consecutive = 0;

      for (int i = 0; i < promotionThreshold; i++) {
        final r = processResult(
          currentRung: rung,
          consecutiveCorrect: consecutive,
          scheduleInput: _base,
          result: ReviewResult.good,
        );
        rung = r.newMasteryRung;
        consecutive = r.newConsecutiveCorrect;
      }

      expect(rung, 2);
      expect(consecutive, 0);
    });

    test('3 consecutive easy results promote rung 1 → 2', () {
      var rung = 1;
      var consecutive = 0;

      for (int i = 0; i < promotionThreshold; i++) {
        final r = processResult(
          currentRung: rung,
          consecutiveCorrect: consecutive,
          scheduleInput: _base,
          result: ReviewResult.easy,
        );
        rung = r.newMasteryRung;
        consecutive = r.newConsecutiveCorrect;
      }

      expect(rung, 2);
      expect(consecutive, 0);
    });

    test('rung 5 good does not exceed 5', () {
      final r = processResult(
        currentRung: 5,
        consecutiveCorrect: promotionThreshold - 1,
        scheduleInput: _base,
        result: ReviewResult.good,
      );
      expect(r.newMasteryRung, 5);
      expect(r.newConsecutiveCorrect, 0);
    });

    test('2 good then again does NOT promote', () {
      var rung = 1;
      var consecutive = 0;

      for (int i = 0; i < 2; i++) {
        final r = processResult(
          currentRung: rung,
          consecutiveCorrect: consecutive,
          scheduleInput: _base,
          result: ReviewResult.good,
        );
        rung = r.newMasteryRung;
        consecutive = r.newConsecutiveCorrect;
      }
      expect(rung, 1);
      expect(consecutive, 2);

      final demote = processResult(
        currentRung: rung,
        consecutiveCorrect: consecutive,
        scheduleInput: _base,
        result: ReviewResult.again,
      );
      expect(demote.newMasteryRung, 1); // was already rung 1 → clamp
      expect(demote.newConsecutiveCorrect, 0);
    });
  });

  group('processResult — demotion', () {
    test('again on rung 3 demotes to rung 2', () {
      final r = processResult(
        currentRung: 3,
        consecutiveCorrect: 1,
        scheduleInput: _base,
        result: ReviewResult.again,
      );
      expect(r.newMasteryRung, 2);
      expect(r.newConsecutiveCorrect, 0);
    });

    test('again on rung 1 stays at rung 1 (min clamp)', () {
      final r = processResult(
        currentRung: 1,
        consecutiveCorrect: 0,
        scheduleInput: _base,
        result: ReviewResult.again,
      );
      expect(r.newMasteryRung, 1);
      expect(r.newConsecutiveCorrect, 0);
    });
  });

  group('processResult — hard', () {
    test('hard resets consecutiveCorrect but does not change rung', () {
      final r = processResult(
        currentRung: 2,
        consecutiveCorrect: 2,
        scheduleInput: _base,
        result: ReviewResult.hard,
      );
      expect(r.newMasteryRung, 2);
      expect(r.newConsecutiveCorrect, 0);
    });

    test('hard still updates SRS (scheduleOutput populated)', () {
      final r = processResult(
        currentRung: 1,
        consecutiveCorrect: 0,
        scheduleInput: const ScheduleInput(ease: 2.5, intervalDays: 4, reps: 2),
        result: ReviewResult.hard,
      );
      expect(r.scheduleOutput.intervalDays, 5); // ceil(4 * 1.2)
      expect(r.scheduleOutput.ease, closeTo(2.35, 0.01));
    });
  });

  test('good result populates scheduleOutput', () {
    final r = processResult(
      currentRung: 1,
      consecutiveCorrect: 0,
      scheduleInput: _base,
      result: ReviewResult.good,
    );
    expect(r.scheduleOutput.intervalDays, 1);
    expect(r.scheduleOutput.reps, 1);
  });
}
