import '../../core/language_pack/language_pack.dart';

/// One passage of the vertical slice: a short piece of real text with
/// its tokens and furigana already computed (prebaked by
/// `tool/prebake_slice.dart` from the real Lindera + JMdict pipeline).
///
/// The app consumes these `Token`s directly — no runtime tokenizer, no
/// native library. That is precisely what the `Tokenizer` seam
/// (SPEC_MINING_PIPELINE.md §2.2) permits: where the tokens came from,
/// the reader "cannot tell and does not care" (see `SpanReader`).
class SlicePassage {
  /// Stable human label used as the passage_snapshot `passageRef` — so a
  /// re-read of the same passage produces a real Then/Now delta.
  final String passageRef;
  final String content;
  final List<Token> tokens;

  /// Reading to draw above a token, keyed by the token's `charStart`
  /// (matches `SpanReader.furiganaByCharStart`).
  final Map<int, String> furiganaByCharStart;

  const SlicePassage({
    required this.passageRef,
    required this.content,
    required this.tokens,
    required this.furiganaByCharStart,
  });

  factory SlicePassage.fromJson(Map<String, dynamic> json) {
    final tokens = (json['tokens'] as List)
        .cast<Map<String, dynamic>>()
        .map((t) => Token(
              surface: t['surface'] as String,
              lemma: t['lemma'] as String,
              reading: t['reading'] as String?,
              pos: t['pos'] as String,
              charStart: t['charStart'] as int,
              charEnd: t['charEnd'] as int,
            ))
        .toList();
    final furigana = <int, String>{
      for (final e in (json['furigana'] as Map<String, dynamic>).entries)
        int.parse(e.key): e.value as String,
    };
    return SlicePassage(
      passageRef: json['passageRef'] as String,
      content: json['content'] as String,
      tokens: tokens,
      furiganaByCharStart: furigana,
    );
  }
}

/// The whole prebaked slice: passages + a `Dictionary` covering exactly
/// the lemmas those passages contain + a small "returning reader already
/// saw these" seed list (see [SlicePack.demoKnownLemmas]).
class SlicePack {
  final String workTitle;
  final String languageCode;
  final List<SlicePassage> passages;
  final Dictionary dictionary;

  /// Common lemmas the demo seeds as already-seen (due) cards so the
  /// in-reading review has something real to surface. This is seeded
  /// *starting knowledge*, never a fabricated measurement — every
  /// snapshot/delta the app shows comes from real reading actions.
  final List<String> demoKnownLemmas;

  const SlicePack({
    required this.workTitle,
    required this.languageCode,
    required this.passages,
    required this.dictionary,
    required this.demoKnownLemmas,
  });

  factory SlicePack.fromJson(Map<String, dynamic> json) {
    final dict = <String, List<Sense>>{};
    for (final e in (json['dictionary'] as Map<String, dynamic>).entries) {
      dict[e.key] = (e.value as List)
          .cast<Map<String, dynamic>>()
          .map((s) => Sense(
                pos: s['pos'] as String,
                glosses: (s['glosses'] as List).cast<String>(),
              ))
          .toList();
    }
    return SlicePack(
      workTitle: json['workTitle'] as String,
      languageCode: json['languageCode'] as String,
      passages: (json['passages'] as List)
          .cast<Map<String, dynamic>>()
          .map(SlicePassage.fromJson)
          .toList(),
      dictionary: PrebakedDictionary(dict),
      demoKnownLemmas: (json['demoKnownLemmas'] as List).cast<String>(),
    );
  }
}

/// The `Dictionary` seam, backed by the prebaked lemma→senses map. Real
/// JMdict senses, frozen at build time — a drop-in for the in-memory
/// dictionary `JaLanguagePack` builds from a full JMdict DB, with the
/// same synchronous `lookup` contract and no native/DB dependency.
class PrebakedDictionary implements Dictionary {
  final Map<String, List<Sense>> _byLemma;

  const PrebakedDictionary(this._byLemma);

  @override
  List<Sense> lookup(String lemma, String pos) {
    final senses = _byLemma[lemma];
    if (senses == null) return const [];
    if (pos.isEmpty) return senses;
    return senses.where((s) => s.pos.contains(pos)).toList();
  }
}
