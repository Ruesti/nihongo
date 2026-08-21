import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/journey/trace_practice.dart';
import 'package:nihongo_app/features/kanji_games/trace/kanji_svg_loader.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

void main() {
  testWidgets('degrades: a missing stroke asset resolves onDone immediately',
      (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TracePractice(
          assetPath: 'assets/kanji_svg/does_not_exist.svg',
          onDone: () => done = true,
        ),
      ),
    ));
    await tester.pump(); // FutureBuilder resolves (loader returns null)
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('renders a trace canvas for a bundled kana', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TracePractice(
          assetPath: 'assets/kanji_svg/3042.svg', // あ
          onDone: () {},
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
    // The canvas is present (CustomPaint with our painter).
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets(
      'completes: tracing every reference stroke fires onDone exactly once',
      (tester) async {
    final strokes = await KanjiSvgLoader.loadStrokes(
        'assets/kanji_svg/3042.svg',
        canvasSize: 300);
    expect(strokes, isNotNull);
    expect(strokes, isNotEmpty);

    var doneCount = 0;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TracePractice(
          assetPath: 'assets/kanji_svg/3042.svg',
          onDone: () => doneCount++,
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();

    // The GestureDetector's own box == the 300x300 canvas box (no padding of
    // its own), so its top-left is the origin that maps our 0..300 reference
    // points (same space KanjiSvgLoader sampled into) onto screen/global
    // coordinates for startGesture/moveTo (which operate in global space).
    final detectorFinder = find.byType(GestureDetector);
    expect(detectorFinder, findsOneWidget);
    final origin = tester.getTopLeft(detectorFinder);

    for (final stroke in strokes!) {
      final gesture = await tester.startGesture(origin + stroke.first);
      for (final p in stroke.skip(1)) {
        await gesture.moveTo(origin + p);
      }
      await gesture.up();
      await tester.pump();
    }

    expect(doneCount, 1);
  });
}
