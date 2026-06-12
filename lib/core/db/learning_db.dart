import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'learning_db.g.dart';

final learningDbProvider = Provider<LearningDb>((ref) {
  final db = LearningDb();
  ref.onDispose(db.close);
  return db;
});

@DriftDatabase(tables: [
  Concepts,
  Assets,
  ScriptProfiles,
  Languages,
  Lexemes,
  Characters,
  CharComponents,
  CanDoGoals,
  GrammarPoints,
  Sentences,
  LearnItems,
  ReviewLog,
])
class LearningDb extends _$LearningDb {
  LearningDb() : super(_openConnection());

  LearningDb.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'learning.db'));
    return NativeDatabase.createInBackground(file);
  });
}
