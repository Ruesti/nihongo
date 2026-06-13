import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/packs/es/es_seed.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedEsPack(db);
  });

  tearDown(() => db.close());

  group('ES seed — script profile', () {
    test('creates alphabet profile with atomic decomposability', () async {
      final profiles = await db.select(db.scriptProfiles).get();
      final es = profiles.firstWhere((p) => p.id == 'sp_es');
      expect(es.scriptType, 'alphabet');
      expect(es.decomposability, 'atomic');
      expect(es.direction, 'ltr');
      expect(es.needsScriptTrack, isFalse);
      expect(es.toneSystem, 'none');
      expect(es.positionalForms, isFalse);
    });
  });

  group('ES seed — language', () {
    test('creates exactly one language', () async {
      final langs = await db.select(db.languages).get();
      expect(langs, hasLength(1));
      expect(langs.first.id, 'lang_es');
      expect(langs.first.scriptProfileId, 'sp_es');
    });
  });

  group('ES seed — concepts (shared pool)', () {
    test('creates 5 concepts with correct glossKeys', () async {
      final concepts = await db.select(db.concepts).get();
      final keys = concepts.map((c) => c.glossKey).toSet();
      expect(keys, containsAll(['dog', 'cat', 'water', 'eat', 'house']));
    });
  });

  group('ES seed — lexemes', () {
    test('creates exactly 5 Spanish lexemes', () async {
      final lexemes = await db.select(db.lexemes).get();
      expect(lexemes, hasLength(5));
      expect(lexemes.every((l) => l.languageId == 'lang_es'), isTrue);
    });

    test('perro is the written form for dog', () async {
      final lexemes = await db.select(db.lexemes).get();
      final dog = lexemes.firstWhere((l) => l.id == 'lex_es_dog');
      expect(dog.writtenForm, 'perro');
      expect(dog.reading, 'perro');
    });

    test('no characters (needsScriptTrack = false for Latin alphabet)', () async {
      final chars = await db.select(db.characters).get();
      expect(chars, isEmpty);
    });
  });

  group('ES seed — idempotency', () {
    test('seeding twice does not duplicate data', () async {
      await seedEsPack(db);
      final langs = await db.select(db.languages).get();
      final lexemes = await db.select(db.lexemes).get();
      expect(langs, hasLength(1));
      expect(lexemes, hasLength(5));
    });
  });
}
