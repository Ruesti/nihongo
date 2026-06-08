import 'mascot_state.dart';

class UserProgress {
  final String languageCode;
  final int totalXp;
  final int totalCardsLearned;
  final int completedLessons;
  final int conversationSessions;
  final int totalSessions;
  final DateTime? lastStudiedAt;

  const UserProgress({
    required this.languageCode,
    this.totalXp = 0,
    this.totalCardsLearned = 0,
    this.completedLessons = 0,
    this.conversationSessions = 0,
    this.totalSessions = 0,
    this.lastStudiedAt,
  });

  TamagoState get tamagoState {
    if (totalXp >= 5000) return TamagoState.hatched;
    if (totalXp >= 3000) return TamagoState.halfOut;
    if (totalXp >= 1500) return TamagoState.peeking;
    if (totalXp >= 500) return TamagoState.cracking;
    return TamagoState.egg;
  }

  int get xpToNextStage {
    if (totalXp < 500) return 500 - totalXp;
    if (totalXp < 1500) return 1500 - totalXp;
    if (totalXp < 3000) return 3000 - totalXp;
    if (totalXp < 5000) return 5000 - totalXp;
    return 0;
  }

  UserProgress copyWith({
    int? totalXp,
    int? totalCardsLearned,
    int? completedLessons,
    int? conversationSessions,
    int? totalSessions,
    DateTime? lastStudiedAt,
  }) {
    return UserProgress(
      languageCode: languageCode,
      totalXp: totalXp ?? this.totalXp,
      totalCardsLearned: totalCardsLearned ?? this.totalCardsLearned,
      completedLessons: completedLessons ?? this.completedLessons,
      conversationSessions:
          conversationSessions ?? this.conversationSessions,
      totalSessions: totalSessions ?? this.totalSessions,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
    );
  }
}
