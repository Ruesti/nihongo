import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/progress/progress_service.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

void main() {
  late LearningDb db;
  late ProgressService svc;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedJaPack(db);
    svc = ProgressService(db);
  });

  tearDown(() => db.close());

  // ── masteryStats ──────────────────────────────────────────────────────────

  group('masteryStats', () {
    test('no items → totalItems 0, perRung empty', () async {
      final stats = await svc.masteryStats('lang_ja');
      expect(stats.totalItems, 0);
      expect(stats.perRung, isEmpty);
      expect(stats.mastered, 0);
      expect(stats.masteryFraction, 0.0);
    });

    test('items at various rungs → correct per-rung counts', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog',
          rung: 1);
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_cat',
          rung: 2);
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_water',
          rung: 3);
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_eat',
          rung: 5);
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_what',
          rung: 5);

      final stats = await svc.masteryStats('lang_ja');
      expect(stats.totalItems, 5);
      expect(stats.perRung[1], 1);
      expect(stats.perRung[2], 1);
      expect(stats.perRung[3], 1);
      expect(stats.perRung[4], isNull);
      expect(stats.perRung[5], 2);
    });

    test('mastered = count at rung 5', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog',
          rung: 5);
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_cat',
          rung: 3);
      final stats = await svc.masteryStats('lang_ja');
      expect(stats.mastered, 1);
    });

    test('productive = count at rungs 3-5', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog',
          rung: 1);
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_cat',
          rung: 3);
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_water',
          rung: 5);
      final stats = await svc.masteryStats('lang_ja');
      expect(stats.productive, 2);
    });

    test('masteryFraction = mastered / total', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog',
          rung: 5);
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_cat',
          rung: 5);
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_water',
          rung: 1);
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_eat',
          rung: 2);
      final stats = await svc.masteryStats('lang_ja');
      expect(stats.masteryFraction, closeTo(2 / 4, 0.001));
    });

    test('isolates by language — other languages not counted', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog',
          rung: 5);
      final stats = await svc.masteryStats('lang_xx');
      expect(stats.totalItems, 0);
    });
  });

  // ── retentionRate ─────────────────────────────────────────────────────────

  group('retentionRate', () {
    Future<String> seedItem(String lexId) async {
      await db.addLearnItem('lang_ja', RefType.lexeme, lexId);
      return 'lang_ja:lexeme:$lexId';
    }

    Future<void> insertLog(
        String itemId, String result, DateTime ts) async {
      await db.into(db.reviewLog).insert(ReviewLogCompanion(
            id: Value('log_${ts.microsecondsSinceEpoch}_$result'),
            learnItemId: Value(itemId),
            rung: const Value(1),
            result: Value(result),
            ts: Value(ts),
          ));
    }

    test('no reviews → 0.0', () async {
      expect(await svc.retentionRate('lang_ja'), 0.0);
    });

    test('all good/easy → 1.0', () async {
      final id = await seedItem('lex_ja_dog');
      await insertLog(id, 'good', DateTime.now());
      await insertLog(id, 'easy', DateTime.now());
      expect(await svc.retentionRate('lang_ja'), 1.0);
    });

    test('half good half again → 0.5', () async {
      final id = await seedItem('lex_ja_dog');
      await insertLog(id, 'good', DateTime.now());
      await insertLog(id, 'again', DateTime.now());
      expect(await svc.retentionRate('lang_ja'), 0.5);
    });

    test('hard counts as negative (not good/easy)', () async {
      final id = await seedItem('lex_ja_dog');
      await insertLog(id, 'hard', DateTime.now());
      expect(await svc.retentionRate('lang_ja'), 0.0);
    });

    test('reviews older than window are excluded', () async {
      final id = await seedItem('lex_ja_dog');
      await insertLog(
          id, 'again', DateTime.now().subtract(const Duration(days: 31)));
      await insertLog(id, 'good', DateTime.now());
      expect(await svc.retentionRate('lang_ja'), 1.0);
    });

    test('days parameter controls window', () async {
      final id = await seedItem('lex_ja_dog');
      await insertLog(
          id, 'again', DateTime.now().subtract(const Duration(days: 8)));
      expect(await svc.retentionRate('lang_ja', days: 7), 0.0);
    });

    test('isolates by language', () async {
      final id = await seedItem('lex_ja_dog');
      await insertLog(id, 'again', DateTime.now());
      expect(await svc.retentionRate('lang_xx'), 0.0);
    });
  });

  // ── achievedGoals ─────────────────────────────────────────────────────────

  group('achievedGoals', () {
    test('no learn items → empty list', () async {
      expect(await svc.achievedGoals('lang_ja'), isEmpty);
    });

    test('all A1 lexemes at rung 3 → goal achieved', () async {
      for (final id in [
        'lex_ja_dog',
        'lex_ja_cat',
        'lex_ja_water',
        'lex_ja_eat',
        'lex_ja_what'
      ]) {
        await db.addLearnItemAtRung('lang_ja', RefType.lexeme, id, rung: 3);
      }
      final achieved = await svc.achievedGoals('lang_ja');
      expect(achieved, hasLength(1));
      expect(achieved.first.id, 'cando_ja_a1_kana');
    });

    test('all A1 lexemes at rung 5 → goal achieved (mastered)', () async {
      for (final id in [
        'lex_ja_dog',
        'lex_ja_cat',
        'lex_ja_water',
        'lex_ja_eat',
        'lex_ja_what'
      ]) {
        await db.addLearnItemAtRung('lang_ja', RefType.lexeme, id, rung: 5);
      }
      expect(await svc.achievedGoals('lang_ja'), hasLength(1));
    });

    test('one lexeme below rung 3 → goal not achieved', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog',
          rung: 3);
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_cat',
          rung: 2); // below threshold
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_water',
          rung: 3);
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_eat',
          rung: 3);
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_what',
          rung: 3);
      expect(await svc.achievedGoals('lang_ja'), isEmpty);
    });

    test('lexeme at rung 2 exactly → not counted (threshold is ≥ 3)', () async {
      for (final id in [
        'lex_ja_dog',
        'lex_ja_cat',
        'lex_ja_water',
        'lex_ja_eat',
        'lex_ja_what'
      ]) {
        await db.addLearnItemAtRung('lang_ja', RefType.lexeme, id, rung: 2);
      }
      expect(await svc.achievedGoals('lang_ja'), isEmpty);
    });

    test('unknown language → empty list', () async {
      expect(await svc.achievedGoals('lang_xx'), isEmpty);
    });

    test('lexeme missing from learn_items → goal not achieved', () async {
      // Only 4 of 5 A1 lexemes have items
      for (final id in [
        'lex_ja_dog',
        'lex_ja_cat',
        'lex_ja_water',
        'lex_ja_eat'
      ]) {
        await db.addLearnItemAtRung('lang_ja', RefType.lexeme, id, rung: 3);
      }
      // lex_ja_what has no item → goal not achieved
      expect(await svc.achievedGoals('lang_ja'), isEmpty);
    });
  });
}
