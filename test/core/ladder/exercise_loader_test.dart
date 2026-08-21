import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/exercise_content.dart';
import 'package:nihongo_app/core/ladder/exercise_loader.dart';
import 'package:nihongo_app/core/ladder/ladder_service.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/script_profile.dart';
import 'package:nihongo_app/core/srs/scheduler.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

const _jaProfile = ScriptProfile(
  id: 'sp_ja_kana',
  scriptType: ScriptType.syllabary,
  direction: Direction.ltr,
  decomposability: Decomposability.atomic,
  positionalForms: false,
  toneSystem: ToneSystem.pitchAccent,
  needsScriptTrack: true,
  transliteration: 'romaji',
  inputMethods: [InputMethod.keyboard],
);

void main() {
  late LearningDb db;
  late ExerciseLoader loader;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedJaPack(db);
    loader = ExerciseLoader(db);
  });

  tearDown(() async => db.close());

  group('character content — each rung', () {
    test('rung 1 → RecognitionContent with glyph and meaning', () async {
      await db.addLearnItem('lang_ja', RefType.character, 'char_ja_a');
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _jaProfile);

      expect(content, isA<RecognitionContent>());
      final rec = content as RecognitionContent;
      expect(rec.displayForm, 'あ');
      expect(rec.answer, 'vowel a');
    });

    test('rung 2 → ReadingInputContent with glyph and expected reading', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 2);
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _jaProfile);

      expect(content, isA<ReadingInputContent>());
      final read = content as ReadingInputContent;
      expect(read.displayForm, 'あ');
      expect(read.expectedReading, 'a');
    });

    test('rung 3 → ProductionInputContent with meaning prompt', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 3);
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _jaProfile);

      expect(content, isA<ProductionInputContent>());
      final prod = content as ProductionInputContent;
      expect(prod.prompt, 'vowel a');
      expect(prod.expectedForm, 'あ');
    });

    test('rung 4 → WriteTraceContent with glyph and reading', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 4);
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _jaProfile);

      expect(content, isA<WriteTraceContent>());
      final trace = content as WriteTraceContent;
      expect(trace.glyph, 'あ');
      expect(trace.expectedReading, 'a');
      // Since the JA seed wires KanjiVG stroke assets, kana carry their path.
      expect(trace.strokeOrderAssetId, 'assets/kanji_svg/3042.svg');
    });
  });

  group('lexeme content loading', () {
    test('rung 1 → RecognitionContent with writtenForm and glossKey', () async {
      await db.addLearnItem('lang_ja', RefType.lexeme, 'lex_ja_dog');
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _jaProfile);

      expect(content, isA<RecognitionContent>());
      final rec = content as RecognitionContent;
      expect(rec.displayForm, '犬');
      expect(rec.answer, 'dog');
    });

    test('rung 2 → ReadingInputContent with writtenForm and reading', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog', rung: 2);
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _jaProfile);

      expect(content, isA<ReadingInputContent>());
      final read = content as ReadingInputContent;
      expect(read.displayForm, '犬');
      expect(read.expectedReading, 'いぬ');
    });
  });

  test('character promotion loop: rung 1 → rung 4, content is WriteTraceContent', () async {
    await db.addLearnItem('lang_ja', RefType.character, 'char_ja_i');

    // 3 promotions × 3 consecutive good = 9 reviews total
    for (int targetRung = 1; targetRung <= 3; targetRung++) {
      for (int i = 0; i < promotionThreshold; i++) {
        final item = (await db.select(db.learnItems).get()).first;
        final result = processResult(
          currentRung: item.masteryRung,
          consecutiveCorrect: item.consecutiveCorrect,
          scheduleInput: ScheduleInput(
            ease: item.ease,
            intervalDays: item.intervalDays,
            reps: item.reps,
          ),
          result: ReviewResult.good,
        );
        await db.applyReviewResult(item, result, ReviewResult.good);
      }
    }

    final promoted = (await db.select(db.learnItems).get()).first;
    expect(promoted.masteryRung, 4);

    final content = await loader.load(promoted, _jaProfile);
    expect(content, isA<WriteTraceContent>());
    final trace = content as WriteTraceContent;
    expect(trace.glyph, 'い');
    expect(trace.expectedReading, 'i');
  });
}
