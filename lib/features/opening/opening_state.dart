import 'package:drift/drift.dart';

import '../../core/datum/observation.dart';
import '../../core/db/mining_db.dart';
import '../../core/pipeline/passage_snapshot.dart';

/// What the opening screen (§8) has to show, derived from real reading
/// history. A sealed hierarchy so the screen must handle every case —
/// including, load-bearingly, the empty ones.
sealed class OpeningState {
  const OpeningState();
}

/// The headline case: the most-recently-read passage has been read at
/// least twice, so there's a Then/Now delta to prove.
class RePresentationState extends OpeningState {
  final PassageDelta delta;
  const RePresentationState(this.delta);
}

/// The graceful empty state (§8): a passage read exactly once. No delta
/// yet — show the passage and let Datum say so plainly, never invent a
/// comparison.
class FirstReadingState extends OpeningState {
  final PassageSnapshot lastReading;
  const FirstReadingState(this.lastReading);
}

/// Brand-new user, nothing read yet. The screen shows an entry point,
/// not a fabricated proof.
class BlankSlateState extends OpeningState {
  const BlankSlateState();
}

/// Loads the opening state from real history: the globally most-recent
/// passage snapshot picks "the most recently read passage" (§8), then
/// that passage's snapshot count decides the case. No task counts, no
/// due numbers, no streaks are read or computed here — the opening
/// screen is a proof, not a dashboard (§8).
Future<OpeningState> loadOpeningState(MiningDb db) async {
  final latest = await (db.select(db.passageSnapshots)
        ..orderBy([(s) => OrderingTerm.desc(s.ts)])
        ..limit(1))
      .getSingleOrNull();
  if (latest == null) return const BlankSlateState();

  final snaps = await (db.select(db.passageSnapshots)
        ..where((s) =>
            s.workId.equals(latest.workId) &
            s.passageRef.equals(latest.passageRef))
        ..orderBy([(s) => OrderingTerm.desc(s.ts)]))
      .get();

  if (snaps.length == 1) return FirstReadingState(snaps.first);
  return RePresentationState(PassageDelta(before: snaps[1], after: snaps[0]));
}

/// The Datum observation for an opening state, built ONLY from measured
/// values (§6.3): a delta comparison when there's a delta, a plain
/// "read once, no comparison yet" note for the empty state, and nothing
/// at all for a blank slate. The caller runs this through `DatumVoice`,
/// which will still refuse any line whose facts aren't all present.
Observation? openingDatumObservation(OpeningState state) {
  switch (state) {
    case RePresentationState(:final delta):
      return Observation(kind: ObservationKind.deltaMeasured, facts: {
        'chapter': delta.after.passageRef,
        'weeks_ago':
            (delta.after.ts.difference(delta.before.ts).inDays / 7).round(),
        'unknown_before': (delta.before.unknownRatio * 100).round(),
        'unknown_after': (delta.after.unknownRatio * 100).round(),
      });
    case FirstReadingState(:final lastReading):
      return Observation(kind: ObservationKind.firstReading, facts: {
        'chapter': lastReading.passageRef,
      });
    case BlankSlateState():
      return null;
  }
}
