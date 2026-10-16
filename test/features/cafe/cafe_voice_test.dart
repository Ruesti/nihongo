import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_voice.dart';
import 'package:nihongo_app/features/cafe/voice_segments.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_voice.dart';

void main() {
  late FakeSpeechEngine engine;
  late DeviceTtsSource src;
  setUp(() {
    engine = FakeSpeechEngine();
    src = DeviceTtsSource(engine);
  });

  test('DeviceTtsSource spricht Stücke mit Sprache und Profil', () async {
    await src.speak(splitSegments('Hör zu: あめ. Jetzt du.'),
        profileFor(CafeGuest.schulkind), CafeGuest.schulkind);
    expect(engine.log, [
      'lang:de-DE', 'pitch:1.3', 'rate:0.6', 'speak:Hör zu:',
      'lang:ja-JP', 'pitch:1.3', 'rate:0.6', 'speak:あめ',
      'lang:de-DE', 'pitch:1.3', 'rate:0.6', 'speak:Jetzt du.',
    ]);
  });

  test('neue Anfrage überholt die alte', () async {
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
    expect(engine.log, contains('stop'));
  });

  test('hasGerman false ohne deutsche Stimme', () async {
    engine.languages = {'ja-JP'};
    expect(await src.hasGerman(), isFalse);
  });

  test('hasGerman true mit Sprache und Stimme, wird gemerkt', () async {
    engine.voices = {'de': ['de-DE-x-a']};
    expect(await src.hasGerman(), isTrue);
    expect(await src.hasGerman(), isTrue);
    expect(engine.log.where((e) => e == 'lang:de-DE').length, 1);
  });

  test('hasGerman false bei Sprache ohne Stimmen', () async {
    expect(await src.hasGerman(), isFalse);
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

  test('CafeVoice: aus → nichts; kein Deutsch → nichts; sonst stop, speak',
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
    expect(fake.log, ['stop', 'speak:[Setz dich.|de] wirtin']);
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
