import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/pipeline/passage_snapshot.dart';
import 'package:nihongo_app/features/reader/re_presentation.dart';

PassageSnapshot _snap({
  required double unknownRatio,
  int lookupCount = 0,
  int? dwellMs,
  required DateTime ts,
}) =>
    PassageSnapshot(
      id: 'snap:$ts',
      workId: 'w1',
      passageRef: 'p1',
      ts: ts,
      unknownRatio: unknownRatio,
      lookupCount: lookupCount,
      miningEventsCount: 0,
      dwellMs: dwellMs,
    );

Widget _wrap(PassageDelta delta) =>
    MaterialApp(home: Scaffold(body: RePresentationView(delta: delta)));

void main() {
  group('RePresentationView (§7/§8)', () {
    testWidgets('shows the Then and Now unknown ratios', (tester) async {
      await tester.pumpWidget(_wrap(PassageDelta(
        before: _snap(unknownRatio: 0.41, ts: DateTime.utc(2026, 1, 1)),
        after: _snap(unknownRatio: 0.08, ts: DateTime.utc(2026, 2, 1)),
      )));

      expect(find.text('41%'), findsOneWidget); // then
      expect(find.text('8%'), findsOneWidget); // now
    });

    testWidgets('an improvement shows a downward arrow', (tester) async {
      await tester.pumpWidget(_wrap(PassageDelta(
        before: _snap(unknownRatio: 0.41, ts: DateTime.utc(2026, 1, 1)),
        after: _snap(unknownRatio: 0.08, ts: DateTime.utc(2026, 2, 1)),
      )));

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
    });

    testWidgets('a REGRESSION is shown honestly, not hidden (§0.29)',
        (tester) async {
      await tester.pumpWidget(_wrap(PassageDelta(
        before: _snap(unknownRatio: 0.10, ts: DateTime.utc(2026, 1, 1)),
        after: _snap(unknownRatio: 0.35, ts: DateTime.utc(2026, 6, 1)),
      )));

      // The harder-now values are on screen...
      expect(find.text('10%'), findsOneWidget);
      expect(find.text('35%'), findsOneWidget);
      // ...an upward (worse) arrow is shown, not suppressed...
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      // ...and the headline names it plainly.
      expect(find.textContaining('schwerer geworden'), findsOneWidget);
    });

    testWidgets('shows secondary lookup counts', (tester) async {
      await tester.pumpWidget(_wrap(PassageDelta(
        before: _snap(unknownRatio: 0.4, lookupCount: 7, ts: DateTime.utc(2026, 1, 1)),
        after: _snap(unknownRatio: 0.1, lookupCount: 1, ts: DateTime.utc(2026, 2, 1)),
      )));

      expect(find.textContaining('Nachschlagen: 7 → 1'), findsOneWidget);
    });

    testWidgets('shows dwell only when both readings recorded it',
        (tester) async {
      await tester.pumpWidget(_wrap(PassageDelta(
        before: _snap(unknownRatio: 0.4, dwellMs: 134000, ts: DateTime.utc(2026, 1, 1)),
        after: _snap(unknownRatio: 0.1, dwellMs: 41000, ts: DateTime.utc(2026, 2, 1)),
      )));

      expect(find.textContaining('Verweildauer'), findsOneWidget);
    });

    testWidgets('omits dwell when a reading lacks it (noisy signal)',
        (tester) async {
      await tester.pumpWidget(_wrap(PassageDelta(
        before: _snap(unknownRatio: 0.4, ts: DateTime.utc(2026, 1, 1)),
        after: _snap(unknownRatio: 0.1, dwellMs: 41000, ts: DateTime.utc(2026, 2, 1)),
      )));

      expect(find.textContaining('Verweildauer'), findsNothing);
    });
  });
}
