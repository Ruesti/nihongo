import '../../core/db/learning_db.dart';
import '../../core/ladder/rung_defs.dart';
import '../story/episode.dart';

/// Reihenfolge der Nachbesprechung (Spec Café-Nachbesprechung §3.3): die
/// Budget-Items nach ihrem ersten Auftritt als Token in der Folge; Items ohne
/// Token-Auftritt (z. B. nur über `targetItemIds` eines Sprechmoments) danach
/// in Budget-Reihenfolge.
List<String> debriefOrder(Episode episode) {
  final budgetIds = {for (final i in episode.budget.items) i.id};
  final order = <String>[];
  for (final panel in episode.allPanels) {
    for (final bubble in panel.bubbles) {
      for (final token in bubble.tokens) {
        final id = token.itemId;
        if (id != null && budgetIds.contains(id) && !order.contains(id)) {
          order.add(id);
        }
      }
    }
  }
  for (final item in episode.budget.items) {
    if (!order.contains(item.id)) order.add(item.id);
  }
  return order;
}

/// Das erste Panel, in dem [itemId] als Token vorkommt — „die Stelle in der
/// Folge" auf der Erklärungskarte. Null, wenn es nirgends als Token steht.
StoryPanel? firstAppearancePanel(Episode episode, String itemId) {
  for (final panel in episode.allPanels) {
    for (final bubble in panel.bubbles) {
      for (final token in bubble.tokens) {
        if (token.itemId == itemId) return panel;
      }
    }
  }
  return null;
}

/// Die Folge, die [itemId] eingeführt hat (im Budget führt), sonst null.
Episode? episodeIntroducing(List<Episode> episodes, String itemId) {
  for (final episode in episodes) {
    if (episode.budget.items.any((i) => i.id == itemId)) return episode;
  }
  return null;
}

/// Die zweite Item-Quelle des Cafés (Spec §4, INV-11): **Manifest ∩
/// Karteikasten.** Liest ausschließlich `learn_items` — ein Budget-Item ohne
/// Übergabe am Folgen-Ende erscheint nicht; die Nachbesprechung führt nichts
/// ein (INV-8). Reihenfolge: [debriefOrder].
///
/// Dieser Ausbauschritt bedient nur Lexeme; Zeichen (`character`) und
/// Grammatik folgen in eigenen Schritten (Spec §11, 3/4) und werden hier
/// bewusst übersprungen statt halb angezeigt.
Future<List<LearnItem>> debriefItemsFor(
    LearningDb db, Episode episode, String languageId) async {
  final byId = {for (final i in episode.budget.items) i.id: i};
  final items = <LearnItem>[];
  for (final id in debriefOrder(episode)) {
    final ref = byId[id]!;
    if (ref.refType != RefType.lexeme) continue;
    final row = await db.getLearnItem('$languageId:${ref.refType.name}:$id');
    if (row != null) items.add(row);
  }
  return items;
}
