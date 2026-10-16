import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_portraits.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/cafe/bubble_overlay.dart';
import 'package:nihongo_app/features/cafe/cafe_summary.dart';
import 'package:nihongo_app/features/cafe/cafe_turn.dart';
import 'package:nihongo_app/features/cafe/cafe_voice.dart';
import 'package:nihongo_app/features/cafe/stations/station_frame.dart';
import 'package:nihongo_app/features/cafe/stations/schulmaedchen_station.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';

import 'fakes/fake_voice.dart';

class _FakeEvaluator implements SpeakEvaluator {
  final List<double> scores;
  int calls = 0;
  _FakeEvaluator(this.scores);
  @override
  Future<double> evaluate(String target) async => scores[calls++ % scores.length];
}

Episode _episode() => Episode.fromJson({
      'id': 'ep_t', 'seasonId': 's', 'orderIndex': 1, 'title': 'T',
      'locale': 'ja', 'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
          {'id': 'lex_ja_kasa', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0, 'asset': 'assets/story/folge01/p03.jpg',
              'bubbles': [
                {
                  'speakerId': 'x', 'text': 'あめ！かさ！',
                  'hitArea': [{'x': 0.1, 'y': 0.1}, {'x': 0.5, 'y': 0.1}, {'x': 0.5, 'y': 0.2}, {'x': 0.1, 'y': 0.2}],
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                    {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                  ],
                },
              ],
              'thoughts': [], 'interactions': [],
            },
          ],
        },
      ],
    });

void main() {
  late LearningDb db;
  List<VisitRecord>? records; // von onDone gesetzt (nicht beim pump kopiert)
  setUp(() async {
    db = LearningDb.forTesting();
    for (final (id, concept, gloss, form) in [
      ('lex_ja_ame', 'concept_rain', 'rain', 'あめ'),
      ('lex_ja_kasa', 'concept_umbrella', 'umbrella', 'かさ'),
    ]) {
      await db.into(db.concepts).insert(ConceptsCompanion.insert(
          id: concept, glossKey: gloss, partOfSpeech: 'noun',
          defaultAssetType: const Value('image')));
      await db.into(db.lexemes).insert(LexemesCompanion.insert(
          id: id, languageId: 'lang_ja', conceptId: concept,
          writtenForm: form, reading: form));
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, id, rung: 1);
    }
  });
  tearDown(() => db.close());

  StationFrame frame(WidgetTester t) =>
      t.widget<StationFrame>(find.byType(StationFrame));
  String bubble(WidgetTester t) =>
      t.widget<Text>(find.byKey(const ValueKey('cafe-station-voice'))).data!;

  Future<List<String>> results() async =>
      (await db.select(db.reviewLog).get()).map((r) => r.result).toList();

  Future<({List<String> spoken})> pump(
      WidgetTester tester, SpeakEvaluator ev, List<String> ids,
      {bool withEpisode = true,
      List<Episode> episodes = const [],
      CafeVoice? voice}) async {
    final spoken = <String>[];
    records = null;
    // Telefon-Hochformat: das Querformat-Panel in voller Breite plus Mikro.
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: SchulmaedchenStation(
        db: db,
        languageId: 'lang_ja',
        episode: withEpisode ? _episode() : null,
        episodes: episodes,
        itemIds: ids,
        startIndex: 0,
        speak: (t) async => spoken.add(t),
        evaluator: ev,
        light: CafeLight.tag,
        onPosition: (_) {},
        onDone: (r) => records = r,
        voice: voice ?? const CafeVoice.silent(),
        onLater: () {},
      ),
    ));
    await tester.pumpAndSettle();
    return (spoken: spoken);
  }

  Future<void> typeKana(WidgetTester tester, String kana) async {
    for (final c in kana.runes.map(String.fromCharCode)) {
      await tester.ensureVisible(find.byKey(ValueKey('kana-key-$c')));
      await tester.tap(find.byKey(ValueKey('kana-key-$c')));
      await tester.pump();
    }
  }

  testWidgets('Position 0 = Hören→Schreiben: Wort wird gesprochen, nicht '
      'gezeigt; richtig getippt → good', (tester) async {
    final r = await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_ame']);
    expect(find.byKey(const ValueKey('schul-hear-write')), findsOneWidget);
    expect(r.spoken, ['あめ']);
    expect(find.text('あめ'), findsNothing);
    await typeKana(tester, 'あめ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    expect(await results(), ['good']);
    expect(bubble(tester), 'Ha, gewusst!');
  });

  testWidgets('falsch → nochmal gesprochen + Kacheln; zweiter Versuch richtig '
      '→ hard; zweimal falsch → again, ein Log-Eintrag', (tester) async {
    final r = await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_ame', 'lex_ja_kasa']);
    await typeKana(tester, 'あき');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    expect(r.spoken, ['あめ', 'あめ']);
    expect(find.byKey(const ValueKey('schul-tiles')), findsOneWidget);
    expect(await results(), isEmpty);
    // Eingabe ist geleert; zweiter Versuch. Die Kacheln verschwinden mit der
    // ersten Taste — der zweite Versuch läuft ohne Krücke.
    await typeKana(tester, 'あ');
    expect(find.byKey(const ValueKey('schul-tiles')), findsNothing);
    await typeKana(tester, 'め');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    expect(await results(), ['hard']);
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    // Position 1 = Sehen→Sprechen für かさ: zweimal nicht erkannt
    expect(find.byKey(const ValueKey('schul-see-speak')), findsOneWidget);
    expect(find.text('あめ！___！'), findsOneWidget);
  });

  testWidgets('Sehen→Sprechen: zweimal nicht erkannt → again, es geht weiter; '
      'onDone liefert Records', (tester) async {
    await pump(tester, _FakeEvaluator([0.1, 0.1]), ['lex_ja_kasa', 'lex_ja_ame']);
    // Position 0 ist Hören→Schreiben (かさ): richtig
    await typeKana(tester, 'かさ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schul-see-speak')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    expect(await results(), ['good']); // noch nicht bewertet
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    expect(await results(), ['good', 'again']);
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(records!.map((x) => x.outcome),
        [CafeOutcome.correct, CafeOutcome.wrong]);
    expect(records!.first.firstTry, isTrue);
  });

  testWidgets('Sehen→Sprechen: „lieber schreiben" blendet die Tastatur ein; '
      'richtig getippt → good, kein Mikro nötig', (tester) async {
    await pump(tester, _FakeEvaluator([0.0]), ['lex_ja_kasa', 'lex_ja_ame']);
    await typeKana(tester, 'かさ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schul-see-speak')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('schul-write-instead')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schul-panel')), findsOneWidget); // Panel bleibt
    await typeKana(tester, 'あめ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    expect(await results(), ['good', 'good']);
  });

  testWidgets('Doppeltipp aufs Mikro während der Erkennung verbraucht nur '
      'einen Versuch', (tester) async {
    final ev = _GatedEvaluator();
    await pump(tester, ev, ['lex_ja_kasa', 'lex_ja_ame']);
    await typeKana(tester, 'かさ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schul-see-speak')), findsOneWidget);
    final mic = find.byKey(const ValueKey('schul-mic'));
    await tester.tap(mic);
    await tester.pump();
    await tester.tap(mic, warnIfMissed: false);
    await tester.pump();
    expect(ev.calls, 1); // zweite Erkennung nie gestartet
    ev.release(0.1);
    await tester.pumpAndSettle();
    expect(await results(), ['good']); // erst ein Versuch, noch nicht bewertet
    expect(tester.widget<FilledButton>(mic).onPressed != null, isTrue);
    await tester.tap(mic);
    await tester.pump();
    ev.release(0.1);
    await tester.pumpAndSettle();
    expect(await results(), ['good', 'again']);
  });

  Future<void> toSeeSpeak(WidgetTester tester) async {
    await typeKana(tester, 'かさ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schul-see-speak')), findsOneWidget);
  }

  testWidgets('Sehen→Sprechen: Panel im Querformat in voller Breite',
      (tester) async {
    await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_kasa', 'lex_ja_ame']);
    await toSeeSpeak(tester);
    final panel = find.byKey(const ValueKey('schul-panel'));
    expect(tester.widget<PanelWithBubble>(panel).format, PanelFormat.landscape);
    expect(tester.getSize(panel).width, closeTo(400 - 32, 1));
  });

  testWidgets('Sehen→Sprechen falsch: sie sagt es vor, aber keine Kacheln',
      (tester) async {
    await pump(tester, _FakeEvaluator([0.1]), ['lex_ja_kasa', 'lex_ja_ame']);
    await toSeeSpeak(tester);
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    expect(bubble(tester), 'Nee. Hör zu: あめ. Jetzt du.');
    expect(find.byKey(const ValueKey('schul-tiles')), findsNothing);
  });

  testWidgets('Sehen→Sprechen: nichts gehört (-1) ist kein Versuch — '
      'Tastatur statt Mikro, nichts bewertet', (tester) async {
    await pump(tester, _FakeEvaluator([-1.0]), ['lex_ja_kasa', 'lex_ja_ame']);
    await toSeeSpeak(tester);
    final before = await results();
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    expect(await results(), before); // kein neuer Log-Eintrag
    expect(bubble(tester), 'Ich hab nichts gehört. Schreib es lieber.');
    expect(find.byKey(const ValueKey('schul-submit')), findsOneWidget);
    expect(find.byKey(const ValueKey('kana-keyboard-value')), findsOneWidget);
    // Der erste getippte Versuch zählt noch als erster: richtig → good.
    await typeKana(tester, 'あめ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    expect(await results(), [...before, 'good']);
  });

  testWidgets('nichts gehört gleich beim ersten Wort: review_log bleibt leer',
      (tester) async {
    await pump(tester, _FakeEvaluator([-1.0]), ['lex_ja_kasa', 'lex_ja_ame']);
    // Direkt bei Position 1 (Sehen→Sprechen) einsteigen, ohne vorher etwas
    // zu bewerten.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MaterialApp(
      home: SchulmaedchenStation(
        db: db, languageId: 'lang_ja', episode: _episode(),
        itemIds: const ['lex_ja_kasa', 'lex_ja_ame'], startIndex: 1,
        speak: (_) async {}, evaluator: _FakeEvaluator([-1.0]),
        light: CafeLight.tag, onPosition: (_) {}, onDone: (_) {},
        onLater: () {},
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    expect(await results(), isEmpty);
    expect(find.byKey(const ValueKey('schul-submit')), findsOneWidget);
  });

  testWidgets('ungerade Position ohne Panel/Blase → Bedeutung→Sprechen ohne '
      'Panel', (tester) async {
    await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_kasa', 'lex_ja_ame'],
        withEpisode: false);
    await typeKana(tester, 'かさ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schul-see-speak')), findsOneWidget);
    expect(find.byKey(const ValueKey('schul-hear-write')), findsNothing);
    expect(find.byKey(const ValueKey('schul-panel')), findsNothing);
    expect(find.byKey(const ValueKey('schul-mic')), findsOneWidget);
    expect(find.byKey(const ValueKey('schul-meaning')), findsOneWidget);
  });

  testWidgets('seeSpeak zeigt Bedeutung und Frage, keine Kana', (tester) async {
    await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_kasa', 'lex_ja_ame']);
    await toSeeSpeak(tester);
    expect(tester.widget<Text>(find.byKey(const ValueKey('schul-meaning'))).data,
        'Regen');
    expect(bubble(tester), 'Wie heißt ‚Regen‘? Sag\'s.');
    expect(find.byKey(const ValueKey('schul-kana')), findsNothing);
    expect(find.byKey(const ValueKey('schul-panel')), findsOneWidget);
    final h = tester.getSize(find.byKey(const ValueKey('schul-panel'))).height;
    expect(h, lessThanOrEqualTo(1400 * 0.2 + 0.5));
    expect(frame(tester).mood, CafeMood.fragend);
  });

  testWidgets('falsch → Vorsagen, Kana sichtbar, abwinkend; zweiter Versuch '
      'richtig → hard', (tester) async {
    final r = await pump(
        tester, _FakeEvaluator([0.1, 0.9]), ['lex_ja_kasa', 'lex_ja_ame']);
    await toSeeSpeak(tester);
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    expect(r.spoken.last, 'あめ');
    expect(find.byKey(const ValueKey('schul-kana')), findsOneWidget);
    expect(bubble(tester), 'Nee. Hör zu: あめ. Jetzt du.');
    expect(frame(tester).mood, CafeMood.abwinkend);
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    expect(await results(), ['good', 'hard']);
    expect(bubble(tester), 'Siehst du, geht doch.');
    expect(frame(tester).mood, CafeMood.zufrieden);
  });

  testWidgets('Stimmung fragend beim Tippen nach Fehlversuch', (tester) async {
    await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_ame']);
    expect(bubble(tester), 'Hör zu und schreib es. Schnell!');
    await typeKana(tester, 'あき');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    expect(frame(tester).mood, CafeMood.abwinkend);
    await typeKana(tester, 'あ');
    expect(frame(tester).mood, CafeMood.fragend);
  });

  testWidgets('Stimme stoppt vor dem Mikro', (tester) async {
    final fake = FakeVoiceSource()..german = true;
    final voice = CafeVoice(source: fake, isEnabled: () async => true);
    final ev = _GatedEvaluator();
    await pump(tester, ev, ['lex_ja_kasa', 'lex_ja_ame'], voice: voice);
    await toSeeSpeak(tester);
    await tester.pumpAndSettle();
    expect(fake.log.last, 'speak:[Wie heißt ‚Regen‘? Sag\'s.|de] schulkind');
    final stopsBefore = fake.log.where((e) => e == 'stop').length;
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pump();
    expect(ev.calls, 1); // Erkennung steht aus: stop kam davor
    expect(fake.log.last, 'stop');
    expect(fake.log.where((e) => e == 'stop').length, stopsBefore + 1);
    ev.release(0.9);
    await tester.pumpAndSettle();
    expect(fake.log.last, 'speak:[Ha, gewusst!|de] schulkind');
  });

  testWidgets('Wechsel zum Schreiben verbirgt die Lesung (INV-9)',
      (tester) async {
    await pump(tester, _FakeEvaluator([0.1]), ['lex_ja_kasa', 'lex_ja_ame']);
    await toSeeSpeak(tester);
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schul-kana')), findsOneWidget);
    expect(bubble(tester), contains('あめ'));
    await tester.ensureVisible(find.byKey(const ValueKey('schul-write-instead')));
    await tester.tap(find.byKey(const ValueKey('schul-write-instead')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schul-kana')), findsNothing);
    expect(bubble(tester), 'Dann schreib es.');
    expect(find.byKey(const ValueKey('kana-keyboard-value')), findsOneWidget);
    await typeKana(tester, 'あめ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    expect(await results(), ['good', 'hard']);
  });

  testWidgets('freier Besuch: Folge je Wort aus episodes → Sehen→Sprechen '
      'mit Panel', (tester) async {
    await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_kasa', 'lex_ja_ame'],
        withEpisode: false, episodes: [_episode()]);
    await toSeeSpeak(tester);
    expect(find.byKey(const ValueKey('schul-panel')), findsOneWidget);
  });
}

class _GatedEvaluator implements SpeakEvaluator {
  int calls = 0;
  Completer<double>? _c;
  @override
  Future<double> evaluate(String target) {
    calls++;
    _c = Completer<double>();
    return _c!.future;
  }

  void release(double score) => _c!.complete(score);
}
