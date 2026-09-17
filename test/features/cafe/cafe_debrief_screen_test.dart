import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_debrief_screen.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

/// かさ zuerst (P0), あめ ab P1 — Auftrittsreihenfolge kasa, ame.
Map<String, dynamic> _episodeJson() => {
      'id': 'ep_test_debrief',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
          {'id': 'lex_ja_kasa', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'debrief': {
        'lex_ja_ame': {
          'usage': 'Regen. Das Wort vom Zettel.',
          'variants': [
            {'form': 'おおあめ', 'reading': 'おおあめ', 'meaning': 'starker Regen'},
          ],
        },
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'assets/story/p01.jpg',
              'bubbles': [
                {
                  'speakerId': 'x',
                  'text': 'かさ',
                  'tokens': [
                    {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 1,
              'asset': 'assets/story/p02.jpg',
              'bubbles': [
                {
                  'speakerId': 'x',
                  'text': 'あめ、かさ',
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                    {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    };

Future<void> _seedLexeme(LearningDb db, String id, String concept,
    String form, String gloss) async {
  await db.into(db.concepts).insert(ConceptsCompanion.insert(
      id: concept,
      glossKey: gloss,
      partOfSpeech: 'noun',
      defaultAssetType: const Value('image')));
  await db.into(db.lexemes).insert(LexemesCompanion.insert(
      id: id,
      languageId: 'lang_ja',
      conceptId: concept,
      writtenForm: form,
      reading: form));
}

void main() {
  late LearningDb db;
  late Episode episode;
  late StoryProgressStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = StoryProgressStore(await SharedPreferences.getInstance());
    db = LearningDb.forTesting();
    episode = Episode.fromJson(_episodeJson());
    await _seedLexeme(db, 'lex_ja_ame', 'concept_rain', 'あめ', 'rain');
    await _seedLexeme(db, 'lex_ja_kasa', 'concept_umbrella', 'かさ', 'umbrella');
  });
  tearDown(() async => db.close());

  Future<int> rungOf(String id) async =>
      (await db.getLearnItem('lang_ja:lexeme:$id'))!.masteryRung;

  Widget screen() =>
      _wrap(CafeDebriefScreen(db: db, episode: episode, progressStore: store));

  Future<void> tapVerstanden(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pumpAndSettle();
  }

  testWidgets('Akt 1 erklärt in Auftrittsreihenfolge, hebt Sprosse 0 → 1 und '
      'geht in Akt 2 über', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_kasa', rung: 0);

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-line')), findsOneWidget);
    // Erste Karte: かさ (erstes Token der Folge), ohne Erklärungsblock.
    expect(find.text('かさ'), findsWidgets);
    expect(find.byKey(const ValueKey('cafe-debrief-usage')), findsNothing);

    await tapVerstanden(tester);
    expect(await rungOf('lex_ja_kasa'), 1);
    expect(await store.debriefIndex(episode.id), 1);
    // Zweite Karte: あめ mit Gebrauch und Variante.
    expect(find.text('あめ'), findsWidgets);
    expect(find.byKey(const ValueKey('cafe-debrief-usage')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-variant-0')), findsOneWidget);

    await tapVerstanden(tester);
    expect(await rungOf('lex_ja_ame'), 1);
    expect(await store.isDebriefDone(episode.id), isTrue);
    // Akt 2: die Wirtin fragt dieselben Items als Turns ab — sofort, obwohl
    // ihr erster Termin nach der Begegnung erst später wäre.
    expect(find.byKey(const ValueKey('cafe-turn-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsNothing);
  });

  testWidgets('Doppeltipp auf „Verstanden" überspringt keine Karte '
      '(Re-Entrancy-Guard)', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_kasa', rung: 0);

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pumpAndSettle();

    expect(await store.debriefIndex(episode.id), 1);
    expect(find.text('あめ'), findsWidgets);
    expect(find.text('かさ'), findsNothing);
    expect(await rungOf('lex_ja_ame'), 0);
  });

  testWidgets('Akt 2 endet mit der Schlusszeile der Wirtin; Varianten wurden '
      'nie zu Items', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_kasa', rung: 0);
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tapVerstanden(tester);
    await tapVerstanden(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('cafe-turn-done-line')), findsOneWidget);
    expect(await db.select(db.reviewLog).get(), hasLength(2));
    // Variante ≠ Item (INV-8): genau die Manifest-Items sind Karteikarten.
    final ids = (await db.select(db.learnItems).get()).map((i) => i.refId).toSet();
    expect(ids, {'lex_ja_ame', 'lex_ja_kasa'});
  });

  testWidgets('Wiederkommen setzt beim ersten offenen Item fort', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_kasa', rung: 1);
    await store.saveDebriefIndex(episode.id, 1);
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('あめ'), findsWidgets);
    expect(find.text('かさ'), findsNothing);
  });

  testWidgets('ein Item, das schon auf Sprosse 1 steht, bekommt die Karte, '
      'bleibt aber unberührt', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_kasa', rung: 1);
    final before = (await db.getLearnItem('lang_ja:lexeme:lex_ja_kasa'))!;
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('かさ'), findsWidgets);
    await tapVerstanden(tester);
    final after = (await db.getLearnItem('lang_ja:lexeme:lex_ja_kasa'))!;
    expect(after.masteryRung, 1);
    expect(after.dueAt, before.dueAt);
  });

  testWidgets('kein eingeführtes Item → die Wirtin nickt nur (leer, ohne Zahl)',
      (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-empty')), findsOneWidget);
    expect(find.textContaining('0'), findsNothing);
  });
}
