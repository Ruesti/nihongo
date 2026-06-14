import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/games/game_availability.dart';
import 'package:nihongo_app/core/script_profile.dart';
import 'package:nihongo_app/packs/ar/ar_seed.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedArPack(db);
  });

  tearDown(() => db.close());

  group('AR ScriptProfile', () {
    test('sp_ar exists', () async {
      final profiles = await db.select(db.scriptProfiles).get();
      expect(profiles.any((p) => p.id == 'sp_ar'), isTrue);
    });

    test('scriptType = abjad', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_ar');
      expect(p.scriptType, 'abjad');
    });

    test('direction = rtl', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_ar');
      expect(p.direction, 'rtl');
    });

    test('decomposability = consonantMatra', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_ar');
      expect(p.decomposability, 'consonantMatra');
    });

    test('positionalForms = true', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_ar');
      expect(p.positionalForms, isTrue);
    });

    test('toneSystem = vowelPoints', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_ar');
      expect(p.toneSystem, 'vowelPoints');
    });

    test('needsScriptTrack = true', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_ar');
      expect(p.needsScriptTrack, isTrue);
    });
  });

  group('AR language', () {
    test('lang_ar exists', () async {
      final langs = await db.select(db.languages).get();
      expect(langs.any((l) => l.id == 'lang_ar'), isTrue);
    });

    test('name = العربية', () async {
      final lang = (await db.select(db.languages).get())
          .firstWhere((l) => l.id == 'lang_ar');
      expect(lang.name, 'العربية');
    });

    test('ttsVoice = ar-SA', () async {
      final lang = (await db.select(db.languages).get())
          .firstWhere((l) => l.id == 'lang_ar');
      expect(lang.ttsVoice, 'ar-SA');
    });
  });

  group('AR lexemes', () {
    test('5 lexemes for lang_ar', () async {
      final lexemes = await (db.select(db.lexemes)
            ..where((t) => t.languageId.equals('lang_ar')))
          .get();
      expect(lexemes, hasLength(5));
    });

    test('كلب exists with reading kalb', () async {
      final lexemes = await (db.select(db.lexemes)
            ..where((t) => t.languageId.equals('lang_ar')))
          .get();
      final dog = lexemes.firstWhere((l) => l.writtenForm == 'كلب');
      expect(dog.reading, 'kalb');
      expect(dog.conceptId, 'concept_dog');
    });

    test('concept_water shared with other packs (I4)', () async {
      final concepts = await db.select(db.concepts).get();
      expect(concepts.any((c) => c.id == 'concept_water'), isTrue);
    });
  });

  group('AR characters (Arabic letters)', () {
    test('5 characters for lang_ar', () async {
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_ar')))
          .get();
      expect(chars, hasLength(5));
    });

    test('ب exists with reading b', () async {
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_ar')))
          .get();
      final ba = chars.firstWhere((c) => c.glyph == 'ب');
      final readings = (jsonDecode(ba.readingsJson) as List).cast<String>();
      expect(readings.contains('b'), isTrue);
      expect(ba.meaning, contains('ba'));
    });

    test('ب has 2 consonantMatra components (base + vowel diacritic)', () async {
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_ar')))
          .get();
      final ba = chars.firstWhere((c) => c.glyph == 'ب');
      final components = await (db.select(db.charComponents)
            ..where((t) => t.characterId.equals(ba.id)))
          .get();
      expect(components, hasLength(2));
      expect(components.any((c) => c.position == 'base'), isTrue);
      expect(components.any((c) => c.position == 'above'), isTrue);
    });

    test('ت has 2 consonantMatra components (base + kasra below)', () async {
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_ar')))
          .get();
      final ta = chars.firstWhere((c) => c.glyph == 'ت');
      final components = await (db.select(db.charComponents)
            ..where((t) => t.characterId.equals(ta.id)))
          .get();
      expect(components, hasLength(2));
      expect(components.any((c) => c.position == 'base'), isTrue);
      expect(components.any((c) => c.position == 'below'), isTrue);
    });
  });

  group('AR I5 proof — gameAvailability from ScriptProfile flags', () {
    const arProfile = ScriptProfile(
      id: 'sp_ar',
      scriptType: ScriptType.abjad,
      direction: Direction.rtl,
      decomposability: Decomposability.consonantMatra,
      positionalForms: true,
      toneSystem: ToneSystem.vowelPoints,
      needsScriptTrack: true,
      transliteration: 'romanization',
      inputMethods: [InputMethod.keyboard],
    );

    test('gameAvailability returns 8 specs for AR profile', () {
      final specs = gameAvailability(arProfile);
      expect(specs, hasLength(8));
    });

    test('positionalForm at rung 3 and rung 4 (positionalForms=true)', () {
      final specs = gameAvailability(arProfile);
      expect(specs.any((s) => s.type == GameType.positionalForm && s.rung == 3), isTrue);
      expect(specs.any((s) => s.type == GameType.positionalForm && s.rung == 4), isTrue);
    });

    test('toneVowelMatch at rung 0 (vowelPoints → hasToneSystem)', () {
      final specs = gameAvailability(arProfile);
      expect(specs.any((s) => s.type == GameType.toneVowelMatch && s.rung == 0), isTrue);
    });
  });

  group('AR can-do goal', () {
    test('cando_ar_a1_abjad exists', () async {
      final goals = await db.select(db.canDoGoals).get();
      expect(goals.any((g) => g.id == 'cando_ar_a1_abjad'), isTrue);
    });

    test('goal is at cefrBand A1 for lang_ar', () async {
      final goal = (await db.select(db.canDoGoals).get())
          .firstWhere((g) => g.id == 'cando_ar_a1_abjad');
      expect(goal.cefrBand, 'A1');
      expect(goal.languageId, 'lang_ar');
    });
  });

  group('AR idempotency', () {
    test('seeding twice does not duplicate data', () async {
      await seedArPack(db);
      final lexemes = await (db.select(db.lexemes)
            ..where((t) => t.languageId.equals('lang_ar')))
          .get();
      expect(lexemes, hasLength(5));
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_ar')))
          .get();
      expect(chars, hasLength(5));
    });
  });
}
