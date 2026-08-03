import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/furigana.dart';

class _FixedReadings implements ReadingProvider {
  final Map<String, String> byLemma;
  const _FixedReadings(this.byLemma);

  @override
  Reading? reading(Token token) {
    final r = byLemma[token.lemma];
    return r == null ? null : Reading(r);
  }
}

Token _tok(String surface, String lemma, {int charStart = 0}) => Token(
      surface: surface,
      lemma: lemma,
      pos: 'noun',
      charStart: charStart,
      charEnd: charStart + surface.length,
    );

void main() {
  group('computeFurigana', () {
    test('null ReadingProvider yields no spans (languages without a reading layer)',
        () {
      final tokens = [_tok('word', 'word')];

      expect(computeFurigana(tokens, null), isEmpty);
    });

    test('a token with a differing reading gets a span', () {
      final tokens = [_tok('日本語', '日本語')];
      const readings = _FixedReadings({'日本語': 'にほんご'});

      final spans = computeFurigana(tokens, readings);

      expect(spans, hasLength(1));
      expect(spans.single.surface, '日本語');
      expect(spans.single.reading, 'にほんご');
    });

    test('a token whose reading equals its surface is skipped (already kana)',
        () {
      final tokens = [_tok('です', 'です')];
      const readings = _FixedReadings({'です': 'です'});

      expect(computeFurigana(tokens, readings), isEmpty);
    });

    test('a token with no reading available is skipped, not errored', () {
      final tokens = [_tok('未知語', '未知語')];
      const readings = _FixedReadings({});

      expect(computeFurigana(tokens, readings), isEmpty);
    });

    test('preserves char offsets from the source token', () {
      final tokens = [_tok('日本語', '日本語', charStart: 5)];
      const readings = _FixedReadings({'日本語': 'にほんご'});

      final span = computeFurigana(tokens, readings).single;

      expect(span.charStart, 5);
      expect(span.charEnd, 8);
    });

    test('only annotates tokens that need it, in a mixed sentence', () {
      final tokens = [
        _tok('私', '私', charStart: 0),
        _tok('は', 'は', charStart: 1),
        _tok('日本語', '日本語', charStart: 2),
        _tok('です', 'です', charStart: 5),
      ];
      const readings = _FixedReadings({
        '私': 'わたし',
        'は': 'は', // particle, kana already — no annotation needed
        '日本語': 'にほんご',
        'です': 'です',
      });

      final spans = computeFurigana(tokens, readings);

      expect(spans.map((s) => s.surface), ['私', '日本語']);
    });
  });
}
