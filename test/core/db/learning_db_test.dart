import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

void main() {
  late LearningDb db;

  setUp(() {
    db = LearningDb.forTesting();
  });

  tearDown(() async => db.close());

  test('fresh DB has no languages', () async {
    final rows = await db.select(db.languages).get();
    expect(rows, isEmpty);
  });

  test('fresh DB has no concepts', () async {
    final rows = await db.select(db.concepts).get();
    expect(rows, isEmpty);
  });

  test('fresh DB has no learn_items', () async {
    final rows = await db.select(db.learnItems).get();
    expect(rows, isEmpty);
  });

  group('JA seed pack', () {
    test('creates exactly one language', () async {
      await seedJaPack(db);
      final rows = await db.select(db.languages).get();
      expect(rows.length, 1);
      expect(rows.first.name, 'Japanese');
    });

    test('script profile is syllabary with needsScriptTrack', () async {
      await seedJaPack(db);
      final rows = await db.select(db.scriptProfiles).get();
      expect(rows.length, 1);
      expect(rows.first.scriptType, 'syllabary');
      expect(rows.first.needsScriptTrack, isTrue);
      expect(rows.first.transliteration, 'romaji');
    });

    test('creates 13 concepts (5 demo + 8 Folge 01)', () async {
      await seedJaPack(db);
      final rows = await db.select(db.concepts).get();
      expect(rows.length, 13);
    });

    test('creates 13 lexemes (5 demo + 8 Folge 01)', () async {
      await seedJaPack(db);
      final rows = await db.select(db.lexemes).get();
      expect(rows.length, 13);
      final forms = rows.map((l) => l.writtenForm).toSet();
      expect(forms, containsAll({'犬', '猫', '水', '食べる', '何'}));
      expect(forms, containsAll(
          {'すみません', 'あめ', 'かさ', 'これ', 'こわれた', 'はい', 'どうぞ', 'ありがとう'}));
    });

    test('creates 5 hiragana vowel characters', () async {
      await seedJaPack(db);
      final rows = await db.select(db.characters).get();
      expect(rows.length, 5);
      final glyphs = rows.map((c) => c.glyph).toSet();
      expect(glyphs, containsAll({'あ', 'い', 'う', 'え', 'お'}));
    });

    test('seeding twice is idempotent', () async {
      await seedJaPack(db);
      await seedJaPack(db);
      final langs = await db.select(db.languages).get();
      expect(langs.length, 1);
      final concepts = await db.select(db.concepts).get();
      expect(concepts.length, 13);
    });
  });
}
