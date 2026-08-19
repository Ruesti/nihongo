import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/lesson/lesson_screen.dart';

// These unit tests exercise the extracted seam the lesson screen calls, so
// the closed seam (lessons → ladder) can be verified without pumping the
// full lesson UI.
void main() {
  late LearningDb db;
  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'ja-JP'));
    await db.into(db.characters).insert(CharactersCompanion.insert(
        id: 'char_ja_a',
        languageId: 'lang_ja',
        glyph: 'あ',
        readingsJson: jsonEncode(['a']),
        meaning: 'a'));
  });
  tearDown(() async => db.close());

  test('introduce + markEncountered leaves a due rung-1 item for Review',
      () async {
    final review = LadderReview(db);
    // lesson start: introduce at rung 0
    await review.introduce('lang_ja', RefType.character, 'char_ja_a');
    // after the encounter step in the lesson:
    final introduced = (await db.select(db.learnItems).get()).single;
    await review.markEncountered(introduced);

    final item = await db.getLearnItem('lang_ja:character:char_ja_a');
    expect(item!.masteryRung, 1);
    // The Review queue will serve it once its scheduled dueAt arrives.
    expect(item.refType, 'character');
  });

  test('resolveKanaCharacterIds maps seeded cardIds by glyph, skips unseeded',
      () async {
    // hira_a → glyph あ → seeded char_ja_a; hira_i → glyph い not seeded;
    // garbage cardId has no KanaEntry at all. Only the resolvable one survives.
    final ids = await resolveKanaCharacterIds(
      db,
      'lang_ja',
      ['hira_a', 'hira_i', 'not_a_real_card'],
    );
    expect(ids, ['char_ja_a']);
  });
}
