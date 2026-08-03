import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/pipeline/passage_snapshot.dart';
import 'package:nihongo_app/features/opening/opening_screen.dart';
import 'package:nihongo_app/features/opening/opening_state.dart';

PassageSnapshot _snap(double unknownRatio, DateTime ts) => PassageSnapshot(
      id: 'snap:$ts',
      workId: 'w1',
      passageRef: 'Kapitel 2',
      ts: ts,
      unknownRatio: unknownRatio,
      lookupCount: 0,
      miningEventsCount: 0,
    );

Widget _screen(OpeningState state, {String? datumLine}) => MaterialApp(
      home: Scaffold(
        body: OpeningScreen(
          state: state,
          datumLine: datumLine,
          onContinueReading: () {},
          onLibrary: () {},
        ),
      ),
    );

void main() {
  final delta = PassageDelta(
    before: _snap(0.41, DateTime.utc(2026, 1, 1)),
    after: _snap(0.08, DateTime.utc(2026, 2, 15)),
  );

  group('OpeningScreen (§8 — a proof, not a menu)', () {
    testWidgets('renders the Then/Now proof from a real delta', (tester) async {
      await tester.pumpWidget(_screen(
        RePresentationState(delta),
        datumLine: 'Kapitel 2. Vor 6 Wochen: 41 Prozent unbekannt. Heute: 8.',
      ));

      expect(find.byKey(const ValueKey('re-presentation')), findsOneWidget);
      expect(find.text('41%'), findsOneWidget);
      expect(find.text('8%'), findsOneWidget);
      expect(find.textContaining('41 Prozent unbekannt'), findsOneWidget);
    });

    testWidgets('keeps navigation below the fold (present, at the bottom)',
        (tester) async {
      await tester.pumpWidget(_screen(RePresentationState(delta)));

      final continueBtn = find.byKey(const ValueKey('continue-reading'));
      final proof = find.byKey(const ValueKey('re-presentation'));
      expect(continueBtn, findsOneWidget);
      expect(find.byKey(const ValueKey('library')), findsOneWidget);
      // Navigation sits below the proof.
      expect(tester.getCenter(continueBtn).dy,
          greaterThan(tester.getCenter(proof).dy));
    });

    testWidgets('shows NO task count, due-card number, or streak (§8, I3)',
        (tester) async {
      await tester.pumpWidget(_screen(
        RePresentationState(delta),
        datumLine: 'Kapitel 2. Vor 6 Wochen: 41 Prozent unbekannt. Heute: 8.',
      ));

      final banned = RegExp(
          r'(fällig|due|streak|serie|in folge|aufgaben|\d+\s*(karten|cards|tasks))',
          caseSensitive: false);
      for (final w in tester.widgetList<Text>(find.byType(Text))) {
        final s = w.data ?? '';
        expect(banned.hasMatch(s), isFalse, reason: 'forbidden text: "$s"');
      }
    });

    testWidgets('graceful empty state: a passage read once shows the passage',
        (tester) async {
      await tester.pumpWidget(_screen(
        FirstReadingState(_snap(0.55, DateTime.utc(2026, 1, 1))),
        datumLine: 'Kapitel 2 einmal gelesen. Noch kein Vergleich möglich.',
      ));

      // The passage's own reading is shown, no fabricated Then/Now.
      expect(find.byKey(const ValueKey('first-reading-proof')), findsOneWidget);
      expect(find.byKey(const ValueKey('re-presentation')), findsNothing);
      expect(find.text('55%'), findsOneWidget);
      // Datum says so plainly.
      expect(find.textContaining('Noch kein Vergleich'), findsOneWidget);
      // Navigation still present.
      expect(find.byKey(const ValueKey('continue-reading')), findsOneWidget);
    });

    testWidgets('blank slate: nothing read yet shows an entry point',
        (tester) async {
      await tester.pumpWidget(_screen(const BlankSlateState()));

      expect(find.byKey(const ValueKey('blank-slate')), findsOneWidget);
      expect(find.byKey(const ValueKey('re-presentation')), findsNothing);
      // No Datum line, no proof — just a way in.
      expect(find.byKey(const ValueKey('datum-line')), findsNothing);
      expect(find.byKey(const ValueKey('continue-reading')), findsOneWidget);
    });

    testWidgets('with Datum disabled (null line) the proof still renders',
        (tester) async {
      await tester.pumpWidget(_screen(RePresentationState(delta),
          datumLine: null));

      // Datum silent, but the measurement is untouched (§0.24).
      expect(find.byKey(const ValueKey('datum-line')), findsNothing);
      expect(find.byKey(const ValueKey('re-presentation')), findsOneWidget);
      expect(find.text('8%'), findsOneWidget);
    });
  });
}
