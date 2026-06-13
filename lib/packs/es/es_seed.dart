import 'package:drift/drift.dart';

import '../../core/db/learning_db.dart';

Future<void> seedEsPack(LearningDb db) async {
  await db.transaction(() async {
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
            enabled: Value(true),
          ),
        );

    // Concepts shared across packs via concept ID (I4: asset belongs to concept)
    final conceptRows = <(String, String, String, String)>[
      ('concept_dog', 'dog', 'noun', 'image'),
      ('concept_cat', 'cat', 'noun', 'image'),
      ('concept_water', 'water', 'noun', 'image'),
      ('concept_eat', 'eat', 'verb', 'clip'),
      ('concept_house', 'house', 'noun', 'image'),
    ];
    for (final (id, gloss, pos, assetType) in conceptRows) {
      await db.into(db.concepts).insertOnConflictUpdate(
            ConceptsCompanion(
              id: Value(id),
              glossKey: Value(gloss),
              partOfSpeech: Value(pos),
              defaultAssetType: Value(assetType),
            ),
          );
    }

    // Lexemes — reading = writtenForm for Latin alphabet (no separate transliteration)
    final lexemeRows = <(String, String, String)>[
      ('lex_es_dog', 'concept_dog', 'perro'),
      ('lex_es_cat', 'concept_cat', 'gato'),
      ('lex_es_water', 'concept_water', 'agua'),
      ('lex_es_eat', 'concept_eat', 'comer'),
      ('lex_es_house', 'concept_house', 'casa'),
    ];
    for (final (id, conceptId, form) in lexemeRows) {
      await db.into(db.lexemes).insertOnConflictUpdate(
            LexemesCompanion(
              id: Value(id),
              languageId: const Value('lang_es'),
              conceptId: Value(conceptId),
              writtenForm: Value(form),
              reading: Value(form), // alphabet: reading == writtenForm
              cefrBand: const Value('A1'),
            ),
          );
    }
    // No characters: needsScriptTrack = false for Latin alphabet
  });
}
