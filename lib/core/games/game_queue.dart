import 'package:drift/drift.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/games/game_availability.dart';

class GameQueue {
  final LearningDb _db;

  GameQueue(this._db);

  Future<List<LearnItem>> getDue(
    GameSpec spec,
    String languageId, {
    DateTime? now,
    int limit = 10,
  }) {
    final cutoff = now ?? DateTime.now();
    return (_db.select(_db.learnItems)
          ..where((t) =>
              t.languageId.equals(languageId) &
              t.masteryRung.equals(spec.rung) &
              t.dueAt.isSmallerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.asc(t.dueAt)])
          ..limit(limit))
        .get();
  }

  Future<int> countDue(
    GameSpec spec,
    String languageId, {
    DateTime? now,
  }) async {
    final cutoff = now ?? DateTime.now();
    final rows = await (_db.select(_db.learnItems)
          ..where((t) =>
              t.languageId.equals(languageId) &
              t.masteryRung.equals(spec.rung) &
              t.dueAt.isSmallerOrEqualValue(cutoff)))
        .get();
    return rows.length;
  }
}
