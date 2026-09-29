import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

/// INV-14: Blasenposition im Bild (Lettering) und Tippfläche in der App
/// stammen aus tool/comic/folge01_layout.json. Läuft im Repo-Wurzelverzeichnis.
void main() {
  late Map<String, dynamic> layout;
  late Episode episode;

  setUpAll(() {
    layout = jsonDecode(File('tool/comic/folge01_layout.json').readAsStringSync())
        as Map<String, dynamic>;
    episode = loadFolge01();
  });

  List<double> rectOf(List<StoryPoint> pts) => [
        pts[0].x,
        pts[0].y,
        pts[1].x - pts[0].x,
        pts[2].y - pts[1].y,
      ];

  test('jede Blase der Folge steht mit Text und Rechteck in beiden Formaten in der Layout-Datei',
      () {
    final panels = layout['panels'] as Map<String, dynamic>;
    var checked = 0;
    for (final panel in episode.allPanels) {
      final pid = 'p${(panel.index + 1).toString().padLeft(2, '0')}';
      final formats = panels[pid] as Map<String, dynamic>?;
      expect(formats, isNotNull, reason: '$pid fehlt in der Layout-Datei');
      for (final entry in {'quer': PanelFormat.landscape, 'hoch': PanelFormat.portrait}.entries) {
        final spec = formats![entry.key] as Map<String, dynamic>;
        final bubbles = (spec['bubbles'] as List).cast<Map<String, dynamic>>();
        final withHit = [for (final b in panel.bubbles) if (b.hitArea.points.isNotEmpty) b];
        expect(bubbles.length, withHit.length,
            reason: '$pid ${entry.key}: ${bubbles.length} Blasen im Layout, ${withHit.length} in der Folge');
        for (var i = 0; i < bubbles.length; i++) {
          expect(withHit[i].text, bubbles[i]['text'],
              reason: '$pid ${entry.key} Blase $i: Text weicht ab');
          final want = (bubbles[i]['rect'] as List).cast<num>().map((n) => n.toDouble()).toList();
          final got = rectOf(withHit[i].hitAreaFor(entry.value).points);
          for (var k = 0; k < 4; k++) {
            expect(got[k], closeTo(want[k], 1e-4),
                reason: '$pid ${entry.key} Blase $i: Rechteck weicht ab (Feld $k)');
          }
          checked++;
        }
      }
    }
    expect(checked, greaterThan(20));
  });

  test('Reaktions-Panels der Layout-Datei tragen Reaktionsbilder in beiden Formaten', () {
    final reactions = (layout['reactions'] as List).cast<String>();
    for (final panel in episode.allPanels) {
      final pid = 'p${(panel.index + 1).toString().padLeft(2, '0')}';
      final it = panel.interactions.where((i) => i.reactionAsset != null).toList();
      if (reactions.contains(pid)) {
        expect(it, isNotEmpty, reason: '$pid: Reaktion im Layout, aber keine Interaktion mit reactionAsset');
        expect(it.first.reactionAssetPortrait, isNotNull, reason: '$pid: Reaktions-Hochbild fehlt');
      }
    }
  });
}
