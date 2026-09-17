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

StoryPanel _panel(int index) => StoryPanel.fromJson({
      'index': index,
      'asset': 'assets/story/p0$index.jpg',
      'bubbles': [],
      'thoughts': [],
      'interactions': [],
    });

void main() {
  testWidgets('volle Karte: Wort, Bedeutung, Stelle in der Folge, Gebrauch, '
      'zwei Varianten, Verstanden', (tester) async {
    var done = false;
    await tester.pumpWidget(_wrap(DebriefCardView(
      content: DebriefCardContent(
        encounter: _encounter,
        firstPanel: _panel(7),
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

  testWidgets('Verstanden bleibt sichtbar, auch wenn die Karte länger wird '
      'als der Schirm', (tester) async {
    // Telefon-Fläche statt der großzügigen Test-Vorgabe, dazu ein
    // Erklärungsblock im Zuschnitt der echten Folge 01 (langer Gebrauch, zwei
    // Varianten mit Notiz): erst so wird die Karte länger als der Schirm —
    // genau der Fall, in dem der Knopf früher unter der Falz lag.
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var done = false;
    await tester.pumpWidget(_wrap(DebriefCardView(
      content: DebriefCardContent(
        encounter: _encounter,
        firstPanel: _panel(3),
        note: const DebriefNote(
          usage: '„Entschuldigung" — aber genauso „Hallo, darf ich mal?". '
              'Mira benutzt es, um jemanden anzusprechen, nicht nur zum '
              'Entschuldigen.',
          variants: [
            DebriefVariant(
                form: 'ごめんなさい',
                reading: 'ごめんなさい',
                meaning: 'tut mir leid',
                note: 'persönlicher, für eigene Fehler'),
            DebriefVariant(
                form: 'すみませんでした',
                reading: 'すみませんでした',
                meaning: 'Entschuldigung',
                note: 'für etwas, das schon passiert ist'),
          ],
        ),
      ),
      onDone: () => done = true,
    )));
    await tester.pumpAndSettle();

    // Die Karte ist tatsächlich länger als der Schirm — sonst prüft der Test
    // darunter gar nichts.
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scroll.position.maxScrollExtent, greaterThan(0));

    // Ohne ensureVisible: der Knopf steht als Fußzeile von selbst im Bild.
    final button = find.byKey(const ValueKey('encounter-next'));
    expect(button.hitTestable(), findsOneWidget);
    expect(
        tester.getRect(button).bottom,
        lessThanOrEqualTo(
            tester.view.physicalSize.height / tester.view.devicePixelRatio));
    await tester.tap(button);
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
