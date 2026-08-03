import 'dart:convert';

import '../../core/language_pack/language_pack.dart';
import 'frequency_db.dart';
import 'jmdict_db.dart';
import 'native_tokenizer.dart';

/// The `Tokenizer`/`Dictionary`/`FrequencyList`/`ReadingProvider` seam
/// signatures (SPEC_MINING_PIPELINE.md §2.2) are synchronous — the
/// sentence-scoring loop (§3) has a hard "< 10s for a full novel"
/// budget, which a per-lookup async SQLite round-trip would blow.
/// [JaDictionary] and [JaReadingProvider] are therefore backed by an
/// in-memory index built once from [JmdictDb] via [JaLanguagePack.load],
/// not by live queries.
class JaLanguagePack implements LanguagePack {
  @override
  final String code = 'ja';

  @override
  final Tokenizer tokenizer;

  @override
  final Dictionary dictionary;

  @override
  final FrequencyList frequency;

  @override
  final ReadingProvider readings;

  JaLanguagePack._({
    required this.tokenizer,
    required this.dictionary,
    required this.frequency,
    required this.readings,
  });

  /// [tokenizerOverride] exists for tests that don't want to depend on
  /// the native library being built (e.g. dictionary-only tests) —
  /// production callers should omit it and get [NativeJaTokenizer].
  /// [frequencyDb] is optional: without it (or if it has no rows yet),
  /// [FrequencyList.rank] returns `null` for everything, same as before
  /// any corpus was imported.
  static Future<JaLanguagePack> load(
    JmdictDb db, {
    FrequencyDb? frequencyDb,
    Tokenizer? tokenizerOverride,
  }) async {
    final lemmas = await db.select(db.jmdictLemmas).get();
    final senses = await db.select(db.jmdictSenses).get();

    final formToEntryIds = <String, List<int>>{};
    final kanjiToReading = <String, String>{};
    final byEntry = <int, List<JmdictLemma>>{};
    for (final l in lemmas) {
      formToEntryIds.putIfAbsent(l.form, () => []).add(l.entryId);
      byEntry.putIfAbsent(l.entryId, () => []).add(l);
    }
    for (final group in byEntry.values) {
      final firstReading = group
          .where((l) => l.kind == 'reading')
          .map((l) => l.form)
          .firstOrNull;
      if (firstReading == null) continue;
      for (final k in group.where((l) => l.kind == 'kanji')) {
        kanjiToReading.putIfAbsent(k.form, () => firstReading);
      }
    }

    final entrySenses = <int, List<Sense>>{};
    for (final s in senses) {
      final glosses = (jsonDecode(s.glossesJson) as List).cast<String>();
      entrySenses
          .putIfAbsent(s.entryId, () => [])
          .add(Sense(pos: s.pos, glosses: glosses));
    }

    var rankByLemma = const <String, int>{};
    if (frequencyDb != null) {
      final entries = await frequencyDb.select(frequencyDb.frequencyEntries).get();
      rankByLemma = {for (final e in entries) e.lemma: e.rank};
    }

    return JaLanguagePack._(
      tokenizer: tokenizerOverride ?? NativeJaTokenizer(),
      dictionary: _JaDictionary(formToEntryIds, entrySenses),
      frequency: _JaFrequencyList(rankByLemma),
      readings: _JaReadingProvider(kanjiToReading),
    );
  }
}

class _JaDictionary implements Dictionary {
  final Map<String, List<int>> _formToEntryIds;
  final Map<int, List<Sense>> _entrySenses;

  const _JaDictionary(this._formToEntryIds, this._entrySenses);

  @override
  List<Sense> lookup(String lemma, String pos) {
    final entryIds = _formToEntryIds[lemma];
    if (entryIds == null) return const [];
    final result = <Sense>[];
    for (final id in entryIds) {
      final senses = _entrySenses[id];
      if (senses == null) continue;
      result.addAll(
        pos.isEmpty ? senses : senses.where((s) => s.pos.contains(pos)),
      );
    }
    return result;
  }
}

class _JaReadingProvider implements ReadingProvider {
  final Map<String, String> _kanjiToReading;

  const _JaReadingProvider(this._kanjiToReading);

  @override
  Reading? reading(Token token) {
    final r = _kanjiToReading[token.lemma];
    return r == null ? null : Reading(r);
  }
}

/// Backed by an in-memory `lemma -> rank` map loaded once from
/// [FrequencyDb] (see `frequency_importer.dart` for how it's
/// populated) — same synchronous-seam reasoning as [_JaDictionary].
/// `null` for a lemma outside the imported corpus is a real,
/// meaningful answer ("not in the list"), not a placeholder.
class _JaFrequencyList implements FrequencyList {
  final Map<String, int> _rankByLemma;
  final List<String> _byRankAscending;

  _JaFrequencyList(this._rankByLemma)
      : _byRankAscending = _rankByLemma.keys.toList()
          ..sort((a, b) => _rankByLemma[a]!.compareTo(_rankByLemma[b]!));

  @override
  int? rank(String lemma) => _rankByLemma[lemma];

  @override
  List<String> topLemmas(int n) => _byRankAscending.take(n).toList();
}
