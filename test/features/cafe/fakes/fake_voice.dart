import 'dart:async';

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

  /// Wenn gesetzt, wartet `speakAndWait` auf dieses Completer-Objekt.
  Completer<void> Function(String text)? hold;

  @override
  Future<bool> setLanguage(String locale) async {
    log.add('lang:$locale');
    return languages.contains(locale);
  }

  @override
  Future<void> setPitch(double v) async => log.add('pitch:$v');

  @override
  Future<void> setRate(double v) async => log.add('rate:$v');

  @override
  Future<void> speakAndWait(String text) async {
    log.add('speak:$text');
    final c = hold?.call(text);
    if (c != null) await c.future;
  }

  @override
  Future<void> stop() async => log.add('stop');

  @override
  Future<List<String>> voiceNamesFor(String langPrefix) async =>
      voices[langPrefix] ?? const [];

  @override
  Future<void> setVoiceByName(String name) async => log.add('voice:$name');
}

/// Test-Quelle: Protokoll `stop` und `speak:[T|de,T|ja] gast`.
class FakeVoiceSource implements VoiceSource {
  final List<String> log = [];
  bool german = true;

  @override
  Future<void> speak(List<VoiceSegment> segments, GuestVoiceProfile profile,
      CafeGuest guest) async {
    final s = segments.map((e) => '${e.text}|${e.lang.name}').join(',');
    log.add('speak:[$s] ${guest.name}');
  }

  @override
  Future<void> stop() async => log.add('stop');

  @override
  Future<bool> hasGerman() async => german;
}
