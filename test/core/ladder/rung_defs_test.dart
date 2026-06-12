import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/script_profile.dart';

const _jaKanaProfile = ScriptProfile(
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

const _esProfile = ScriptProfile(
  id: 'sp_es',
  scriptType: ScriptType.alphabet,
  direction: Direction.ltr,
  decomposability: Decomposability.atomic,
  positionalForms: false,
  toneSystem: ToneSystem.none,
  needsScriptTrack: false,
  transliteration: 'none',
  inputMethods: [InputMethod.keyboard],
);

void main() {
  group('resolveExercise', () {
    test('rung 1 → recognition (any refType, any profile)', () {
      expect(resolveExercise(1, RefType.lexeme, _jaKanaProfile), ExerciseType.recognition);
      expect(resolveExercise(1, RefType.character, _jaKanaProfile), ExerciseType.recognition);
      expect(resolveExercise(1, RefType.lexeme, _esProfile), ExerciseType.recognition);
    });

    test('rung 2 → readingInput', () {
      expect(resolveExercise(2, RefType.lexeme, _jaKanaProfile), ExerciseType.readingInput);
      expect(resolveExercise(2, RefType.character, _jaKanaProfile), ExerciseType.readingInput);
    });

    test('rung 3 → productionInput (I1: no MC on production rungs)', () {
      expect(resolveExercise(3, RefType.lexeme, _jaKanaProfile), ExerciseType.productionInput);
      expect(resolveExercise(3, RefType.character, _jaKanaProfile), ExerciseType.productionInput);
    });

    test('rung 4 → writeTrace (always, per spec §5)', () {
      expect(resolveExercise(4, RefType.lexeme, _jaKanaProfile), ExerciseType.writeTrace);
      expect(resolveExercise(4, RefType.character, _jaKanaProfile), ExerciseType.writeTrace);
      expect(resolveExercise(4, RefType.lexeme, _esProfile), ExerciseType.writeTrace);
    });

    test('rung 5 → productionInput', () {
      expect(resolveExercise(5, RefType.lexeme, _jaKanaProfile), ExerciseType.productionInput);
      expect(resolveExercise(5, RefType.character, _jaKanaProfile), ExerciseType.productionInput);
    });

    test('production rungs never return recognition (I1 invariant)', () {
      for (final rung in [3, 4, 5]) {
        final type = resolveExercise(rung, RefType.lexeme, _jaKanaProfile);
        expect(type, isNot(ExerciseType.recognition));
      }
    });
  });

  test('promotionThreshold is 3', () {
    expect(promotionThreshold, 3);
  });
}
