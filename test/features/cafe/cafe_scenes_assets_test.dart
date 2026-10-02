import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('jede Tabellenzeile hat eine gebündelte Datei (> 1 KB)', () async {
    for (final e in cafeSceneLibrary.entries) {
      for (final light in e.value) {
        final path = '$cafeSceneDir/${e.key.stem}_${light.name}.jpg';
        final data = await rootBundle.load(path);
        expect(data.lengthInBytes, greaterThan(1000), reason: '$path fehlt');
      }
    }
  });

  test('jede Datei im Ordner steht in der Tabelle (keine Leichen im Bundle)',
      () {
    final files = Directory(cafeSceneDir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.jpg'))
        .toSet();
    final listed = {
      for (final e in cafeSceneLibrary.entries)
        for (final l in e.value) '${e.key.stem}_${l.name}.jpg',
    };
    expect(files, listed);
  });
}
