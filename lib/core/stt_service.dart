import 'package:speech_to_text/speech_to_text.dart';

class SttService {
  final SpeechToText _stt = SpeechToText();
  bool _available = false;

  Future<bool> init() async {
    _available = await _stt.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );
    return _available;
  }

  bool get isAvailable => _available;
  bool get isListening => _stt.isListening;

  Future<String> listen({String locale = 'ja_JP', int seconds = 5}) async {
    if (!_available) {
      final ok = await init();
      if (!ok) return '';
    }
    String result = '';
    await _stt.listen(
      localeId: locale,
      onResult: (r) {
        if (r.finalResult) result = r.recognizedWords;
      },
      listenFor: Duration(seconds: seconds),
      pauseFor: const Duration(seconds: 3),
    );
    await Future.delayed(Duration(seconds: seconds + 1));
    await _stt.stop();
    return result;
  }

  Future<void> stop() async {
    if (_stt.isListening) await _stt.stop();
  }

  // Bewertet ob erkannter Text dem Solltext entspricht (0.0 – 1.0)
  static double similarity(String recognized, String target) {
    if (recognized.isEmpty || target.isEmpty) return 0.0;
    final r = recognized.toLowerCase().trim();
    final t = target.toLowerCase().trim();
    if (r == t) return 1.0;
    if (t.contains(r) || r.contains(t)) return 0.8;
    // Einfacher Zeichenüberlapp
    final rChars = r.split('').toSet();
    final tChars = t.split('').toSet();
    final common = rChars.intersection(tChars).length;
    return common / tChars.length.clamp(1, 999);
  }

  static final SttService instance = SttService();
}
