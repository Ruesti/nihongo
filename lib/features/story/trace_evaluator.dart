import 'package:flutter/widgets.dart';

import '../../data/kana_strokes.dart';
import '../kanji_games/trace/kanji_svg_loader.dart';

/// Judges a handwriting attempt at [target] (a short kana string), returning
/// whether it's an acceptable trace. An interface so [DiegeticTraceSheet] can
/// be widget-tested with a fake — the real evaluator loads stroke references
/// from bundled SVG assets, awkward in a widget test. Direct analogue of
/// P6a's `SpeakEvaluator`.
abstract class TraceEvaluator {
  Future<bool> evaluate(String target, List<List<Offset>> userStrokes);
}

/// Real evaluator: accepts when the reader drew at least the expected number
/// of strokes for [target]. The expected count is the real per-character
/// KanjiVG reference stroke count where a kana SVG is bundled
/// (`strokeAssetForKana`), and a minimum of 1 where it isn't (e.g. め today).
/// A deliberately honest "did you make a genuine attempt" bar — precise
/// per-stroke shape scoring (`StrokeValidator`) and bundling more kana SVGs
/// are noted upgrades, not this slice. Not unit-tested (needs bundled assets).
class KanaTraceEvaluator implements TraceEvaluator {
  const KanaTraceEvaluator();

  @override
  Future<bool> evaluate(String target, List<List<Offset>> userStrokes) async {
    if (userStrokes.isEmpty) return false;
    var expected = 0;
    for (final ch in target.split('')) {
      final asset = strokeAssetForKana(ch);
      if (asset == null) {
        expected += 1;
        continue;
      }
      final ref = await KanjiSvgLoader.loadStrokes(asset);
      expected += (ref == null || ref.isEmpty) ? 1 : ref.length;
    }
    return userStrokes.length >= expected;
  }
}
