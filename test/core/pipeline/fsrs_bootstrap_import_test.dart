import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/fsrs_bootstrap_import.dart';

class _FixedFrequency implements FrequencyList {
  final List<String> ordered;
  const _FixedFrequency(this.ordered);

  @override
  int? rank(String lemma) {
    final i = ordered.indexOf(lemma);
    return i == -1 ? null : i + 1;
  }

  @override
  List<String> topLemmas(int n) => ordered.take(n).toList();
}

void main() {
  late MiningDb db;

  setUp(() => db = MiningDb.forTesting());
  tearDown(() => db.close());

  group('simulateWellKnownCard', () {
    test('reaches state review after several easy reviews', () {
      final card = simulateWellKnownCard(FSRS());

      expect(card.state, State.review);
    });

    test('has positive, non-trivial stability', () {
      final card = simulateWellKnownCard(FSRS());

      expect(card.stability, greaterThan(1.0));
    });
  });

  group('importFrequencyBootstrap', () {
    const frequency = _FixedFrequency(['a', 'b', 'c', 'd', 'e']);

    test('creates a VocabItems row per top-N lemma', () async {
      await importFrequencyBootstrap(db, frequency,
          languageCode: 'ja', topN: 3);

      final items = await db.select(db.vocabItems).get();
      expect(items.map((v) => v.lemma), unorderedEquals(['a', 'b', 'c']));
    });

    test('creates a Cards row per VocabItems row, in state review',
        () async {
      await importFrequencyBootstrap(db, frequency,
          languageCode: 'ja', topN: 2);

      final cards = await db.select(db.cards).get();
      expect(cards, hasLength(2));
      expect(cards.every((c) => c.state == 'review'), isTrue);
      expect(cards.every((c) => c.stability > 0), isTrue);
    });

    test('reports the actual imported lemma count', () async {
      final result = await importFrequencyBootstrap(db, frequency,
          languageCode: 'ja', topN: 100); // more than the corpus has

      expect(result.lemmaCount, 5); // capped by topLemmas' own list length
    });

    test('is idempotent-safe: importing twice does not duplicate rows',
        () async {
      await importFrequencyBootstrap(db, frequency,
          languageCode: 'ja', topN: 3);
      await importFrequencyBootstrap(db, frequency,
          languageCode: 'ja', topN: 3);

      final items = await db.select(db.vocabItems).get();
      expect(items, hasLength(3));
    });
  });
}
