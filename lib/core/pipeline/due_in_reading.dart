import 'package:drift/drift.dart';

import '../db/mining_db.dart';
import '../language_pack/language_pack.dart';

/// One due review opportunity surfaced from the text in view.
class DueCardInView {
  final String cardId;
  final String vocabItemId;
  final String lemma;

  const DueCardInView({
    required this.cardId,
    required this.vocabItemId,
    required this.lemma,
  });
}

/// Surfaces due review items *from what the reader is currently looking
/// at* (SPEC_MINING_PIPELINE.md §7). This is the structural heart of
/// "scheduling woven into reading, no review screen": the review
/// opportunity is derived from the lemmas present in the reader's
/// current span, not drawn from a separate due-queue the user has to
/// navigate to. No deck, no review screen — the text itself is the
/// queue.
class DueInReading {
  final MiningDb db;

  const DueInReading(this.db);

  /// Due cards (due <= [now]) for [languageCode] whose lemma is among
  /// the [tokens] the reader can currently see. Ordered most-overdue
  /// first, so the reader is offered the item that has waited longest.
  Future<List<DueCardInView>> dueInView({
    required String languageCode,
    required List<Token> tokens,
    DateTime? now,
  }) async {
    final lemmasInView = tokens.map((t) => t.lemma).toSet();
    if (lemmasInView.isEmpty) return const [];

    final asOf = (now ?? DateTime.now()).toUtc();

    final query = db.select(db.vocabItems).join([
      innerJoin(db.cards, db.cards.vocabItemId.equalsExp(db.vocabItems.id)),
    ])
      ..where(db.vocabItems.languageCode.equals(languageCode) &
          db.vocabItems.lemma.isIn(lemmasInView) &
          db.cards.due.isSmallerOrEqualValue(asOf))
      ..orderBy([OrderingTerm.asc(db.cards.due)]);

    final rows = await query.get();
    return rows.map((row) {
      final vocab = row.readTable(db.vocabItems);
      final card = row.readTable(db.cards);
      return DueCardInView(
        cardId: card.id,
        vocabItemId: vocab.id,
        lemma: vocab.lemma,
      );
    }).toList();
  }
}
