import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/db/learning_db.dart';

Future<void> seedZhPack(LearningDb db) async {
  await db.transaction(() async {
    await db.into(db.scriptProfiles).insertOnConflictUpdate(
          ScriptProfilesCompanion(
            id: const Value('sp_zh'),
            scriptType: const Value('logographic'),
            direction: const Value('ltr'),
            decomposability: const Value('radicals'),
            positionalForms: const Value(false),
            toneSystem: const Value('tonal'),
            needsScriptTrack: const Value(true),
            transliteration: const Value('pinyin'),
            inputMethodsJson: Value(jsonEncode(['ime', 'keyboard'])),
          ),
        );

    await db.into(db.languages).insertOnConflictUpdate(
          const LanguagesCompanion(
            id: Value('lang_zh'),
            name: Value('中文'),
            scriptProfileId: Value('sp_zh'),
            ttsVoice: Value('zh-CN'),
            enabled: Value(true),
          ),
        );

    // Concepts — shared pool (I4). concept_water and concept_eat already exist
    // in JA/ES/KO packs; insertOnConflictUpdate is idempotent.
    final conceptRows = <(String, String, String, String)>[
      ('concept_water', 'water', 'noun', 'image'),
      ('concept_eat', 'eat', 'verb', 'clip'),
      ('concept_person', 'person', 'noun', 'none'),
      ('concept_big', 'big', 'adjective', 'none'),
      ('concept_small', 'small', 'adjective', 'none'),
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

    // Lexemes — writtenForm = hanzi, reading = tone-marked pinyin
    final lexemeRows = <(String, String, String, String)>[
      ('lex_zh_water', 'concept_water', '水', 'shuǐ'),
      ('lex_zh_eat', 'concept_eat', '吃', 'chī'),
      ('lex_zh_person', 'concept_person', '人', 'rén'),
      ('lex_zh_big', 'concept_big', '大', 'dà'),
      ('lex_zh_small', 'concept_small', '小', 'xiǎo'),
    ];
    for (final (id, conceptId, form, reading) in lexemeRows) {
      await db.into(db.lexemes).insertOnConflictUpdate(
            LexemesCompanion(
              id: Value(id),
              languageId: const Value('lang_zh'),
              conceptId: Value(conceptId),
              writtenForm: Value(form),
              reading: Value(reading),
              cefrBand: const Value('A1'),
            ),
          );
    }

    // Characters — key hanzi, two with radical decomposition shown
    // 明 (bright) = 日 (sun, left) + 月 (moon, right) — classic composition example
    // 好 (good)   = 女 (woman, left) + 子 (child, right)
    final charRows = <(String, String, List<String>, String, List<(String, String)>)>[
      ('char_zh_ri', '日', ['rì'], 'sun / day', []),
      ('char_zh_yue', '月', ['yuè'], 'moon / month', []),
      ('char_zh_ming', '明', ['míng'], 'bright / clear',
          [('日', 'left'), ('月', 'right')]),
      ('char_zh_nv', '女', ['nǚ'], 'woman', []),
      ('char_zh_hao', '好', ['hǎo'], 'good / bright',
          [('女', 'left'), ('子', 'right')]),
    ];
    for (final (charId, glyph, readings, meaning, components) in charRows) {
      await db.into(db.characters).insertOnConflictUpdate(
            CharactersCompanion(
              id: Value(charId),
              languageId: const Value('lang_zh'),
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
            id: Value('cando_zh_a1_hanzi'),
            languageId: Value('lang_zh'),
            cefrBand: Value('A1'),
            description: Value('I can read basic Chinese characters and their pinyin'),
          ),
        );
  });
}
