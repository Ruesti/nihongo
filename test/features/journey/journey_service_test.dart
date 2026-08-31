import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';
import 'package:nihongo_app/features/journey/journey_service.dart';

Curriculum _curriculum() => const Curriculum(
      languageCode: 'ja',
      title: 'T',
      steps: [
        LessonStep(id: 'l1', chapterRef: 'K1', characterIds: ['char_ja_a'], lexemeIds: [], grammarIds: []),
        MangaStep(id: 'm1', chapterRef: 'K1', comicAsset: 'assets/comic/ja_l0.json'),
        LessonStep(id: 'l2', chapterRef: 'K2', characterIds: ['char_ja_i'], lexemeIds: [], grammarIds: []),
      ],
    );

void main() {
  late LearningDb db;
  setUp(() => db = LearningDb.forTesting());
  tearDown(() => db.close());

  JourneyService svc() =>
      JourneyService(curriculum: _curriculum(), learning: db, languageId: 'lang_ja');

  test('with nothing known, current step is index 0', () async {
    expect(await svc().resolveStepIndex(0), 0);
  });

  test('a lesson whose items are all already known is skipped', () async {
    // char_ja_a already introduced (rung ≥ 1) → step 0 is known → skip to 1 (manga).
    await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 3);
    expect(await svc().resolveStepIndex(0), 1);
  });

  test('a rung-0 (introduced-not-encountered) lesson is NOT skipped', () async {
    // char_ja_a only introduced at rung 0 (e.g. lesson start/abandon or a
    // conversation error) — not yet actually learned → step 0 must NOT be skipped.
    await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 0);
    expect(await svc().resolveStepIndex(0), 0);
  });

  test('past the end returns null', () async {
    expect(await svc().resolveStepIndex(3), isNull);
  });
}
