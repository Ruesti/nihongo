import 'dart:convert';

import '../../core/language_pack/language_pack.dart';
import 'es_pack_db.dart';
import 'es_whitespace_tokenizer.dart';

/// The Spanish `LanguagePack` — a REAL second language proving the
/// four-seam design (§2.2) generalizes past JA with **zero changes to
/// pipeline or experience code** (Phase 11, verified by diff). It
/// implements the exact same `Tokenizer`/`Dictionary`/`FrequencyList`/
/// `ReadingProvider` interfaces JA does; the mining pipeline, the
/// reader, the re-presentation, and Datum all run over it unchanged.
///
/// Two seams differ in kind from JA, exactly as §2.2's table predicts
/// for a whitespace language:
///  - the tokenizer is regex word-break, not an FFI morphological
///    analyzer;
///  - `readings` is `null` — Spanish has no separate reading layer.
class EsLanguagePack implements LanguagePack {
  @override
  final String code = 'es';

  @override
  final Tokenizer tokenizer;

  @override
  final Dictionary dictionary;

  @override
  final FrequencyList frequency;

  @override
  final ReadingProvider? readings = null; // no reading layer (§2.2)

  EsLanguagePack._({
    required this.tokenizer,
    required this.dictionary,
    required this.frequency,
  });

  static Future<EsLanguagePack> load(EsPackDb db) async {
    final lexemes = await db.select(db.esLexemes).get();
    final glossesByForm = <String, List<String>>{};
    for (final l in lexemes) {
      glossesByForm[l.form] =
          (jsonDecode(l.glossesJson) as List).cast<String>();
    }

    final freqRows = await db.select(db.esFrequencyEntries).get();
    final rankByLemma = {for (final e in freqRows) e.lemma: e.rank};

    return EsLanguagePack._(
      tokenizer: const EsWhitespaceTokenizer(),
      dictionary: _EsDictionary(glossesByForm),
      frequency: _EsFrequencyList(rankByLemma),
    );
  }
}

class _EsDictionary implements Dictionary {
  final Map<String, List<String>> _glossesByForm;

  const _EsDictionary(this._glossesByForm);

  @override
  List<Sense> lookup(String lemma, String pos) {
    final glosses = _glossesByForm[lemma];
    if (glosses == null) return const [];
    return [Sense(pos: '', glosses: glosses)];
  }
}

class _EsFrequencyList implements FrequencyList {
  final Map<String, int> _rankByLemma;
  final List<String> _byRankAscending;

  _EsFrequencyList(this._rankByLemma)
      : _byRankAscending = _rankByLemma.keys.toList()
          ..sort((a, b) => _rankByLemma[a]!.compareTo(_rankByLemma[b]!));

  @override
  int? rank(String lemma) => _rankByLemma[lemma];

  @override
  List<String> topLemmas(int n) => _byRankAscending.take(n).toList();
}
