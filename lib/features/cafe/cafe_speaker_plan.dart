import 'cafe_occupancy.dart';

/// Wer in Akt 2 der Nachbesprechung welchen Turn fragt (Spec
/// Café-Szenen-und-Stimmen §3.1/§5.1): Blöcke von [cafeBlockSize] Turns.
/// Den ersten Block hat die Wirtin, ab drei Blöcken auch den letzten;
/// dazwischen kreisen Schulkind → Vielredner → Gleichaltrige, Startpunkt
/// aus dem Sitzungs-Offset. Reine Funktionen, kein Zufall: gleicher Input,
/// gleicher Plan. Die Stimme ändert nie die Übungsform — die kommt weiter
/// aus der Sprosse (`kindForRung`, Spec §6).
const int cafeBlockSize = 3;

const List<CafeGuest> _others = [
  CafeGuest.schulkind,
  CafeGuest.vielredner,
  CafeGuest.gleichaltrige,
];

List<CafeGuest> speakerPlan(int itemCount,
    {int blockSize = cafeBlockSize, int sessionOffset = 0}) {
  if (itemCount <= 0) return const [];
  final blocks = (itemCount + blockSize - 1) ~/ blockSize;
  final start = sessionOffset % _others.length;
  final plan = <CafeGuest>[];
  for (var b = 0; b < blocks; b++) {
    final frames = b == 0 || (blocks >= 3 && b == blocks - 1);
    final speaker =
        frames ? CafeGuest.wirtin : _others[(start + b - 1) % _others.length];
    final remaining = itemCount - plan.length;
    plan.addAll(
        List.filled(remaining < blockSize ? remaining : blockSize, speaker));
  }
  return plan;
}

/// Ordnungszahl des bei [turnIndex] laufenden Blocks unter den Blöcken
/// desselben Sprechers (0 = sein erster Block). Damit rotieren Einstiegs-
/// zeile und Szene je Sprecher, nicht global. Außerhalb des Plans: 0.
int speakerBlockOrdinal(List<CafeGuest> plan, int turnIndex,
    {int blockSize = cafeBlockSize}) {
  if (turnIndex < 0 || turnIndex >= plan.length) return 0;
  final speaker = plan[turnIndex];
  final block = turnIndex ~/ blockSize;
  var ordinal = 0;
  for (var b = 0; b < block; b++) {
    if (plan[b * blockSize] == speaker) ordinal++;
  }
  return ordinal;
}

/// True, wenn bei [turnIndex] ein anderer Sprecher übernimmt als beim Turn
/// davor. Am ersten Turn und außerhalb des Plans: false.
bool isSpeakerChange(List<CafeGuest> plan, int turnIndex) =>
    turnIndex > 0 &&
    turnIndex < plan.length &&
    plan[turnIndex] != plan[turnIndex - 1];
