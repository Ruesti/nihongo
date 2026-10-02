import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/plan/pool_checks.dart';
import 'package:nihongo_app/features/story/plan/pool_entry.dart';
import 'package:nihongo_app/features/story/plan/vocab_pool_ja_verben.dart';

void main() {
  test('Liste E ist regelkonform', () {
    expect(checkPool(vocabPoolJaVerben), isEmpty);
  });

  test('Liste E hat die geplante Größe und nur Verben', () {
    expect(vocabPoolJaVerben.length, inInclusiveRange(120, 145));
    expect(vocabPoolJaVerben.every((e) => e.pos == PartOfSpeech.verb), isTrue);
  });

  test('Liste E trägt eat und kowareta mit festen IDs', () {
    final byId = {for (final e in vocabPoolJaVerben) e.id: e};
    expect(byId['lex_ja_eat']?.written, '食べる');
    expect(byId['lex_ja_kowareta']?.plannedEpisode, 1);
    expect(byId['lex_ja_kowareta']?.status, PoolStatus.ausgeliefert);
  });
}
