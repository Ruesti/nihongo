import 'package:drift/drift.dart';

import '../db/mining_db.dart';
import 'sentence_scoring.dart';

/// The real [KnowledgeSource] per §0.4.13's decision ("FSRS stability
/// threshold defines known") — supersedes Phase 3's
/// `FrequencyBootstrapKnowledge`, which checked frequency rank
/// directly rather than actual review state. Built once from
/// [MiningDb]'s `VocabItems`/`Cards` tables (same synchronous-seam
/// reasoning as `JaLanguagePack`'s in-memory dictionary/reading
/// indexes — §3's scoring loop can't afford per-lookup DB queries).
///
/// A lemma with no [Cards] row at all is `unknown` — never
/// encountered. A lemma with a card that hasn't reached
/// [knownStabilityThreshold] yet is `learning` — introduced, not yet
/// mastered. Only `state == review` past the threshold counts as
/// `known`.
class FsrsKnowledgeSource {
  final Map<String, ({String state, double stability})> _byLemma;
  final double knownStabilityThreshold;

  const FsrsKnowledgeSource(
    this._byLemma, {
    required this.knownStabilityThreshold,
  });

  Knowledge call(String lemma) {
    final card = _byLemma[lemma];
    if (card == null) return Knowledge.unknown;
    if (card.state == 'review' && card.stability >= knownStabilityThreshold) {
      return Knowledge.known;
    }
    return Knowledge.learning;
  }

  static Future<FsrsKnowledgeSource> load(
    MiningDb db, {
    required String languageCode,
    double knownStabilityThreshold = 5.0,
  }) async {
    final query = db.select(db.vocabItems).join([
      innerJoin(
        db.cards,
        db.cards.vocabItemId.equalsExp(db.vocabItems.id),
      ),
    ])
      ..where(db.vocabItems.languageCode.equals(languageCode));

    final rows = await query.get();
    final byLemma = <String, ({String state, double stability})>{};
    for (final row in rows) {
      final vocabItem = row.readTable(db.vocabItems);
      final card = row.readTable(db.cards);
      byLemma[vocabItem.lemma] =
          (state: card.state, stability: card.stability);
    }

    return FsrsKnowledgeSource(
      byLemma,
      knownStabilityThreshold: knownStabilityThreshold,
    );
  }
}
