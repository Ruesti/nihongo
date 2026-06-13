import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/assets/asset_resolver.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

void main() {
  late LearningDb db;
  late AssetResolver resolver;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedJaPack(db);
    resolver = AssetResolver(db);

    // Insert a test asset for concept_dog
    await db.into(db.assets).insertOnConflictUpdate(
          const AssetsCompanion(
            id: Value('asset_concept_dog'),
            conceptId: Value('concept_dog'),
            type: Value('image'),
            path: Value('assets/concept_dog.webp'),
          ),
        );
  });

  tearDown(() => db.close());

  Future<Lexeme> getLexeme(String id) async {
    return (await (db.select(db.lexemes)
                  ..where((t) => t.id.equals(id)))
                .get())
            .first;
  }

  group('I1 — production rungs (3-5) always return null', () {
    test('rung 3 → null regardless of asset presence', () async {
      final lexeme = await getLexeme('lex_ja_dog');
      expect(await resolver.resolve(lexeme, 3), isNull);
    });

    test('rung 4 → null', () async {
      final lexeme = await getLexeme('lex_ja_dog');
      expect(await resolver.resolve(lexeme, 4), isNull);
    });

    test('rung 5 → null', () async {
      final lexeme = await getLexeme('lex_ja_dog');
      expect(await resolver.resolve(lexeme, 5), isNull);
    });
  });

  group('I4 — asset resolved by conceptId (not lexeme/language)', () {
    test('rung 1 with asset → returns Asset', () async {
      final lexeme = await getLexeme('lex_ja_dog');
      final asset = await resolver.resolve(lexeme, 1);
      expect(asset, isNotNull);
      expect(asset!.conceptId, 'concept_dog');
      expect(asset.type, 'image');
      expect(asset.path, 'assets/concept_dog.webp');
    });

    test('rung 2 with asset → returns Asset', () async {
      final lexeme = await getLexeme('lex_ja_dog');
      final asset = await resolver.resolve(lexeme, 2);
      expect(asset, isNotNull);
    });

    test('asset for concept_dog is found via any lexeme sharing that concept', () async {
      // ES lexeme for same concept — same asset should resolve (I4: one pool)
      // We add a minimal ES lexeme for concept_dog to test cross-language sharing
      await db.into(db.scriptProfiles).insertOnConflictUpdate(
            const ScriptProfilesCompanion(
              id: Value('sp_es'),
              scriptType: Value('alphabet'),
              direction: Value('ltr'),
              decomposability: Value('atomic'),
              positionalForms: Value(false),
              toneSystem: Value('none'),
              needsScriptTrack: Value(false),
              transliteration: Value('none'),
              inputMethodsJson: Value('["keyboard"]'),
            ),
          );
      await db.into(db.languages).insertOnConflictUpdate(
            const LanguagesCompanion(
              id: Value('lang_es'),
              name: Value('Español'),
              scriptProfileId: Value('sp_es'),
              ttsVoice: Value('es-ES'),
            ),
          );
      await db.into(db.lexemes).insertOnConflictUpdate(
            const LexemesCompanion(
              id: Value('lex_es_dog'),
              languageId: Value('lang_es'),
              conceptId: Value('concept_dog'),
              writtenForm: Value('perro'),
              reading: Value('perro'),
            ),
          );

      final esLexeme = (await (db.select(db.lexemes)
                    ..where((t) => t.id.equals('lex_es_dog')))
                  .get())
              .first;
      final asset = await resolver.resolve(esLexeme, 1);
      expect(asset, isNotNull);
      expect(asset!.conceptId, 'concept_dog'); // same asset, different language
    });
  });

  group('graceful fallback — no crash on missing/none assets', () {
    test('rung 1 no asset in DB → null', () async {
      final lexeme = await getLexeme('lex_ja_cat'); // concept_cat has no asset
      final asset = await resolver.resolve(lexeme, 1);
      expect(asset, isNull);
    });

    test('rung 1 with type=none asset → null', () async {
      await db.into(db.assets).insertOnConflictUpdate(
            const AssetsCompanion(
              id: Value('asset_concept_what'),
              conceptId: Value('concept_what'),
              type: Value('none'),
              path: Value(''),
            ),
          );
      final lexeme = await getLexeme('lex_ja_what');
      final asset = await resolver.resolve(lexeme, 1);
      expect(asset, isNull);
    });
  });
}
