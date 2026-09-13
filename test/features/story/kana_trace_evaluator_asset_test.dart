import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/trace_evaluator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<List<Offset>> strokes(int n) => List.generate(
      n, (_) => [const Offset(0, 0), const Offset(10, 10)]);

  test('あ nutzt das gebuendelte SVG: erst die volle Strichzahl genuegt',
      () async {
    const evaluator = KanaTraceEvaluator();
    // Erwartete Strichzahl = Anzahl der <path>-Elemente in
    // assets/kanji_svg/3042.svg (KanjiVG: あ hat 3 Striche). Weicht das
    // SVG ab, gilt das SVG — Zahl hier anpassen und im Commit begruenden.
    expect(await evaluator.evaluate('あ', strokes(3)), isTrue);
    expect(await evaluator.evaluate('あ', strokes(2)), isFalse);
  });

  test('め ist nicht gebuendelt und faellt ehrlich auf Minimum 1 zurueck',
      () async {
    const evaluator = KanaTraceEvaluator();
    expect(await evaluator.evaluate('め', strokes(1)), isTrue);
  });
}
