import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/db/learning_db.dart';

Future<void> seedKoPack(LearningDb db) async {
  await db.transaction(() async {
    await db.into(db.scriptProfiles).insertOnConflictUpdate(
          const ScriptProfilesCompanion(
            id: Value('sp_ko'),
            scriptType: Value('hangul'),
            direction: Value('ltr'),
            decomposability: Value('jamo'),
            positionalForms: Value(false),
            toneSystem: Value('none'),
            needsScriptTrack: Value(true),
            transliteration: Value('romanization'),
            inputMethodsJson: Value('["keyboard"]'),
          ),
        );

    await db.into(db.languages).insertOnConflictUpdate(
          const LanguagesCompanion(
            id: Value('lang_ko'),
            name: Value('한국어'),
            scriptProfileId: Value('sp_ko'),
            ttsVoice: Value('ko-KR'),
            enabled: Value(true),
          ),
        );

    // Concepts (same IDs shared with ES/JA where applicable — I4)
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

    // Korean lexemes (writtenForm = hangul, reading = hangul pronunciation)
    final lexemeRows = <(String, String, String, String)>[
      ('lex_ko_dog', 'concept_dog', '개', '개'),
      ('lex_ko_cat', 'concept_cat', '고양이', '고양이'),
      ('lex_ko_water', 'concept_water', '물', '물'),
      ('lex_ko_eat', 'concept_eat', '먹다', '먹다'),
      ('lex_ko_house', 'concept_house', '집', '집'),
    ];
    for (final (id, conceptId, form, reading) in lexemeRows) {
      await db.into(db.lexemes).insertOnConflictUpdate(
            LexemesCompanion(
              id: Value(id),
              languageId: const Value('lang_ko'),
              conceptId: Value(conceptId),
              writtenForm: Value(form),
              reading: Value(reading),
              cefrBand: const Value('A1'),
            ),
          );
    }

    // Hangul syllable block characters (needsScriptTrack = true)
    // Each block decomposes into initial consonant (초성) + vowel (중성)
    final charRows = <(String, String, List<String>, String, List<(String, String)>)>[
      ('char_ko_ga', '가', ['ga'], 'syllable ga', [('ㄱ', 'initial'), ('ㅏ', 'vowel')]),
      ('char_ko_na', '나', ['na'], 'syllable na', [('ㄴ', 'initial'), ('ㅏ', 'vowel')]),
      ('char_ko_da', '다', ['da'], 'syllable da', [('ㄷ', 'initial'), ('ㅏ', 'vowel')]),
      ('char_ko_ma', '마', ['ma'], 'syllable ma', [('ㅁ', 'initial'), ('ㅏ', 'vowel')]),
      ('char_ko_ba', '바', ['ba'], 'syllable ba', [('ㅂ', 'initial'), ('ㅏ', 'vowel')]),
    ];
    for (final (charId, glyph, readings, meaning, components) in charRows) {
      await db.into(db.characters).insertOnConflictUpdate(
            CharactersCompanion(
              id: Value(charId),
              languageId: const Value('lang_ko'),
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
            id: Value('cando_ko_a1_hangul'),
            languageId: Value('lang_ko'),
            cefrBand: Value('A1'),
            description: Value('I can read and write basic hangul syllable blocks'),
          ),
        );
  });
}
