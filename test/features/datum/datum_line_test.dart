import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/datum/datum_line.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('DatumLine — §0.24 ornament, never information', () {
    testWidgets('shows the line when there is one', (tester) async {
      await tester.pumpWidget(_wrap(
        const DatumLine(line: 'Vor 23 Tagen. Damals nicht erkannt.'),
      ));

      expect(find.text('Vor 23 Tagen. Damals nicht erkannt.'), findsOneWidget);
      expect(find.byKey(const ValueKey('datum-line')), findsOneWidget);
    });

    testWidgets('renders NOTHING when the line is null (Datum silent/disabled)',
        (tester) async {
      await tester.pumpWidget(_wrap(const DatumLine(line: null)));

      // No line widget, no placeholder, no "nothing to say" notice —
      // just an empty box that takes no space.
      expect(find.byKey(const ValueKey('datum-line')), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets(
        "the surrounding information is untouched whether Datum speaks or not",
        (tester) async {
      // Simulate a screen showing real information (a measurement) with a
      // Datum line above it. Datum silent -> the measurement still shows.
      Widget screen(String? datumLine) => _wrap(Column(
            children: [
              DatumLine(line: datumLine),
              const Text('Unbekannt: 8%'), // the real, legible-without-Datum info
            ],
          ));

      await tester.pumpWidget(screen('Kapitel 2. Heute: 8 Prozent.'));
      expect(find.text('Unbekannt: 8%'), findsOneWidget);

      await tester.pumpWidget(screen(null)); // Datum disabled
      expect(find.text('Unbekannt: 8%'), findsOneWidget); // still there
      expect(find.byKey(const ValueKey('datum-line')), findsNothing);
    });
  });
}
