import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/packs/zh/zh_seed.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedZhPack(db);
  });

  tearDown(() => db.close());

  // ── ScriptProfile ─────────────────────────────────────────────────────────

  group('ZH ScriptProfile', () {
    test('sp_zh exists', () async {
      final profiles = await db.select(db.scriptProfiles).get();
      expect(profiles.any((p) => p.id == 'sp_zh'), isTrue);
    });

    test('scriptType = logographic', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_zh');
      expect(p.scriptType, 'logographic');
    });

    test('decomposability = radicals', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_zh');
      expect(p.decomposability, 'radicals');
    });

    test('toneSystem = tonal', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_zh');
      expect(p.toneSystem, 'tonal');
    });

    test('needsScriptTrack = true', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_zh');
      expect(p.needsScriptTrack, isTrue);
    });

    test('transliteration = pinyin', () async {
      final p = (await db.select(db.scriptProfiles).get())
          .firstWhere((p) => p.id == 'sp_zh');
      expect(p.transliteration, 'pinyin');
    });
  });

  // ── Language ──────────────────────────────────────────────────────────────

  group('ZH language', () {
    test('lang_zh exists', () async {
      final langs = await db.select(db.languages).get();
      expect(langs.any((l) => l.id == 'lang_zh'), isTrue);
    });

    test('name = 中文', () async {
      final lang = (await db.select(db.languages).get())
          .firstWhere((l) => l.id == 'lang_zh');
      expect(lang.name, '中文');
    });

    test('ttsVoice = zh-CN', () async {
      final lang = (await db.select(db.languages).get())
          .firstWhere((l) => l.id == 'lang_zh');
      expect(lang.ttsVoice, 'zh-CN');
    });
  });

  // ── Lexemes ───────────────────────────────────────────────────────────────

  group('ZH lexemes', () {
    test('5 lexemes for lang_zh', () async {
      final lexemes = await (db.select(db.lexemes)
            ..where((t) => t.languageId.equals('lang_zh')))
          .get();
      expect(lexemes, hasLength(5));
    });

    test('all lexemes at cefrBand A1', () async {
      final lexemes = await (db.select(db.lexemes)
            ..where((t) => t.languageId.equals('lang_zh')))
          .get();
      expect(lexemes.every((l) => l.cefrBand == 'A1'), isTrue);
    });

    test('水 (water) — written form and pinyin reading', () async {
      final lex = (await db.select(db.lexemes).get())
          .firstWhere((l) => l.id == 'lex_zh_water');
      expect(lex.writtenForm, '水');
      expect(lex.reading, 'shuǐ');
    });

    test('吃 (eat) — tone-marked pinyin reading', () async {
      final lex = (await db.select(db.lexemes).get())
          .firstWhere((l) => l.id == 'lex_zh_eat');
      expect(lex.writtenForm, '吃');
      expect(lex.reading, 'chī');
    });

    test('人 (person) shares concept_person', () async {
      final lex = (await db.select(db.lexemes).get())
          .firstWhere((l) => l.id == 'lex_zh_person');
      expect(lex.conceptId, 'concept_person');
    });

    test('concept_person exists in concepts table', () async {
      final concepts = await db.select(db.concepts).get();
      expect(concepts.any((c) => c.id == 'concept_person'), isTrue);
    });

    test('concept_water and concept_eat shared with other packs (I4)', () async {
      final concepts = await db.select(db.concepts).get();
      expect(concepts.any((c) => c.id == 'concept_water'), isTrue);
      expect(concepts.any((c) => c.id == 'concept_eat'), isTrue);
    });
  });

  // ── Characters ────────────────────────────────────────────────────────────

  group('ZH characters (hanzi)', () {
    test('5 characters for lang_zh', () async {
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_zh')))
          .get();
      expect(chars, hasLength(5));
    });

    test('明 (bright) exists with pinyin reading', () async {
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_zh')))
          .get();
      final ming = chars.firstWhere((c) => c.glyph == '明');
      expect(ming.meaning, contains('bright'));
    });

    test('明 decomposes into 2 radical components (日 + 月)', () async {
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_zh')))
          .get();
      final ming = chars.firstWhere((c) => c.glyph == '明');
      final components = await (db.select(db.charComponents)
            ..where((t) => t.characterId.equals(ming.id)))
          .get();
      expect(components, hasLength(2));
      final glyphs = components.map((c) => c.componentGlyph).toSet();
      expect(glyphs.contains('日'), isTrue);
      expect(glyphs.contains('月'), isTrue);
    });

    test('日 component has position left', () async {
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_zh')))
          .get();
      final ming = chars.firstWhere((c) => c.glyph == '明');
      final components = await (db.select(db.charComponents)
            ..where((t) => t.characterId.equals(ming.id)))
          .get();
      final ri = components.firstWhere((c) => c.componentGlyph == '日');
      expect(ri.position, 'left');
    });

    test('好 decomposes into 女 + 子', () async {
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_zh')))
          .get();
      final hao = chars.firstWhere((c) => c.glyph == '好');
      final components = await (db.select(db.charComponents)
            ..where((t) => t.characterId.equals(hao.id)))
          .get();
      expect(components, hasLength(2));
      final glyphs = components.map((c) => c.componentGlyph).toSet();
      expect(glyphs.contains('女'), isTrue);
      expect(glyphs.contains('子'), isTrue);
    });
  });

  // ── Can-Do Goal ───────────────────────────────────────────────────────────

  group('ZH can-do goal', () {
    test('cando_zh_a1_hanzi exists', () async {
      final goals = await db.select(db.canDoGoals).get();
      expect(goals.any((g) => g.id == 'cando_zh_a1_hanzi'), isTrue);
    });

    test('goal is at cefrBand A1', () async {
      final goal = (await db.select(db.canDoGoals).get())
          .firstWhere((g) => g.id == 'cando_zh_a1_hanzi');
      expect(goal.cefrBand, 'A1');
      expect(goal.languageId, 'lang_zh');
    });
  });

  // ── Idempotency ───────────────────────────────────────────────────────────

  group('ZH idempotency', () {
    test('seeding twice does not duplicate data', () async {
      await seedZhPack(db);
      final lexemes = await (db.select(db.lexemes)
            ..where((t) => t.languageId.equals('lang_zh')))
          .get();
      expect(lexemes, hasLength(5));
      final chars = await (db.select(db.characters)
            ..where((t) => t.languageId.equals('lang_zh')))
          .get();
      expect(chars, hasLength(5));
    });
  });
}
