import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/tts_queue.dart';
import '../../core/tts_service.dart';
import 'cafe_occupancy.dart';
import 'voice_segments.dart';

/// Stimmprofil eines Café-Gasts (Tonhöhe und Sprechtempo für die Sprachausgabe).
class GuestVoiceProfile {
  const GuestVoiceProfile({required this.pitch, required this.rate});

  final double pitch;
  final double rate;

  @override
  bool operator ==(Object other) =>
      other is GuestVoiceProfile && other.pitch == pitch && other.rate == rate;

  @override
  int get hashCode => Object.hash(pitch, rate);

  @override
  String toString() => 'GuestVoiceProfile(pitch: $pitch, rate: $rate)';
}

/// Das Stimmprofil des jeweiligen Gasts.
GuestVoiceProfile profileFor(CafeGuest g) => switch (g) {
  CafeGuest.wirtin => const GuestVoiceProfile(pitch: 1.0, rate: 0.5),
  CafeGuest.schulkind => const GuestVoiceProfile(pitch: 1.3, rate: 0.6),
  CafeGuest.vielredner => const GuestVoiceProfile(pitch: 0.8, rate: 0.4),
  CafeGuest.gleichaltrige => const GuestVoiceProfile(pitch: 1.1, rate: 0.5),
};

/// Sprachmotor des Geräts (von `TtsService` umgesetzt).
abstract class SpeechEngine {
  /// Stellt die Sprache ein; true, wenn sie verfügbar ist.
  Future<bool> setLanguage(String locale);
  Future<void> setPitch(double v);
  Future<void> setRate(double v);

  /// Spricht den Text und kehrt erst nach dem Ende der Ausgabe zurück
  /// (setzt [setAwaitCompletion] mit true voraus).
  Future<void> speakAndWait(String text);

  /// Ob `speak` bis zum Ende der Ausgabe wartet (dauerhafte Einstellung).
  Future<void> setAwaitCompletion(bool on);

  /// Hält alles an: laufende Ausgabe und wartende Aufträge.
  Future<void> stop();

  /// Führt [job] exklusiv aus: Aufträge laufen nacheinander (FIFO) und
  /// teilen sich den einen Sprachmotor nie gleichzeitig.
  Future<T> exclusive<T>(Future<T> Function() job);

  /// Namen der installierten Stimmen, deren Sprache mit [langPrefix] beginnt.
  Future<List<String>> voiceNamesFor(String langPrefix);
  Future<void> setVoiceByName(String name);
}

/// Quelle der Gästestimme (heute: Gerätestimme).
abstract class VoiceSource {
  /// Reiht die Zeile sofort (synchron beim Aufruf) in die Warteschlange ein.
  /// Kommt sie dran, wird zuerst [ready] gefragt (z. B. „noch eingeschaltet,
  /// noch die jüngste Zeile?") und ob Deutsch da ist; sonst entfällt sie.
  Future<void> speak(
    List<VoiceSegment> segments,
    GuestVoiceProfile profile,
    CafeGuest guest, {
    Future<bool> Function()? ready,
  });
  Future<void> stop();

  /// Ob eine deutsche Stimme zur Verfügung steht.
  Future<bool> hasGerman();
}

/// Spricht die Stücke nacheinander über die Gerätestimme — eine Zeile ist
/// ein Auftrag in der Warteschlange des Sprachmotors (nach einem laufenden
/// Wort, vor später angefragtem Wortaudio).
class DeviceTtsSource implements VoiceSource {
  DeviceTtsSource(this._engine);

  final SpeechEngine _engine;
  int _run = 0;
  bool _german = false; // nur ein „ja" wird gemerkt

  /// Prüft in der Warteschlange (setLanguage darf kein laufendes Wort
  /// umstellen); ein „nein" wird beim nächsten Mal neu geprüft.
  @override
  Future<bool> hasGerman() async {
    if (_german) return true;
    try {
      return await _engine.exclusive(_probeGerman);
    } on TtsJobCancelled {
      return false;
    }
  }

  /// Die eigentliche Prüfung; nur innerhalb eines Auftrags aufrufen.
  Future<bool> _probeGerman() async {
    if (_german) return true;
    _german = await _engine.setLanguage('de-DE') &&
        (await _engine.voiceNamesFor('de')).isNotEmpty;
    return _german;
  }

  /// Hart anhalten: laufendes Stück abbrechen, wartende Zeilen verwerfen.
  @override
  Future<void> stop() async {
    _run++;
    await _engine.stop();
  }

  /// Eine neuere Zeile hält die ältere nicht hart an: das laufende Stück
  /// spricht zu Ende, ihre noch nicht begonnenen Stücke entfallen.
  @override
  Future<void> speak(
    List<VoiceSegment> segments,
    GuestVoiceProfile profile,
    CafeGuest guest, {
    Future<bool> Function()? ready,
  }) async {
    final run = ++_run;
    try {
      await _engine.exclusive(() async {
        if (run != _run) return;
        if (ready != null && !await ready()) return;
        if (run != _run) return;
        if (!await _probeGerman()) return;
        if (run != _run) return;
        await _engine.setAwaitCompletion(true);
        try {
          final germanVoice = await _germanVoiceFor(guest);
          for (final seg in segments) {
            if (run != _run) return;
            final de = seg.lang == VoiceLang.de;
            await _engine.setLanguage(de ? 'de-DE' : 'ja-JP');
            if (run != _run) return;
            if (de && germanVoice != null) {
              await _engine.setVoiceByName(germanVoice);
              if (run != _run) return;
            }
            await _engine.setPitch(profile.pitch);
            if (run != _run) return;
            await _engine.setRate(profile.rate);
            if (run != _run) return;
            await _engine.speakAndWait(seg.text);
          }
        } finally {
          await _engine.setAwaitCompletion(false);
        }
      });
    } on TtsJobCancelled {
      // vor dem Start verworfen (stop): nichts zu tun
    }
  }

  /// Wählt bei mindestens zwei deutschen Stimmen eine feste je Gast.
  Future<String?> _germanVoiceFor(CafeGuest guest) async {
    final names = await _engine.voiceNamesFor('de');
    if (names.length < 2) return null;
    if (guest != CafeGuest.vielredner) return names.first;
    for (final n in names) {
      final l = n.toLowerCase();
      if ((l.contains('male') || l.contains('männlich')) &&
          !l.contains('female')) {
        return n;
      }
    }
    return names[1];
  }
}

/// Einstellung: Gästestimme an oder aus (Standard: an).
class CafeVoicePrefs {
  static const key = 'cafe_voice_enabled';

  Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? true;

  Future<void> setEnabled(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(key, v);
}

/// Fassade für die Stationen: eine Zeile eines Gasts laut sprechen.
class CafeVoice {
  const CafeVoice({
    required VoiceSource source,
    required Future<bool> Function() isEnabled,
  })  : _source = source,
        _isEnabled = isEnabled;

  /// Spricht nie; `say` und `stop` tun nichts.
  const CafeVoice.silent()
      : _source = null,
        _isEnabled = null;

  final VoiceSource? _source;
  final Future<bool> Function()? _isEnabled;

  /// true bei [CafeVoice.silent] (dann gibt es auch keinen Lautsprecher).
  bool get isSilent => _source == null;

  // Expando statt Feld, damit die Konstruktoren const bleiben können.
  static final _ids = Expando<int>('CafeVoice.current');
  int get _current => _ids[this] ?? 0;
  set _current(int v) => _ids[this] = v;

  /// Nummer der zuletzt begonnenen Zeile. Sie steht schon fest, sobald [say]
  /// aufgerufen wurde (vor dem ersten Warten), und gehört dem Aufrufer.
  int get currentId => _current;

  /// Spricht die Zeile und liefert deren Nummer (0 bei stumm). Die Zeile
  /// steht schon beim Aufruf (synchron) in der Warteschlange — Wortaudio, das
  /// danach angefragt wird, kommt nach ihr. Eine laufende ältere Zeile wird
  /// nicht hart angehalten (siehe [DeviceTtsSource.speak]); [stop] dagegen
  /// verhindert auch den Start einer Zeile, die noch wartet.
  Future<int> say(CafeGuest guest, String line) async {
    final source = _source;
    if (source == null) return 0;
    final id = ++_current;
    try {
      final segments = splitSegments(line);
      if (segments.isEmpty) return id;
      // Nach jedem Warten neu prüfen: ein stop() dazwischen gewinnt.
      Future<bool> ready() async {
        if (id != _current) return false;
        if (!await _isEnabled!()) return false;
        return id == _current;
      }

      await source.speak(segments, profileFor(guest), guest, ready: ready);
    } catch (e) {
      debugPrint('CafeVoice.say: $e'); // Stimme ist nur Zierde
    }
    return id;
  }

  /// Ob die Stimme gerade spricht, wenn man sie lässt: eingeschaltet und
  /// eine deutsche Stimme vorhanden. Stumm → false.
  Future<bool> isActive() async {
    final source = _source;
    if (source == null) return false;
    try {
      return await _isEnabled!() && await source.hasGerman();
    } catch (e) {
      debugPrint('CafeVoice.isActive: $e');
      return false;
    }
  }

  /// Stoppt nur, wenn die Zeile [id] noch die jüngste ist; sonst gehört die
  /// Ausgabe schon jemand anderem und läuft weiter.
  Future<void> stopIf(int id) async {
    if (id == _current) await stop();
  }

  /// Hält hart an (vor dem Mikro, beim Schließen, beim Ausschalten): auch
  /// eine Zeile, die noch nicht begonnen hat, entfällt.
  Future<void> stop() async {
    final source = _source;
    if (source == null) return;
    _current = _current + 1;
    try {
      await source.stop();
    } catch (e) {
      debugPrint('CafeVoice.stop: $e');
    }
  }
}

/// Die Gästestimme der App: einmal gebaut, von allen Besuchen geteilt.
final cafeVoiceProvider = Provider<CafeVoice>((ref) => CafeVoice(
      source: DeviceTtsSource(TtsService.instance),
      isEnabled: CafeVoicePrefs().isEnabled,
    ));
