import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

void main() {
  test('Folge 01 erfuellt das Dichte-Soll des Formats', () {
    final episode = loadFolge01();
    final tokenCounts = <String, int>{};
    var bubbleTokens = 0;
    for (final panel in episode.allPanels) {
      for (final bubble in panel.bubbles) {
        for (final token in bubble.tokens) {
          bubbleTokens++;
          final id = token.itemId;
          if (id != null) tokenCounts[id] = (tokenCounts[id] ?? 0) + 1;
        }
      }
    }
    var targetHits = 0;
    for (final it in episode.allPanels.expand((p) => p.interactions)) {
      for (final id in it.targetItemIds ?? const <String>[]) {
        targetHits++;
        tokenCounts[id] = (tokenCounts[id] ?? 0) + 1;
      }
    }
    expect(bubbleTokens, greaterThanOrEqualTo(28),
        reason: 'zu wenig Sprache in den Blasen');
    expect(bubbleTokens + targetHits, greaterThanOrEqualTo(30));
    for (final ref in episode.budget.items) {
      expect(tokenCounts[ref.id] ?? 0, greaterThanOrEqualTo(2),
          reason: '${ref.id} kommt zu selten vor (Wiederholung ist das Lernen)');
    }
    expect(episode.allPanels.length, 10);
    expect(episode.intro, isNotNull);
    expect(episode.outro, isNotNull);
  });
}
