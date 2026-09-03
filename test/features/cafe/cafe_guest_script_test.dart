import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_turn.dart';
import 'package:nihongo_app/features/cafe/cafe_guest_script.dart';

void main() {
  test('each guest has ≥3 distinct lines for every outcome it reacts to', () {
    for (final guest in CafeGuest.values) {
      final script = scriptFor(guest);
      for (final outcome in script.lines.keys) {
        final lines = {
          script.followUp(outcome, 0),
          script.followUp(outcome, 1),
          script.followUp(outcome, 2),
        };
        expect(lines.length, greaterThanOrEqualTo(3),
            reason: '$guest/$outcome has fewer than 3 lines');
      }
    }
  });

  test('the Gleichaltrige reacts to free production; the Vielredner to '
      'correct/wrong/hinted', () {
    expect(scriptFor(CafeGuest.gleichaltrige).lines.keys,
        contains(CafeOutcome.freeProduced));
    expect(scriptFor(CafeGuest.vielredner).lines.keys,
        containsAll([CafeOutcome.correct, CafeOutcome.wrong, CafeOutcome.hinted]));
  });

  test('followUp rotates deterministically by turn index', () {
    final script = scriptFor(CafeGuest.schulkind);
    final a = script.followUp(CafeOutcome.correct, 0);
    final b = script.followUp(CafeOutcome.correct, 1);
    expect(a, isNot(b));
    // Wraps around: with 3 lines, index 3 must return the same line as index 0.
    expect(script.followUp(CafeOutcome.correct, 3),
        script.followUp(CafeOutcome.correct, 0));
    // And an out-of-order pair still differs (index 4 wraps to 1, not 0).
    expect(script.followUp(CafeOutcome.correct, 4),
        isNot(script.followUp(CafeOutcome.correct, 0)));
  });

  test('the Schulkind sounds nothing like the Wirtin (distinct content)', () {
    final wirtin = scriptFor(CafeGuest.wirtin).followUp(CafeOutcome.wrong, 0);
    final kind = scriptFor(CafeGuest.schulkind).followUp(CafeOutcome.wrong, 0);
    expect(wirtin, isNot(kind));
  });
}
