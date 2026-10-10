import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/cafe/cafe_visit_screen.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

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


  Widget afterEpisode() => MaterialApp(
        home: CafeVisitScreen.afterEpisode(
          db: db, languageId: 'lang_ja', episode: _episode(), store: store,
          speak: (_) async {}, speakSlow: (_) async {},
          evaluator: _Always(1.0), light: CafeLight.tag,
        ),
      );

  Future<void> typeKana(WidgetTester tester, String kana) async {
    for (final c in kana.runes.map(String.fromCharCode)) {
      await tester.ensureVisible(find.byKey(ValueKey('kana-key-$c')));
      await tester.tap(find.byKey(ValueKey('kana-key-$c')));
      await tester.pump();
    }
  }

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
}
