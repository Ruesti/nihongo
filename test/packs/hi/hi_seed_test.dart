import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/games/game_availability.dart';
import 'package:nihongo_app/core/script_profile.dart';
import 'package:nihongo_app/packs/hi/hi_seed.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedHiPack(db);
  });

  tearDown(() => db.close());

  group('HI ScriptProfile', () {
    test('sp_hi exists', () async {
      final profiles = await db.select(db.scriptProfiles).get();
      expect(profiles.any((p) => p.id == 'sp_hi'), isTrue);
    });

    test('scriptType = abugida', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_hi');
      expect(p.scriptType, 'abugida');
    });

    test('direction = ltr', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_hi');
      expect(p.direction, 'ltr');
    });

    test('decomposability = baseDiacritics', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_hi');
      expect(p.decomposability, 'baseDiacritics');
    });

    test('positionalForms = false', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_hi');
      expect(p.positionalForms, isFalse);
    });

    test('toneSystem = none', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_hi');
      expect(p.toneSystem, 'none');
    });

    test('needsScriptTrack = true', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_hi');
      expect(p.needsScriptTrack, isTrue);
    });
  });

  group('HI language', () {
    test('lang_hi exists', () async {
      final langs = await db.select(db.languages).get();
      expect(langs.any((l) => l.id == 'lang_hi'), isTrue);
    });

    test('name = हिन्दी', () async {
      final lang = (await db.select(db.languages).get())
          .firstWhere((l) => l.id == 'lang_hi');
      expect(lang.name, 'हिन्दी');
    });

    test('ttsVoice = hi-IN', () async {
      final lang = (await db.select(db.languages).get())
          .firstWhere((l) => l.id == 'lang_hi');
      expect(lang.ttsVoice, 'hi-IN');
    });
  });

  group('HI lexemes', () {
    test('5 lexemes for lang_hi', () async {
      final lexemes = await (db.select(db.lexemes)
            ..where((t) => t.languageId.equals('lang_hi')))
          .get();
      expect(lexemes, hasLength(5));
    });

    test('कुत्ता exists with reading kutta', () async {
      final lexemes = await (db.select(db.lexemes)
            ..where((t) => t.languageId.equals('lang_hi')))
          .get();
      final dog = lexemes.firstWhere((l) => l.writtenForm == 'कुत्ता');
      expect(dog.reading, 'kutta');
      expect(dog.conceptId, 'concept_dog');
    });

    test('concept_water shared with other packs (I4)', () async {
      final concepts = await db.select(db.concepts).get();
      expect(concepts.any((c) => c.id == 'concept_water'), isTrue);
    });
  });

  group('HI characters (Devanagari aksharas)', () {
    test('5 characters for lang_hi', () async {
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_hi')))
          .get();
      expect(chars, hasLength(5));
    });

    test('का exists with reading kaa', () async {
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_hi')))
          .get();
      final kaa = chars.firstWhere((c) => c.glyph == 'का');
      final readings = (jsonDecode(kaa.readingsJson) as List).cast<String>();
      expect(readings.contains('kaa'), isTrue);
      expect(kaa.meaning, contains('long a'));
    });

    test('का has 2 baseDiacritics components (base + aa-matra right)', () async {
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_hi')))
          .get();
      final kaa = chars.firstWhere((c) => c.glyph == 'का');
      final components = await (db.select(db.charComponents)
            ..where((t) => t.characterId.equals(kaa.id)))
          .get();
      expect(components, hasLength(2));
      expect(components.any((c) => c.position == 'base'), isTrue);
      expect(components.any((c) => c.position == 'right'), isTrue);
    });

    test('कि has 2 baseDiacritics components (base + i-matra above_left)', () async {
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_hi')))
          .get();
      final ki = chars.firstWhere((c) => c.glyph == 'कि');
      final components = await (db.select(db.charComponents)
            ..where((t) => t.characterId.equals(ki.id)))
          .get();
      expect(components, hasLength(2));
      expect(components.any((c) => c.position == 'base'), isTrue);
      expect(components.any((c) => c.position == 'above_left'), isTrue);
    });
  });

  group('HI I5 proof — gameAvailability from ScriptProfile flags', () {
    const hiProfile = ScriptProfile(
      id: 'sp_hi',
      scriptType: ScriptType.abugida,
      direction: Direction.ltr,
      decomposability: Decomposability.baseDiacritics,
      positionalForms: false,
      toneSystem: ToneSystem.none,
      needsScriptTrack: true,
      transliteration: 'romanization',
      inputMethods: [InputMethod.keyboard],
    );

    test('gameAvailability returns 5 specs for HI profile', () {
      final specs = gameAvailability(hiProfile);
      expect(specs, hasLength(5));
    });

    test('componentBuild at rung 3 (baseDiacritics → decomposable, non-alphabet)', () {
      final specs = gameAvailability(hiProfile);
      expect(
        specs.any((s) => s.type == GameType.componentBuild && s.rung == 3),
        isTrue,
      );
    });

    test('no positionalForm and no toneVowelMatch', () {
      final specs = gameAvailability(hiProfile);
      expect(specs.any((s) => s.type == GameType.positionalForm), isFalse);
      expect(specs.any((s) => s.type == GameType.toneVowelMatch), isFalse);
    });
  });

  group('HI can-do goal', () {
    test('cando_hi_a1_devanagari exists', () async {
      final goals = await db.select(db.canDoGoals).get();
      expect(goals.any((g) => g.id == 'cando_hi_a1_devanagari'), isTrue);
    });

    test('goal is at cefrBand A1 for lang_hi', () async {
      final goal = (await db.select(db.canDoGoals).get())
          .firstWhere((g) => g.id == 'cando_hi_a1_devanagari');
      expect(goal.cefrBand, 'A1');
      expect(goal.languageId, 'lang_hi');
    });
  });

  group('HI idempotency', () {
    test('seeding twice does not duplicate data', () async {
      await seedHiPack(db);
      final lexemes = await (db.select(db.lexemes)
            ..where((t) => t.languageId.equals('lang_hi')))
          .get();
      expect(lexemes, hasLength(5));
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_hi')))
          .get();
      expect(chars, hasLength(5));
    });
  });
}
