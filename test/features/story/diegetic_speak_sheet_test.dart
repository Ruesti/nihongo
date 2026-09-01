import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/diegetic_speak_sheet.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';

class _FakeEvaluator implements SpeakEvaluator {
  final double score;
  int calls = 0;
  _FakeEvaluator(this.score);
  @override
  Future<double> evaluate(String target) async {
    calls++;
    return score;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required SpeakEvaluator evaluator,
  required void Function() onSuccess,
  required void Function() onSkip,
  List<String>? spoken,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: DiegeticSpeakSheet(
        targetText: 'すみません',
        evaluator: evaluator,
        speak: (t) async => spoken?.add(t),
        onSuccess: onSuccess,
        onSkip: onSkip,
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('a good attempt shows success and fires onSuccess once',
      (tester) async {
    var successes = 0;
    final evaluator = _FakeEvaluator(0.9);
    await _pump(tester,
        evaluator: evaluator, onSuccess: () => successes++, onSkip: () {});

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pumpAndSettle();

    expect(successes, 1);
    // A second mic tap after success does not re-fire.
    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pumpAndSettle();
    expect(successes, 1);
  });

  testWidgets('a poor attempt does not fire onSuccess; skip fires onSkip',
      (tester) async {
    var successes = 0;
    var skips = 0;
    await _pump(tester,
        evaluator: _FakeEvaluator(0.1),
        onSuccess: () => successes++,
        onSkip: () => skips++);

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pumpAndSettle();
    expect(successes, 0);
    expect(find.byKey(const ValueKey('diegetic-speak-feedback')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-skip')));
    await tester.pumpAndSettle();
    expect(skips, 1);
  });

  testWidgets('the listen button plays the target text via TTS',
      (tester) async {
    final spoken = <String>[];
    await _pump(tester,
        evaluator: _FakeEvaluator(0.0),
        onSuccess: () {},
        onSkip: () {},
        spoken: spoken);

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-listen')));
    await tester.pumpAndSettle();
    expect(spoken, ['すみません']);
  });
}
