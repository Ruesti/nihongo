import '../script_profile.dart';

enum ExerciseType {
  recognition,     // rung 1: show written/glyph, identify meaning
  readingInput,    // rung 2: show written/glyph, type reading
  productionInput, // rung 3+: show meaning, type written form (no MC — I1)
}

enum RefType { lexeme, character, grammar }

const int promotionThreshold = 3;

ExerciseType resolveExercise(int rung, RefType refType, ScriptProfile profile) {
  assert(rung >= 1 && rung <= 5, 'rung must be 1–5, got $rung');
  if (rung <= 1) return ExerciseType.recognition;
  if (rung == 2) return ExerciseType.readingInput;
  return ExerciseType.productionInput;
}
