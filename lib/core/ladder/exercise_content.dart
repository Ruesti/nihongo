/// Pure data model for exercise content — no logic, no DB dependencies.
///
/// These 4 variants represent the different exercise types across rungs 1–4:
/// - RecognitionContent → rung 1: show form, identify meaning
/// - ReadingInputContent → rung 2: show form, type reading
/// - ProductionInputContent → rungs 3 & 5: show meaning, type form
/// - WriteTraceContent → rung 4: show glyph + optional stroke order, trace it
sealed class ExerciseContent {}

/// Rung 1: Recognition — show written form or glyph, identify its meaning.
final class RecognitionContent extends ExerciseContent {
  /// The form to display (glyph or writtenForm).
  final String displayForm;

  /// The expected answer (meaning or glossKey).
  final String answer;

  RecognitionContent({
    required this.displayForm,
    required this.answer,
  });
}

/// Rung 2: Reading Input — show written form, type its reading.
final class ReadingInputContent extends ExerciseContent {
  /// The form to display (glyph or writtenForm).
  final String displayForm;

  /// The expected reading for validation.
  final String expectedReading;

  ReadingInputContent({
    required this.displayForm,
    required this.expectedReading,
  });
}

/// Rungs 3 & 5: Production Input — show meaning, type the written form.
final class ProductionInputContent extends ExerciseContent {
  /// The prompt shown to the learner (meaning or glossKey — what to produce).
  final String prompt;

  /// The expected written form the learner must type.
  final String expectedForm;

  ProductionInputContent({
    required this.prompt,
    required this.expectedForm,
  });
}

/// Rung 4: Write Trace — show glyph + optional stroke order, trace it.
final class WriteTraceContent extends ExerciseContent {
  /// The glyph to trace.
  final String glyph;

  /// Asset ID for stroke order animation (null until Phase 6).
  final String? strokeOrderAssetId;

  /// The expected reading after trace is complete.
  final String expectedReading;

  WriteTraceContent({
    required this.glyph,
    this.strokeOrderAssetId,
    required this.expectedReading,
  });
}
