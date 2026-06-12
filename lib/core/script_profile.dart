enum ScriptType { alphabet, syllabary, logographic, abugida, abjad, hangul }

enum Direction { ltr, rtl }

enum Decomposability { atomic, radicals, jamo, consonantMatra, baseDiacritics }

enum ToneSystem { none, tonal, pitchAccent, vowelPoints }

enum InputMethod { keyboard, ime, handwriting }

class ScriptProfile {
  final String id;
  final ScriptType scriptType;
  final Direction direction;
  final Decomposability decomposability;
  final bool positionalForms;
  final ToneSystem toneSystem;
  final bool needsScriptTrack;
  final String transliteration;
  final List<InputMethod> inputMethods;

  const ScriptProfile({
    required this.id,
    required this.scriptType,
    required this.direction,
    required this.decomposability,
    required this.positionalForms,
    required this.toneSystem,
    required this.needsScriptTrack,
    required this.transliteration,
    required this.inputMethods,
  });

  bool get isDecomposable => decomposability != Decomposability.atomic;

  bool get hasToneSystem =>
      toneSystem == ToneSystem.tonal || toneSystem == ToneSystem.vowelPoints;
}
