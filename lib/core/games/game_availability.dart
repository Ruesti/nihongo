import 'package:nihongo_app/core/script_profile.dart';

enum GameType {
  mnemonicMatch,  // rung 1: associate glyph with mnemonic — decomposable scripts
  readingBlitz,   // rung 2: show glyph, tap reading — always
  componentBuild, // rung 3: build from radicals/jamo — decomposable non-alphabet
  wordBuild,      // rung 3 (alphabet) / rung 5 (non-logographic)
  positionalForm, // rung 3-4: match positional variants — positionalForms=true
  writeTrace,     // rung 4: trace stroke order — always
  kanjiCompound,  // rung 5: build compound from kanji — logographic only
  toneVowelMatch, // rung 0 (any): match tone/vowel marks — tonal or vowelPoints
}

typedef GameSpec = ({GameType type, int rung});

/// Returns the list of game specs available for a given script profile.
/// Order: ascending by rung. Pure function — no DB, no IO.
List<GameSpec> gameAvailability(ScriptProfile profile) {
  final specs = <GameSpec>[];

  // rung 1: mnemonicMatch if decomposable
  if (profile.isDecomposable) {
    specs.add((type: GameType.mnemonicMatch, rung: 1));
  }

  // rung 2: readingBlitz always
  specs.add((type: GameType.readingBlitz, rung: 2));

  // rung 3: componentBuild (decomposable non-alphabet) or wordBuild (alphabet)
  if (profile.isDecomposable && profile.scriptType != ScriptType.alphabet) {
    specs.add((type: GameType.componentBuild, rung: 3));
  } else if (profile.scriptType == ScriptType.alphabet) {
    specs.add((type: GameType.wordBuild, rung: 3));
  }

  // rung 3-4: positionalForm if positionalForms flag set
  if (profile.positionalForms) {
    specs.add((type: GameType.positionalForm, rung: 3));
    specs.add((type: GameType.positionalForm, rung: 4));
  }

  // rung 4: writeTrace always
  specs.add((type: GameType.writeTrace, rung: 4));

  // rung 5: kanjiCompound (logographic) or wordBuild (all others)
  if (profile.scriptType == ScriptType.logographic) {
    specs.add((type: GameType.kanjiCompound, rung: 5));
  } else {
    specs.add((type: GameType.wordBuild, rung: 5));
  }

  // rung 0 (any): toneVowelMatch if tonal or vowelPoints
  if (profile.hasToneSystem) {
    specs.add((type: GameType.toneVowelMatch, rung: 0));
  }

  return specs;
}
