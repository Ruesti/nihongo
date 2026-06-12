import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ladder/ladder_service.dart';
import '../ladder/rung_defs.dart';
import '../srs/scheduler.dart';
import 'tables.dart';

part 'learning_db.g.dart';

final learningDbProvider = Provider<LearningDb>((ref) {
  final db = LearningDb();
  ref.onDispose(db.close);
  return db;
});

@DriftDatabase(tables: [
  Concepts,
  Assets,
  ScriptProfiles,
  Languages,
  Lexemes,
  Characters,
  CharComponents,
  CanDoGoals,
  GrammarPoints,
  Sentences,
  LearnItems,
  ReviewLog,
])
class LearningDb extends _$LearningDb {
  LearningDb() : super(_openConnection());

  LearningDb.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(learnItems, learnItems.consecutiveCorrect);
          }
        },
      );

  // --- LearnItem DAOs ---

  Future<void> addLearnItem(
    String langId,
    RefType refType,
    String refId,
  ) =>
      _insertLearnItem(langId, refType, refId, rung: 1);

  Future<void> addLearnItemAtRung(
    String langId,
    RefType refType,
    String refId, {
    required int rung,
  }) =>
      _insertLearnItem(langId, refType, refId, rung: rung);

  Future<void> _insertLearnItem(
    String langId,
    RefType refType,
    String refId, {
    required int rung,
  }) async {
    await into(learnItems).insertOnConflictUpdate(
      LearnItemsCompanion(
        id: Value('$langId:${refType.name}:$refId'),
        languageId: Value(langId),
        refType: Value(refType.name),
        refId: Value(refId),
        masteryRung: Value(rung),
        consecutiveCorrect: const Value(0),
        dueAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<LearnItem>> getDueItems(String langId, {int limit = 20}) {
    final now = DateTime.now();
    return (select(learnItems)
          ..where((t) =>
              t.languageId.equals(langId) &
              t.dueAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.dueAt)])
          ..limit(limit))
        .get();
  }

  Future<void> applyReviewResult(
    LearnItem item,
    LadderResult ladderResult,
    ReviewResult reviewResult,
  ) async {
    await transaction(() async {
      final newLapses =
          reviewResult == ReviewResult.again ? item.lapses + 1 : item.lapses;

      await (update(learnItems)..where((t) => t.id.equals(item.id))).write(
        LearnItemsCompanion(
          masteryRung: Value(ladderResult.newMasteryRung),
          consecutiveCorrect: Value(ladderResult.newConsecutiveCorrect),
          ease: Value(ladderResult.scheduleOutput.ease),
          intervalDays: Value(ladderResult.scheduleOutput.intervalDays),
          dueAt: Value(ladderResult.scheduleOutput.dueAt),
          reps: Value(ladderResult.scheduleOutput.reps),
          lapses: Value(newLapses),
        ),
      );

      await into(reviewLog).insert(
        ReviewLogCompanion(
          id: Value('${item.id}_${DateTime.now().microsecondsSinceEpoch}'),
          learnItemId: Value(item.id),
          rung: Value(item.masteryRung),
          result: Value(reviewResult.name),
          ts: Value(DateTime.now()),
        ),
      );
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'learning.db'));
    return NativeDatabase.createInBackground(file);
  });
}
