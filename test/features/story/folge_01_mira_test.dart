import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

void main() {
  final episode = loadFolge01();

  test('Mira sagt in Folge 01 kein Wort Japanisch, nur „…“', () {
    for (final p in episode.allPanels) {
      for (final b in p.bubbles.where((b) => b.speakerId == kProtagonist)) {
        expect(b.isSilence, isTrue, reason: 'Panel ${p.index}: „${b.text}"');
      }
    }
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
