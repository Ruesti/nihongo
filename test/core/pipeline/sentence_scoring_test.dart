import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';

TextSpan _span(
  String content, {
  String id = 's1',
  int ordinal = 1,
  int? tStartMs,
}) =>
    TextSpan(
      id: id,
      workId: 'w1',
      sourceId: 'src1',
      ordinal: ordinal,
      content: content,
      anchorType: 'time',
      tStartMs: tStartMs,
      tEndMs: tStartMs == null ? null : tStartMs + 1000,
    );

Token _tok(String surface, String lemma) => Token(
      surface: surface,
      lemma: lemma,
      pos: 'word',
      charStart: 0,
      charEnd: surface.length,
    );

/// Splits on whitespace and treats each word as its own lemma —
/// enough determinism to test the scoring math without depending on
/// the native JA tokenizer.
class _WordTokenizer implements Tokenizer {
  const _WordTokenizer();

  @override
  List<Token> tokenize(String text) =>
      text.split(' ').where((w) => w.isNotEmpty).map((w) => _tok(w, w)).toList();
}

class _FixedFrequency implements FrequencyList {
  final Map<String, int> ranks;
  const _FixedFrequency(this.ranks);

  @override
  int? rank(String lemma) => ranks[lemma];

  @override
  List<String> topLemmas(int n) {
    final sorted = ranks.keys.toList()
      ..sort((a, b) => ranks[a]!.compareTo(ranks[b]!));
    return sorted.take(n).toList();
  }
}

void main() {
  const tokenizer = _WordTokenizer();

  group('scoreSegment', () {
    test('unknownCount counts only unknown-state tokens', () {
      final span = _span('a b c');
      Knowledge knowledgeOf(String lemma) =>
          lemma == 'a' ? Knowledge.known : Knowledge.unknown;

      final scored =
          scoreSegment(span, tokenizer, const _FixedFrequency({}), knowledgeOf);

      expect(scored.unknownCount, 2); // b, c
    });

    test('knownRatio is knownCount / totalTokens', () {
      final span = _span('a b c d');
      Knowledge knowledgeOf(String lemma) =>
          (lemma == 'a' || lemma == 'b') ? Knowledge.known : Knowledge.unknown;

      final scored =
          scoreSegment(span, tokenizer, const _FixedFrequency({}), knowledgeOf);

      expect(scored.knownRatio, 0.5);
    });

    test('empty segment has knownRatio 0.0, not NaN', () {
      final span = _span('');

      final scored = scoreSegment(
          span, tokenizer, const _FixedFrequency({}), (_) => Knowledge.unknown);

      expect(scored.knownRatio, 0.0);
    });

    test('targetRank is set only when unknownCount == 1', () {
      final span = _span('known unknown1');
      Knowledge knowledgeOf(String lemma) =>
          lemma == 'known' ? Knowledge.known : Knowledge.unknown;
      const frequency = _FixedFrequency({'unknown1': 42});

      final scored = scoreSegment(span, tokenizer, frequency, knowledgeOf);

      expect(scored.unknownCount, 1);
      expect(scored.targetRank, 42);
    });

    test(
        'punctuation-only tokens are excluded from unknownCount and '
        'knownRatio, but still present in tokens', () {
      final span = _span('a 。');
      // '.' is not the sole token — punctuation should be ignored by
      // the counting logic even though the fake tokenizer, like real
      // ones, still emits it as a token.
      final scored = scoreSegment(span, tokenizer, const _FixedFrequency({}),
          (_) => Knowledge.unknown);

      expect(scored.tokens.map((t) => t.surface), ['a', '。']);
      expect(scored.unknownCount, 1); // only 'a', not '。'
    });

    test('a segment of only punctuation has knownRatio 0.0, not NaN', () {
      final span = _span('。 ！');

      final scored = scoreSegment(
          span, tokenizer, const _FixedFrequency({}), (_) => Knowledge.known);

      expect(scored.knownRatio, 0.0);
      expect(scored.unknownCount, 0);
    });

    test('targetRank is null when unknownCount != 1', () {
      final span = _span('unknown1 unknown2');
      const frequency = _FixedFrequency({'unknown1': 1, 'unknown2': 2});

      final scored = scoreSegment(
          span, tokenizer, frequency, (_) => Knowledge.unknown);

      expect(scored.unknownCount, 2);
      expect(scored.targetRank, isNull);
    });
  });

  group('rankCandidates', () {
    test('only includes unknownCount == 1 segments', () {
      final zero = scoreSegment(_span('a b'), tokenizer, const _FixedFrequency({}),
          (_) => Knowledge.known);
      final one = scoreSegment(_span('a unknown1'), tokenizer,
          const _FixedFrequency({'unknown1': 5}), (l) => l == 'a' ? Knowledge.known : Knowledge.unknown);
      final two = scoreSegment(_span('unknown1 unknown2'), tokenizer,
          const _FixedFrequency({}), (_) => Knowledge.unknown);

      final ranked = rankCandidates([zero, one, two]);

      expect(ranked, [one]);
    });

    test('lower frequency rank sorts first (rule 2)', () {
      const frequency = _FixedFrequency({'rare': 9000, 'common': 5});
      Knowledge knowledgeOf(String l) => l == 'x' ? Knowledge.known : Knowledge.unknown;
      final rareSeg = scoreSegment(_span('x rare', id: 'rare'), tokenizer, frequency, knowledgeOf);
      final commonSeg = scoreSegment(_span('x common', id: 'common'), tokenizer, frequency, knowledgeOf);

      final ranked = rankCandidates([rareSeg, commonSeg]);

      expect(ranked.map((s) => s.segment.id), ['common', 'rare']);
    });

    test('segments with no frequency rank sort last (rule 2 tiebreak)',
        () {
      const frequency = _FixedFrequency({'ranked': 100});
      Knowledge knowledgeOf(String l) => l == 'x' ? Knowledge.known : Knowledge.unknown;
      final unrankedSeg = scoreSegment(
          _span('x unranked', id: 'unranked'), tokenizer, frequency, knowledgeOf);
      final rankedSeg = scoreSegment(
          _span('x ranked', id: 'ranked'), tokenizer, frequency, knowledgeOf);

      final ranked = rankCandidates([unrankedSeg, rankedSeg]);

      expect(ranked.map((s) => s.segment.id), ['ranked', 'unranked']);
    });

    test('within equal frequency rank, in-range length wins (rule 3)', () {
      const frequency = _FixedFrequency({'w': 1});
      // Only 'w' is unknown; every filler word is known, so padding
      // the sentence for length doesn't change unknownCount.
      Knowledge knowledgeOf(String l) => l == 'w' ? Knowledge.unknown : Knowledge.known;
      // Same target lemma/rank on both, so rule 2 is a tie.
      final tooShort =
          scoreSegment(_span('x w', id: 'short'), tokenizer, frequency, knowledgeOf);
      final justRight = scoreSegment(
          _span('x w this is a long enough sentence', id: 'right'),
          tokenizer,
          frequency,
          knowledgeOf);

      final ranked =
          rankCandidates([tooShort, justRight], minLen: 15, maxLen: 60);

      expect(ranked.first.segment.id, 'right');
    });

    test('within equal rank and length, audio-backed segment wins (rule 4)',
        () {
      const frequency = _FixedFrequency({'w': 1});
      Knowledge knowledgeOf(String l) => l == 'w' ? Knowledge.unknown : Knowledge.known;
      final noAudio = scoreSegment(
          _span('x w padding padding', id: 'no-audio'),
          tokenizer, frequency, knowledgeOf);
      final withAudio = scoreSegment(
          _span('x w padding padding', id: 'audio', tStartMs: 1000),
          tokenizer, frequency, knowledgeOf);

      final ranked = rankCandidates([noAudio, withAudio], minLen: 0, maxLen: 999);

      expect(ranked.first.segment.id, 'audio');
    });
  });

  group('secondaryCandidates', () {
    test('only includes unknownCount == 2 segments', () {
      final one = scoreSegment(_span('a unknown1', id: '1'), tokenizer,
          const _FixedFrequency({}), (l) => l == 'a' ? Knowledge.known : Knowledge.unknown);
      final two = scoreSegment(_span('unknown1 unknown2', id: '2'), tokenizer,
          const _FixedFrequency({}), (_) => Knowledge.unknown);
      final three = scoreSegment(
          _span('unknown1 unknown2 unknown3', id: '3'),
          tokenizer,
          const _FixedFrequency({}),
          (_) => Knowledge.unknown);

      final secondary = secondaryCandidates([one, two, three]);

      expect(secondary.map((s) => s.segment.id), ['2']);
    });
  });
}
