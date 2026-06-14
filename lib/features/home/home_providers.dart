import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../models/progress.dart';

final userProgressProvider = FutureProvider.family<UserProgress, String>(
  (ref, lang) async {
    final db = ref.read(dbProvider);
    final stats = await db.getUserStats(lang: lang);
    final lessonProgress = await db.getAllLessonProgress(lang: lang);
    final completed = lessonProgress.where((p) => p.status == 3).length;
    return UserProgress(
      languageCode: lang,
      totalXp: stats?.totalXp ?? 0,
      totalCardsLearned: stats?.totalCardsLearned ?? 0,
      completedLessons: completed,
      conversationSessions: stats?.conversationSessions ?? 0,
    );
  },
);

final lessonStatusProvider = FutureProvider.family<Map<int, int>, String>(
  (ref, lang) async {
    final db = ref.read(dbProvider);
    final all = await db.getAllLessonProgress(lang: lang);
    final map = <int, int>{};
    for (final p in all) {
      map[p.lessonId] = p.status;
    }
    if (!map.containsKey(1)) map[1] = 1;
    return map;
  },
);

final dueCardsProvider = FutureProvider.family<int, String>(
  (ref, lang) async {
    final db = ref.read(dbProvider);
    final cards = await db.getDueCards(lang: lang);
    return cards.length;
  },
);
