import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'frequency_tables.dart';

part 'frequency_db.g.dart';

/// Storage for the JA `FrequencyList` seam implementation. Its own
/// database, like [JmdictDb] — corpus-derived frequency data is per
/// `LanguagePack`, not shared pipeline state. No `path_provider`
/// dependency (see `jmdict_db.dart`'s doc comment for why): this needs
/// to run under plain `dart run` for the Phase 3 CLI tooling.
@DriftDatabase(tables: [FrequencyEntries])
class FrequencyDb extends _$FrequencyDb {
  FrequencyDb.at(File file) : super(NativeDatabase(file));

  FrequencyDb.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}
