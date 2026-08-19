import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/learning_db.dart';
import '../script_profile.dart';
import 'encounter.dart';
import 'exercise_content.dart';
import 'rung_defs.dart';

class ExerciseLoader {
  final LearningDb _db;

  ExerciseLoader(this._db);

  Future<ExerciseContent> load(LearnItem item, ScriptProfile profile) {
    final refType = RefType.values.byName(item.refType);
    final exerciseType = resolveExercise(item.masteryRung, refType, profile);

    return switch (refType) {
      RefType.character => _loadCharacter(item.refId, exerciseType),
      RefType.lexeme => _loadLexeme(item.refId, exerciseType),
      RefType.grammar => _loadGrammar(item.refId, exerciseType),
    };
  }

  Future<ExerciseContent> _loadCharacter(
    String charId,
    ExerciseType type,
  ) async {
    final char = await (_db.select(_db.characters)
          ..where((t) => t.id.equals(charId)))
        .getSingle();
    final readings = (jsonDecode(char.readingsJson) as List).cast<String>();
    final reading = readings.isNotEmpty ? readings.first : '';

    return switch (type) {
      ExerciseType.encounter => EncounterContent(
          encounter: CharacterEncounter(
            glyph: char.glyph,
            reading: reading,
            audioText: char.glyph,
            strokeOrderAssetId: char.strokeOrderAssetId,
            mnemonic: null,
          ),
        ),
      ExerciseType.recognition =>
        RecognitionContent(displayForm: char.glyph, answer: char.meaning),
      ExerciseType.readingInput =>
        ReadingInputContent(displayForm: char.glyph, expectedReading: reading),
      ExerciseType.productionInput =>
        ProductionInputContent(prompt: char.meaning, expectedForm: char.glyph),
      ExerciseType.writeTrace => WriteTraceContent(
          glyph: char.glyph,
          strokeOrderAssetId: char.strokeOrderAssetId,
          expectedReading: reading,
        ),
    };
  }

  Future<ExerciseContent> _loadLexeme(
    String lexemeId,
    ExerciseType type,
  ) async {
    final lexeme = await (_db.select(_db.lexemes)
          ..where((t) => t.id.equals(lexemeId)))
        .getSingle();
    final concept = await (_db.select(_db.concepts)
          ..where((t) => t.id.equals(lexeme.conceptId)))
        .getSingle();

    if (type == ExerciseType.encounter) {
      final asset = await (_db.select(_db.assets)
            ..where((t) =>
                t.conceptId.equals(lexeme.conceptId) & t.type.equals('image')))
          .getSingleOrNull();
      return EncounterContent(
        encounter: LexemeEncounter(
          writtenForm: lexeme.writtenForm,
          reading: lexeme.reading,
          audioText: lexeme.writtenForm,
          meaning: concept.glossKey,
          conceptImagePath: asset?.path,
          exampleSentence: null,
        ),
      );
    }

    return switch (type) {
      ExerciseType.encounter => throw StateError('handled above'),
      ExerciseType.recognition => RecognitionContent(
          displayForm: lexeme.writtenForm, answer: concept.glossKey),
      ExerciseType.readingInput => ReadingInputContent(
          displayForm: lexeme.writtenForm, expectedReading: lexeme.reading),
      ExerciseType.productionInput => ProductionInputContent(
          prompt: concept.glossKey, expectedForm: lexeme.writtenForm),
      ExerciseType.writeTrace => ProductionInputContent(
          prompt: concept.glossKey, expectedForm: lexeme.writtenForm),
    };
  }

  Future<ExerciseContent> _loadGrammar(
    String grammarId,
    ExerciseType type,
  ) async {
    final gp = await (_db.select(_db.grammarPoints)
          ..where((t) => t.id.equals(grammarId)))
        .getSingle();
    final canDo = await (_db.select(_db.canDoGoals)
          ..where((t) => t.id.equals(gp.canDoId)))
        .getSingle();

    if (type == ExerciseType.encounter) {
      return EncounterContent(
        encounter: GrammarEncounter(
          pattern: gp.id,
          plainExplanation: canDo.description,
          example: '',
          canDoDescription: canDo.description,
          contrast: null,
        ),
      );
    }
    // Graded grammar exercises are out of scope for this plan.
    throw UnimplementedError('grammar graded exercises not yet supported');
  }
}
