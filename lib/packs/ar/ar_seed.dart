import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/db/learning_db.dart';

Future<void> seedArPack(LearningDb db) async {
  await db.transaction(() async {
    await db.into(db.scriptProfiles).insertOnConflictUpdate(
          ScriptProfilesCompanion(
            id: const Value('sp_ar'),
            scriptType: const Value('abjad'),
            direction: const Value('rtl'),
            decomposability: const Value('consonantMatra'),
            positionalForms: const Value(true),
            toneSystem: const Value('vowelPoints'),
            needsScriptTrack: const Value(true),
            transliteration: const Value('romanization'),
            inputMethodsJson: Value(jsonEncode(['keyboard'])),
          ),
        );

    await db.into(db.languages).insertOnConflictUpdate(
          const LanguagesCompanion(
            id: Value('lang_ar'),
            name: Value('العربية'),
            scriptProfileId: Value('sp_ar'),
            ttsVoice: Value('ar-SA'),
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
      ('lex_ar_dog', 'concept_dog', 'كلب', 'kalb'),
      ('lex_ar_cat', 'concept_cat', 'قطة', 'qitta'),
      ('lex_ar_water', 'concept_water', 'ماء', 'maa'),
      ('lex_ar_eat', 'concept_eat', 'أكل', 'akala'),
      ('lex_ar_house', 'concept_house', 'بيت', 'bayt'),
    ];
    for (final (id, conceptId, form, reading) in lexemeRows) {
      await db.into(db.lexemes).insertOnConflictUpdate(
            LexemesCompanion(
              id: Value(id),
              languageId: const Value('lang_ar'),
              conceptId: Value(conceptId),
              writtenForm: Value(form),
              reading: Value(reading),
              cefrBand: const Value('A1'),
            ),
          );
    }

    // consonantMatra: base consonant + vowel diacritic
    // ب (ba) + fatha (َ, above) ; ت (ta) + kasra (ِ, below)
    final charRows =
        <(String, String, List<String>, String, List<(String, String)>)>[
      ('char_ar_ba', 'ب', ['b'], 'letter ba',
          [('ب', 'base'), ('َ', 'above')]),
      ('char_ar_ta', 'ت', ['t'], 'letter ta',
          [('ت', 'base'), ('ِ', 'below')]),
      ('char_ar_nun', 'ن', ['n'], 'letter nun', []),
      ('char_ar_mim', 'م', ['m'], 'letter mim', []),
      ('char_ar_alif', 'ا', ['a', 'aa'], 'letter alif', []),
    ];
    for (final (charId, glyph, readings, meaning, components) in charRows) {
      await db.into(db.characters).insertOnConflictUpdate(
            CharactersCompanion(
              id: Value(charId),
              languageId: const Value('lang_ar'),
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
            id: Value('cando_ar_a1_abjad'),
            languageId: Value('lang_ar'),
            cefrBand: Value('A1'),
            description:
                Value('I can recognize basic Arabic letters and read simple words'),
          ),
        );
  });
}
