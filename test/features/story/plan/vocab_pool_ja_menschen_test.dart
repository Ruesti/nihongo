import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/plan/pool_checks.dart';
import 'package:nihongo_app/features/story/plan/pool_entry.dart';
import 'package:nihongo_app/features/story/plan/vocab_pool_ja_menschen.dart';

void main() {
  test('Liste C ist regelkonform', () {
    expect(checkPool(vocabPoolJaMenschen), isEmpty);
  });

  test('Liste C hat die geplante Größe', () {
    expect(vocabPoolJaMenschen.length, inInclusiveRange(65, 85));
  });

  test('Liste C unterscheidet Homophone über die Schreibung', () {
    final hana = vocabPoolJaMenschen.where((e) => e.kana == 'はな').toList();
    expect(hana.map((e) => e.written), contains('鼻'));
    expect(vocabPoolJaMenschen.any((e) => e.id == 'lex_ja_kami_hair'), isTrue);
    expect(vocabPoolJaMenschen.every((e) => e.status == PoolStatus.geplant), isTrue);
  });
}
