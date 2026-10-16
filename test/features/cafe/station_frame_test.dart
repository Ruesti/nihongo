import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_portraits.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/cafe/cafe_visit.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_voice.dart';
import 'package:nihongo_app/features/cafe/stations/station_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_voice.dart';

void setSize(WidgetTester t, Size s) {
  t.view.physicalSize = s;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
}

const portrait = Size(400, 1400);
const landscape = Size(1400, 640);

void main() {
  late FakeVoiceSource fake;
  late CafeVoice voice;

  setUp(() {
    fake = FakeVoiceSource()..german = true;
    voice = CafeVoice(source: fake, isEnabled: () async => true);
  });

  Future<void> pump(
    WidgetTester t, {
    CafeMood mood = CafeMood.fragend,
    int variant = 1,
    String line = 'Setz dich.',
    Map<String, Map<String, List<int>>> files = const {},
    VoidCallback? onNext,
    VoidCallback? onLater,
    bool withVoice = true,
  }) async {
    await t.pumpWidget(MaterialApp(
      home: StationFrame(
        station: CafeStation.wirtin,
        light: CafeLight.tag,
        mood: mood,
        variant: variant,
        line: line,
        files: files,
        voice: withVoice ? voice : null,
        onNext: onNext,
        onLater: onLater,
        child: const SizedBox(height: 40, child: Text('Inhalt')),
      ),
    ));
    await t.pump();
  }

  testWidgets('keine AppBar, Bild füllt den Schirm, Fläche und Blase da',
      (t) async {
    setSize(t, portrait);
    await pump(t, withVoice: false);
    expect(find.byType(AppBar), findsNothing);
    expect(t.getRect(find.byKey(const ValueKey('cafe-station-scene'))),
        const Rect.fromLTWH(0, 0, 400, 1400));
    expect(find.byKey(const ValueKey('cafe-overlay')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-back')), findsOneWidget);
    expect(find.text('Setz dich.'), findsOneWidget);
    expect(
        t.widget<Text>(find.byKey(const ValueKey('cafe-station-voice'))).data,
        'Setz dich.');
    expect(
        t.widget<Text>(find.byKey(const ValueKey('cafe-station-name'))).data,
        'Die Wirtin');
    expect(find.text('Inhalt'), findsOneWidget);
  });

  testWidgets('Stimmung ändert das Bild, Nummer bleibt', (t) async {
    setSize(t, portrait);
    final files = {
      'wirtin_fragend': {'hoch': [1, 2, 3]},
      'wirtin_zufrieden': {'hoch': [1, 2, 3]},
    };
    String asset() => (t
            .widget<Image>(find.byKey(const ValueKey('cafe-station-scene')))
            .image as AssetImage)
        .assetName;
    await pump(t, mood: CafeMood.fragend, variant: 2, files: files);
    expect(asset(), endsWith('wirtin_fragend_2_hoch.jpg'));
    await pump(t, mood: CafeMood.zufrieden, variant: 2, files: files);
    expect(asset(), endsWith('wirtin_zufrieden_2_hoch.jpg'));
    await pump(t, mood: CafeMood.abwinkend, variant: 2, files: files);
    expect(asset(), endsWith('wirtin_fragend_2_hoch.jpg'));
    await pump(t, mood: CafeMood.fragend, variant: 2, files: const {});
    expect(asset(), sceneAsset(CafeMotif.wirtinTresen, CafeLight.tag));
  });

  testWidgets('Zeile wird beim Aufbau und bei Änderung gesprochen, dispose stoppt',
      (t) async {
    setSize(t, portrait);
    await pump(t, line: 'Setz dich.');
    expect(fake.log, ['stop', 'speak:[Setz dich.|de] wirtin']);
    await pump(t, line: 'Genau so.');
    expect(fake.log.last, 'speak:[Genau so.|de] wirtin');
    expect(fake.log.length, 4);
    await pump(t, line: 'Genau so.');
    expect(fake.log.length, 4);
    await t.pumpWidget(const SizedBox());
    expect(fake.log.last, 'stop');
  });

  testWidgets('dispose stoppt eine fremde, jüngere Zeile nicht', (t) async {
    setSize(t, portrait);
    await pump(t, line: 'Setz dich.');
    await voice.say(CafeGuest.wirtin, 'Abschluss.'); // jemand anderes spricht
    fake.log.clear();
    await t.pumpWidget(const SizedBox());
    expect(fake.log, isNot(contains('stop')));
  });

  testWidgets('Drehen behält Zeile und Knöpfe, Fläche wechselt die Seite',
      (t) async {
    setSize(t, portrait);
    await pump(t, onNext: () {}, onLater: () {}, withVoice: false);
    final hoch = t.getRect(find.byKey(const ValueKey('cafe-overlay')));
    expect(hoch.width, 400);
    expect(hoch.bottom, 1400);
    setSize(t, landscape);
    await t.pump();
    final quer = t.getRect(find.byKey(const ValueKey('cafe-overlay')));
    expect(quer.width, lessThan(1400));
    expect(quer.right, 1400);
    expect(find.text('Setz dich.'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-station-next')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-station-later')), findsOneWidget);
    expect(t.getRect(find.byKey(const ValueKey('cafe-station-scene'))),
        const Rect.fromLTWH(0, 0, 1400, 640));
  });

  testWidgets('Später weiter und Weiter wie bisher', (t) async {
    setSize(t, portrait);
    var next = 0, later = 0;
    await pump(t,
        onNext: () => next++, onLater: () => later++, withVoice: false);
    await t.tap(find.byKey(const ValueKey('cafe-station-next')));
    await t.tap(find.byKey(const ValueKey('cafe-station-later')));
    expect([next, later], [1, 1]);
    await pump(t, onNext: null, withVoice: false);
    expect(find.byKey(const ValueKey('cafe-station-later')), findsNothing);
    expect(
        t
            .widget<FilledButton>(find.byKey(const ValueKey('cafe-station-next')))
            .onPressed,
        isNull);
  });

  testWidgets('Lautsprecher in der Blase schaltet um und stoppt', (t) async {
    SharedPreferences.setMockInitialValues({});
    setSize(t, portrait);
    await pump(t);
    await t.pumpAndSettle();
    Icon icon() => t.widget<Icon>(find.descendant(
        of: find.byKey(const ValueKey('cafe-voice-toggle')),
        matching: find.byType(Icon)));
    expect(icon().icon, Icons.volume_up);
    await t.tap(find.byKey(const ValueKey('cafe-voice-toggle')));
    await t.pumpAndSettle();
    expect(icon().icon, Icons.volume_off);
    final p = await SharedPreferences.getInstance();
    expect(p.getBool(CafeVoicePrefs.key), false);
    expect(fake.log.last, 'stop');
  });

  testWidgets('Lautsprecher: schon aus beim Aufbau, Tipp schaltet ein',
      (t) async {
    SharedPreferences.setMockInitialValues({CafeVoicePrefs.key: false});
    setSize(t, portrait);
    await pump(t);
    await t.pumpAndSettle();
    Icon icon() => t.widget<Icon>(find.descendant(
        of: find.byKey(const ValueKey('cafe-voice-toggle')),
        matching: find.byType(Icon)));
    expect(icon().icon, Icons.volume_off);
    final before = fake.log.length;
    await t.tap(find.byKey(const ValueKey('cafe-voice-toggle')));
    await t.pumpAndSettle();
    expect(icon().icon, Icons.volume_up);
    final p = await SharedPreferences.getInstance();
    expect(p.getBool(CafeVoicePrefs.key), true);
    expect(fake.log.skip(before), isNot(contains('stop')));
  });
}
