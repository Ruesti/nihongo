import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/cafe/cafe_voice.dart';
import 'package:nihongo_app/features/cafe/cafe_visit_screen.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/reader_system_ui.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_voice.dart';

class _RecordingSystemUi implements ReaderSystemUi {
  final List<String> calls = [];
  @override
  Future<void> enterImmersive() async => calls.add('enter');
  @override
  Future<void> exitImmersive() async => calls.add('exit');
}

class _Always implements SpeakEvaluator {
  final double score;
  _Always(this.score);
  @override
  Future<double> evaluate(String target) async => score;
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
              'index': 0, 'asset': 'x.jpg',
              'bubbles': [
                {
                  'speakerId': 'x', 'text': 'あめ！かさ！', 'hitArea': [],
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
  late StoryProgressStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = StoryProgressStore(await SharedPreferences.getInstance());
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
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, id, rung: 0);
    }
    await store.markCompleted('ep_t');
  });
  tearDown(() => db.close());


  final recorder = _RecordingSystemUi();
  final voiceSource = FakeVoiceSource();
  late CafeVoice voice;
  setUp(() {
    recorder.calls.clear();
    voiceSource.log.clear();
    voice = CafeVoice(source: voiceSource, isEnabled: () async => true);
  });

  Widget afterEpisode() => MaterialApp(
        home: CafeVisitScreen.afterEpisode(
          db: db, languageId: 'lang_ja', episode: _episode(), store: store,
          speak: (_) async {}, speakSlow: (_) async {},
          evaluator: _Always(1.0), light: CafeLight.tag,
          systemUi: recorder, voice: voice,
        ),
      );

  Future<void> typeKana(WidgetTester tester, String kana) async {
    for (final c in kana.runes.map(String.fromCharCode)) {
      await tester.ensureVisible(find.byKey(ValueKey('kana-key-$c')));
      await tester.tap(find.byKey(ValueKey('kana-key-$c')));
      await tester.pump();
    }
  }

  testWidgets('Vollbild beim Betreten, Ende beim Verlassen', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(afterEpisode());
    await tester.pumpAndSettle();
    expect(recorder.calls, ['enter']);
    await tester.pumpWidget(const SizedBox());
    expect(recorder.calls, ['enter', 'exit']);
  });

  testWidgets('nach dem Routenwechsel (wie Endkarte → Café) erneut Vollbild',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          key: const ValueKey('go'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => CafeVisitScreen.afterEpisode(
              db: db, languageId: 'lang_ja', episode: _episode(), store: store,
              speak: (_) async {}, speakSlow: (_) async {},
              evaluator: _Always(1.0), light: CafeLight.tag,
              systemUi: recorder, voice: voice,
            ),
          )),
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('go')));
    await tester.pump();
    expect(recorder.calls, ['enter']); // initState
    await tester.pumpAndSettle();
    // Der alte Reader holt im dispose die Leisten zurück — nach dem
    // Einblenden setzt das Café das Vollbild deshalb noch einmal.
    expect(recorder.calls.where((c) => c == 'enter').length,
        greaterThanOrEqualTo(2));
  });

  testWidgets('Raum: Bild füllt (cover), Lautsprecher in der Blase',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(afterEpisode());
    await tester.pumpAndSettle();
    final img =
        tester.widget<Image>(find.byKey(const ValueKey('cafe-visit-scene-room')));
    expect(img.fit, BoxFit.cover);
    expect(img.alignment, Alignment.topCenter);
    expect(find.byKey(const ValueKey('cafe-voice-toggle')), findsOneWidget);
  });

  testWidgets('Raum ohne AppBar mit Bild, Blase und Start; Zeile einmal gesprochen',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(afterEpisode());
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey('cafe-visit-room')), findsOneWidget);
    expect(find.descendant(
        of: find.byKey(const ValueKey('cafe-station-voice')),
        matching: find.text('Setz dich. Wer ist heute da?')), findsNothing);
    expect(find.text('Setz dich. Wer ist heute da?'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-visit-start')), findsOneWidget);
    await tester.pumpWidget(afterEpisode()); // Neuaufbau, gleiche Ansicht
    await tester.pumpAndSettle();
    final said = voiceSource.log.where((l) => l.startsWith('speak:')).toList();
    expect(said.length, 1);
    expect(said.single, endsWith(' wirtin'));
  });

  testWidgets('Abschluss zeigt Wirtin zufrieden und Zeilen', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(afterEpisode());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-visit-start')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
      await tester.pumpAndSettle();
    }
    await typeKana(tester, 'あめ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey('cafe-visit-summary')), findsOneWidget);
    expect(find.descendant(
        of: find.byKey(const ValueKey('cafe-station-voice')),
        matching: find.byType(Text)), findsNothing);
    expect(tester.widget<Text>(find.byKey(const ValueKey('cafe-station-voice'))).data,
        'あめ und かさ sitzen.');
    expect(find.byKey(const ValueKey('cafe-visit-summary-line-0')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-visit-leave')), findsOneWidget);
    final img = tester.widget<Image>(find.descendant(
        of: find.byKey(const ValueKey('cafe-visit-frame-summary')),
        matching: find.byType(Image)));
    expect((img.image as AssetImage).assetName, endsWith('wirtin_tresen_tag.jpg'));
  });

  testWidgets('Abschluss: erste Zeile wird gesprochen, danach kein stop',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(afterEpisode());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-visit-start')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
      await tester.pumpAndSettle();
    }
    await typeKana(tester, 'あめ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-summary')), findsOneWidget);
    final i = voiceSource.log.lastIndexWhere(
        (l) => l == 'speak:[あめ|ja,und|de,かさ|ja,sitzen.|de] wirtin');
    expect(i, isNonNegative);
    expect(voiceSource.log.sublist(i + 1), isNot(contains('stop')));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Zurück-Chip verlässt das Café', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => TextButton(
          key: const ValueKey('open'),
          onPressed: () => Navigator.of(c).push(MaterialPageRoute(
              builder: (_) => CafeVisitScreen.afterEpisode(
                    db: db, languageId: 'lang_ja', episode: _episode(),
                    store: store, speak: (_) async {}, speakSlow: (_) async {},
                    evaluator: _Always(1.0), light: CafeLight.tag,
                    systemUi: recorder, voice: voice,
                  ))),
          child: const Text('auf'),
        ),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-room')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cafe-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-room')), findsNothing);
    expect(find.byKey(const ValueKey('open')), findsOneWidget);
    // initState + nach dem Einblenden der Route, dann beim Verlassen aus.
    expect(recorder.calls, ['enter', 'enter', 'exit']);
  });

  testWidgets('Raum zeigt vier Gäste, Wirtin aktiv; Start öffnet die Wirtin',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(afterEpisode());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-room')), findsOneWidget);
    for (final g in ['wirtin', 'schulmaedchen', 'vielredner', 'gleichaltrige']) {
      expect(find.byKey(ValueKey('cafe-visit-guest-$g')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('cafe-visit-start')));
    await tester.pumpAndSettle();
    expect(find.text('Die Wirtin'), findsOneWidget);
    expect(find.byKey(const ValueKey('wirtin-word')), findsOneWidget);
  });

  testWidgets('Später weiter speichert die Position; Fortsetzen springt dorthin',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(afterEpisode());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-visit-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next'))); // あめ fertig
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-later')));
    await tester.pumpAndSettle();
    expect(await store.cafeVisitPosition('ep_t'), (station: 0, item: 1));

    await tester.pumpWidget(const SizedBox()); // frischer Einstieg, neuer State
    await tester.pumpWidget(afterEpisode());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-resume')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cafe-visit-resume')));
    await tester.pumpAndSettle();
    expect(find.text('かさ'), findsWidgets); // zweites Wort, nicht wieder あめ
  });

  testWidgets('ganzer Weg 1: Wirtin → Schulmädchen → Abschluss; Besuch erledigt',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(afterEpisode());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-visit-start')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
      await tester.pumpAndSettle();
    }
    // Schulmädchen: あめ Hören→Schreiben, かさ Sehen→Sprechen (Always 1.0)
    expect(find.text('Das Schulmädchen'), findsOneWidget);
    await typeKana(tester, 'あめ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-summary')), findsOneWidget);
    expect(find.text('あめ und かさ sitzen.'), findsOneWidget);
    expect((await db.select(db.reviewLog).get()).length, 2); // beide bewertet
    expect(await store.isCafeVisitPending('ep_t'), isFalse);
    expect(await store.cafeVisitPosition('ep_t'), isNull);
  });

  testWidgets('freier Besuch ohne fällige Items: Wirtin wischt den Tresen, '
      'kein Start-Knopf', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final empty = LearningDb.forTesting();
    await tester.pumpWidget(MaterialApp(
      home: CafeVisitScreen.free(
        db: empty, languageId: 'lang_ja', episodes: [_episode()], store: store,
        speak: (_) async {}, speakSlow: (_) async {},
        evaluator: _Always(1.0), light: CafeLight.tag,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-empty')), findsOneWidget);
    expect(find.text('Die Wirtin wischt den Tresen und nickt dir zu.'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-visit-start')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-visit-practice-anyway')), findsNothing);
    // Tresen ganz zeigen, sonst fällt die Wirtin aus dem Bild.
    final img = tester
        .widget<Image>(find.byKey(const ValueKey('cafe-visit-scene-empty')));
    expect(img.fit, BoxFit.contain);
    // Stumme Stimme: kein Lautsprecher.
    expect(find.byKey(const ValueKey('cafe-voice-toggle')), findsNothing);
    await empty.close();
  });

  testWidgets('freier Besuch, nichts fällig, aber bekannte Wörter: freiwillige '
      'Runde beim Schulmädchen', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // Beide Items kennen wir schon (Sprosse 2) und sie sind erst morgen fällig.
    for (final id in ['lex_ja_ame', 'lex_ja_kasa']) {
      final item = (await db.getLearnItem('lang_ja:lexeme:$id'))!;
      await db.update(db.learnItems).replace(item.copyWith(
          masteryRung: 2, dueAt: DateTime.now().add(const Duration(days: 1))));
    }
    await tester.pumpWidget(MaterialApp(
      home: CafeVisitScreen.free(
        db: db, languageId: 'lang_ja', episodes: [_episode()], store: store,
        speak: (_) async {}, speakSlow: (_) async {},
        evaluator: _Always(1.0), light: CafeLight.tag,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cafe-visit-practice-anyway')));
    await tester.pumpAndSettle();
    expect(find.text('Das Schulmädchen'), findsOneWidget);
  });

  Widget freeVisit() => MaterialApp(
        home: CafeVisitScreen.free(
          db: db, languageId: 'lang_ja', episodes: [_episode()], store: store,
          speak: (_) async {}, speakSlow: (_) async {},
          evaluator: _Always(1.0), light: CafeLight.tag,
        ),
      );

  testWidgets('freier Besuch: Später weiter speichert nichts, kein Fortsetzen',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(freeVisit());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-visit-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-later')));
    await tester.pumpAndSettle();
    expect(await store.cafeVisitPosition('free'), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(freeVisit());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-start')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-visit-resume')), findsNothing);
  });

  testWidgets('freiwillige Runde: Später weiter lässt Weg-1-Position unberührt',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    for (final id in ['lex_ja_ame', 'lex_ja_kasa']) {
      final item = (await db.getLearnItem('lang_ja:lexeme:$id'))!;
      await db.update(db.learnItems).replace(item.copyWith(
          masteryRung: 2, dueAt: DateTime.now().add(const Duration(days: 1))));
    }
    await store.saveCafeVisitPosition('ep_t', 1, 0);
    await tester.pumpWidget(freeVisit());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-visit-practice-anyway')));
    await tester.pumpAndSettle();
    expect(find.text('Das Schulmädchen'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cafe-station-later')));
    await tester.pumpAndSettle();
    expect(await store.cafeVisitPosition('free'), isNull);
    expect(await store.cafeVisitPosition('ep_t'), (station: 1, item: 0));
  });

  testWidgets('Weg 1: wackelige Wirtin-Wörter werden gespeichert; Fortsetzen '
      'nach der Wirtin ordnet das Schulmädchen genauso (wackelige zuerst)',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final spoken = <String>[];
    Widget screen() => MaterialApp(
          home: CafeVisitScreen.afterEpisode(
            db: db, languageId: 'lang_ja', episode: _episode(), store: store,
            speak: (t) async => spoken.add(t), speakSlow: (_) async {},
            evaluator: _Always(0.0), light: CafeLight.tag,
          ),
        );
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-visit-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next'))); // あめ
    await tester.pumpAndSettle();
    // かさ: einmal nachgesprochen, nicht geschafft → wackelig
    await tester.tap(find.byKey(const ValueKey('wirtin-mic')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(find.text('Das Schulmädchen'), findsOneWidget);
    expect(await store.cafeVisitWobbly('ep_t'), {'lex_ja_kasa'});
    expect(spoken.last, 'かさ'); // wackeliges Wort zuerst
    await tester.tap(find.byKey(const ValueKey('cafe-station-later')));
    await tester.pumpAndSettle();
    expect(await store.cafeVisitPosition('ep_t'), (station: 1, item: 0));

    spoken.clear();
    await tester.pumpWidget(const SizedBox()); // frischer Einstieg
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-visit-resume')));
    await tester.pumpAndSettle();
    expect(find.text('Das Schulmädchen'), findsOneWidget);
    expect(spoken, ['かさ']); // nicht あめ: die Ordnung ist erhalten
  });

  testWidgets('Weg 1 ohne übbare Wörter: leerer Raum, Besuch sofort erledigt',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final empty = Episode.fromJson({
      'id': 'ep_leer', 'seasonId': 's', 'orderIndex': 2, 'title': 'L',
      'locale': 'ja', 'era': 'e',
      'budget': {'items': [], 'glyphs': []},
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0, 'asset': 'x.jpg', 'bubbles': [],
              'thoughts': [], 'interactions': [],
            },
          ],
        },
      ],
    });
    await store.markCompleted('ep_leer');
    expect(await store.isCafeVisitPending('ep_leer'), isTrue);
    await tester.pumpWidget(MaterialApp(
      home: CafeVisitScreen.afterEpisode(
        db: db, languageId: 'lang_ja', episode: empty, store: store,
        speak: (_) async {}, speakSlow: (_) async {},
        evaluator: _Always(1.0), light: CafeLight.tag,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-empty')), findsOneWidget);
    expect(find.text('Die Wirtin wischt den Tresen und nickt dir zu.'), findsOneWidget);
    expect(await store.isCafeVisitPending('ep_leer'), isFalse);
  });

  testWidgets('Doppeltipp auf „Setz dich" startet den Besuch nur einmal',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final obs = _PushCounter();
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [obs],
      home: CafeVisitScreen.afterEpisode(
        db: db, languageId: 'lang_ja', episode: _episode(), store: store,
        speak: (_) async {}, speakSlow: (_) async {},
        evaluator: _Always(1.0), light: CafeLight.tag,
      ),
    ));
    await tester.pumpAndSettle();
    final pushesBefore = obs.pushes;
    final start = find.byKey(const ValueKey('cafe-visit-start'));
    await tester.tap(start);
    await tester.tap(start, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(obs.pushes - pushesBefore, 1);
  });
}

class _PushCounter extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;
}
