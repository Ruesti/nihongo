import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  String _locale = 'ja-JP';

  Future<void> init({String locale = 'ja-JP'}) async {
    if (_initialized && _locale == locale) return;
    _locale = locale;
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(0.8);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (!_initialized) await init(locale: _locale);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> speakSlow(String text) async {
    if (!_initialized) await init(locale: _locale);
    await _tts.stop();
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
    await _tts.setSpeechRate(0.8);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  void setLocale(String locale) {
    _locale = locale;
    _initialized = false;
  }

  static final TtsService instance = TtsService();
}
