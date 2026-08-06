import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_boot.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/pipeline/fsrs_knowledge_source.dart';
import 'package:nihongo_app/core/pipeline/knowledge_bridge.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';

Future<void> _seedLexeme(LearningDb db,
    {required String id, required String written, required int rung}) async {
  await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex:$id',
        languageId: 'lang_ja', // on-ramp id form
        conceptId: 'c:$id',
        writtenForm: written,
        reading: written,
      ));
  await db.into(db.learnItems).insert(LearnItemsCompanion.insert(
        id: 'li:$id',
        languageId: 'lang_ja',
        refType: 'lexeme',
        refId: 'lex:$id',
        masteryRung: Value(rung),
        dueAt: DateTime.utc(2026, 8, 6),
      ));
}

Future<Knowledge> _knows(MiningDb db, String lemma) async =>
    (await FsrsKnowledgeSource.load(db, languageCode: 'ja')).call(lemma);

void main() {
  late LearningDb learning;
  late MiningDb mining;
  late KnowledgeBoot boot;
  late Set<String> done;

  setUp(() async {
    learning = LearningDb.forTesting();
    mining = MiningDb.forTesting();
    boot = KnowledgeBoot(KnowledgeBridge(mining));
    done = <String>{};
    await _seedLexeme(learning, id: 'neko', written: '猫', rung: 4); // mastered
  });

  tearDown(() async {
    await learning.close();
    await mining.close();
  });

  Future<void> run() => boot.ensureBackfilled(
        learning,
        languages: const [(languageId: 'lang_ja', languageCode: 'ja')],
        isDone: (k) async => done.contains(k),
        markDone: (k) async {
          done.add(k);
        },
      );

  test('first boot backfills the on-ramp base and maps lang_ja → ja',
      () async {
    await run();
    expect(await _knows(mining, '猫'), Knowledge.known);
    expect(done, contains('knowledge_backfill:ja'));
  });

  test('second boot is a no-op — it must not clobber live reading progress',
      () async {
    await run();
    // Simulate in-reading mining demoting the word after the hand-off.
    await (mining.update(mining.cards)
          ..where((c) => c.vocabItemId.equals('vocab:ja:猫')))
        .write(const CardsCompanion(
            state: Value('learning'), stability: Value(1.0)));
    expect(await _knows(mining, '猫'), Knowledge.learning);

    await run(); // guard skips the already-done language …
    expect(await _knows(mining, '猫'), Knowledge.learning); // … so no reset
  });
}
