import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';

final progressServiceProvider = Provider<ProgressService>((ref) {
  return ProgressService(ref.watch(learningDbProvider));
});

class MasteryStats {
  final String languageId;
  final int totalItems;
  final Map<int, int> perRung;

  const MasteryStats({
    required this.languageId,
    required this.totalItems,
    required this.perRung,
  });

  int get mastered => perRung[5] ?? 0;
  int get productive =>
      [3, 4, 5].fold(0, (s, r) => s + (perRung[r] ?? 0));
  double get masteryFraction =>
      totalItems == 0 ? 0.0 : mastered / totalItems;
}

class ProgressService {
  final LearningDb _db;

  ProgressService(this._db);

  Future<MasteryStats> masteryStats(String langId) async {
    final items = await (_db.select(_db.learnItems)
          ..where((t) => t.languageId.equals(langId)))
        .get();

    final perRung = <int, int>{};
    for (final item in items) {
      perRung[item.masteryRung] = (perRung[item.masteryRung] ?? 0) + 1;
    }

    return MasteryStats(
      languageId: langId,
      totalItems: items.length,
      perRung: Map.unmodifiable(perRung),
    );
  }

  Future<double> retentionRate(String langId, {int days = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final rows = await (_db.select(_db.reviewLog).join([
      innerJoin(
        _db.learnItems,
        _db.learnItems.id.equalsExp(_db.reviewLog.learnItemId),
      ),
    ])
          ..where(
            _db.learnItems.languageId.equals(langId) &
                _db.reviewLog.ts.isBiggerOrEqualValue(cutoff),
          ))
        .get();

    if (rows.isEmpty) return 0.0;

    final positive = rows.where((r) {
      final result = r.readTable(_db.reviewLog).result;
      return result == 'good' || result == 'easy';
    }).length;

    return positive / rows.length;
  }

  Future<List<CanDoGoal>> achievedGoals(String langId) async {
    final goals = await (_db.select(_db.canDoGoals)
          ..where((t) => t.languageId.equals(langId)))
        .get();

    final achieved = <CanDoGoal>[];

    for (final goal in goals) {
      final lexemes = await (_db.select(_db.lexemes)
            ..where((t) =>
                t.languageId.equals(langId) &
                t.cefrBand.equals(goal.cefrBand)))
          .get();

      if (lexemes.isEmpty) continue;

      final lexemeIds = lexemes.map((l) => l.id).toList();
      final masteredItems = await (_db.select(_db.learnItems)
            ..where((t) =>
                t.languageId.equals(langId) &
                t.refType.equals('lexeme') &
                t.refId.isIn(lexemeIds) &
                t.masteryRung.isBiggerOrEqualValue(3)))
          .get();

      final masteredIds = masteredItems.map((i) => i.refId).toSet();
      if (lexemeIds.every(masteredIds.contains)) achieved.add(goal);
    }

    return achieved;
  }
}
