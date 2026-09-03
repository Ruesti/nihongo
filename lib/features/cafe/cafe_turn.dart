import '../../core/db/learning_db.dart';
import '../../core/srs/scheduler.dart';

/// How a café turn ended (brief §4.4/§4.5): the learner answered correctly,
/// wrongly, or dodged by tapping the meaning as a hint.
enum CafeOutcome { correct, wrong, hinted }

/// Maps the café outcome to the SM-2 grade fed to [LadderReview.submit].
/// A tapped hint schedules like [ReviewResult.hard] — it counts, but does not
/// extend the interval the way a clean [ReviewResult.good] would (§4.4).
ReviewResult resultForOutcome(CafeOutcome outcome) => switch (outcome) {
      CafeOutcome.correct => ReviewResult.good,
      CafeOutcome.wrong => ReviewResult.again,
      CafeOutcome.hinted => ReviewResult.hard,
    };

/// A used hint dodges the turn: the outcome is [CafeOutcome.hinted] regardless
/// of whether the eventual answer was right. Otherwise correctness decides.
CafeOutcome outcomeFor({required bool hintUsed, required bool answerCorrect}) {
  if (hintUsed) return CafeOutcome.hinted;
  return answerCorrect ? CafeOutcome.correct : CafeOutcome.wrong;
}

/// The café turn's exercise shape for rungs 1–3 (P8). Mirrors
/// `resolveExercise` (rung_defs.dart) for these rungs without pulling in the
/// `ScriptProfile` it requires but does not use.
enum CafeExerciseKind { recognition, readingInput, productionInput }

CafeExerciseKind kindForRung(int rung) {
  if (rung <= 1) return CafeExerciseKind.recognition;
  if (rung == 2) return CafeExerciseKind.readingInput;
  return CafeExerciseKind.productionInput; // rung 3 (P8's top rung)
}

/// The content of one café turn, built from a due lexeme [LearnItem] by a
/// café-scoped Lexemes+Concepts query (the same data `ExerciseLoader` reads).
/// [meaning] is the concept's `glossKey` — the English key `review_screen`
/// also shows today; German localization is a deferred follow-up.
class CafeTurnContent {
  final CafeExerciseKind kind;

  /// What the guest shows: the word (recognition/reading) or the meaning
  /// (production).
  final String promptText;

  /// The answer the learner must give: the meaning (recognition), the reading
  /// (readingInput), or the written form (productionInput).
  final String expectedAnswer;

  final String meaning;
  final String writtenForm;
  final String reading;

  const CafeTurnContent({
    required this.kind,
    required this.promptText,
    required this.expectedAnswer,
    required this.meaning,
    required this.writtenForm,
    required this.reading,
  });

  /// Builds the turn content for [item] (a lexeme). Returns null if the
  /// lexeme or its concept is missing — the caller skips such an item rather
  /// than crashing the café.
  static Future<CafeTurnContent?> forItem(LearningDb db, LearnItem item) async {
    final lex = await (db.select(db.lexemes)
          ..where((t) => t.id.equals(item.refId)))
        .getSingleOrNull();
    if (lex == null) return null;
    final concept = await (db.select(db.concepts)
          ..where((t) => t.id.equals(lex.conceptId)))
        .getSingleOrNull();
    if (concept == null) return null;

    final kind = kindForRung(item.masteryRung);
    final meaning = concept.glossKey;
    final (promptText, expectedAnswer) = switch (kind) {
      CafeExerciseKind.recognition => (lex.writtenForm, meaning),
      CafeExerciseKind.readingInput => (lex.writtenForm, lex.reading),
      CafeExerciseKind.productionInput => (meaning, lex.writtenForm),
    };

    return CafeTurnContent(
      kind: kind,
      promptText: promptText,
      expectedAnswer: expectedAnswer,
      meaning: meaning,
      writtenForm: lex.writtenForm,
      reading: lex.reading,
    );
  }
}
