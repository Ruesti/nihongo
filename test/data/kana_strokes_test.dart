import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/data/kana_strokes.dart';

void main() {
  test('maps あ to its KanjiVG codepoint asset', () {
    expect(strokeAssetForKana('あ'), 'assets/kanji_svg/3042.svg');
  });

  test('returns null for a kana with no bundled stroke file', () {
    // A rarely-bundled kana → graceful null, never a crash.
    expect(strokeAssetForKana('ゑ'), isNull);
  });
}
