import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../db/mining_db.dart';
import '../language_pack/language_pack.dart';

String _stateToText(fsrs.State s) => switch (s) {
      fsrs.State.newState => 'newState',
      fsrs.State.learning => 'learning',
      fsrs.State.review => 'review',
      fsrs.State.relearning => 'relearning',
    };

/// Simulates a realistic "well-known" review history using the real
/// FSRS algorithm (several straight `easy` ratings, each jumping
/// forward to the card's next due date) rather than hand-picking a
/// stability number. This is what genuine review history for an
/// already-known word looks like — FSRS run forward, not worked
/// around.
fsrs.Card simulateWellKnownCard(fsrs.FSRS scheduler, {int reviews = 4}) {
  var card = fsrs.Card();
  var now = DateTime.now().toUtc();
  for (var i = 0; i < reviews; i++) {
    final outcomes = scheduler.repeat(card, now);
    card = outcomes[fsrs.Rating.easy]!.card;
    now = card.due;
  }
  return card;
}

class FrequencyBootstrapImportResult {
  final int lemmaCount;
  final Duration elapsed;

  const FrequencyBootstrapImportResult({
    required this.lemmaCount,
    required this.elapsed,
  });
}

/// The §0.4.14 "mark first N of frequency list as known" bootstrap,
/// made real: creates [VocabItems] + [Cards] rows for the [topN] most
/// common lemmas in [frequency], with every card's state simulated to
/// a genuinely FSRS-earned "known" level via [simulateWellKnownCard].
/// All bootstrapped lemmas share the same simulated trajectory — this
/// is synthetic knowledge injection, not per-word history, so a
/// uniform template is the honest choice rather than fabricating
/// per-word variation with no basis.
Future<FrequencyBootstrapImportResult> importFrequencyBootstrap(
  MiningDb db,
  FrequencyList frequency, {
  required String languageCode,
  required int topN,
}) async {
  final stopwatch = Stopwatch()..start();
  final lemmas = frequency.topLemmas(topN);
  final wellKnown = simulateWellKnownCard(fsrs.FSRS());

  await db.batch((b) {
    for (final lemma in lemmas) {
      final vocabItemId = 'vocab:$languageCode:$lemma';
      b.insert(
        db.vocabItems,
        VocabItemsCompanion.insert(
          id: vocabItemId,
          languageCode: languageCode,
          lemma: lemma,
          pos: '', // unknown at bootstrap time; not needed for the known-check
          createdAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );
      b.insert(
        db.cards,
        CardsCompanion.insert(
          id: 'card:$vocabItemId',
          vocabItemId: vocabItemId,
          state: Value(_stateToText(wellKnown.state)),
          stability: Value(wellKnown.stability),
          difficulty: Value(wellKnown.difficulty),
          elapsedDays: Value(wellKnown.elapsedDays),
          scheduledDays: Value(wellKnown.scheduledDays),
          reps: Value(wellKnown.reps),
          lapses: Value(wellKnown.lapses),
          due: wellKnown.due,
          lastReview: wellKnown.lastReview,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  });

  stopwatch.stop();
  return FrequencyBootstrapImportResult(
    lemmaCount: lemmas.length,
    elapsed: stopwatch.elapsed,
  );
}
