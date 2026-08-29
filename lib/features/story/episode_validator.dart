import 'episode.dart';

class StoryValidationException implements Exception {
  final List<String> violations;
  const StoryValidationException(this.violations);

  @override
  String toString() =>
      'StoryValidationException:\n${violations.map((v) => '  - $v').join('\n')}';
}

/// Enforces INV-3 (no panel may use an item outside the episode's declared
/// budget) and INV-4 (every non-singleton budgeted item must appear as a
/// tagged token in ≥2 distinct panels). Throws [StoryValidationException]
/// listing every violation found; does not stop at the first one.
void validateEpisode(Episode episode) {
  final violations = <String>[];
  final budgetIds = {for (final item in episode.budget.items) item.id};
  final panelsByItem = <String, Set<int>>{};

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
        panelsByItem.putIfAbsent(itemId, () => {}).add(panel.index);
      }
    }
  }

  for (final item in episode.budget.items) {
    final panelCount = panelsByItem[item.id]?.length ?? 0;
    final minRequired = item.singleton ? 1 : 2;
    if (panelCount < minRequired) {
      violations.add(
        'Item "${item.id}" appears in $panelCount panel(s) but requires at '
        'least $minRequired (singleton=${item.singleton}) (INV-4).',
      );
    }
  }

  if (violations.isNotEmpty) {
    throw StoryValidationException(violations);
  }
}
