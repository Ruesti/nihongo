import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'jmdict_tables.dart';

part 'jmdict_db.g.dart';

/// Storage for the JA `Dictionary` seam implementation. Deliberately
/// its own database, not part of [MiningDb] (core/db/mining_db.dart) —
/// dictionary data is per-`LanguagePack`, not shared pipeline state
/// (SPEC_MINING_PIPELINE.md §2.2's seam discipline: the core doesn't
/// know what a JMdict entry is).
///
/// Deliberately has no `path_provider` dependency (unlike [MiningDb]):
/// this file needs to compile and run under plain `dart run`, not just
/// inside a Flutter binding, so the Phase 2 import/benchmark CLI tool
/// (tool/phase2_import_and_benchmark.dart) can use it directly. Callers
/// resolve the real on-device path themselves and pass it to
/// [JmdictDb.at] — see `core/db` for where the rest of the app does
/// this via `path_provider`.
@DriftDatabase(tables: [JmdictEntries, JmdictLemmas, JmdictSenses])
class JmdictDb extends _$JmdictDb {
  JmdictDb.at(File file) : super(NativeDatabase(file));

  JmdictDb.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );

  Future<bool> isEmpty() async {
    final count = await (selectOnly(jmdictEntries)
          ..addColumns([jmdictEntries.id.count()]))
        .map((row) => row.read(jmdictEntries.id.count()))
        .getSingle();
    return (count ?? 0) == 0;
  }
}
