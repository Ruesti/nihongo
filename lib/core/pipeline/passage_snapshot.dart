import 'package:drift/drift.dart';

import '../db/mining_db.dart';
import '../language_pack/language_pack.dart';
import 'sentence_scoring.dart' show KnowledgeSource, Knowledge, isContentToken;

/// The user-interaction signals recorded alongside a passage read
/// (§7). These come from the reader (dwell timer, tap-to-look-up
/// counter, mining-action counter) and are injected here rather than
/// measured in core — dwell time especially is local-only (§0.9.27).
class PassageMetrics {
  final int? dwellMs;
  final int lookupCount;
  final int miningEventsCount;

  const PassageMetrics({
    this.dwellMs,
    this.lookupCount = 0,
    this.miningEventsCount = 0,
  });
}

/// The unknown-token ratio for a passage: the fraction of its *content*
/// tokens (punctuation excluded, reusing [isContentToken] so this can't
/// diverge from the scoring definition) whose lemma is `unknown`. §7's
/// primary re-presentation metric.
double computeUnknownRatio(List<Token> tokens, KnowledgeSource knowledgeOf) {
  final content = tokens.where(isContentToken).toList();
  if (content.isEmpty) return 0.0;
  final unknown =
      content.where((t) => knowledgeOf(t.lemma) == Knowledge.unknown).length;
  return unknown / content.length;
}

/// Records an immutable [PassageSnapshots] row for one reading of a
/// passage (§7 — "written as an immutable passage_snapshot"). Every
/// read appends a new row; snapshots are never updated, so the delta
/// between two of them is always traceable to records that can't have
/// been altered afterward (§4, same discipline as review_log).
Future<PassageSnapshot> recordPassageSnapshot(
  MiningDb db, {
  required String workId,
  required String passageRef,
  required List<Token> tokens,
  required KnowledgeSource knowledgeOf,
  PassageMetrics metrics = const PassageMetrics(),
  DateTime? ts,
}) async {
  final now = (ts ?? DateTime.now()).toUtc();
  final unknownRatio = computeUnknownRatio(tokens, knowledgeOf);
  final id = 'snap:$workId:$passageRef:${now.microsecondsSinceEpoch}';

  await db.into(db.passageSnapshots).insert(
        PassageSnapshotsCompanion.insert(
          id: id,
          workId: workId,
          passageRef: passageRef,
          ts: now,
          unknownRatio: unknownRatio,
          dwellMs: Value(metrics.dwellMs),
          lookupCount: Value(metrics.lookupCount),
          miningEventsCount: Value(metrics.miningEventsCount),
        ),
      );

  return (db.select(db.passageSnapshots)..where((s) => s.id.equals(id)))
      .getSingle();
}

/// The measured change between two readings of the same passage (§7).
/// Carries the raw before/after values and names the direction
/// honestly: a passage that got *harder* after a long break is a
/// regression, surfaced, never hidden (§0.9.29 — "the whole credibility
/// of the instrument rests on this").
class PassageDelta {
  final PassageSnapshot before;
  final PassageSnapshot after;

  const PassageDelta({required this.before, required this.after});

  /// Positive = harder now (unknown ratio rose); negative = easier now.
  double get unknownRatioChange => after.unknownRatio - before.unknownRatio;

  /// The unknown ratio dropped — the passage got easier. The headline
  /// "good" case, but never assumed: [isRegression] is equally real.
  bool get isImprovement => after.unknownRatio < before.unknownRatio;

  /// The unknown ratio rose — the passage got harder (e.g. forgetting
  /// after a long gap). Shown, not suppressed.
  bool get isRegression => after.unknownRatio > before.unknownRatio;

  int get lookupChange => after.lookupCount - before.lookupCount;

  /// null when either reading didn't record dwell (it's optional and
  /// noisy — §7 says display it with less weight than the ratio).
  int? get dwellMsChange => (before.dwellMs == null || after.dwellMs == null)
      ? null
      : after.dwellMs! - before.dwellMs!;
}

/// The delta between the two most recent readings of [passageRef] in
/// [workId], or null if it hasn't been read at least twice yet (the
/// graceful "no delta exists" case — §8's empty state).
Future<PassageDelta?> latestPassageDelta(
  MiningDb db, {
  required String workId,
  required String passageRef,
}) async {
  final snaps = await (db.select(db.passageSnapshots)
        ..where((s) => s.workId.equals(workId) & s.passageRef.equals(passageRef))
        ..orderBy([(s) => OrderingTerm.desc(s.ts)])
        ..limit(2))
      .get();
  if (snaps.length < 2) return null;
  return PassageDelta(before: snaps[1], after: snaps[0]);
}
