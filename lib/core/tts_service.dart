import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../features/cafe/cafe_voice.dart';
import 'tts_queue.dart';

/// Der eine Sprachmotor der App. Alles, was spricht (Wortaudio und
/// Gästestimme), läuft über eine Warteschlange ([exclusive]) — nacheinander,
/// nie verschränkt; jeder Auftrag stellt seine Einstellungen selbst her.
class TtsService implements SpeechEngine {
  final FlutterTts _tts = FlutterTts();
  final TtsQueue _queue = TtsQueue();
  bool _available = true;
  String _locale = 'ja-JP';

  /// Gewählte Stimme je Locale (einmal nachgeschlagen; null = keine da).
  final Map<String, Map<String, String>?> _voiceFor = {};

  /// Läuft gerade ein Wort-Auftrag (speak/speakSlow)?
  bool _wordRunning = false;

  /// Zählt harte Stopps ([stop]); ein Wort, in dessen Lauf einer fiel, gilt
  /// als abgebrochen.
  int _stops = 0;

  bool _errorHandlerSet = false;

  Future<void> init({String locale = 'ja-JP'}) async {
    if (!_available) return;
    _locale = locale;
    try {
      // Meldet der Motor einen Fehler (Netzstimme offline, Sprachdaten
      // fehlen), beendet nur stop() das wartende speak — sonst hinge die
      // Warteschlange für immer.
      if (!_errorHandlerSet) {
        _errorHandlerSet = true;
        _tts.setErrorHandler((_) {
          _tts.stop().catchError((Object _) {});
        });
      }
      await _applyDefaults(rate: 0.5);
    } on MissingPluginException {
      _available = false;
    }
  }

  /// Stellt Sprache, Stimme, Tempo und Tonhöhe der Lern-Locale her — ohne
  /// sich auf einen früheren Zustand zu verlassen (das Café ändert sie).
  Future<void> _applyDefaults({required double rate}) async {
    final locale = _locale;
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
    if (!_voiceFor.containsKey(locale)) {
      final voices = await _tts.getVoices;
      final wanted = locale.split('-').first;
      final matching = (voices is List ? voices : const [])
          .whereType<Map>()
          .where((v) => v['locale'].toString().startsWith(wanted))
          .toList();
      debugPrint('TtsService: ${matching.length} Stimmen für $wanted: '
          '${matching.take(3).map((v) => v['name']).toList()}');
      if (matching.isEmpty) {
        debugPrint('TtsService: KEINE $wanted-Stimme installiert — '
            'Sprachdaten der TTS-Engine fehlen auf dem Gerät.');
      }
      _voiceFor[locale] = matching.isEmpty
          ? null
          : {
              'name': matching.first['name'].toString(),
              'locale': matching.first['locale'].toString(),
            };
    }
    final voice = _voiceFor[locale];
    if (voice != null) await _tts.setVoice(voice);
    // In flutter_tts ist auf Android 0.5 die NORMALE Geschwindigkeit
    // (0.0–1.0 wird auf 0–2x gemappt). 0.8 war ~1.6x und klang gehetzt.
    await _tts.setSpeechRate(rate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  /// Spricht ein Wort; true, wenn es zu Ende gesprochen wurde — false, wenn
  /// es verworfen, angehalten, abgeschnitten oder nicht hörbar war.
  Future<bool> speak(String text) => _speakWord(text, rate: 0.5);

  /// Wie [speak], nur langsam.
  Future<bool> speakSlow(String text) => _speakWord(text, rate: 0.3);

  /// Spricht [text] (awaitSpeakCompletion muss an sein) und wartet auf das
  /// Ende — höchstens [ttsTimeoutFor]; danach wird hart angehalten. true nur,
  /// wenn der Motor das Ende meldet (stop() liefert 0).
  Future<bool> _speakTimed(String text) async {
    try {
      final r = await _tts.speak(text).timeout(ttsTimeoutFor(text));
      return r != 0;
    } on TimeoutException {
      debugPrint('TtsService: speak hängt — angehalten.');
      try {
        await _tts.stop();
      } catch (_) {}
      return false;
    }
  }

  /// Ein Wort als eigener Auftrag der Warteschlange: wartet, bis eine
  /// laufende Café-Zeile fertig ist, und wird von ihr nie abgeschnitten.
  /// Ein neues Wort schneidet ein noch laufendes Wort ab (Antippen).
  Future<bool> _speakWord(String text, {required double rate}) async {
    if (!_available) return false;
    final stops = _stops;
    if (_wordRunning) {
      try {
        await _tts.stop();
      } on MissingPluginException {
        _available = false;
        return false;
      }
    }
    try {
      final done = await _queue.run(() async {
        if (!_available) return false;
        _wordRunning = true;
        try {
          await _applyDefaults(rate: rate);
          await _tts.awaitSpeakCompletion(true);
          try {
            return await _speakTimed(text);
          } finally {
            await _tts.awaitSpeakCompletion(false);
          }
        } on MissingPluginException {
          _available = false;
          return false;
        } finally {
          _wordRunning = false;
        }
      });
      return done && stops == _stops;
    } on TtsJobCancelled {
      // vor dem Start abgebrochen (stop): nichts sprechen
      return false;
    }
  }

  @override
  Future<T> exclusive<T>(Future<T> Function() job) => _queue.run(job);

  /// Hält alles an: die laufende Ausgabe und alle wartenden Aufträge.
  @override
  Future<void> stop() async {
    _stops++;
    _queue.cancelPending();
    if (!_available) return;
    try {
      await _tts.stop();
    } on MissingPluginException {
      _available = false;
    }
  }

  void setLocale(String locale) {
    _locale = locale;
  }

  @override
  Future<bool> setLanguage(String locale) async {
    if (!_available) return false;
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
    await _tts.setPitch(v);
  }

  @override
  Future<void> setRate(double v) async {
    if (!_available) return;
    await _tts.setSpeechRate(v);
  }

  @override
  Future<void> setAwaitCompletion(bool on) async {
    if (!_available) return;
    await _tts.awaitSpeakCompletion(on);
  }

  /// Spricht und wartet auf das Ende — vorausgesetzt, der Auftrag hat
  /// [setAwaitCompletion] mit true gesetzt (die Café-Zeile tut das einmal).
  /// false, wenn angehalten, fehlgeschlagen oder hängend (Zeitlimit).
  @override
  Future<bool> speakAndWait(String text) async {
    if (!_available) return false;
    return _speakTimed(text);
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
