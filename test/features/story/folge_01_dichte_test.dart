import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

void main() {
  test('Folge 01 V3 erfüllt das Dichte-Soll (Spec Mira schweigt §4.3)', () {
    final episode = loadFolge01();
    final counts = <String, int>{};
    var heard = 0;
    for (final panel in episode.allPanels) {
      for (final bubble in panel.bubbles) {
        if (bubble.speakerId == kProtagonist) continue;
        for (final token in bubble.tokens) {
          final id = token.itemId;
          if (id == null) continue;
          heard++;
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }
    }
    var targets = 0;
    for (final it in episode.allPanels.expand((p) => p.interactions)) {
      for (final id in it.targetItemIds ?? const <String>[]) {
        targets++;
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    expect(heard, greaterThanOrEqualTo(44), reason: 'zu wenig gehörte Sprache');
    expect(heard + targets, greaterThanOrEqualTo(50));
    for (final ref in episode.budget.items) {
      expect(
        counts[ref.id] ?? 0,
        greaterThanOrEqualTo(2),
        reason: '${ref.id} kommt zu selten vor',
      );
    }
    // Bilanz aus der Spec, Wort für Wort (gehört + Ziele); Stand 6.10.:
    // Wörter über Szenen gestreut statt in der Blase verdoppelt.
    expect(counts, {
      'lex_ja_ame': 5,
      'lex_ja_kasa': 4,
      'lex_ja_hai': 4,
      'lex_ja_kowareta': 3,
      'lex_ja_douzo': 3,
      'lex_ja_sumimasen': 3,
      'lex_ja_samui': 3,
      'lex_ja_hontou': 3,
      'lex_ja_koko': 3,
      'lex_ja_daijoubu': 3,
      'lex_ja_eki': 2,
      'lex_ja_kore': 2,
      'lex_ja_dame': 2,
      'lex_ja_hitori': 2,
      'lex_ja_iie': 2,
      'lex_ja_mise': 2,
      'lex_ja_ikura': 2,
      'lex_ja_arigatou': 2,
    });
    expect(episode.allPanels.length, 10);
    expect(episode.intro, isNotNull);
    expect(episode.outro, isNotNull);
  });

  test('Folge 01: kein Wort doppelt in einer Blase (außer Floskel-Liste)', () {
    final episode = loadFolge01();
    final problems = <String>[];
    for (final panel in episode.allPanels) {
      for (final bubble in panel.bubbles) {
        final seen = <String>{};
        for (final token in bubble.tokens) {
          final id = token.itemId;
          if (id == null || seen.add(id)) continue;
          final idiom = kIdiomDoubles.any(
            (i) => i.contains(token.surface) && bubble.text.contains(i),
          );
          if (!idiom) {
            problems.add(
              'Panel ${panel.index}: „${bubble.text}" sagt $id '
              'zweimal',
            );
          }
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('Floskel-Liste bleibt klein (höchstens zwei echte Doppel-Floskeln)', () {
    expect(kIdiomDoubles.length, lessThanOrEqualTo(2));
  });
}

/// Drehbuch-Regel (Uli, 6.10.): Wiederholung entsteht über Szenen und
/// Sprecher, nicht durch Verdoppeln in derselben Blase (「ここ、ここ」).
/// Erlaubt sind nur diese echten Doppel-Floskeln.
const kIdiomDoubles = [
  'どうぞ、どうぞ', // „bitte, bitte" beim Aufdrängen eines Geschenks
  'はいはい', // „ja, ja" beim lachenden Abwinken
];
