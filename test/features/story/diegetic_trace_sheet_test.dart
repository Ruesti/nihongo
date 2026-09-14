import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/diegetic_speak_sheet.dart'
    show kDiegeticSuccessAutoClose;
import 'package:nihongo_app/features/story/diegetic_trace_sheet.dart';
import 'package:nihongo_app/features/story/trace_evaluator.dart';

class _FakeTraceEvaluator implements TraceEvaluator {
  final bool ok;
  int calls = 0;
  _FakeTraceEvaluator(this.ok);
  @override
  Future<bool> evaluate(String target, List<List<Offset>> userStrokes) async {
    calls++;
    return ok;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required TraceEvaluator evaluator,
  required void Function() onSuccess,
  required void Function() onSkip,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: DiegeticTraceSheet(
        targetText: 'あめ',
        evaluator: evaluator,
        onSuccess: onSuccess,
        onSkip: onSkip,
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('an accepted trace shows success and fires onSuccess once',
      (tester) async {
    var successes = 0;
    await _pump(tester,
        evaluator: _FakeTraceEvaluator(true),
        onSuccess: () => successes++,
        onSkip: () {});

    // Draw a stroke on the canvas, then submit.
    await tester.drag(
        find.byKey(const ValueKey('diegetic-trace-canvas')), const Offset(60, 40));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('diegetic-trace-done')));
    await tester.pumpAndSettle();

    expect(successes, 1);
    expect(find.byKey(const ValueKey('diegetic-trace-feedback')), findsOneWidget);

    // A second submit after success does not re-fire.
    await tester.tap(find.byKey(const ValueKey('diegetic-trace-done')));
    await tester.pumpAndSettle();
    expect(successes, 1);

    // Flush the auto-close timer so it doesn't leak past this test.
    await tester.pump(kDiegeticSuccessAutoClose);
  });

  testWidgets('bei Erfolg schliesst sich das Sheet nach kurzer Pause von selbst',
      (tester) async {
    var skipped = 0;
    await _pump(tester,
        evaluator: _FakeTraceEvaluator(true),
        onSuccess: () {},
        onSkip: () => skipped++);

    await tester.drag(find.byKey(const ValueKey('diegetic-trace-canvas')),
        const Offset(60, 40));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('diegetic-trace-done')));
    await tester.pump();
    expect(find.text('Gut! ✓'), findsOneWidget);
    expect(skipped, 0); // noch offen — das ✓ soll ankommen
    await tester.pump(const Duration(milliseconds: 950));
    expect(skipped, 1); // Auto-Close hat onSkip gerufen
  });

  testWidgets('the canvas shows a ghost template of the target character',
      (tester) async {
    await _pump(tester,
        evaluator: _FakeTraceEvaluator(true), onSuccess: () {}, onSkip: () {});

    expect(find.byKey(const ValueKey('diegetic-trace-ghost')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('diegetic-trace-ghost')),
            matching: find.text('あめ')),
        findsOneWidget);
  });

  testWidgets('a rejected trace does not fire onSuccess; skip fires onSkip',
      (tester) async {
    var successes = 0;
    var skips = 0;
    await _pump(tester,
        evaluator: _FakeTraceEvaluator(false),
        onSuccess: () => successes++,
        onSkip: () => skips++);

    await tester.tap(find.byKey(const ValueKey('diegetic-trace-done')));
    await tester.pumpAndSettle();
    expect(successes, 0);
    expect(find.byKey(const ValueKey('diegetic-trace-feedback')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('diegetic-trace-skip')));
    await tester.pumpAndSettle();
    expect(skips, 1);
  });
}
