import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/conversation/conversation_service.dart';
import 'package:nihongo_app/core/conversation/error_span.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

void main() {
  late LearningDb db;
  late ConversationService service;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedJaPack(db);
    service = ConversationService(db);
  });

  tearDown(() => db.close());

  group('onError — new item (I7: Fehler erzeugt Item)', () {
    test('introduces an unmet LearnItem at rung 0 when not yet known', () async {
      await service.onError(const ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.lexeme,
        refId: 'lex_ja_dog',
      ));

      final items = await db.select(db.learnItems).get();
      expect(items, hasLength(1));
      expect(items.first.masteryRung, 0);
      expect(items.first.refId, 'lex_ja_dog');
      expect(items.first.refType, 'lexeme');
    });

    test('new item is due immediately', () async {
      await service.onError(const ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.lexeme,
        refId: 'lex_ja_dog',
      ));

      final item = (await db.select(db.learnItems).get()).first;
      expect(item.dueAt.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
    });

    test('character refType creates character item', () async {
      await service.onError(const ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.character,
        refId: 'char_ja_a',
      ));

      final item = (await db.select(db.learnItems).get()).first;
      expect(item.refType, 'character');
      expect(item.refId, 'char_ja_a');
    });

    test('no review_log entry for brand-new item (first creation, not demotion)', () async {
      await service.onError(const ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.lexeme,
        refId: 'lex_ja_dog',
      ));

      final logs = await db.select(db.reviewLog).get();
      expect(logs, isEmpty);
    });
  });

  group('onError — existing item (I7: Fehler stuft zurück)', () {
    test('demotes item from rung 3 to rung 2 on error', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog', rung: 3);

      await service.onError(const ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.lexeme,
        refId: 'lex_ja_dog',
      ));

      final item = (await db.select(db.learnItems).get()).first;
      expect(item.masteryRung, 2);
    });

    test('resets consecutiveCorrect to 0 on error', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog', rung: 2);

      await service.onError(const ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.lexeme,
        refId: 'lex_ja_dog',
      ));

      final item = (await db.select(db.learnItems).get()).first;
      expect(item.consecutiveCorrect, 0);
    });

    test('increments lapses on error', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog', rung: 2);

      await service.onError(const ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.lexeme,
        refId: 'lex_ja_dog',
      ));

      final item = (await db.select(db.learnItems).get()).first;
      expect(item.lapses, 1);
    });

    test('rung 1 stays at rung 1 (floor clamp)', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog', rung: 1);

      await service.onError(const ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.lexeme,
        refId: 'lex_ja_dog',
      ));

      final item = (await db.select(db.learnItems).get()).first;
      expect(item.masteryRung, 1);
    });

    test('logs result=again to review_log', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog', rung: 2);

      await service.onError(const ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.lexeme,
        refId: 'lex_ja_dog',
      ));

      final logs = await db.select(db.reviewLog).get();
      expect(logs, hasLength(1));
      expect(logs.first.result, 'again');
    });

    test('multiple errors accumulate lapses', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog', rung: 3);
      const span = ErrorSpan(
        languageId: 'lang_ja',
        refType: RefType.lexeme,
        refId: 'lex_ja_dog',
      );

      await service.onError(span); // 3→2
      await service.onError(span); // 2→1
      await service.onError(span); // 1→1 (clamped)

      final item = (await db.select(db.learnItems).get()).first;
      expect(item.masteryRung, 1);
      expect(item.lapses, 3);
      final logs = await db.select(db.reviewLog).get();
      expect(logs, hasLength(3));
    });
  });
}
