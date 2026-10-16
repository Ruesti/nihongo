import 'package:shared_preferences/shared_preferences.dart';

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

  /// Spricht den Text und kehrt erst nach dem Ende der Ausgabe zurück.
  Future<void> speakAndWait(String text);
  Future<void> stop();

  /// Namen der installierten Stimmen, deren Sprache mit [langPrefix] beginnt.
  Future<List<String>> voiceNamesFor(String langPrefix);
  Future<void> setVoiceByName(String name);
}

/// Quelle der Gästestimme (heute: Gerätestimme).
abstract class VoiceSource {
  Future<void> speak(
    List<VoiceSegment> segments,
    GuestVoiceProfile profile,
    CafeGuest guest,
  );
  Future<void> stop();

  /// Ob eine deutsche Stimme zur Verfügung steht.
  Future<bool> hasGerman();
}

/// Spricht die Stücke nacheinander über die Gerätestimme.
class DeviceTtsSource implements VoiceSource {
  DeviceTtsSource(this._engine);

  final SpeechEngine _engine;
  int _run = 0;
  bool _speaking = false;
  bool? _german;

  @override
  Future<bool> hasGerman() async => _german ??=
      await _engine.setLanguage('de-DE') &&
      (await _engine.voiceNamesFor('de')).isNotEmpty;

  @override
  Future<void> stop() async {
    _run++;
    _speaking = false;
    await _engine.stop();
  }

  @override
  Future<void> speak(
    List<VoiceSegment> segments,
    GuestVoiceProfile profile,
    CafeGuest guest,
  ) async {
    final run = ++_run;
    // Läuft noch eine ältere Ausgabe, wird sie hart unterbrochen.
    if (_speaking) await _engine.stop();
    if (run != _run) return;
    _speaking = true;
    try {
      final germanVoice = await _germanVoiceFor(guest);
      for (final seg in segments) {
        if (run != _run) return;
        final de = seg.lang == VoiceLang.de;
        await _engine.setLanguage(de ? 'de-DE' : 'ja-JP');
        if (de && germanVoice != null) {
          await _engine.setVoiceByName(germanVoice);
        }
        await _engine.setPitch(profile.pitch);
        await _engine.setRate(profile.rate);
        await _engine.speakAndWait(seg.text);
      }
    } finally {
      if (run == _run) _speaking = false;
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

  Future<void> say(CafeGuest guest, String line) async {
    final source = _source;
    if (source == null || !await _isEnabled!()) return;
    if (!await source.hasGerman()) return;
    final segments = splitSegments(line);
    if (segments.isEmpty) return;
    await source.stop();
    await source.speak(segments, profileFor(guest), guest);
  }

  Future<void> stop() async => _source?.stop();
}
