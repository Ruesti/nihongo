import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_speaker_plan.dart';

void main() {
  const w = CafeGuest.wirtin;
  const s = CafeGuest.schulkind;
  const v = CafeGuest.vielredner;
  const g = CafeGuest.gleichaltrige;

  /// Ein Sprecher je Block (jeder dritte Eintrag).
  List<CafeGuest> blocksOf(List<CafeGuest> plan) =>
      [for (var i = 0; i < plan.length; i += cafeBlockSize) plan[i]];

  test('18 Items, Offset 0 → Wirtin, Schulkind, Vielredner, Gleichaltrige, '
      'Schulkind, Wirtin (Spec §3.1)', () {
    final plan = speakerPlan(18);
    expect(plan.length, 18);
    expect(blocksOf(plan), [w, s, v, g, s, w]);
    // Innerhalb eines Blocks bleibt der Sprecher gleich.
    for (var i = 0; i < 18; i++) {
      expect(plan[i], plan[i - i % cafeBlockSize]);
    }
  });

  test('der Sitzungs-Offset dreht den Kreis der drei anderen', () {
    expect(blocksOf(speakerPlan(18, sessionOffset: 1)), [w, v, g, s, v, w]);
    expect(blocksOf(speakerPlan(18, sessionOffset: 2)), [w, g, s, v, g, w]);
    expect(blocksOf(speakerPlan(18, sessionOffset: 3)),
        blocksOf(speakerPlan(18, sessionOffset: 0)));
  });

  test('drei Blöcke: die Wirtin rahmt (erster und letzter Block)', () {
    expect(blocksOf(speakerPlan(9)), [w, s, w]);
  });

  test('zwei Blöcke: Wirtin und eine zweite Stimme, keine Rahmung', () {
    expect(blocksOf(speakerPlan(6)), [w, s]);
    // Angebrochener zweiter Block (4 Items): W W W S.
    expect(speakerPlan(4), [w, w, w, s]);
  });

  test('ein Block oder nichts: nur die Wirtin', () {
    expect(speakerPlan(3), [w, w, w]);
    expect(speakerPlan(1), [w]);
    expect(speakerPlan(0), isEmpty);
    expect(speakerPlan(-2), isEmpty);
  });

  test('ab fünf Blöcken kommen alle drei anderen vor', () {
    final blocks = blocksOf(speakerPlan(15)).toSet();
    expect(blocks, containsAll([w, s, v, g]));
  });

  test('speakerBlockOrdinal zählt die Blöcke desselben Sprechers', () {
    final plan = speakerPlan(18); // W S V G S W
    expect(speakerBlockOrdinal(plan, 0), 0); // Wirtin, 1. Block
    expect(speakerBlockOrdinal(plan, 4), 0); // Schulkind, 1. Block
    expect(speakerBlockOrdinal(plan, 13), 1); // Schulkind, 2. Block
    expect(speakerBlockOrdinal(plan, 16), 1); // Wirtin, 2. Block
    expect(speakerBlockOrdinal(plan, 99), 0); // außerhalb: harmlos
  });

  test('isSpeakerChange nur am ersten Turn eines Blocks mit neuem Sprecher',
      () {
    final plan = speakerPlan(18);
    expect(isSpeakerChange(plan, 0), isFalse);
    expect(isSpeakerChange(plan, 2), isFalse);
    expect(isSpeakerChange(plan, 3), isTrue);
    expect(isSpeakerChange(plan, 4), isFalse);
    expect(isSpeakerChange(plan, 15), isTrue);
    expect(isSpeakerChange(plan, 18), isFalse);
    expect(isSpeakerChange(const [w, w, w], 1), isFalse);
  });
}
