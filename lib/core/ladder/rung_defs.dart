import '../script_profile.dart';

enum ExerciseType {
  encounter,       // rung 0: first meeting, ungraded (see/hear/trace)
  recognition,     // rung 1: show written/glyph, identify meaning
  readingInput,    // rung 2: show written/glyph, type reading
  productionInput, // rung 3, 5: show meaning, type written form (no MC — I1)
  writeTrace,      // rung 4: show glyph + stroke order, trace it (spec §5)
}

enum RefType { lexeme, character, grammar }

const int promotionThreshold = 3;

ExerciseType resolveExercise(int rung, RefType refType, ScriptProfile profile) {
  assert(rung >= 0 && rung <= 5, 'rung must be 0–5, got $rung');
  if (rung <= 0) return ExerciseType.encounter;
  if (rung == 1) return ExerciseType.recognition;
  if (rung == 2) return ExerciseType.readingInput;
  if (rung == 4) return ExerciseType.writeTrace;
  return ExerciseType.productionInput;
}
