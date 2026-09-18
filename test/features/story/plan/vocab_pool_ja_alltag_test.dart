import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/plan/pool_checks.dart';
import 'package:nihongo_app/features/story/plan/pool_entry.dart';
import 'package:nihongo_app/features/story/plan/vocab_pool_ja_alltag.dart';

void main() {
  test('Liste G und Bank sind zusammen regelkonform', () {
    expect(checkPool([...vocabPoolJaAlltag, ...vocabPoolJaBank], maxBank: 40),
        isEmpty);
  });

  test('Liste G hat die geplante Größe, die Bank genau 40', () {
    expect(vocabPoolJaAlltag.length, inInclusiveRange(130, 150));
    expect(vocabPoolJaBank.length, 40);
    expect(vocabPoolJaBank.every((e) => e.status == PoolStatus.bank), isTrue);
    expect(vocabPoolJaAlltag.every((e) => e.status == PoolStatus.geplant), isTrue);
  });

  test('Liste G trägt die Shotengai-Wörter', () {
    final kana = vocabPoolJaAlltag.map((e) => e.kana).toSet();
    expect(kana, containsAll(['かぎ', 'シャッター', 'はり', 'いと', 'てがみ', 'じしょ', 'かんばん']));
  });
}
