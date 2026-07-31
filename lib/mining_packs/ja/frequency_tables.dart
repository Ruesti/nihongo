import 'package:drift/drift.dart';

/// A lemma's frequency rank within the imported corpus. Backs the JA
/// `FrequencyList` seam (SPEC_MINING_PIPELINE.md §2.2).
///
/// Source is Tatoeba's Japanese sentence export (CC-BY, already an
/// approved source per §0.5.17), not BCCWJ/JPDB as the spec's §2.2
/// table names them — those need a commercial license (BCCWJ) or have
/// unclear redistribution terms (JPDB) that haven't been cleared for
/// a commercial product (§0.1.3). Tatoeba is a legally uncomplicated
/// stand-in with the same shape; swapping in a licensed corpus later
/// is a re-import, not a seam change.
class FrequencyEntries extends Table {
  TextColumn get lemma => text()();
  IntColumn get count => integer()();
  IntColumn get rank => integer()(); // 1 = most frequent

  @override
  Set<Column> get primaryKey => {lemma};
}
