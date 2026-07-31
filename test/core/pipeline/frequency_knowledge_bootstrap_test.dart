import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/frequency_knowledge_bootstrap.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';

class _FixedFrequency implements FrequencyList {
  final Map<String, int> ranks;
  const _FixedFrequency(this.ranks);

  @override
  int? rank(String lemma) => ranks[lemma];
}

void main() {
  group('FrequencyBootstrapKnowledge', () {
    test('lemma at or below the threshold rank is known', () {
      final knowledgeOf = FrequencyBootstrapKnowledge(
        const _FixedFrequency({'common': 500}),
        knownRankThreshold: 1000,
      );

      expect(knowledgeOf('common'), Knowledge.known);
    });

    test('lemma above the threshold rank is unknown', () {
      final knowledgeOf = FrequencyBootstrapKnowledge(
        const _FixedFrequency({'rare': 5000}),
        knownRankThreshold: 1000,
      );

      expect(knowledgeOf('rare'), Knowledge.unknown);
    });

    test('lemma with no rank at all is unknown, not learning', () {
      final knowledgeOf = FrequencyBootstrapKnowledge(
        const _FixedFrequency({}),
        knownRankThreshold: 1000,
      );

      expect(knowledgeOf('never seen'), Knowledge.unknown);
    });

    test('rank exactly at the threshold counts as known (inclusive)', () {
      final knowledgeOf = FrequencyBootstrapKnowledge(
        const _FixedFrequency({'edge': 1000}),
        knownRankThreshold: 1000,
      );

      expect(knowledgeOf('edge'), Knowledge.known);
    });
  });
}
