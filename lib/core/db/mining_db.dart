import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'mining_tables.dart';

part 'mining_db.g.dart';

final miningDbProvider = Provider<MiningDb>((ref) {
  final db = MiningDb();
  ref.onDispose(db.close);
  return db;
});

/// Schema for the immersion-mining pipeline (SPEC_MINING_PIPELINE.md §4,
/// §9). Deliberately a separate database from [LearningDb] — the entity
/// model is lemma-centric and mined, not curriculum-centric and
/// hand-authored, and the two don't share identity.
@DriftDatabase(tables: [
  Works,
  Sources,
  TextSpans,
  TokenOccurrences,
  VocabItems,
  Cards,
  ReviewLogs,
  MediaBlobs,
  LanguagePacks,
  ReadingSessions,
  PassageSnapshots,
  Observations,
])
class MiningDb extends _$MiningDb {
  MiningDb() : super(_openConnection());

  MiningDb.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );

  Future<void> registerLanguagePack({
    required String code,
    required String name,
    required bool hasReadings,
  }) =>
      into(languagePacks).insertOnConflictUpdate(
        LanguagePacksCompanion(
          code: Value(code),
          name: Value(name),
          hasReadings: Value(hasReadings),
        ),
      );

  Future<List<LanguagePackRow>> installedLanguagePacks() =>
      select(languagePacks).get();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'mining.db'));
    return NativeDatabase.createInBackground(file);
  });
}
