import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

void main() {
  final episode = loadFolge01();

  test('Mira hat in Folge 01 keine Blase — ihr Schweigen steht im Erzähltext',
      () {
    for (final p in episode.allPanels) {
      expect(p.bubbles.where((b) => b.speakerId == kProtagonist), isEmpty,
          reason: 'Panel ${p.index}');
    }
  });

  test('jeder stumme Moment sagt im Erzähltext, dass Mira schweigt', () {
    const silence = {
      3: 'Es bleibt dort.',
      5: 'Sie bringt es nicht heraus.',
      6: 'Sie bleibt stumm.',
      9: 'Sie bleibt stumm vor der Tür.',
    };
    for (final p in episode.allPanels) {
      final text = p.thoughts.map((t) => t.text).join(' ');
      if (silence.containsKey(p.index)) {
        expect(text, contains(silence[p.index]), reason: 'Panel ${p.index}');
      }
    }
  });

  test('Sprecher außerhalb des Bildes nennt der Erzähltext (P3, P8)', () {
    String thoughts(int i) => episode.allPanels
        .firstWhere((p) => p.index == i)
        .thoughts
        .map((t) => t.text)
        .join(' ');
    expect(thoughts(2), contains('Passanten'));
    expect(thoughts(7), contains('Hinter ihr ruft der Ladenbesitzer.'));
  });

  test('„Acht Wörter“: P8, P10 und Endkarte zählen gleich', () {
    String thoughts(int i) => episode.allPanels
        .firstWhere((p) => p.index == i)
        .thoughts
        .map((t) => t.text)
        .join(' ');
    expect(thoughts(7), contains('Acht Wörter heute.'));
    expect(thoughts(9), contains('ein Zeichen und acht Wörter'));
    expect(episode.outro, contains('ein Zeichen und acht Wörter'));
  });

  test('vier stumme Momente: P4 あめ, P6 こわれた, P7 いくら, P10 すみません', () {
    final moments = [
      for (final p in episode.allPanels)
        for (final i in p.interactions)
          if (i.type == InteractionType.silent)
            (p.index, i.target, i.targetItemIds!.single, i.promptText),
    ];
    expect(moments.map((m) => (m.$1, m.$2, m.$3)).toList(), [
      (3, 'あめ', 'lex_ja_ame'),
      (5, 'こわれた', 'lex_ja_kowareta'),
      (6, 'いくら', 'lex_ja_ikura'),
      (9, 'すみません', 'lex_ja_sumimasen'),
    ]);
    for (final m in moments) {
      expect(m.$4, isNotNull, reason: 'Wirtin-Frage fehlt (Panel ${m.$1})');
      expect(m.$4, isNot(contains(m.$2)),
          reason: 'die Frage verrät das Wort (Panel ${m.$1})');
    }
  });

  test('die beiden Sprechmomente bleiben', () {
    final speaks = [
      for (final p in episode.allPanels)
        for (final i in p.interactions)
          if (i.type == InteractionType.speak) (p.index, i.target),
    ];
    expect(speaks, [(4, 'すみません'), (7, 'ありがとう')]);
  });
}
