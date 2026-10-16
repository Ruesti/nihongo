import 'dart:async';

import 'package:nihongo_app/core/tts_queue.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_voice.dart';
import 'package:nihongo_app/features/cafe/voice_segments.dart';

/// Test-Sprachmotor: protokolliert Aufrufe als Strings
/// (`lang:de-DE`, `pitch:1.3`, `rate:0.6`, `voice:X`, `speak:T`, `stop`).
class FakeSpeechEngine implements SpeechEngine {
  final List<String> log = [];

  /// Sprachen, für die `setLanguage` true liefert.
  Set<String> languages = {'de-DE', 'ja-JP'};

  /// Stimmennamen je Sprachpräfix, z. B. `{'de': ['a', 'b']}`.
  Map<String, List<String>> voices = {};

  /// Wenn gesetzt, wartet `setPitch` auf den Completer.
  Completer<void>? Function()? holdPitch;

  /// Wenn gesetzt, wartet `speakAndWait` auf dieses Completer-Objekt.
  Completer<void> Function(String text)? hold;

  /// Texte, bei denen `speakAndWait` false liefert (angehalten/Fehler).
  Set<String> failing = {};

  @override
  Future<bool> setLanguage(String locale) async {
    log.add('lang:$locale');
    return languages.contains(locale);
  }

  @override
  Future<void> setPitch(double v) async {
    log.add('pitch:$v');
    final c = holdPitch?.call();
    if (c != null) await c.future;
  }

  @override
  Future<void> setRate(double v) async => log.add('rate:$v');

  @override
  Future<bool> speakAndWait(String text) async {
    log.add('speak:$text');
    final c = hold?.call(text);
    if (c != null) await c.future;
    return !failing.contains(text);
  }

  @override
  Future<void> stop() async => log.add('stop');

  /// Wenn gesetzt, laufen Aufträge wie im echten Dienst durch diese
  /// Warteschlange; sonst führt `exclusive` den Auftrag einfach aus.
  TtsQueue? queue;

  @override
  Future<T> exclusive<T>(Future<T> Function() job) =>
      queue?.run(job) ?? job();

  @override
  Future<void> setAwaitCompletion(bool on) async {}

  @override
  Future<List<String>> voiceNamesFor(String langPrefix) async =>
      voices[langPrefix] ?? const [];

  @override
  Future<void> setVoiceByName(String name) async => log.add('voice:$name');
}

/// Test-Quelle: Protokoll `stop` und `speak:[T|de,T|ja] gast`. Mit [sink]
/// landet jede Zeile zusätzlich als `line:<Zeile>` in einer gemeinsamen
/// Ereignisliste — im Moment des Einreihens (synchron beim Aufruf), wie der
/// Platz in der echten FIFO-Warteschlange (Reihenfolge Zeile ↔ Wortaudio).
class FakeVoiceSource implements VoiceSource {
  FakeVoiceSource({this.sink});

  final List<String> log = [];
  final List<String>? sink;
  bool german = true;
  bool throwOnSpeak = false;

  @override
  Future<void> speak(List<VoiceSegment> segments, GuestVoiceProfile profile,
      CafeGuest guest, {Future<bool> Function()? ready}) async {
    if (throwOnSpeak) throw StateError('boom');
    sink?.add('line:${segments.map((e) => e.text).join(' ')}');
    if (ready != null && !await ready()) return;
    if (!german) return;
    final s = segments.map((e) => '${e.text}|${e.lang.name}').join(',');
    log.add('speak:[$s] ${guest.name}');
  }

  @override
  Future<void> stop() async => log.add('stop');

  /// Wenn gesetzt, wartet `hasGerman` auf diesen Completer und liefert
  /// dessen Wert (statt [german]).
  Completer<bool>? germanGate;

  @override
  Future<bool> hasGerman() async {
    final g = germanGate;
    if (g != null) return g.future;
    return german;
  }
}
