import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../features/cafe/cafe_voice.dart';

class TtsService implements SpeechEngine {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _available = true;
  String _locale = 'ja-JP';

  Future<void> init({String locale = 'ja-JP'}) async {
    if (!_available) return;
    if (_initialized && _locale == locale) return;
    _locale = locale;
    try {
      // flutter_tts: Rückgabe 1 = ok. Ein Fehlschlag heißt: keine Stimme
      // für diese Sprache — dann liest eine Fallback-Stimme den Text falsch
      // vor. Das darf nicht stumm bleiben.
      final langResult = await _tts.setLanguage(locale);
      if (langResult != 1) {
        debugPrint('TtsService: setLanguage($locale) fehlgeschlagen '
            '($langResult) — es spricht eine Fallback-Stimme.');
      }
      // setLanguage(ok) heißt nur "Sprache bekannt" — nicht, dass eine
      // Stimme samt Sprachdaten wirklich da ist. Deshalb: explizit eine
      // Stimme der Ziel-Locale wählen und loggen, was verfügbar ist.
      final voices = await _tts.getVoices;
      final wanted = locale.split('-').first;
      final matching = (voices as List)
          .whereType<Map>()
          .where((v) => v['locale'].toString().startsWith(wanted))
          .toList();
      debugPrint('TtsService: ${matching.length} Stimmen für $wanted: '
          '${matching.take(3).map((v) => v['name']).toList()}');
      if (matching.isNotEmpty) {
        final v = matching.first;
        await _tts.setVoice({
          'name': v['name'].toString(),
          'locale': v['locale'].toString(),
        });
      } else {
        debugPrint('TtsService: KEINE $wanted-Stimme installiert — '
            'Sprachdaten der TTS-Engine fehlen auf dem Gerät.');
      }
      // In flutter_tts ist auf Android 0.5 die NORMALE Geschwindigkeit
      // (0.0–1.0 wird auf 0–2x gemappt). 0.8 war ~1.6x und klang gehetzt.
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _initialized = true;
    } on MissingPluginException {
      _available = false;
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
    await _tts.setSpeechRate(0.3);
    await _tts.speak(text);
    await _tts.setSpeechRate(0.5);
  }

  @override
  Future<void> stop() async {
    if (!_available) return;
    await _tts.stop();
  }

  void setLocale(String locale) {
    _locale = locale;
    _initialized = false;
  }

  @override
  Future<bool> setLanguage(String locale) async {
    if (!_available) return false;
    _initialized = false; // Café ändert Einstellungen: nächstes speak() stellt sie her
    try {
      final r = await _tts.setLanguage(locale);
      if (r != 1) return false;
      final avail = await _tts.isLanguageAvailable(locale);
      return avail == true || avail == 1;
    } on MissingPluginException {
      _available = false;
      return false;
    }
  }

  @override
  Future<void> setPitch(double v) async {
    if (!_available) return;
    _initialized = false;
    await _tts.setPitch(v);
  }

  @override
  Future<void> setRate(double v) async {
    if (!_available) return;
    _initialized = false;
    await _tts.setSpeechRate(v);
  }

  @override
  Future<void> speakAndWait(String text) async {
    if (!_available) return;
    // Das Warte-Flag ist eine dauerhafte Plugin-Einstellung: nur um diesen
    // Aufruf setzen, damit speak()/speakSlow() nicht blockierend werden.
    await _tts.awaitSpeakCompletion(true);
    try {
      await _tts.speak(text);
    } finally {
      await _tts.awaitSpeakCompletion(false);
    }
  }

  @override
  Future<List<String>> voiceNamesFor(String langPrefix) async {
    if (!_available) return const [];
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return const [];
      return voices
          .whereType<Map>()
          .where((v) => v['locale'].toString().startsWith(langPrefix))
          .map((v) => v['name'].toString())
          .toList();
    } on MissingPluginException {
      _available = false;
      return const [];
    }
  }

  @override
  Future<void> setVoiceByName(String name) async {
    if (!_available) return;
    _initialized = false;
    final voices = await _tts.getVoices;
    if (voices is! List) return;
    for (final v in voices.whereType<Map>()) {
      if (v['name'].toString() == name) {
        await _tts.setVoice({
          'name': name,
          'locale': v['locale'].toString(),
        });
        return;
      }
    }
  }

  static final TtsService instance = TtsService();
}
