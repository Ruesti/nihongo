import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/encounter.dart';
import 'package:nihongo_app/features/encounter/encounter_view.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('character encounter shows the glyph and a Weiter button, no grades',
      (tester) async {
    var done = false;
    await tester.pumpWidget(_wrap(EncounterView(
      encounter: const CharacterEncounter(
          glyph: 'あ', reading: 'a', audioText: 'あ'),
      onDone: () => done = true,
    )));

    expect(find.text('あ'), findsOneWidget);
    // Ungraded: none of the SRS grade labels appear.
    expect(find.text('Nochmal'), findsNothing);
    expect(find.text('Gut'), findsNothing);

    await tester.tap(find.text('Verstanden'));
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('lexeme encounter without a concept image shows meaning as text',
      (tester) async {
    await tester.pumpWidget(_wrap(EncounterView(
      encounter: const LexemeEncounter(
          writtenForm: '猫', reading: 'ねこ', audioText: '猫', meaning: 'cat'),
      onDone: () {},
    )));

    expect(find.text('猫'), findsOneWidget);
    expect(find.text('cat'), findsOneWidget);
    expect(find.byType(Image), findsNothing); // degraded, no crash
  });

  testWidgets(
      'lexeme encounter with a missing concept asset degrades gracefully, no crash',
      (tester) async {
    await tester.pumpWidget(_wrap(EncounterView(
      encounter: const LexemeEncounter(
        writtenForm: '猫',
        reading: 'ねこ',
        audioText: '猫',
        meaning: 'cat',
        conceptImagePath: 'assets/does_not_exist.webp',
      ),
      onDone: () {},
    )));
    await tester.pumpAndSettle();

    // errorBuilder swallows the missing-asset failure: no crash, and the
    // meaning text still renders.
    expect(find.text('cat'), findsOneWidget);
  });
}
