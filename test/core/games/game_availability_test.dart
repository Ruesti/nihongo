import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/games/game_availability.dart';
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

const _jaKanjiProfile = ScriptProfile(
  id: 'sp_ja_kanji',
  scriptType: ScriptType.logographic,
  direction: Direction.ltr,
  decomposability: Decomposability.radicals,
  positionalForms: false,
  toneSystem: ToneSystem.pitchAccent,
  needsScriptTrack: true,
  transliteration: 'romaji',
  inputMethods: [InputMethod.keyboard, InputMethod.ime],
);

const _arProfile = ScriptProfile(
  id: 'sp_ar',
  scriptType: ScriptType.abjad,
  direction: Direction.rtl,
  decomposability: Decomposability.consonantMatra,
  positionalForms: true,
  toneSystem: ToneSystem.vowelPoints,
  needsScriptTrack: true,
  transliteration: 'none',
  inputMethods: [InputMethod.keyboard],
);

void main() {
  group('gameAvailability — JA kana (syllabary, atomic, pitchAccent)', () {
    late List<GameSpec> specs;

    setUp(() => specs = gameAvailability(_jaKanaProfile));

    test('always has readingBlitz at rung 2', () {
      expect(specs.any((s) => s.type == GameType.readingBlitz && s.rung == 2), isTrue);
    });

    test('always has writeTrace at rung 4', () {
      expect(specs.any((s) => s.type == GameType.writeTrace && s.rung == 4), isTrue);
    });

    test('wordBuild at rung 5 (non-logographic)', () {
      expect(specs.any((s) => s.type == GameType.wordBuild && s.rung == 5), isTrue);
    });

    test('no mnemonicMatch (atomic)', () {
      expect(specs.any((s) => s.type == GameType.mnemonicMatch), isFalse);
    });

    test('no componentBuild (atomic)', () {
      expect(specs.any((s) => s.type == GameType.componentBuild), isFalse);
    });

    test('no kanjiCompound (not logographic)', () {
      expect(specs.any((s) => s.type == GameType.kanjiCompound), isFalse);
    });

    test('no positionalForm (positionalForms=false)', () {
      expect(specs.any((s) => s.type == GameType.positionalForm), isFalse);
    });

    test('no toneVowelMatch (pitchAccent ≠ tonal/vowelPoints)', () {
      expect(specs.any((s) => s.type == GameType.toneVowelMatch), isFalse);
    });

    test('exactly 3 game specs total', () {
      expect(specs, hasLength(3));
    });
  });

  group('gameAvailability — ES alphabet (atomic, no tone)', () {
    late List<GameSpec> specs;

    setUp(() => specs = gameAvailability(_esProfile));

    test('wordBuild appears at rung 3 (alphabet)', () {
      expect(specs.any((s) => s.type == GameType.wordBuild && s.rung == 3), isTrue);
    });

    test('wordBuild appears at rung 5 (non-logographic)', () {
      expect(specs.any((s) => s.type == GameType.wordBuild && s.rung == 5), isTrue);
    });

    test('readingBlitz at rung 2', () {
      expect(specs.any((s) => s.type == GameType.readingBlitz && s.rung == 2), isTrue);
    });

    test('writeTrace at rung 4', () {
      expect(specs.any((s) => s.type == GameType.writeTrace && s.rung == 4), isTrue);
    });

    test('no mnemonicMatch (atomic alphabet)', () {
      expect(specs.any((s) => s.type == GameType.mnemonicMatch), isFalse);
    });

    test('no componentBuild (alphabet uses wordBuild instead)', () {
      expect(specs.any((s) => s.type == GameType.componentBuild), isFalse);
    });

    test('exactly 4 specs (readingBlitz, wordBuild×2, writeTrace)', () {
      expect(specs, hasLength(4));
    });
  });

  group('gameAvailability — JA kanji (logographic, radicals, pitchAccent)', () {
    late List<GameSpec> specs;

    setUp(() => specs = gameAvailability(_jaKanjiProfile));

    test('mnemonicMatch at rung 1 (decomposable)', () {
      expect(specs.any((s) => s.type == GameType.mnemonicMatch && s.rung == 1), isTrue);
    });

    test('readingBlitz at rung 2', () {
      expect(specs.any((s) => s.type == GameType.readingBlitz && s.rung == 2), isTrue);
    });

    test('componentBuild at rung 3 (decomposable, non-alphabet)', () {
      expect(specs.any((s) => s.type == GameType.componentBuild && s.rung == 3), isTrue);
    });

    test('writeTrace at rung 4', () {
      expect(specs.any((s) => s.type == GameType.writeTrace && s.rung == 4), isTrue);
    });

    test('kanjiCompound at rung 5 (logographic)', () {
      expect(specs.any((s) => s.type == GameType.kanjiCompound && s.rung == 5), isTrue);
    });

    test('no wordBuild (logographic uses kanjiCompound at 5; non-alphabet non-atomic at 3)', () {
      expect(specs.any((s) => s.type == GameType.wordBuild), isFalse);
    });

    test('exactly 5 specs', () {
      expect(specs, hasLength(5));
    });
  });

  group('gameAvailability — AR abjad (consonantMatra, positionalForms, vowelPoints)', () {
    late List<GameSpec> specs;

    setUp(() => specs = gameAvailability(_arProfile));

    test('mnemonicMatch at rung 1 (decomposable)', () {
      expect(specs.any((s) => s.type == GameType.mnemonicMatch && s.rung == 1), isTrue);
    });

    test('readingBlitz at rung 2', () {
      expect(specs.any((s) => s.type == GameType.readingBlitz && s.rung == 2), isTrue);
    });

    test('componentBuild at rung 3 (decomposable, abjad)', () {
      expect(specs.any((s) => s.type == GameType.componentBuild && s.rung == 3), isTrue);
    });

    test('positionalForm at rung 3 and rung 4', () {
      expect(specs.any((s) => s.type == GameType.positionalForm && s.rung == 3), isTrue);
      expect(specs.any((s) => s.type == GameType.positionalForm && s.rung == 4), isTrue);
    });

    test('writeTrace at rung 4', () {
      expect(specs.any((s) => s.type == GameType.writeTrace && s.rung == 4), isTrue);
    });

    test('wordBuild at rung 5 (abjad is not logographic)', () {
      expect(specs.any((s) => s.type == GameType.wordBuild && s.rung == 5), isTrue);
    });

    test('toneVowelMatch at rung 0 (vowelPoints)', () {
      expect(specs.any((s) => s.type == GameType.toneVowelMatch && s.rung == 0), isTrue);
    });

    test('exactly 8 specs', () {
      expect(specs, hasLength(8));
    });
  });
}
