import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

void main() {
  test('loadFolge01 liefert die validierte Folge 01', () {
    final episode = loadFolge01();
    expect(episode.id, 'ep_ja_shotengai_01');
    expect(episode.locale, 'ja');
    expect(episode.budget.items, isNotEmpty);
    expect(episode.allPanels.length, greaterThanOrEqualTo(2));
  });

  test('Folge 01 traegt intro, outro und pro Dialog-Bubble eine hitArea', () {
    final episode = loadFolge01();
    expect(episode.intro, isNotNull);
    expect(episode.outro, isNotNull);
    for (final panel in episode.allPanels) {
      for (final bubble in panel.bubbles) {
        if (bubble.tokens.isNotEmpty) {
          expect(bubble.hitArea.points, hasLength(4),
              reason: 'Panel ${panel.index}: Dialog-Bubble ohne Tippflaeche');
        }
      }
    }
    final speakTrace = episode.allPanels
        .expand((p) => p.interactions)
        .where((i) => i.diegetic &&
            (i.type == InteractionType.speak ||
             i.type == InteractionType.trace));
    for (final it in speakTrace) {
      expect(it.reactionAsset, isNotNull);
      expect(it.reactionCaption, isNotNull);
    }
  });

  test('das Folge-01-Woerterbuch deckt jedes Budget-Item ab', () {
    final episode = loadFolge01();
    final dictIds = folge01DictionaryEntries.map((e) => e.id).toSet();
    for (final item in episode.budget.items) {
      expect(dictIds, contains(item.id),
          reason: '${item.id} hat keinen Woerterbuch-Eintrag');
    }
  });

  test('jedes Budget-Wort hat einen Erklärungsblock der Wirtin (Gebrauch, '
      '≤2 Varianten) — und nur Budget-Wörter haben einen', () {
    final episode = loadFolge01();
    for (final item in episode.budget.items) {
      final note = episode.debrief[item.id];
      expect(note, isNotNull, reason: '${item.id} ohne Erklärungsblock');
      expect(note!.usage.trim(), isNotEmpty);
      expect(note.variants.length, lessThanOrEqualTo(2));
    }
    expect(episode.debrief.keys.toSet(),
        {for (final i in episode.budget.items) i.id});
  });
}
