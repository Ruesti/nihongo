import 'episode.dart';

class StoryValidationException implements Exception {
  final List<String> violations;
  const StoryValidationException(this.violations);

  @override
  String toString() =>
      'StoryValidationException:\n${violations.map((v) => '  - $v').join('\n')}';
}

/// Enforces INV-3 (no panel may use an item outside the episode's declared
/// budget) and INV-4 (every non-singleton budgeted item must occur ≥2 times
/// across the episode). Throws [StoryValidationException] listing every
/// violation found; does not stop at the first one.
///
/// INV-4 counts total occurrences (bubble tokens plus interaction
/// `targetItemIds` hits), not distinct panels: since Folge01 V2 (dense,
/// 10-panel format — docs/story/DREHBUCH_FOLGE_01_V2.md), a single panel
/// legitimately carries several exchanged lines belonging to one narrative
/// beat (e.g. a diagnosis scene repeating a word 3x in one panel), and a
/// diegetic speak/trace `target` can be the sole carrier of a word's
/// repetition (the Dichte-Test in folge_01_dichte_test.dart uses the same
/// occurrence-based math).
void validateEpisode(Episode episode) {
  final violations = <String>[];
  final budgetIds = {for (final item in episode.budget.items) item.id};
  final occurrencesByItem = <String, int>{};
  // Oberflächen aller Budget-Items, wie sie in der Folge stehen — die Menge,
  // gegen die Varianten der Nachbesprechung geprüft werden (§5.6).
  final budgetSurfaces = <String>{};

  // Structural check: panel indices must be unique across the whole episode
  final seenPanelIndices = <int>{};
  for (final panel in episode.allPanels) {
    if (!seenPanelIndices.add(panel.index)) {
      violations.add(
        'Duplicate panel index ${panel.index}: panel indices must be '
        'unique across the whole episode (structural).',
      );
    }
  }

  for (final panel in episode.allPanels) {
    for (final bubble in panel.bubbles) {
      for (final token in bubble.tokens) {
        final itemId = token.itemId;
        if (itemId == null) continue;
        if (!budgetIds.contains(itemId)) {
          violations.add(
            'Panel ${panel.index}: token "${token.surface}" references item '
            '"$itemId", which is not in the episode budget (INV-3).',
          );
          continue;
        }
        budgetSurfaces.add(token.surface);
        occurrencesByItem[itemId] = (occurrencesByItem[itemId] ?? 0) + 1;
      }
    }
    for (final interaction in panel.interactions) {
      for (final itemId in interaction.targetItemIds ?? const <String>[]) {
        occurrencesByItem[itemId] = (occurrencesByItem[itemId] ?? 0) + 1;
      }
    }
  }

  for (final item in episode.budget.items) {
    final count = occurrencesByItem[item.id] ?? 0;
    final minRequired = item.singleton ? 1 : 2;
    if (count < minRequired) {
      violations.add(
        'Item "${item.id}" occurs $count time(s) but requires at '
        'least $minRequired (singleton=${item.singleton}) (INV-4).',
      );
    }
  }

  // Nachbesprechung (Spec Café-Nachbesprechung §5.6): Die Wirtin erklärt nur
  // Budget-Items; Varianten („man kann auch sagen") sind Wissen am Item, keine
  // Items — höchstens zwei, und keine Variante darf selbst ein Budget-Item
  // dieser Folge sein (dann gehört sie ins Budget, nicht in die Randnotiz).
  for (final entry in episode.debrief.entries) {
    final itemId = entry.key;
    final note = entry.value;
    if (!budgetIds.contains(itemId)) {
      violations.add(
        'Debrief "$itemId" erklärt ein Item, das nicht im Budget dieser Folge '
        'steht (Nachbesprechung erklärt nur Eingeführtes, INV-8/INV-11).',
      );
    }
    if (note.variants.length > 2) {
      violations.add(
        'Debrief "$itemId" nennt ${note.variants.length} Varianten; erlaubt '
        'sind höchstens 2 (keine Varianten-Kaskade).',
      );
    }
    for (final v in note.variants) {
      if (budgetSurfaces.contains(v.form)) {
        violations.add(
          'Debrief "$itemId": Variante "${v.form}" ist selbst ein Budget-Item '
          'dieser Folge — dann gehört sie ins Budget, nicht in „man kann auch '
          'sagen".',
        );
      }
    }
  }

  if (violations.isNotEmpty) {
    throw StoryValidationException(violations);
  }
}
