import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/script_profile.dart';

void main() {
  test('ScriptProfile fields round-trip', () {
    const p = ScriptProfile(
      id: 'sp_test',
      scriptType: ScriptType.syllabary,
      direction: Direction.ltr,
      decomposability: Decomposability.atomic,
      positionalForms: false,
      toneSystem: ToneSystem.pitchAccent,
      needsScriptTrack: true,
      transliteration: 'romaji',
      inputMethods: [InputMethod.keyboard, InputMethod.ime],
    );
    expect(p.scriptType, ScriptType.syllabary);
    expect(p.direction, Direction.ltr);
    expect(p.inputMethods, [InputMethod.keyboard, InputMethod.ime]);
  });

  test('isDecomposable true when not atomic', () {
    const p = ScriptProfile(
      id: 'sp_kanji',
      scriptType: ScriptType.logographic,
      direction: Direction.ltr,
      decomposability: Decomposability.radicals,
      positionalForms: false,
      toneSystem: ToneSystem.none,
      needsScriptTrack: true,
      transliteration: 'none',
      inputMethods: [InputMethod.ime],
    );
    expect(p.isDecomposable, isTrue);
  });

  test('isDecomposable false when atomic', () {
    const p = ScriptProfile(
      id: 'sp_latin',
      scriptType: ScriptType.alphabet,
      direction: Direction.ltr,
      decomposability: Decomposability.atomic,
      positionalForms: false,
      toneSystem: ToneSystem.none,
      needsScriptTrack: false,
      transliteration: 'none',
      inputMethods: [InputMethod.keyboard],
    );
    expect(p.isDecomposable, isFalse);
  });

  test('hasToneSystem true for tonal', () {
    const p = ScriptProfile(
      id: 'sp_zh',
      scriptType: ScriptType.logographic,
      direction: Direction.ltr,
      decomposability: Decomposability.radicals,
      positionalForms: false,
      toneSystem: ToneSystem.tonal,
      needsScriptTrack: false,
      transliteration: 'pinyin',
      inputMethods: [InputMethod.ime],
    );
    expect(p.hasToneSystem, isTrue);
  });

  test('hasToneSystem true for vowelPoints', () {
    const p = ScriptProfile(
      id: 'sp_ar',
      scriptType: ScriptType.abjad,
      direction: Direction.rtl,
      decomposability: Decomposability.baseDiacritics,
      positionalForms: true,
      toneSystem: ToneSystem.vowelPoints,
      needsScriptTrack: true,
      transliteration: 'none',
      inputMethods: [InputMethod.keyboard],
    );
    expect(p.hasToneSystem, isTrue);
  });

  test('hasToneSystem false for pitchAccent', () {
    const p = ScriptProfile(
      id: 'sp_ja',
      scriptType: ScriptType.syllabary,
      direction: Direction.ltr,
      decomposability: Decomposability.atomic,
      positionalForms: false,
      toneSystem: ToneSystem.pitchAccent,
      needsScriptTrack: true,
      transliteration: 'romaji',
      inputMethods: [InputMethod.keyboard],
    );
    expect(p.hasToneSystem, isFalse);
  });
}
