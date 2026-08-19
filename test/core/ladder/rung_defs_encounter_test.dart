import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/script_profile.dart';

const _p = ScriptProfile(
  id: 'sp_ja_kana',
  scriptType: ScriptType.syllabary,
  direction: Direction.ltr,
  decomposability: Decomposability.atomic,
  positionalForms: false,
  toneSystem: ToneSystem.pitchAccent,
  needsScriptTrack: true,
  transliteration: 'romaji',
  inputMethods: [InputMethod.keyboard],
);

void main() {
  test('rung 0 → encounter for every refType', () {
    for (final rt in RefType.values) {
      expect(resolveExercise(0, rt, _p), ExerciseType.encounter);
    }
  });

  test('rung 1 is still recognition (unchanged)', () {
    expect(resolveExercise(1, RefType.character, _p), ExerciseType.recognition);
  });

  test('rung 4 is still writeTrace (unchanged)', () {
    expect(resolveExercise(4, RefType.character, _p), ExerciseType.writeTrace);
  });
}
