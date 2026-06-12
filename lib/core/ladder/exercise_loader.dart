import 'dart:convert';

import '../db/learning_db.dart';
import '../script_profile.dart';
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
      RefType.grammar =>
        throw UnimplementedError('grammar exercises not yet supported'),
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

    return switch (type) {
      ExerciseType.recognition =>
        RecognitionContent(displayForm: lexeme.writtenForm, answer: concept.glossKey),
      ExerciseType.readingInput => ReadingInputContent(
          displayForm: lexeme.writtenForm,
          expectedReading: lexeme.reading,
        ),
      ExerciseType.productionInput => ProductionInputContent(
          prompt: concept.glossKey,
          expectedForm: lexeme.writtenForm,
        ),
      ExerciseType.writeTrace => ProductionInputContent(
          prompt: concept.glossKey,
          expectedForm: lexeme.writtenForm,
        ),
    };
  }
}
