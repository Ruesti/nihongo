import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/srs_card.dart';

part 'database.g.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

@DataClassName('SrsCardRow')
class SrsCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cardId => text()();
  TextColumn get front => text()();
  TextColumn get back => text()();
  TextColumn get reading => text().nullable()();
  RealColumn get ease => real().withDefault(const Constant(2.5))();
  IntColumn get interval => integer().withDefault(const Constant(0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get dueAt => integer().withDefault(const Constant(0))();
  TextColumn get cardType => text()();
  TextColumn get languageCode => text().withDefault(const Constant('ja'))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {cardId, languageCode}
      ];
}

class LessonProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lessonId => integer()();
  TextColumn get languageCode => text().withDefault(const Constant('ja'))();
  IntColumn get status => integer().withDefault(const Constant(0))();
  IntColumn get accuracy => integer().withDefault(const Constant(0))();
  IntColumn get xpEarned => integer().withDefault(const Constant(0))();
  IntColumn get completedAt => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {lessonId, languageCode}
      ];
}

class UserStats extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get languageCode => text().withDefault(const Constant('ja'))();
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  IntColumn get totalCardsLearned =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalSessions => integer().withDefault(const Constant(0))();
  IntColumn get conversationSessions =>
      integer().withDefault(const Constant(0))();
  IntColumn get lastStudiedAt => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {languageCode}
      ];
}

class StudyHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get languageCode => text().withDefault(const Constant('ja'))();
  IntColumn get dayEpoch => integer()();
  IntColumn get cardsStudied => integer().withDefault(const Constant(0))();
  IntColumn get correctAnswers => integer().withDefault(const Constant(0))();
  IntColumn get minutesStudied => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {languageCode, dayEpoch}
      ];
}

class BlitzHighscores extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get score => integer()();
  IntColumn get correctCount => integer()();
  IntColumn get bestStreak => integer()();
  IntColumn get playedAt => integer()();
  TextColumn get kanjiSet => text().withDefault(const Constant('N5'))();
}

class MemoryBesttimes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get gridSize => text()();
  TextColumn get pairType => text()();
  IntColumn get moves => integer()();
  IntColumn get timeSeconds => integer()();
  IntColumn get playedAt => integer()();
}

@DriftDatabase(tables: [
  SrsCards,
  LessonProgress,
  UserStats,
  StudyHistory,
  BlitzHighscores,
  MemoryBesttimes,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // --- SRS-Karten ---

  Future<SrsCard?> getSrsCard(String cardId, {String lang = 'ja'}) async {
    final q = select(srsCards)
      ..where(
          (t) => t.cardId.equals(cardId) & t.languageCode.equals(lang));
    final row = await q.getSingleOrNull();
    return row == null ? null : _rowToSrsCard(row);
  }

  Future<List<SrsCard>> getDueCards({String lang = 'ja'}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final q = select(srsCards)
      ..where((t) =>
          t.languageCode.equals(lang) &
          t.dueAt.isSmallerOrEqualValue(now));
    final rows = await q.get();
    return rows.map(_rowToSrsCard).toList();
  }

  Future<List<SrsCard>> getAllCards({String lang = 'ja'}) async {
    final q = select(srsCards)
      ..where((t) => t.languageCode.equals(lang));
    final rows = await q.get();
    return rows.map(_rowToSrsCard).toList();
  }

  Future<void> upsertSrsCard(SrsCard card) async {
    await into(srsCards)
        .insertOnConflictUpdate(_srsCardToCompanion(card));
  }

  SrsCard _rowToSrsCard(SrsCardRow row) => SrsCard(
        id: row.id,
        cardId: row.cardId,
        front: row.front,
        back: row.back,
        reading: row.reading,
        ease: row.ease,
        interval: row.interval,
        reps: row.reps,
        dueAt: row.dueAt,
        cardType: row.cardType,
        languageCode: row.languageCode,
      );

  SrsCardsCompanion _srsCardToCompanion(SrsCard c) =>
      SrsCardsCompanion(
        cardId: Value(c.cardId),
        front: Value(c.front),
        back: Value(c.back),
        reading: Value(c.reading),
        ease: Value(c.ease),
        interval: Value(c.interval),
        reps: Value(c.reps),
        dueAt: Value(c.dueAt),
        cardType: Value(c.cardType),
        languageCode: Value(c.languageCode),
      );

  // --- Lektionsfortschritt ---

  Future<LessonProgressData?> getLessonProgress(int lessonId,
      {String lang = 'ja'}) async {
    final q = select(lessonProgress)
      ..where((t) =>
          t.lessonId.equals(lessonId) & t.languageCode.equals(lang));
    return q.getSingleOrNull();
  }

  Future<List<LessonProgressData>> getAllLessonProgress(
      {String lang = 'ja'}) async {
    final q = select(lessonProgress)
      ..where((t) => t.languageCode.equals(lang));
    return q.get();
  }

  Future<void> setLessonStatus(int lessonId, int status,
      {int accuracy = 0, int xp = 0, String lang = 'ja'}) async {
    final now = status == 3
        ? DateTime.now().millisecondsSinceEpoch
        : 0;
    await into(lessonProgress).insertOnConflictUpdate(
      LessonProgressCompanion(
        lessonId: Value(lessonId),
        languageCode: Value(lang),
        status: Value(status),
        accuracy: Value(accuracy),
        xpEarned: Value(xp),
        completedAt: Value(now),
      ),
    );
  }

  // --- User-Stats ---

  Future<UserStat?> getUserStats({String lang = 'ja'}) async {
    final q = select(userStats)
      ..where((t) => t.languageCode.equals(lang));
    return q.getSingleOrNull();
  }

  Future<void> addXp(int xp, {String lang = 'ja'}) async {
    final existing = await getUserStats(lang: lang);
    if (existing == null) {
      await into(userStats).insert(UserStatsCompanion(
        languageCode: Value(lang),
        totalXp: Value(xp),
        lastStudiedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
    } else {
      await (update(userStats)
            ..where((t) => t.languageCode.equals(lang)))
          .write(UserStatsCompanion(
        totalXp: Value(existing.totalXp + xp),
        lastStudiedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
    }
  }

  Future<void> incrementCardsLearned(int count,
      {String lang = 'ja'}) async {
    final existing = await getUserStats(lang: lang);
    if (existing == null) {
      await into(userStats).insert(UserStatsCompanion(
        languageCode: Value(lang),
        totalCardsLearned: Value(count),
      ));
    } else {
      await (update(userStats)
            ..where((t) => t.languageCode.equals(lang)))
          .write(UserStatsCompanion(
        totalCardsLearned: Value(existing.totalCardsLearned + count),
      ));
    }
  }

  Future<void> incrementConversationSessions({String lang = 'ja'}) async {
    final existing = await getUserStats(lang: lang);
    if (existing == null) {
      await into(userStats).insert(UserStatsCompanion(
        languageCode: Value(lang),
        conversationSessions: const Value(1),
      ));
    } else {
      await (update(userStats)
            ..where((t) => t.languageCode.equals(lang)))
          .write(UserStatsCompanion(
        conversationSessions: Value(existing.conversationSessions + 1),
      ));
    }
  }

  // --- Lernhistorie ---

  Future<List<StudyHistoryData>> getStudyHistory(
      {String lang = 'ja', int days = 30}) async {
    final cutoff =
        DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch ~/
            86400000;
    final q = select(studyHistory)
      ..where((t) =>
          t.languageCode.equals(lang) &
          t.dayEpoch.isBiggerOrEqualValue(cutoff))
      ..orderBy([(t) => OrderingTerm.asc(t.dayEpoch)]);
    return q.get();
  }

  Future<void> recordStudySession(
      int cardsStudied, int correct, int minutes,
      {String lang = 'ja'}) async {
    final today =
        DateTime.now().millisecondsSinceEpoch ~/ 86400000;
    final existing = await (select(studyHistory)
          ..where((t) =>
              t.languageCode.equals(lang) & t.dayEpoch.equals(today)))
        .getSingleOrNull();
    if (existing == null) {
      await into(studyHistory).insert(StudyHistoryCompanion(
        languageCode: Value(lang),
        dayEpoch: Value(today),
        cardsStudied: Value(cardsStudied),
        correctAnswers: Value(correct),
        minutesStudied: Value(minutes),
      ));
    } else {
      await (update(studyHistory)
            ..where((t) =>
                t.languageCode.equals(lang) & t.dayEpoch.equals(today)))
          .write(StudyHistoryCompanion(
        cardsStudied: Value(existing.cardsStudied + cardsStudied),
        correctAnswers: Value(existing.correctAnswers + correct),
        minutesStudied: Value(existing.minutesStudied + minutes),
      ));
    }
  }

  // --- Blitz Highscores ---

  Future<List<BlitzHighscore>> getBlitzHighscores(
      {int limit = 10}) async {
    final q = select(blitzHighscores)
      ..orderBy([(t) => OrderingTerm.desc(t.score)])
      ..limit(limit);
    return q.get();
  }

  Future<void> addBlitzHighscore(int score, int correct, int streak,
      {String kanjiSet = 'N5'}) async {
    await into(blitzHighscores).insert(BlitzHighscoresCompanion(
      score: Value(score),
      correctCount: Value(correct),
      bestStreak: Value(streak),
      playedAt: Value(DateTime.now().millisecondsSinceEpoch),
      kanjiSet: Value(kanjiSet),
    ));
    final all = await (select(blitzHighscores)
          ..orderBy([(t) => OrderingTerm.desc(t.score)]))
        .get();
    if (all.length > 10) {
      for (final old in all.skip(10)) {
        await (delete(blitzHighscores)
              ..where((t) => t.id.equals(old.id)))
            .go();
      }
    }
  }

  // --- Memory Bestzeiten ---

  Future<MemoryBesttime?> getMemoryBesttime(
      String gridSize, String pairType) async {
    final q = select(memoryBesttimes)
      ..where((t) =>
          t.gridSize.equals(gridSize) & t.pairType.equals(pairType))
      ..orderBy([(t) => OrderingTerm.asc(t.timeSeconds)])
      ..limit(1);
    return q.getSingleOrNull();
  }

  Future<void> saveMemoryResult(
      String gridSize, String pairType, int moves, int seconds) async {
    await into(memoryBesttimes).insert(MemoryBesttimesCompanion(
      gridSize: Value(gridSize),
      pairType: Value(pairType),
      moves: Value(moves),
      timeSeconds: Value(seconds),
      playedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'nihongo.db'));
    return NativeDatabase.createInBackground(file);
  });
}
