import '../../core/stt_service.dart';

/// Scores a spoken attempt at [target], returning 0.0–1.0. An interface so the
/// diegetic speak sheet can be widget-tested with a fake (a real microphone is
/// unavailable in tests); the real implementation wraps [SttService].
abstract class SpeakEvaluator {
  Future<double> evaluate(String target);
}

/// Real evaluator: listens on the mic via [SttService] and scores the
/// recognised text against [target] with `SttService.similarity`. Not
/// unit-tested (needs a device mic); verified on-device.
class SttSpeakEvaluator implements SpeakEvaluator {
  final SttService stt;
  final String locale;

  SttSpeakEvaluator({SttService? stt, this.locale = 'ja_JP'})
      : stt = stt ?? SttService.instance;

  @override
  Future<double> evaluate(String target) async {
    final heard = await stt.listen(locale: locale);
    return SttService.similarity(heard, target);
  }
}
