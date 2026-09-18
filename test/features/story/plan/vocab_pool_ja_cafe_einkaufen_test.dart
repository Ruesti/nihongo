import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/plan/pool_checks.dart';
import 'package:nihongo_app/features/story/plan/pool_entry.dart';
import 'package:nihongo_app/features/story/plan/vocab_pool_ja_cafe_einkaufen.dart';

void main() {
  test('Liste B ist regelkonform', () {
    expect(checkPool(vocabPoolJaCafeEinkaufen), isEmpty);
  });

  test('Liste B hat die geplante Größe', () {
    expect(vocabPoolJaCafeEinkaufen.length, inInclusiveRange(85, 105));
  });

  test('Liste B trägt die festen IDs water, mise, kasa', () {
    final ids = vocabPoolJaCafeEinkaufen.map((e) => e.id).toSet();
    expect(ids, containsAll(['lex_ja_water', 'lex_ja_mise', 'lex_ja_kasa']));
    final mise = vocabPoolJaCafeEinkaufen.firstWhere((e) => e.id == 'lex_ja_mise');
    expect(mise.plannedEpisode, 1);
    expect(mise.status, PoolStatus.ausgeliefert);
    final water = vocabPoolJaCafeEinkaufen.firstWhere((e) => e.id == 'lex_ja_water');
    expect(water.status, PoolStatus.geplant);
  });
}
