/// One entry in the diegetic dictionary (brief §3). The dictionary's
/// contents are the reader's own learned vocabulary — [meaning] is only
/// ever shown once the reader has learned this entry (see
/// `DictionarySheet`'s `knownIds`). [marginNote], when present, belongs to
/// the book's previous owner and is never resolvable (§3.5) — it is not
/// itself a translation and is unrelated to whether the entry is known.
class DictionaryEntry {
  final String id;
  final String headword;
  final String meaning;
  final String? marginNote;

  const DictionaryEntry({
    required this.id,
    required this.headword,
    required this.meaning,
    this.marginNote,
  });
}
