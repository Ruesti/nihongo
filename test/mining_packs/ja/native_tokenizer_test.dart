import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/mining_packs/ja/native_tokenizer.dart';

// Exercises the real Lindera + embedded-IPADIC tokenizer via
// dart:ffi (native/ja_tokenizer). Requires the native library to be
// built first:
//   cd native/ja_tokenizer && cargo build --release
// (documented in native/ja_tokenizer/README.md).

void main() {
  late NativeJaTokenizer tokenizer;

  setUp(() => tokenizer = NativeJaTokenizer());

  group('NativeJaTokenizer', () {
    test('tokenizes a proper noun as a single token, matching Phase 1',
        () {
      // Same probe sentence as BERICHT_1_lindera-spike.md's spot check.
      final tokens = tokenizer.tokenize('関西国際空港限定トートバッグ');

      expect(tokens[0].surface, '関西国際空港');
      expect(tokens[0].lemma, '関西国際空港');
      expect(tokens[0].pos, startsWith('名詞'));
    });

    test('reports a katakana reading for a known word', () {
      final tokens = tokenizer.tokenize('日本語');

      expect(tokens.single.reading, 'ニホンゴ');
    });

    test('reports the dictionary base form for a conjugated verb', () {
      final tokens = tokenizer.tokenize('食べます');
      final verbStem = tokens.first;

      expect(verbStem.lemma, '食べる');
    });

    test('char offsets are correct in Dart string (UTF-16) index space',
        () {
      const text = '私は学生です。';
      final tokens = tokenizer.tokenize(text);

      for (final t in tokens) {
        expect(text.substring(t.charStart, t.charEnd), t.surface);
      }
    });

    test('tokens tile the source text in order with no gaps or overlaps',
        () {
      const text = '今日は良い天気ですね';
      final tokens = tokenizer.tokenize(text);

      var cursor = 0;
      for (final t in tokens) {
        expect(t.charStart, cursor);
        cursor = t.charEnd;
      }
      expect(cursor, text.length);
    });

    test('empty input yields no tokens', () {
      expect(tokenizer.tokenize(''), isEmpty);
    });

    test('mixed Japanese and ASCII text tokenizes without error', () {
      final tokens = tokenizer.tokenize('Flutterでアプリを作ります');

      expect(tokens, isNotEmpty);
    });
  });
}
