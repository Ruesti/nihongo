import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';

void main() {
  group('lightFor', () {
    DateTime at(int h, [int m = 0]) => DateTime(2026, 9, 19, h, m);
    test('Uhrgrenzen 06 / 17 / 21', () {
      expect(lightFor(at(5, 59)), CafeLight.nacht);
      expect(lightFor(at(6)), CafeLight.tag);
      expect(lightFor(at(16, 59)), CafeLight.tag);
      expect(lightFor(at(17)), CafeLight.abend);
      expect(lightFor(at(20, 59)), CafeLight.abend);
      expect(lightFor(at(21)), CafeLight.nacht);
      expect(lightFor(at(0)), CafeLight.nacht);
    });
    test('Regen ersetzt nur den Tag', () {
      expect(lightFor(at(10), rain: true), CafeLight.regen);
      expect(lightFor(at(18), rain: true), CafeLight.abend);
      expect(lightFor(at(23), rain: true), CafeLight.nacht);
    });
  });

  group('sceneAssetIn — Rückfallkette', () {
    const onlyTag = {
      CafeMotif.leer: {CafeLight.tag},
      CafeMotif.wirtinTresen: {CafeLight.tag},
      CafeMotif.schulkindNische: {CafeLight.tag},
      CafeMotif.vielrednerZeitung: {CafeLight.tag},
      CafeMotif.gleichaltrigeKaffee: {CafeLight.tag},
    };
    test('vorhanden → direkter Pfad', () {
      expect(sceneAssetIn(onlyTag, CafeMotif.leer, CafeLight.tag),
          'assets/comic/cafe/leer_tag.jpg');
    });
    test('Moment ohne Licht → Stammplatz im Licht, sonst Stammplatz bei Tag',
        () {
      const lib = {
        CafeMotif.schulkindNische: {CafeLight.tag, CafeLight.nacht},
        CafeMotif.leer: {CafeLight.tag},
      };
      expect(sceneAssetIn(lib, CafeMotif.schulkindKakao, CafeLight.nacht),
          'assets/comic/cafe/schulkind_nische_nacht.jpg');
      expect(sceneAssetIn(lib, CafeMotif.schulkindKakao, CafeLight.abend),
          'assets/comic/cafe/schulkind_nische_tag.jpg');
    });
    test('Raum ohne Licht → Raum bei Tag; gar nichts → leer_tag', () {
      expect(sceneAssetIn(onlyTag, CafeMotif.leer, CafeLight.nacht),
          'assets/comic/cafe/leer_tag.jpg');
      expect(sceneAssetIn(const {}, CafeMotif.wirtinTee, CafeLight.abend),
          'assets/comic/cafe/leer_tag.jpg');
    });
    test('jede Kombination liefert einen Pfad', () {
      for (final m in CafeMotif.values) {
        for (final l in CafeLight.values) {
          expect(sceneAsset(m, l), startsWith('assets/comic/cafe/'));
          expect(sceneAsset(m, l), endsWith('.jpg'));
        }
      }
    });
  });

  group('turnScene', () {
    test('Ordnungszahl rotiert über Stammplatz und Momente des Sprechers', () {
      final a = turnScene(CafeGuest.schulkind, CafeLight.tag, 0);
      expect(a, sceneAsset(CafeMotif.schulkindNische, CafeLight.tag));
      expect(turnScene(CafeGuest.schulkind, CafeLight.tag, 1),
          sceneAsset(CafeMotif.schulkindHausaufgaben, CafeLight.tag));
      expect(turnScene(CafeGuest.schulkind, CafeLight.tag, 2),
          sceneAsset(CafeMotif.schulkindKakao, CafeLight.tag));
      expect(turnScene(CafeGuest.schulkind, CafeLight.tag, 3), a);
    });
    test('jeder Gast hat genau drei Motive, Stammplatz zuerst', () {
      for (final g in CafeGuest.values) {
        final motifs = CafeMotif.values.where((m) => m.guest == g).toList();
        expect(motifs.length, 3, reason: '$g');
        expect(motifs.first, stammplatzOf(g));
      }
    });
  });

  test('Tabelle: nur Motive mit den vier Lichtern, Dateistämme eindeutig', () {
    final stems = CafeMotif.values.map((m) => m.stem).toSet();
    expect(stems.length, CafeMotif.values.length);
    for (final e in cafeSceneLibrary.entries) {
      expect(e.value, isNotEmpty, reason: '${e.key} ohne Licht');
    }
  });
}
