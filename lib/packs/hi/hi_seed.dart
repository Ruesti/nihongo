import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/db/learning_db.dart';

Future<void> seedHiPack(LearningDb db) async {
  await db.transaction(() async {
    await db.into(db.scriptProfiles).insertOnConflictUpdate(
          ScriptProfilesCompanion(
            id: const Value('sp_hi'),
            scriptType: const Value('abugida'),
            direction: const Value('ltr'),
            decomposability: const Value('baseDiacritics'),
            positionalForms: const Value(false),
            toneSystem: const Value('none'),
            needsScriptTrack: const Value(true),
            transliteration: const Value('romanization'),
            inputMethodsJson: Value(jsonEncode(['keyboard'])),
          ),
        );

    await db.into(db.languages).insertOnConflictUpdate(
          const LanguagesCompanion(
            id: Value('lang_hi'),
            name: Value('हिन्दी'),
            scriptProfileId: Value('sp_hi'),
            ttsVoice: Value('hi-IN'),
            enabled: Value(true),
          ),
        );

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

    final lexemeRows = <(String, String, String, String)>[
      ('lex_hi_dog', 'concept_dog', 'कुत्ता', 'kutta'),
      ('lex_hi_cat', 'concept_cat', 'बिल्ली', 'billi'),
      ('lex_hi_water', 'concept_water', 'पानी', 'paani'),
      ('lex_hi_eat', 'concept_eat', 'खाना', 'khaana'),
      ('lex_hi_house', 'concept_house', 'घर', 'ghar'),
    ];
    for (final (id, conceptId, form, reading) in lexemeRows) {
      await db.into(db.lexemes).insertOnConflictUpdate(
            LexemesCompanion(
              id: Value(id),
              languageId: const Value('lang_hi'),
              conceptId: Value(conceptId),
              writtenForm: Value(form),
              reading: Value(reading),
              cefrBand: const Value('A1'),
            ),
          );
    }

    // baseDiacritics: base consonant + vowel matra
    // का (kaa) = क (base) + ा (aa-matra, right)
    // कि (ki)  = क (base) + ि (i-matra, above_left)
    // ग, म, प carry inherent 'a' — no explicit matra, no components
    final charRows =
        <(String, String, List<String>, String, List<(String, String)>)>[
      ('char_hi_kaa', 'का', ['kaa'], 'ka + long a vowel',
          [('क', 'base'), ('ा', 'right')]),
      ('char_hi_ki', 'कि', ['ki'], 'ka + short i vowel',
          [('क', 'base'), ('ि', 'above_left')]),
      ('char_hi_ga', 'ग', ['ga'], 'letter ga (inherent a)', []),
      ('char_hi_ma', 'म', ['ma'], 'letter ma (inherent a)', []),
      ('char_hi_pa', 'प', ['pa'], 'letter pa (inherent a)', []),
    ];
    for (final (charId, glyph, readings, meaning, components) in charRows) {
      await db.into(db.characters).insertOnConflictUpdate(
            CharactersCompanion(
              id: Value(charId),
              languageId: const Value('lang_hi'),
              glyph: Value(glyph),
              readingsJson: Value(jsonEncode(readings)),
              meaning: Value(meaning),
            ),
          );
      for (final (compGlyph, position) in components) {
        await db.into(db.charComponents).insertOnConflictUpdate(
              CharComponentsCompanion(
                id: Value('${charId}_$position'),
                characterId: Value(charId),
                componentGlyph: Value(compGlyph),
                position: Value(position),
              ),
            );
      }
    }

    await db.into(db.canDoGoals).insertOnConflictUpdate(
          const CanDoGoalsCompanion(
            id: Value('cando_hi_a1_devanagari'),
            languageId: Value('lang_hi'),
            cefrBand: Value('A1'),
            description: Value(
                'I can recognize basic Devanagari letters and read simple Hindi words'),
          ),
        );
  });
}
