import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/encounter.dart';
import 'package:nihongo_app/features/cafe/cafe_debrief.dart';
import 'package:nihongo_app/features/cafe/cafe_debrief_card.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

const _encounter = LexemeEncounter(
    writtenForm: 'ありがとう',
    reading: 'ありがとう',
    audioText: 'ありがとう',
    meaning: 'danke');

void main() {
  testWidgets('volle Karte: Wort, Bedeutung, Stelle in der Folge, Gebrauch, '
      'zwei Varianten, Verstanden', (tester) async {
    final panel = StoryPanel.fromJson({
      'index': 7,
      'asset': 'assets/story/p08.jpg',
      'bubbles': [],
      'thoughts': [],
      'interactions': [],
    });
    var done = false;
    await tester.pumpWidget(_wrap(DebriefCardView(
      content: DebriefCardContent(
        encounter: _encounter,
        firstPanel: panel,
        note: const DebriefNote(usage: '„danke".', variants: [
          DebriefVariant(
              form: 'ありがとうございます',
              reading: 'ありがとうございます',
              meaning: 'vielen Dank',
              note: 'höflicher'),
          DebriefVariant(form: 'どうも', reading: 'どうも', meaning: 'danke, kurz'),
        ]),
      ),
      onDone: () => done = true,
    )));
    await tester.pumpAndSettle();

    expect(find.text('ありがとう'), findsWidgets); // Form + Lesung
    expect(find.text('danke'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-usage')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-variant-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-variant-1')), findsOneWidget);
    expect(find.text('höflicher'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('ohne Folge und ohne Erklärungsblock: nur die Begegnung, kein '
      'Zusatz', (tester) async {
    await tester.pumpWidget(_wrap(DebriefCardView(
      content: const DebriefCardContent(encounter: _encounter),
      onDone: () {},
    )));
    await tester.pumpAndSettle();
    expect(find.text('ありがとう'), findsWidgets);
    expect(find.byKey(const ValueKey('cafe-debrief-panel')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-debrief-usage')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-debrief-variants-title')),
        findsNothing);
  });
}
