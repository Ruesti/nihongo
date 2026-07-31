import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'mining_tables.dart';

part 'mining_db.g.dart';

/// Schema for the immersion-mining pipeline (SPEC_MINING_PIPELINE.md §4,
/// §9). Deliberately a separate database from [LearningDb] — the entity
/// model is lemma-centric and mined, not curriculum-centric and
/// hand-authored, and the two don't share identity.
///
/// Deliberately has no `path_provider`/`flutter_riverpod` dependency
/// (see `jmdict_db.dart`'s doc comment for the same reasoning): the
/// Phase 3 gate CLI tool needs this to compile and run under plain
/// `dart run`. Nothing in the app wires up a real on-device instance
/// yet (only `.forTesting()`/`.at()` are used so far) — add a
/// `path_provider`-based provider in the app's composition root
/// (`lib/app.dart` or similar) when that's actually needed, rather
/// than importing Flutter here.
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
  MiningDb.at(File file) : super(NativeDatabase(file));

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
