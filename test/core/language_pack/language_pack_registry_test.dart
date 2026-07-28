import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/language_pack/language_pack_registry.dart';

class _FakePack implements LanguagePack {
  @override
  final String code;

  const _FakePack(this.code);

  @override
  Tokenizer get tokenizer => throw UnimplementedError();
  @override
  Dictionary get dictionary => throw UnimplementedError();
  @override
  FrequencyList get frequency => throw UnimplementedError();
  @override
  ReadingProvider? get readings => null;
}

void main() {
  group('LanguagePackRegistry', () {
    test('resolves a registered pack by code', () {
      final registry = LanguagePackRegistry();
      registry.register(const _FakePack('ja'));

      expect(registry['ja']?.code, 'ja');
    });

    test('returns null for an unregistered code', () {
      final registry = LanguagePackRegistry();

      expect(registry['zz'], isNull);
    });

    test('registering the same code twice replaces the pack (last wins)', () {
      final registry = LanguagePackRegistry();
      final first = const _FakePack('ja');
      final second = const _FakePack('ja');
      registry.register(first);
      registry.register(second);

      expect(identical(registry['ja'], second), isTrue);
    });

    test('registeredCodes lists every distinct registered code', () {
      final registry = LanguagePackRegistry();
      registry.register(const _FakePack('ja'));
      registry.register(const _FakePack('xx'));

      expect(registry.registeredCodes, unorderedEquals(['ja', 'xx']));
    });
  });
}
