import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('jedes Panel der Folge 01 referenziert ein wirklich gebündeltes Bild',
      () async {
    final episode = loadFolge01();
    for (final panel in episode.allPanels) {
      expect(panel.asset, isNot(contains('placeholder')),
          reason: 'Panel ${panel.index} zeigt noch den Platzhalter');
      final data = await rootBundle.load(panel.asset);
      expect(data.lengthInBytes, greaterThan(1000),
          reason: '${panel.asset} fehlt oder ist leer');
    }
  });
}
