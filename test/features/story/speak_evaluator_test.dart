import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';

void main() {
  test('nichts gehört → -1 (kein Versuch)', () {
    expect(SttSpeakEvaluator.bestSimilarity('', 'えき'), -1.0);
    expect(SttSpeakEvaluator.bestSimilarity('  ', 'えき|駅'), -1.0);
  });

  test('Alternativen mit |: der beste Treffer zählt (Kanji-Ergebnis passt)', () {
    expect(SttSpeakEvaluator.bestSimilarity('駅', 'えき|駅'), 1.0);
    expect(SttSpeakEvaluator.bestSimilarity('えき', 'えき|駅'), 1.0);
    expect(SttSpeakEvaluator.bestSimilarity('かさ', 'えき|駅'), 0.0);
    expect(SttSpeakEvaluator.bestSimilarity('駅', 'えき||駅|'), 1.0);
  });

  test('ohne | wie bisher: Ähnlichkeit gegen das eine Ziel', () {
    expect(SttSpeakEvaluator.bestSimilarity('あめ', 'あめ'), 1.0);
  });

  test('speakTarget: ohne Dubletten und ohne leere Teile', () {
    expect(speakTarget('えき', '駅', '駅'), 'えき|駅');
    expect(speakTarget('あめ', 'あめ', 'あめ'), 'あめ');
    expect(speakTarget('えき', 'えき', ''), 'えき');
  });
}
