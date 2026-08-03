import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/pipeline/fsrs_knowledge_source.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';

Future<void> _insertCard(
  MiningDb db, {
  required String lemma,
  required String state,
  required double stability,
}) async {
  final vocabId = 'vocab:$lemma';
  await db.into(db.vocabItems).insert(VocabItemsCompanion.insert(
        id: vocabId,
        languageCode: 'ja',
        lemma: lemma,
        pos: '',
        createdAt: DateTime.now(),
      ));
  await db.into(db.cards).insert(CardsCompanion.insert(
        id: 'card:$vocabId',
        vocabItemId: vocabId,
        state: Value(state),
        stability: Value(stability),
        due: DateTime.now(),
        lastReview: DateTime.now(),
      ));
}

void main() {
  late MiningDb db;

  setUp(() => db = MiningDb.forTesting());
  tearDown(() => db.close());

  group('FsrsKnowledgeSource', () {
    test('a lemma with no card at all is unknown', () async {
      final source =
          await FsrsKnowledgeSource.load(db, languageCode: 'ja');

      expect(source('never seen'), Knowledge.unknown);
    });

    test('state review at/above the threshold is known', () async {
      await _insertCard(db, lemma: 'known', state: 'review', stability: 10);

      final source = await FsrsKnowledgeSource.load(db,
          languageCode: 'ja', knownStabilityThreshold: 5.0);

      expect(source('known'), Knowledge.known);
    });

    test('state review below the threshold is learning, not known',
        () async {
      await _insertCard(db, lemma: 'young', state: 'review', stability: 1);

      final source = await FsrsKnowledgeSource.load(db,
          languageCode: 'ja', knownStabilityThreshold: 5.0);

      expect(source('young'), Knowledge.learning);
    });

    test('high stability but state != review is learning, not known',
        () async {
      // A card mid-relearning after a lapse shouldn't count as known
      // just because its historical stability number is still high.
      await _insertCard(db,
          lemma: 'lapsed', state: 'relearning', stability: 50);

      final source = await FsrsKnowledgeSource.load(db,
          languageCode: 'ja', knownStabilityThreshold: 5.0);

      expect(source('lapsed'), Knowledge.learning);
    });

    test('only loads cards for the requested languageCode', () async {
      await _insertCard(db, lemma: 'ja-word', state: 'review', stability: 10);
      final vocabId = 'vocab:es-word';
      await db.into(db.vocabItems).insert(VocabItemsCompanion.insert(
            id: vocabId,
            languageCode: 'es',
            lemma: 'es-word',
            pos: '',
            createdAt: DateTime.now(),
          ));
      await db.into(db.cards).insert(CardsCompanion.insert(
            id: 'card:$vocabId',
            vocabItemId: vocabId,
            state: const Value('review'),
            stability: const Value(10),
            due: DateTime.now(),
            lastReview: DateTime.now(),
          ));

      final source = await FsrsKnowledgeSource.load(db, languageCode: 'ja');

      expect(source('ja-word'), Knowledge.known);
      expect(source('es-word'), Knowledge.unknown);
    });
  });
}
