import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedJaPack(db);
    await db.batch((b) => b.insertAll(db.sentences, [
          SentencesCompanion(
            id: const Value('sent_ja_001'),
            languageId: const Value('lang_ja'),
            cefrBand: const Value('A1'),
            content: const Value('これは犬です。'),
            knownCoverage: const Value(0.9),
          ),
          SentencesCompanion(
            id: const Value('sent_ja_002'),
            languageId: const Value('lang_ja'),
            cefrBand: const Value('A1'),
            content: const Value('犬が好きです。'),
            knownCoverage: const Value(0.7),
          ),
          SentencesCompanion(
            id: const Value('sent_ja_003'),
            languageId: const Value('lang_ja'),
            cefrBand: const Value('A2'),
            content: const Value('この犬はとても可愛いです。'),
            knownCoverage: const Value(0.5),
          ),
        ]));
  });

  tearDown(() => db.close());

  group('getSentences', () {
    test('returns all sentences for language when no filters', () async {
      final sents = await db.getSentences('lang_ja');
      expect(sents, hasLength(3));
    });

    test('returns empty list for unknown language', () async {
      final sents = await db.getSentences('lang_es');
      expect(sents, isEmpty);
    });

    test('filters by cefrBand', () async {
      final sents = await db.getSentences('lang_ja', cefrBand: 'A1');
      expect(sents, hasLength(2));
      expect(sents.every((s) => s.cefrBand == 'A1'), isTrue);
    });

    test('filters by minCoverage', () async {
      final sents = await db.getSentences('lang_ja', minCoverage: 0.8);
      expect(sents, hasLength(1));
      expect(sents.first.id, 'sent_ja_001');
    });

    test('orders by knownCoverage descending (most-known first = i+1 input)', () async {
      final sents = await db.getSentences('lang_ja');
      final coverages = sents.map((s) => s.knownCoverage).toList();
      for (int i = 0; i < coverages.length - 1; i++) {
        expect(coverages[i], greaterThanOrEqualTo(coverages[i + 1]));
      }
    });

    test('cefrBand + minCoverage filters combine correctly', () async {
      final sents = await db.getSentences('lang_ja', cefrBand: 'A1', minCoverage: 0.8);
      expect(sents, hasLength(1));
      expect(sents.first.cefrBand, 'A1');
      expect(sents.first.knownCoverage, greaterThanOrEqualTo(0.8));
    });
  });
}
