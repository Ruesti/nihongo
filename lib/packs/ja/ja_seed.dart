import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/db/learning_db.dart';
import '../../data/kana_strokes.dart';

Future<void> seedJaPack(LearningDb db) async {
  await db.transaction(() async {
    await db.into(db.scriptProfiles).insertOnConflictUpdate(
          ScriptProfilesCompanion(
            id: const Value('sp_ja_kana'),
            scriptType: const Value('syllabary'),
            direction: const Value('ltr'),
            decomposability: const Value('atomic'),
            positionalForms: const Value(false),
            toneSystem: const Value('pitchAccent'),
            needsScriptTrack: const Value(true),
            transliteration: const Value('romaji'),
            inputMethodsJson: Value(jsonEncode(['keyboard', 'ime'])),
          ),
        );

    await db.into(db.languages).insertOnConflictUpdate(
          LanguagesCompanion(
            id: const Value('lang_ja'),
            name: const Value('Japanese'),
            scriptProfileId: const Value('sp_ja_kana'),
            ttsVoice: const Value('ja-JP'),
            enabled: const Value(true),
          ),
        );

    final conceptRows = <(String, String, String, String)>[
      ('concept_dog', 'dog', 'noun', 'image'),
      ('concept_cat', 'cat', 'noun', 'image'),
      ('concept_water', 'water', 'noun', 'image'),
      ('concept_eat', 'eat', 'verb', 'clip'),
      ('concept_what', 'what', 'pronoun', 'none'),
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
      ('lex_ja_dog', 'concept_dog', '犬', 'いぬ'),
      ('lex_ja_cat', 'concept_cat', '猫', 'ねこ'),
      ('lex_ja_water', 'concept_water', '水', 'みず'),
      ('lex_ja_eat', 'concept_eat', '食べる', 'たべる'),
      ('lex_ja_what', 'concept_what', '何', 'なに'),
    ];
    for (final (id, conceptId, form, reading) in lexemeRows) {
      await db.into(db.lexemes).insertOnConflictUpdate(
            LexemesCompanion(
              id: Value(id),
              languageId: const Value('lang_ja'),
              conceptId: Value(conceptId),
              writtenForm: Value(form),
              reading: Value(reading),
              cefrBand: const Value('A1'),
            ),
          );
    }

    final charRows = <(String, String, List<String>, String)>[
      ('char_ja_a', 'あ', ['a'], 'vowel a'),
      ('char_ja_i', 'い', ['i'], 'vowel i'),
      ('char_ja_u', 'う', ['u'], 'vowel u'),
      ('char_ja_e', 'え', ['e'], 'vowel e'),
      ('char_ja_o', 'お', ['o'], 'vowel o'),
      ('char_ja_ka', 'か', ['ka'], 'ka'),
      ('char_ja_ki', 'き', ['ki'], 'ki'),
    ];
    for (final (id, glyph, readings, meaning) in charRows) {
      await db.into(db.characters).insertOnConflictUpdate(
            CharactersCompanion(
              id: Value(id),
              languageId: const Value('lang_ja'),
              glyph: Value(glyph),
              readingsJson: Value(jsonEncode(readings)),
              meaning: Value(meaning),
              strokeOrderAssetId: Value(strokeAssetForKana(glyph)),
            ),
          );
    }

    await db.into(db.canDoGoals).insertOnConflictUpdate(
          CanDoGoalsCompanion(
            id: const Value('cando_ja_a1_kana'),
            languageId: const Value('lang_ja'),
            cefrBand: const Value('A1'),
            description:
                const Value('I can read and write hiragana vowels'),
          ),
        );
  });
}
