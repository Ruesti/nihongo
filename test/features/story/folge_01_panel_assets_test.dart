import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('jedes Panel der Folge 01 referenziert gebündelte Bilder in beiden Formaten',
      () async {
    final episode = loadFolge01();
    Future<void> bundled(String? asset, String what) async {
      expect(asset, isNotNull, reason: '$what fehlt');
      expect(asset, isNot(contains('placeholder')), reason: '$what zeigt den Platzhalter');
      final data = await rootBundle.load(asset!);
      expect(data.lengthInBytes, greaterThan(1000), reason: '$asset fehlt oder ist leer');
    }

    for (final panel in episode.allPanels) {
      await bundled(panel.asset, 'Panel ${panel.index} quer');
      await bundled(panel.assetPortrait, 'Panel ${panel.index} hoch');
      expect(panel.asset, startsWith('assets/story/folge01/'));
    }
    for (final it in episode.allPanels.expand((p) => p.interactions)) {
      if (it.reactionAsset != null) {
        await bundled(it.reactionAsset, 'Reaktion quer');
        await bundled(it.reactionAssetPortrait, 'Reaktion hoch');
      }
    }
    await bundled(episode.cover, 'Titelbild quer');
    await bundled(episode.coverPortrait, 'Titelbild hoch');
    expect(episode.titleJa, '雨');
  });
}
