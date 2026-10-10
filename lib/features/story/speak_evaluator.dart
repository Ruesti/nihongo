import 'package:flutter/foundation.dart';

import '../../core/stt_service.dart';

/// Scores a spoken attempt at [target], returning 0.0–1.0, or a negative value
/// when nothing was heard (no recognizer, silence) — callers must not count
/// that as an attempt. [target] may list alternatives separated by `|` (e.g.
/// reading and kanji form, see [speakTarget]). An interface so the
/// diegetic speak sheet can be widget-tested with a fake (a real microphone is
/// unavailable in tests); the real implementation wraps [SttService].
abstract class SpeakEvaluator {
  Future<double> evaluate(String target);
}

/// Real evaluator: listens on the mic via [SttService] and scores the
/// recognised text against [target] with [bestSimilarity]. The listening
/// itself is not unit-tested (needs a device mic); verified on-device.
class SttSpeakEvaluator implements SpeakEvaluator {
  final SttService stt;
  final String locale;

  SttSpeakEvaluator({SttService? stt, this.locale = 'ja_JP'})
      : stt = stt ?? SttService.instance;

  /// Bester Treffer von [heard] gegen die `|`-getrennten Alternativen in
  /// [target]; `-1.0`, wenn nichts gehört wurde (`SttService.listen` liefert
  /// dann '' und wirft nie).
  static double bestSimilarity(String heard, String target) {
    if (heard.trim().isEmpty) return -1.0;
    var best = 0.0;
    for (final alt in target.split('|')) {
      if (alt.trim().isEmpty) continue;
      final s = SttService.similarity(heard, alt);
      if (s > best) best = s;
    }
    return best;
  }

  @override
  Future<double> evaluate(String target) async {
    final heard = await stt.listen(locale: locale);
    final score = bestSimilarity(heard, target);
    // Diagnose am Gerät: ohne dieses Log ist "Sprechen hatte keinen
    // Effekt" nicht von "nichts erkannt" unterscheidbar.
    debugPrint('SttSpeakEvaluator: gehört="$heard" soll="$target" '
        'score=${score.toStringAsFixed(2)}');
    return score;
  }
}

/// Zielangabe fürs Sprechen: Lesung, Schriftform und Oberfläche als
/// `|`-Alternativen, ohne Dubletten und leere Teile — so passt auch ein
/// Erkennungsergebnis in Kanji (駅 statt えき).
String speakTarget(String reading, String writtenForm, String surface) =>
    {reading, writtenForm, surface}
        .where((s) => s.trim().isNotEmpty)
        .join('|');
