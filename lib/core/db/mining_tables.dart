import 'package:drift/drift.dart';

/// A book, series, episode, or volume the user is reading/watching.
/// Medium-agnostic; groups [TextSpans] (SPEC_MINING_PIPELINE.md §9).
class Works extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get medium => text()(); // plainText|epub|srt|ocr
  TextColumn get languageCode => text()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One imported file/import batch that contributed [TextSpans] to a
/// [Works] entry (§4).
class Sources extends Table {
  TextColumn get id => text()();
  TextColumn get workId =>
      text().references(Works, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text()(); // plainText|epub|srt|ocr
  TextColumn get path => text()();
  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A positioned text unit (§5, §9). Replaces the standalone `segment`
/// from §4 — Anchor is a tagged union, stored as [anchorType] plus the
/// columns relevant to that type (nullable for the other two kinds).
class TextSpans extends Table {
  TextColumn get id => text()();
  TextColumn get workId =>
      text().references(Works, #id, onDelete: KeyAction.cascade)();
  TextColumn get sourceId =>
      text().references(Sources, #id, onDelete: KeyAction.cascade)();
  IntColumn get ordinal => integer()(); // reading order, medium-independent
  TextColumn get content => text()();
  TextColumn get anchorType => text()(); // flow|time|spatial

  // FlowAnchor (EPUB / plain text)
  IntColumn get charStart => integer().nullable()();
  IntColumn get charEnd => integer().nullable()();

  // TimeAnchor (SRT/ASS) — audio is extractable from [tStartMs]/[tEndMs]
  IntColumn get tStartMs => integer().nullable()();
  IntColumn get tEndMs => integer().nullable()();

  // SpatialAnchor (manga OCR, Phase 12)
  TextColumn get pageId => text().nullable()();
  TextColumn get rectJson => text().nullable()(); // {left,top,right,bottom}

  @override
  Set<Column> get primaryKey => {id};
}

/// One tokenizer hit of a lemma within a [TextSpans] row. The join
/// table that enables sentence re-election (§2.4) — expected to be the
/// largest table; index on (lemma, sourceId) per §4.
class TokenOccurrences extends Table {
  TextColumn get id => text()();
  TextColumn get textSpanId =>
      text().references(TextSpans, #id, onDelete: KeyAction.cascade)();
  TextColumn get lemma => text()();
  TextColumn get surface => text()();
  TextColumn get reading => text().nullable()();
  TextColumn get pos => text()();
  IntColumn get charStart => integer()();
  IntColumn get charEnd => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The SRS-trainable identity. Lemma-centric, not sentence-bound (§2.4):
/// "card ≠ sentence" — the currently-best example sentence lives on
/// [Cards.contextTextSpanId], a mutable field, never on this row.
class VocabItems extends Table {
  TextColumn get id => text()();
  TextColumn get languageCode => text()();
  TextColumn get lemma => text()();
  TextColumn get pos => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {languageCode, lemma, pos},
      ];
}

/// FSRS scheduling state for a [VocabItems] row, plus the currently
/// elected example sentence. Field names mirror the `fsrs` package's
/// `Card` class so DB rows round-trip through it without translation
/// tables (§0.4.12).
class Cards extends Table {
  TextColumn get id => text()();
  TextColumn get vocabItemId => text()
      .references(VocabItems, #id, onDelete: KeyAction.cascade)
      .unique()();
  TextColumn get contextTextSpanId =>
      text().nullable().references(TextSpans, #id)();

  TextColumn get state =>
      text().withDefault(const Constant('learning'))(); // learning|review|relearning
  IntColumn get step => integer().nullable()();
  RealColumn get stability => real().nullable()();
  RealColumn get difficulty => real().nullable()();
  DateTimeColumn get due => dateTime()();
  DateTimeColumn get lastReview => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// FSRS review history. Append-only (§4): parameter re-optimisation and
/// Datum's honest measurements both depend on this never being edited.
class ReviewLogs extends Table {
  TextColumn get id => text()();
  TextColumn get cardId =>
      text().references(Cards, #id, onDelete: KeyAction.cascade)();
  TextColumn get rating => text()(); // again|hard|good|easy
  DateTimeColumn get reviewDateTime => dateTime()();
  IntColumn get reviewDurationMs => integer().nullable()();
  RealColumn get stabilityBefore => real().nullable()();
  RealColumn get stabilityAfter => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Path + content hash for extracted audio/screenshot media. Blobs live
/// on the filesystem, not in SQLite (§4) — this table only indexes them.
class MediaBlobs extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()(); // audio|image
  TextColumn get path => text()();
  TextColumn get contentHash => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Registers an installed `LanguagePack` (§2.2) by BCP-47 code. Row
/// presence means "installed"; the seam implementations themselves are
/// resolved in Dart code via a registry, not stored here.
///
/// Row type is named [LanguagePackRow], not `LanguagePack` — that name
/// is reserved for the seam interface itself (core/language_pack/).
@DataClassName('LanguagePackRow')
class LanguagePacks extends Table {
  TextColumn get code => text()(); // BCP-47
  TextColumn get name => text()();
  BoolColumn get hasReadings =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {code};
}

/// One continuous engagement with a work (§9).
class ReadingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get workId =>
      text().references(Works, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get spanStartOrdinal => integer().nullable()();
  IntColumn get spanEndOrdinal => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Immutable measurement of one passage at one time (§7, §9) — the
/// substrate of re-presentation. Append-only; a negative delta between
/// two snapshots is reported honestly, never hidden (§0.9.29).
class PassageSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get workId =>
      text().references(Works, #id, onDelete: KeyAction.cascade)();
  TextColumn get passageRef =>
      text()(); // passage delimiting scheme is an open question, §12
  DateTimeColumn get ts => dateTime()();
  RealColumn get unknownRatio => real()();
  IntColumn get dwellMs => integer().nullable()(); // local-only, §0.9.27
  IntColumn get lookupCount => integer().withDefault(const Constant(0))();
  IntColumn get miningEventsCount =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Facts available to Datum (§6.3). Derived, may be recomputed; never a
/// source of truth. Every fact an emitted line interpolates must trace
/// back to a real record elsewhere — enforced by the Phase 9 test gate,
/// not by this table.
class Observations extends Table {
  TextColumn get id => text()();
  TextColumn get kind =>
      text()(); // reencounter|prediction_miss|delta_measured|load_warning|...
  TextColumn get factsJson => text()(); // serialized Map<String, Object>
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
