import 'package:drift/drift.dart';

/// One FreeDict spa-eng headword and its English glosses. Looked up by
/// the lowercased [form].
@TableIndex(name: 'es_lexemes_form_idx', columns: {#form})
class EsLexemes extends Table {
  TextColumn get id => text()();
  TextColumn get form => text()(); // lowercase Spanish headword
  TextColumn get glossesJson => text()(); // JSON list of English glosses

  @override
  Set<Column> get primaryKey => {id};
}

/// A Spanish lemma's frequency rank within the imported corpus.
class EsFrequencyEntries extends Table {
  TextColumn get lemma => text()();
  IntColumn get count => integer()();
  IntColumn get rank => integer()(); // 1 = most frequent

  @override
  Set<Column> get primaryKey => {lemma};
}
