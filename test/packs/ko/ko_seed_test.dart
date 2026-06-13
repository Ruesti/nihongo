import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/packs/ko/ko_seed.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedKoPack(db);
  });

  tearDown(() => db.close());

  group('KO seed — script profile', () {
    test('creates hangul profile with jamo decomposability', () async {
      final profiles = await db.select(db.scriptProfiles).get();
      final ko = profiles.firstWhere((p) => p.id == 'sp_ko');
      expect(ko.scriptType, 'hangul');
      expect(ko.decomposability, 'jamo');
      expect(ko.direction, 'ltr');
      expect(ko.needsScriptTrack, isTrue);
      expect(ko.toneSystem, 'none');
      expect(ko.positionalForms, isFalse);
    });
  });

  group('KO seed — language', () {
    test('creates exactly one language', () async {
      final langs = await db.select(db.languages).get();
      expect(langs, hasLength(1));
      expect(langs.first.id, 'lang_ko');
      expect(langs.first.scriptProfileId, 'sp_ko');
    });
  });

  group('KO seed — concepts', () {
    test('creates 5 concepts', () async {
      final concepts = await db.select(db.concepts).get();
      expect(concepts, hasLength(5));
    });

    test('includes dog, cat, water, eat, house glossKeys', () async {
      final concepts = await db.select(db.concepts).get();
      final keys = concepts.map((c) => c.glossKey).toSet();
      expect(keys, containsAll(['dog', 'cat', 'water', 'eat', 'house']));
    });
  });

  group('KO seed — lexemes', () {
    test('creates 5 Korean lexemes', () async {
      final lexemes = await db.select(db.lexemes).get();
      expect(lexemes, hasLength(5));
      expect(lexemes.every((l) => l.languageId == 'lang_ko'), isTrue);
    });

    test('개 (dog) has correct reading', () async {
      final lexemes = await db.select(db.lexemes).get();
      final dog = lexemes.firstWhere((l) => l.id == 'lex_ko_dog');
      expect(dog.writtenForm, '개');
      expect(dog.reading, '개');
    });
  });

  group('KO seed — characters (hangul syllable blocks)', () {
    test('creates 5 hangul characters', () async {
      final chars = await db.select(db.characters).get();
      expect(chars, hasLength(5));
      expect(chars.every((c) => c.languageId == 'lang_ko'), isTrue);
    });

    test('each character has jamo components', () async {
      final components = await db.select(db.charComponents).get();
      expect(components.isNotEmpty, isTrue);
    });

    test('가 (ga) has initial ㄱ and vowel ㅏ', () async {
      final chars = await db.select(db.characters).get();
      final ga = chars.firstWhere((c) => c.id == 'char_ko_ga');
      expect(ga.glyph, '가');

      final components = await (db.select(db.charComponents)
            ..where((t) => t.characterId.equals('char_ko_ga')))
          .get();
      expect(components, hasLength(2));
      final glyphs = components.map((c) => c.componentGlyph).toSet();
      expect(glyphs, containsAll(['ㄱ', 'ㅏ']));
    });
  });

  group('KO seed — idempotency', () {
    test('seeding twice does not duplicate data', () async {
      await seedKoPack(db);
      final langs = await db.select(db.languages).get();
      final chars = await db.select(db.characters).get();
      expect(langs, hasLength(1));
      expect(chars, hasLength(5));
    });
  });
}
