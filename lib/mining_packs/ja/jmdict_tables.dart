import 'package:drift/drift.dart';

/// One JMdict entry (`ent_seq` — EDRDG's stable numeric id, unchanged
/// across dictionary releases).
class JmdictEntries extends Table {
  IntColumn get id => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Every surface form (kanji writing or kana reading) an entry can be
/// looked up by. A single entry commonly has several — `lookup()`
/// matches against [form], not a single canonical lemma.
@TableIndex(name: 'jmdict_lemmas_form_idx', columns: {#form})
class JmdictLemmas extends Table {
  TextColumn get id => text()();
  IntColumn get entryId =>
      integer().references(JmdictEntries, #id, onDelete: KeyAction.cascade)();
  TextColumn get form => text()();
  TextColumn get kind => text()(); // kanji|reading

  @override
  Set<Column> get primaryKey => {id};
}

/// One `<sense>` block: a part-of-speech tagged group of glosses.
class JmdictSenses extends Table {
  TextColumn get id => text()();
  IntColumn get entryId =>
      integer().references(JmdictEntries, #id, onDelete: KeyAction.cascade)();
  IntColumn get senseOrder => integer()();
  TextColumn get pos => text()(); // comma-joined short JMdict POS codes
  TextColumn get glossesJson => text()(); // JSON list of English glosses

  @override
  Set<Column> get primaryKey => {id};
}
