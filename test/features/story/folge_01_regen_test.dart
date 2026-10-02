import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

void main() {
  test('loadFolge01 liefert die validierte Folge 01', () {
    final episode = loadFolge01();
    expect(episode.id, 'ep_ja_shotengai_01');
    expect(episode.locale, 'ja');
    expect(episode.budget.items, isNotEmpty);
    expect(episode.allPanels.length, greaterThanOrEqualTo(2));
  });

  test('das Folge-01-Woerterbuch deckt jedes Budget-Item ab', () {
    final episode = loadFolge01();
    final dictIds = folge01DictionaryEntries.map((e) => e.id).toSet();
    for (final item in episode.budget.items) {
      expect(dictIds, contains(item.id),
          reason: '${item.id} hat keinen Woerterbuch-Eintrag');
    }
  });
}
