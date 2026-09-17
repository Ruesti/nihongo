import 'package:drift/drift.dart';

import '../../core/db/learning_db.dart';
import '../../core/i18n/concept_meaning.dart';
import '../../core/ladder/encounter.dart';
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

/// Inhalt einer Erklärungskarte (Spec §5.4): die Begegnung wie in der
/// Lektion plus das, was nur das Café weiß — die Stelle in der Folge und der
/// Erklärungsblock der Wirtin. Beides optional mit Fallback.
class DebriefCardContent {
  final LexemeEncounter encounter;
  final StoryPanel? firstPanel;
  final DebriefNote? note;

  const DebriefCardContent({
    required this.encounter,
    this.firstPanel,
    this.note,
  });
}

/// Baut die Karte aus Lexemes + Concepts (+ Assets) — dieselben Tabellen wie
/// `ExerciseLoader` und `CafeTurnContent.forItem`. Null, wenn das Lexem oder
/// sein Konzept fehlt (der Aufrufer überspringt das Item, kein Absturz).
/// [episode] optional: liefert Stelle-in-der-Folge und Erklärungsblock; im
/// normalen Besuch ohne Folgen-Kontext zeigt die Karte, was sie hat (§3.5).
Future<DebriefCardContent?> loadDebriefCard(
  LearningDb db,
  LearnItem item, {
  Episode? episode,
}) async {
  if (item.refType != RefType.lexeme.name) return null;
  final lex = await (db.select(db.lexemes)
        ..where((t) => t.id.equals(item.refId)))
      .getSingleOrNull();
  if (lex == null) return null;
  final concept = await (db.select(db.concepts)
        ..where((t) => t.id.equals(lex.conceptId)))
      .getSingleOrNull();
  if (concept == null) return null;
  final asset = await (db.select(db.assets)
        ..where((t) =>
            t.conceptId.equals(lex.conceptId) & t.type.equals('image')))
      .getSingleOrNull();
  return DebriefCardContent(
    encounter: LexemeEncounter(
      writtenForm: lex.writtenForm,
      reading: lex.reading,
      audioText: lex.writtenForm,
      meaning: meaningForConcept(concept.id, fallback: concept.glossKey),
      conceptImagePath: asset?.path,
    ),
    firstPanel:
        episode == null ? null : firstAppearancePanel(episode, item.refId),
    note: episode?.debrief[item.refId],
  );
}
