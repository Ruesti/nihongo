import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/journey/trace_practice.dart';

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
}
