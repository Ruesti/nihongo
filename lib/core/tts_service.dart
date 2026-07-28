import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  // OEM engines (e.g. Samsung's) often ship with only the device's system
  // language installed and mispronounce everything else instead of
  // failing. Google's engine covers far more languages, so prefer it
  // on Android when it's present.
  static const _preferredEngine = 'com.google.android.tts';

  // flutter_tts's Android backend multiplies this by 2.0 before calling
  // TextToSpeech.setSpeechRate(), so 0.5 here is native 1.0x (normal).
  static const _normalRate = 0.5;
  static const _slowRate = 0.33;

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _available = true;
  String _locale = 'ja-JP';

  Future<void> init({String locale = 'ja-JP'}) async {
    if (!_available) return;
    if (_initialized && _locale == locale) return;
    _locale = locale;
    try {
      await _preferGoogleEngine();
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(_normalRate);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _initialized = true;
      await _warnIfLanguageUnavailable(locale);
    } on MissingPluginException {
      _available = false;
    }
  }

  Future<void> _preferGoogleEngine() async {
    try {
      final engines = await _tts.getEngines;
      if (engines is List && engines.contains(_preferredEngine)) {
        await _tts.setEngine(_preferredEngine);
      }
    } catch (_) {
      // setEngine/getEngines are Android-only; ignore elsewhere.
    }
  }

  Future<void> _warnIfLanguageUnavailable(String locale) async {
    try {
      final available = await _tts.isLanguageAvailable(locale);
      if (available == false) {
        debugPrint(
            'TtsService: "$locale" has no installed voice data on this '
            'device — speech will mispronounce. Install it under system '
            'Settings > Text-to-speech output.');
      }
    } catch (_) {
      // Not all platforms implement language-availability checks.
    }
  }

  Future<void> speak(String text) async {
    if (!_available) return;
    if (!_initialized) await init(locale: _locale);
    if (!_available) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> speakSlow(String text) async {
    if (!_available) return;
    if (!_initialized) await init(locale: _locale);
    if (!_available) return;
    await _tts.stop();
    await _tts.setSpeechRate(_slowRate);
    await _tts.speak(text);
    await _tts.setSpeechRate(_normalRate);
  }

  Future<void> stop() async {
    if (!_available) return;
    await _tts.stop();
  }

  void setLocale(String locale) {
    _locale = locale;
    _initialized = false;
  }

  static final TtsService instance = TtsService();
}
