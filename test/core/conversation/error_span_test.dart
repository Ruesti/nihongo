import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/conversation/error_span.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';

void main() {
  group('ErrorSpan', () {
    test('holds required fields', () {
      const span = ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.lexeme,
        refId: 'lex_ja_dog',
      );
      expect(span.languageId, 'lang_ja');
      expect(span.refType, RefType.lexeme);
      expect(span.refId, 'lex_ja_dog');
    });

    test('errorText and correction default to null', () {
      const span = ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.character,
        refId: 'char_ja_a',
      );
      expect(span.errorText, isNull);
      expect(span.correction, isNull);
    });

    test('can carry errorText and correction annotation', () {
      const span = ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.lexeme,
        refId: 'lex_ja_dog',
        errorText: '犬が',
        correction: '犬は',
      );
      expect(span.errorText, '犬が');
      expect(span.correction, '犬は');
    });

    test('supports grammar refType', () {
      const span = ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.grammar,
        refId: 'gp_ja_001',
      );
      expect(span.refType, RefType.grammar);
    });
  });
}
