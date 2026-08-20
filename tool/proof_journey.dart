// Proof: Der geführte Weg (docs/superpowers/specs/2026-08-20-gefuehrter-weg-lektion-manga-design.md)
//   "A learner walks the guided path: a lesson step introduces its items,
//    the sequencer then advances to the manga step; a vocab-knower's known
//    lesson is skipped."
//
// Usage:
//   dart run tool/proof_journey.dart

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';
import 'package:nihongo_app/features/journey/journey_service.dart';

Curriculum _curriculum() => const Curriculum(
      languageCode: 'ja',
      title: 'proof',
      steps: [
        LessonStep(id: 'l1', chapterRef: 'K1', characterIds: ['char_ja_a'], lexemeIds: [], grammarIds: []),
        MangaStep(id: 'm1', chapterRef: 'K1', comicAsset: 'assets/comic/ja_l0.json'),
        LessonStep(id: 'l2', chapterRef: 'K2', characterIds: ['char_ja_i'], lexemeIds: [], grammarIds: []),
      ],
    );

Future<void> main(List<String> args) async {
  final db = LearningDb.forTesting();
  await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
      id: 'sp_ja_kana', scriptType: 'syllabary', decomposability: 'atomic'));
  await db.into(db.languages).insert(LanguagesCompanion.insert(
      id: 'lang_ja', name: 'JA', scriptProfileId: 'sp_ja_kana', ttsVoice: 'ja-JP'));
  await db.into(db.characters).insert(CharactersCompanion.insert(
      id: 'char_ja_a', languageId: 'lang_ja', glyph: 'あ',
      readingsJson: jsonEncode(['a']), meaning: 'a'));
  await db.into(db.characters).insert(CharactersCompanion.insert(
      id: 'char_ja_i', languageId: 'lang_ja', glyph: 'い',
      readingsJson: jsonEncode(['i']), meaning: 'i'));

  final svc = JourneyService(
      curriculum: _curriculum(), learning: db, languageId: 'lang_ja');
  final review = LadderReview(db);

  // Fresh learner → step 0 (the opening lesson).
  final firstIsLesson = (await svc.resolveStepIndex(0)) == 0;

  // Complete lesson 0's encounter for char_ja_a — mirrors LessonStepScreen's
  // introduce (rung 0) → markEncountered (rung 0→1) flow, since a lesson
  // whose items are only introduced-not-encountered is deliberately NOT
  // treated as known (see journey_service_test.dart) — then advance from
  // index 1 → manga.
  await review.introduce('lang_ja', RefType.character, 'char_ja_a');
  await review.markEncountered(
      (await db.getLearnItem('lang_ja:character:char_ja_a'))!);
  final secondIsManga = (await svc.resolveStepIndex(1)) == 1;

  // A "vocab-knower" who already has char_ja_i mastered (introduced AND
  // encountered → rung ≥ 1) → step 2 (l2) is skipped by resolveStepIndex
  // when starting from 2.
  await review.introduce('lang_ja', RefType.character, 'char_ja_i');
  await review.markEncountered(
      (await db.getLearnItem('lang_ja:character:char_ja_i'))!);
  final knownLessonSkipped = (await svc.resolveStepIndex(2)) == null;

  print('=== Geführter-Weg gate ===');
  print('first step is the opening lesson: $firstIsLesson');
  print('after lesson → manga step:        $secondIsManga');
  print('already-known lesson is skipped:  $knownLessonSkipped');
  final pass = firstIsLesson && secondIsManga && knownLessonSkipped;
  print('GATE: ${pass ? 'PASS' : 'FAIL'}');
  await db.close();
  print(pass ? '=== PASS ===' : '=== FAIL ===');
}
