import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_turn.dart';
import 'package:nihongo_app/features/cafe/cafe_guest_script.dart';

void main() {
  test('the Wirtin and the Schulkind each have ≥3 lines per outcome', () {
    for (final guest in [CafeGuest.wirtin, CafeGuest.schulkind]) {
      final script = scriptFor(guest);
      for (final outcome in CafeOutcome.values) {
        expect(script.followUp(outcome, 0), isNotEmpty);
        // ≥3 distinct lines → indices 0,1,2 don't all collapse to one.
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

  test('followUp rotates deterministically by turn index', () {
    final script = scriptFor(CafeGuest.schulkind);
    final a = script.followUp(CafeOutcome.correct, 0);
    final b = script.followUp(CafeOutcome.correct, 1);
    expect(a, isNot(b));
    // Wraps around.
    expect(script.followUp(CafeOutcome.correct, 0),
        script.followUp(CafeOutcome.correct, 0));
  });

  test('the Schulkind sounds nothing like the Wirtin (distinct content)', () {
    final wirtin = scriptFor(CafeGuest.wirtin).followUp(CafeOutcome.wrong, 0);
    final kind = scriptFor(CafeGuest.schulkind).followUp(CafeOutcome.wrong, 0);
    expect(wirtin, isNot(kind));
  });
}
