import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/srs/scheduler.dart';
import 'package:nihongo_app/features/cafe/cafe_turn.dart';

void main() {
  group('grading', () {
    test('outcome maps to the right ReviewResult (hint = hard, §4.4)', () {
      expect(resultForOutcome(CafeOutcome.correct), ReviewResult.good);
      expect(resultForOutcome(CafeOutcome.wrong), ReviewResult.again);
      expect(resultForOutcome(CafeOutcome.hinted), ReviewResult.hard);
    });

    test('a used hint dodges — hinted even when the answer was correct', () {
      expect(outcomeFor(hintUsed: true, answerCorrect: true),
          CafeOutcome.hinted);
      expect(outcomeFor(hintUsed: true, answerCorrect: false),
          CafeOutcome.hinted);
    });

    test('without a hint, correctness decides', () {
      expect(outcomeFor(hintUsed: false, answerCorrect: true),
          CafeOutcome.correct);
      expect(outcomeFor(hintUsed: false, answerCorrect: false),
          CafeOutcome.wrong);
    });
  });

  group('kindForRung', () {
    test('rung 1 recognition, rung 2 reading, rung 3 production', () {
      expect(kindForRung(1), CafeExerciseKind.recognition);
      expect(kindForRung(2), CafeExerciseKind.readingInput);
      expect(kindForRung(3), CafeExerciseKind.productionInput);
    });
  });

  group('CafeTurnContent.forItem', () {
    late LearningDb db;
    setUp(() async {
      db = LearningDb.forTesting();
      // A minimal lexeme + concept, as ja_seed lays them down.
      await db.into(db.concepts).insert(ConceptsCompanion.insert(
          id: 'concept_rain', glossKey: 'rain', partOfSpeech: 'noun',
          defaultAssetType: const Value('image')));
      await db.into(db.lexemes).insert(LexemesCompanion.insert(
          id: 'lex_ja_ame', languageId: 'lang_ja', conceptId: 'concept_rain',
          writtenForm: 'あめ', reading: 'あめ'));
    });
    tearDown(() async => db.close());

    Future<LearnItem> due(int rung) async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame',
          rung: rung);
      return (await db.getDueItems('lang_ja', limit: 500)).single;
    }

    test('rung 3 (production): prompt is the meaning, answer is the word',
        () async {
      final content = await CafeTurnContent.forItem(db, await due(3));
      expect(content!.kind, CafeExerciseKind.productionInput);
      expect(content.promptText, 'rain'); // glossKey (meaning) shown
      expect(content.expectedAnswer, 'あめ'); // learner produces the word
      expect(content.meaning, 'rain');
    });

    test('rung 1 (recognition): prompt is the word, answer is the meaning',
        () async {
      final content = await CafeTurnContent.forItem(db, await due(1));
      expect(content!.kind, CafeExerciseKind.recognition);
      expect(content.promptText, 'あめ');
      expect(content.expectedAnswer, 'rain');
    });

    test('a lexeme that is not in the DB yields null (skippable)', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_missing',
          rung: 3);
      final item = (await db.getDueItems('lang_ja', limit: 500))
          .firstWhere((i) => i.refId == 'lex_missing');
      expect(await CafeTurnContent.forItem(db, item), isNull);
    });
  });
}
