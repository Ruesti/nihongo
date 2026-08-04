import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'es_pack_tables.dart';

part 'es_pack_db.g.dart';

/// Storage for the Spanish `LanguagePack`'s data (FreeDict lexemes +
/// corpus frequency). Its own database, exactly as JA's dictionary and
/// frequency have theirs — pack data is per-`LanguagePack`, never
/// shared pipeline state. No `path_provider` dependency, so the Phase
/// 11 CLI tooling runs it under plain `dart run` (same reasoning as
/// `jmdict_db.dart`).
@DriftDatabase(tables: [EsLexemes, EsFrequencyEntries])
class EsPackDb extends _$EsPackDb {
  EsPackDb.at(File file) : super(NativeDatabase(file));

  EsPackDb.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}
