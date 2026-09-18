import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/plan/pool_checks.dart';
import 'package:nihongo_app/features/story/plan/pool_entry.dart';
import 'package:nihongo_app/features/story/plan/vocab_pool_ja_orte_wetter.dart';

void main() {
  test('Liste D ist regelkonform', () {
    expect(checkPool(vocabPoolJaOrteWetter), isEmpty);
  });

  test('Liste D hat die geplante Größe', () {
    expect(vocabPoolJaOrteWetter.length, inInclusiveRange(90, 110));
  });

  test('Liste D trägt die festen IDs koko, eki, ame, samui, dog, cat', () {
    final byId = {for (final e in vocabPoolJaOrteWetter) e.id: e};
    for (final id in ['lex_ja_koko', 'lex_ja_eki', 'lex_ja_ame', 'lex_ja_samui']) {
      expect(byId[id]?.plannedEpisode, 1, reason: id);
      expect(byId[id]?.status, PoolStatus.ausgeliefert, reason: id);
    }
    expect(byId['lex_ja_dog']?.written, '犬');
    expect(byId['lex_ja_cat']?.written, '猫');
    expect(byId['lex_ja_ame']?.written, '雨');
  });
}
