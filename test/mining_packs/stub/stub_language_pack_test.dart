import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/mining_packs/stub/stub_language_pack.dart';

void main() {
  group('StubLanguagePack', () {
    const pack = StubLanguagePack();

    test('code is the reserved-for-testing "xx" tag, not a real language',
        () {
      expect(pack.code, 'xx');
    });

    test('has no reading layer', () {
      expect(pack.readings, isNull);
    });

    test('tokenizer splits on whitespace and strips punctuation', () {
      final tokens = pack.tokenizer.tokenize('hello world, this is a test.');

      expect(
        tokens.map((t) => t.surface).toList(),
        ['hello', 'world', 'this', 'is', 'a', 'test'],
      );
    });

    test('tokenizer preserves correct char offsets into the source text',
        () {
      final tokens = pack.tokenizer.tokenize('ab cd');

      expect(tokens[0].charStart, 0);
      expect(tokens[0].charEnd, 2);
      expect(tokens[1].charStart, 3);
      expect(tokens[1].charEnd, 5);
    });

    test('dictionary lookup always returns empty (no real data)', () {
      expect(pack.dictionary.lookup('hello', ''), isEmpty);
    });

    test('frequency rank is always unknown (no real data)', () {
      expect(pack.frequency.rank('hello'), isNull);
    });
  });
}
