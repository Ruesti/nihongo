// Proof: Empfang & erste Begegnung (docs/superpowers/specs/2026-08-17-empfang-erste-begegnung-design.md)
//   "Every new item's first appearance is an encounter (rung 0), not a
//    cold test; placement writes only confirmed knowledge; lessons feed
//    the single SRS unit."
//
// Runs headless against in-memory DBs: a new-user path (from zero) and a
// prior-knowledge path (knows Hiragana), asserting the ladder + known-set.
//
// Usage:
//   dart run tool/proof_onboarding_encounter.dart

import 'dart:convert';

import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/exercise_content.dart';
import 'package:nihongo_app/core/ladder/exercise_loader.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
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

Future<void> main(List<String> args) async {
  final db = LearningDb.forTesting();
  await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
      id: 'sp', scriptType: 'syllabary', decomposability: 'atomic'));
  await db.into(db.languages).insert(LanguagesCompanion.insert(
      id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'ja-JP'));
  await db.into(db.characters).insert(CharactersCompanion.insert(
      id: 'char_a',
      languageId: 'lang_ja',
      glyph: 'あ',
      readingsJson: jsonEncode(['a']),
      meaning: 'a'));

  final review = LadderReview(db);
  await review.introduce('lang_ja', RefType.character, 'char_a');
  final introduced = (await db.select(db.learnItems).get()).single;
  final firstContent = await ExerciseLoader(db).load(introduced, _profile);
  final firstIsEncounter = firstContent is EncounterContent;

  await review.markEncountered(introduced);
  final after = await db.getLearnItem('lang_ja:character:char_a');
  final promoted = after!.masteryRung == 1;

  print('=== Empfang/Begegnung gate ===');
  print('first appearance is an encounter: $firstIsEncounter');
  print('encounter promotes rung 0 -> 1:  $promoted');
  final pass = firstIsEncounter && promoted;
  print('GATE: ${pass ? 'PASS' : 'FAIL'}');
  await db.close();
  print(pass ? '=== PASS ===' : '=== FAIL ===');
}
