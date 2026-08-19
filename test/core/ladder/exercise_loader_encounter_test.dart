import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/encounter.dart';
import 'package:nihongo_app/core/ladder/exercise_content.dart';
import 'package:nihongo_app/core/ladder/exercise_loader.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/script_profile.dart';

const _profile = ScriptProfile(
  id: 'sp',
  scriptType: ScriptType.syllabary,
  direction: Direction.ltr,
  decomposability: Decomposability.atomic,
  positionalForms: false,
  toneSystem: ToneSystem.none,
  needsScriptTrack: true,
  transliteration: 'romaji',
  inputMethods: [InputMethod.keyboard],
);

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'ja-JP'));
    await db.into(db.characters).insert(CharactersCompanion.insert(
          id: 'char_a',
          languageId: 'lang_ja',
          glyph: 'あ',
          readingsJson: jsonEncode(['a']),
          meaning: 'a',
          strokeOrderAssetId: const Value('assets/kanji_svg/3042.svg'),
        ));
  });

  tearDown(() async => db.close());

  test('rung-0 character item loads a CharacterEncounter', () async {
    await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_a', rung: 0);
    final item = (await db.select(db.learnItems).get()).first;

    final content = await ExerciseLoader(db).load(item, _profile);

    expect(content, isA<EncounterContent>());
    final enc = (content as EncounterContent).encounter;
    expect(enc, isA<CharacterEncounter>());
    final ce = enc as CharacterEncounter;
    expect(ce.glyph, 'あ');
    expect(ce.reading, 'a');
    expect(ce.strokeOrderAssetId, 'assets/kanji_svg/3042.svg');
  });

  test('rung-1 character item still loads a RecognitionContent', () async {
    await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_a', rung: 1);
    final item = (await db.select(db.learnItems).get()).first;

    final content = await ExerciseLoader(db).load(item, _profile);
    expect(content, isA<RecognitionContent>());
  });
}
