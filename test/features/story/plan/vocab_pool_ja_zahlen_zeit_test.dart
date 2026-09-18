import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/plan/pool_checks.dart';
import 'package:nihongo_app/features/story/plan/pool_entry.dart';
import 'package:nihongo_app/features/story/plan/vocab_pool_ja_zahlen_zeit.dart';

void main() {
  test('Liste A ist regelkonform', () {
    expect(checkPool(vocabPoolJaZahlenZeit), isEmpty);
  });

  test('Liste A hat die geplante Größe', () {
    expect(vocabPoolJaZahlenZeit.length, inInclusiveRange(105, 120));
  });

  test('Liste A trägt das Folge-01-Wort hitori mit fester ID', () {
    final hitori =
        vocabPoolJaZahlenZeit.firstWhere((e) => e.id == 'lex_ja_hitori');
    expect(hitori.plannedEpisode, 1);
    expect(hitori.status, PoolStatus.ausgeliefert);
    expect(hitori.written, '一人');
  });
}
