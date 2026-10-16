import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/tts_queue.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_voice.dart';
import 'package:nihongo_app/features/cafe/voice_segments.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_voice.dart';

void main() {
  late FakeSpeechEngine engine;
  late DeviceTtsSource src;
  setUp(() {
    // Eine deutsche Stimme: die Quelle prüft das vor jeder Zeile.
    engine = FakeSpeechEngine()..voices = {'de': ['de-DE-x-a']};
    src = DeviceTtsSource(engine);
  });

  test('DeviceTtsSource spricht Stücke mit Sprache und Profil', () async {
    await src.speak(splitSegments('Hör zu: あめ. Jetzt du.'),
        profileFor(CafeGuest.schulkind), CafeGuest.schulkind);
    expect(engine.log, [
      'lang:de-DE', // Prüfung: Deutsch vorhanden
      'lang:de-DE', 'pitch:1.3', 'rate:0.6', 'speak:Hör zu:',
      'lang:ja-JP', 'pitch:1.3', 'rate:0.6', 'speak:あめ',
      'lang:de-DE', 'pitch:1.3', 'rate:0.6', 'speak:Jetzt du.',
    ]);
  });

  test('neue Anfrage überholt die alte, ohne hart anzuhalten', () async {
    final gate = Completer<void>();
    engine.hold = (t) => t == 'Eins' ? gate : (Completer<void>()..complete());
    final p = profileFor(CafeGuest.wirtin);
    final first = src.speak(
        [VoiceSegment('Eins', VoiceLang.de), VoiceSegment('Zwei', VoiceLang.de)],
        p, CafeGuest.wirtin);
    await Future<void>.delayed(Duration.zero);
    final second = src.speak(
        [VoiceSegment('Drei', VoiceLang.de)], p, CafeGuest.wirtin);
    gate.complete();
    await Future.wait([first, second]);
    final spoken = engine.log.where((e) => e.startsWith('speak:')).toList();
    expect(spoken, ['speak:Eins', 'speak:Drei']);
    expect(engine.log, isNot(contains('stop')));
  });

  test('Überholen während setPitch: altes Stück wird nicht gesprochen',
      () async {
    final gate = Completer<void>();
    var first = true;
    engine.holdPitch = () {
      if (first) {
        first = false;
        return gate;
      }
      return null;
    };
    final p = profileFor(CafeGuest.wirtin);
    final a = src.speak([VoiceSegment('Alt', VoiceLang.de)], p, CafeGuest.wirtin);
    await Future<void>.delayed(Duration.zero);
    final b = src.speak([VoiceSegment('Neu', VoiceLang.de)], p, CafeGuest.wirtin);
    gate.complete();
    await Future.wait([a, b]);
    expect(engine.log.where((e) => e.startsWith('speak:')), ['speak:Neu']);
  });

  test('CafeVoice schluckt Fehler der Quelle', () async {
    final fake = FakeVoiceSource()..throwOnSpeak = true;
    final v = CafeVoice(source: fake, isEnabled: () async => true);
    await v.say(CafeGuest.wirtin, 'Setz dich.');
    await v.stop();
  });

  test('hasGerman false ohne deutsche Stimme', () async {
    engine.languages = {'ja-JP'};
    expect(await src.hasGerman(), isFalse);
  });

  test('hasGerman true mit Sprache und Stimme, wird gemerkt', () async {
    expect(await src.hasGerman(), isTrue);
    expect(await src.hasGerman(), isTrue);
    expect(engine.log.where((e) => e == 'lang:de-DE').length, 1);
  });

  test('hasGerman false bei Sprache ohne Stimmen', () async {
    engine.voices = {};
    expect(await src.hasGerman(), isFalse);
  });

  test('hasGerman: ein „nein" wird beim nächsten Mal neu geprüft', () async {
    engine.voices = {};
    expect(await src.hasGerman(), isFalse);
    engine.voices = {'de': ['de-DE-x-a']};
    expect(await src.hasGerman(), isTrue);
    expect(engine.log.where((e) => e == 'lang:de-DE').length, 2);
  });

  test('zwei überlappende Zeilen: FIFO, kein stop dazwischen', () async {
    engine.queue = TtsQueue();
    final gate = Completer<void>();
    engine.hold = (t) => t == 'Eins.' ? gate : (Completer<void>()..complete());
    final v = CafeVoice(source: src, isEnabled: () async => true);
    final a = v.say(CafeGuest.wirtin, 'Eins.');
    await Future<void>.delayed(Duration.zero);
    final b = v.say(CafeGuest.schulkind, 'Zwei.');
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    // Zwei wartet in der Schlange, bis Eins zu Ende gesprochen ist.
    expect(engine.log.where((e) => e.startsWith('speak:')), ['speak:Eins.']);
    gate.complete();
    await Future.wait([a, b]);
    expect(engine.log.where((e) => e.startsWith('speak:')),
        ['speak:Eins.', 'speak:Zwei.']);
    expect(engine.log, isNot(contains('stop')));
  });

  test('say reiht synchron ein: ein danach angefragtes Wort kommt nach der Zeile',
      () async {
    engine.queue = TtsQueue();
    final v = CafeVoice(source: src, isEnabled: () async => true);
    final line = v.say(CafeGuest.wirtin, 'Setz dich.');
    final word = engine.exclusive(() async => engine.log.add('word'));
    await Future.wait([line, word]);
    final events =
        engine.log.where((e) => e == 'word' || e.startsWith('speak:')).toList();
    expect(events, ['speak:Setz dich.', 'word']);
  });

  test('stop während say noch wartet: die Zeile beginnt nicht', () async {
    final fake = FakeVoiceSource();
    final enabled = Completer<bool>();
    final v = CafeVoice(source: fake, isEnabled: () => enabled.future);
    final p = v.say(CafeGuest.wirtin, 'Setz dich.');
    await v.stop();
    enabled.complete(true);
    await p;
    expect(fake.log, ['stop']);
  });

  test('stop verwirft eine Zeile, die in der Schlange wartet', () async {
    engine.queue = TtsQueue();
    final gate = Completer<void>();
    engine.hold = (t) => t == 'Eins.' ? gate : (Completer<void>()..complete());
    final v = CafeVoice(source: src, isEnabled: () async => true);
    final a = v.say(CafeGuest.wirtin, 'Eins.');
    await Future<void>.delayed(Duration.zero);
    final b = v.say(CafeGuest.wirtin, 'Zwei.');
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    await v.stop();
    gate.complete();
    await Future.wait([a, b]);
    expect(engine.log.where((e) => e.startsWith('speak:')), ['speak:Eins.']);
  });

  test('isActive: an + Deutsch → true; aus, ohne Deutsch, stumm → false',
      () async {
    final fake = FakeVoiceSource();
    expect(await CafeVoice(source: fake, isEnabled: () async => true).isActive(),
        isTrue);
    expect(
        await CafeVoice(source: fake, isEnabled: () async => false).isActive(),
        isFalse);
    fake.german = false;
    expect(await CafeVoice(source: fake, isEnabled: () async => true).isActive(),
        isFalse);
    expect(await const CafeVoice.silent().isActive(), isFalse);
  });

  test('alter Mann bekommt die männliche Stimme', () async {
    engine.voices = {'de': ['de-DE-x-female', 'de-DE-x-male']};
    await src.speak([VoiceSegment('Na.', VoiceLang.de)],
        profileFor(CafeGuest.vielredner), CafeGuest.vielredner);
    expect(engine.log, contains('voice:de-DE-x-male'));
  });

  test('übrige Gäste bekommen die erste Stimme', () async {
    engine.voices = {'de': ['de-DE-x-female', 'de-DE-x-male']};
    await src.speak([VoiceSegment('Na.', VoiceLang.de)],
        profileFor(CafeGuest.wirtin), CafeGuest.wirtin);
    expect(engine.log, contains('voice:de-DE-x-female'));
    expect(engine.log, isNot(contains('voice:de-DE-x-male')));
  });

  test('ohne Männerstimme: zweite Stimme für den Vielredner', () async {
    engine.voices = {'de': ['de-a', 'de-b']};
    await src.speak([VoiceSegment('Na.', VoiceLang.de)],
        profileFor(CafeGuest.vielredner), CafeGuest.vielredner);
    expect(engine.log, contains('voice:de-b'));
  });

  test('CafeVoice: aus → nichts; kein Deutsch → nichts; sonst speak',
      () async {
    final fake = FakeVoiceSource();
    final v = CafeVoice(source: fake, isEnabled: () async => false);
    await v.say(CafeGuest.wirtin, 'Setz dich.');
    expect(fake.log, isEmpty);
    fake.german = false;
    final v2 = CafeVoice(source: fake, isEnabled: () async => true);
    await v2.say(CafeGuest.wirtin, 'Setz dich.');
    expect(fake.log, isEmpty);
    fake.german = true;
    await v2.say(CafeGuest.wirtin, 'Setz dich.');
    expect(fake.log, ['speak:[Setz dich.|de] wirtin']);
  });

  test('CafeVoice.stopIf: veraltete Nummer stoppt nicht, aktuelle schon',
      () async {
    final fake = FakeVoiceSource();
    final v = CafeVoice(source: fake, isEnabled: () async => true);
    final a = await v.say(CafeGuest.wirtin, 'Eins.');
    final b = await v.say(CafeGuest.wirtin, 'Zwei.');
    expect(b, greaterThan(a));
    fake.log.clear();
    await v.stopIf(a);
    expect(fake.log, isNot(contains('stop')));
    await v.stopIf(b);
    expect(fake.log, contains('stop'));
    expect(await const CafeVoice.silent().say(CafeGuest.wirtin, 'x'), 0);
  });

  test('CafeVoice: leere Zerlegung → nichts; silent tut nichts', () async {
    final fake = FakeVoiceSource();
    await CafeVoice(source: fake, isEnabled: () async => true)
        .say(CafeGuest.wirtin, '...');
    expect(fake.log, isEmpty);
    const s = CafeVoice.silent();
    await s.say(CafeGuest.wirtin, 'Hallo');
    await s.stop();
  });

  test('CafeVoicePrefs Standard an, speichert aus', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await CafeVoicePrefs().isEnabled(), isTrue);
    await CafeVoicePrefs().setEnabled(false);
    expect(await CafeVoicePrefs().isEnabled(), isFalse);
  });
}
