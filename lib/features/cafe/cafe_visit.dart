import 'dart:math';

import '../../core/db/learning_db.dart';
import '../../core/ladder/rung_defs.dart';
import '../story/episode.dart';
import 'cafe_debrief.dart';

/// Die vier Stationen (Spec §3) in fester Reihenfolge.
enum CafeStation { wirtin, schulmaedchen, vielredner, gleichaltrige }

class CafeStationPlan {
  final CafeStation station;
  final List<String> itemIds; // refIds (Lexem-IDs), in Übungsreihenfolge
  const CafeStationPlan(this.station, this.itemIds);
}

class CafeVisitPlan {
  final List<CafeStationPlan> stations;
  const CafeVisitPlan(this.stations);

  CafeStationPlan? stationFor(CafeStation s) {
    for (final p in stations) {
      if (p.station == s) return p;
    }
    return null;
  }
}

/// Weg 1 (Spec §2.1): Wirtin alle Wörter in Auftrittsreihenfolge; Schul-
/// mädchen alle Wörter, die weder beim alten Mann noch bei der Gleichaltrigen
/// Ziel sind — wackelige zuerst. Stationen 3/4 füllt Plan B über die
/// Ziel-Mengen; leere Stationen fehlen im Plan.
CafeVisitPlan planAfterEpisode(
  Episode episode, {
  Set<String> vielrednerTargets = const {},
  Set<String> gleichaltrigeTargets = const {},
  Set<String> wobbly = const {},
}) {
  final order = [
    for (final id in debriefOrder(episode))
      if (episode.budget.items.any((i) => i.id == id && i.refType == RefType.lexeme)) id,
  ];
  final others = {...vielrednerTargets, ...gleichaltrigeTargets};
  final rest = order.where((id) => !others.contains(id)).toList();
  final schul = [
    ...rest.where(wobbly.contains),
    ...rest.where((id) => !wobbly.contains(id)),
  ];
  return CafeVisitPlan([
    if (order.isNotEmpty) CafeStationPlan(CafeStation.wirtin, order),
    if (schul.isNotEmpty) CafeStationPlan(CafeStation.schulmaedchen, schul),
  ]);
}

/// Weg 2 (Spec §2.2): nach Sprosse. Sprosse ≤2 mit letztem Ergebnis
/// again/hard → Wirtin, sonst Schulmädchen; Sprosse 3 → Schulmädchen.
/// Plan A: Sprosse 4/5 ebenfalls Schulmädchen (Stationen 3/4 kommen in
/// Plan B und übernehmen dann). Höchstens [maxItems], die am längsten
/// fälligen zuerst. [lastResultById] ist `LearnItem.id → review_log.result`.
CafeVisitPlan planFreeVisit(
  List<LearnItem> due,
  Map<String, String?> lastResultById, {
  int maxItems = 12,
}) {
  final sorted = [...due]..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  final picked = sorted.take(maxItems);
  final wirtin = <String>[];
  final schul = <String>[];
  for (final item in picked) {
    final last = lastResultById[item.id];
    final shaky = last == 'again' || last == 'hard';
    if (item.masteryRung <= 2 && shaky) {
      wirtin.add(item.refId);
    } else {
      schul.add(item.refId);
    }
  }
  return CafeVisitPlan([
    if (wirtin.isNotEmpty) CafeStationPlan(CafeStation.wirtin, wirtin),
    if (schul.isNotEmpty) CafeStationPlan(CafeStation.schulmaedchen, schul),
  ]);
}

/// Freiwillige Runde, wenn nichts fällig ist (Spec §2): das Schulmädchen
/// fragt bis zu [max] bekannte Wörter (Sprosse ≥ 1) ab, deterministisch
/// gemischt — der Aufrufer gibt als [seed] z. B. den Tag des Monats.
CafeVisitPlan planPracticeAnyway(List<LearnItem> all,
    {int max = 6, required int seed}) {
  final known = all.where((i) => i.masteryRung >= 1).toList()
    ..shuffle(Random(seed));
  final ids = known.take(max).map((i) => i.refId).toList();
  return CafeVisitPlan([
    if (ids.isNotEmpty) CafeStationPlan(CafeStation.schulmaedchen, ids),
  ]);
}
