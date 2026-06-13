import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/games/game_availability.dart';
import 'package:nihongo_app/core/games/game_queue.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

void main() {
  late LearningDb db;
  late GameQueue queue;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedJaPack(db);
    queue = GameQueue(db);
  });

  tearDown(() => db.close());

  group('getDue', () {
    test('returns item at matching rung when due', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 2);
      const spec = (type: GameType.readingBlitz, rung: 2);

      final items = await queue.getDue(spec, 'lang_ja');

      expect(items, hasLength(1));
      expect(items.first.masteryRung, 2);
    });

    test('returns nothing when no items at that rung', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 1);
      const spec = (type: GameType.readingBlitz, rung: 2);

      final items = await queue.getDue(spec, 'lang_ja');

      expect(items, isEmpty);
    });

    test('excludes items not yet due (future dueAt)', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 2);

      const spec = (type: GameType.readingBlitz, rung: 2);
      final past = DateTime.now().subtract(const Duration(days: 1));

      final items = await queue.getDue(spec, 'lang_ja', now: past);

      expect(items, isEmpty);
    });

    test('includes multiple items at same rung', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 2);
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_i', rung: 2);
      const spec = (type: GameType.readingBlitz, rung: 2);

      final items = await queue.getDue(spec, 'lang_ja');

      expect(items, hasLength(2));
    });

    test('respects languageId — different lang returns nothing', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 2);
      const spec = (type: GameType.readingBlitz, rung: 2);

      final items = await queue.getDue(spec, 'lang_es');

      expect(items, isEmpty);
    });

    test('respects limit parameter', () async {
      for (final charId in ['char_ja_a', 'char_ja_i', 'char_ja_u', 'char_ja_e', 'char_ja_o']) {
        await db.addLearnItemAtRung('lang_ja', RefType.character, charId, rung: 2);
      }
      const spec = (type: GameType.readingBlitz, rung: 2);

      final items = await queue.getDue(spec, 'lang_ja', limit: 3);

      expect(items, hasLength(3));
    });
  });

  group('countDue', () {
    test('returns 0 when no items due', () async {
      const spec = (type: GameType.readingBlitz, rung: 2);
      expect(await queue.countDue(spec, 'lang_ja'), 0);
    });

    test('counts due items at matching rung', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 2);
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_i', rung: 2);
      await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_u', rung: 1);
      const spec = (type: GameType.readingBlitz, rung: 2);

      expect(await queue.countDue(spec, 'lang_ja'), 2);
    });
  });
}
