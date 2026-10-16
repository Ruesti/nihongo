import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_portrait_library.g.dart';
import 'package:nihongo_app/features/cafe/cafe_portraits.dart';

void main() {
  test('jede Tabellenzeile hat ihre Datei im Ordner', () {
    for (final e in cafePortraitFiles.entries) {
      for (final f in e.value.entries) {
        for (final n in f.value) {
          final path = '$cafePortraitDir/${e.key}_${n}_${f.key}.jpg';
          expect(File(path).existsSync(), isTrue, reason: '$path fehlt');
        }
      }
    }
  });

  test('jede Datei im Ordner steht in der Tabelle (keine Leichen im Bundle)',
      () {
    final listed = {
      for (final e in cafePortraitFiles.entries)
        for (final f in e.value.entries)
          for (final n in f.value) '${e.key}_${n}_${f.key}.jpg',
    };
    final files = Directory(cafePortraitDir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.jpg'));
    for (final n in files) {
      expect(listed, contains(n), reason: '$n fehlt in der Tabelle');
    }
  });
}
