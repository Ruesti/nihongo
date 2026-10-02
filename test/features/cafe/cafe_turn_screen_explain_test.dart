import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

Episode _episode() => Episode.fromJson({
      'id': 'ep_t',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'debrief': {
        'lex_ja_ame': {'usage': 'Regen. Das Wort vom Zettel.'},
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
                  'text': 'あめ',
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    });

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_rain',
        glossKey: 'rain',
        partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ame',
        languageId: 'lang_ja',
        conceptId: 'concept_rain',
        writtenForm: 'あめ',
        reading: 'あめ'));
  });
  tearDown(() async => db.close());

  Future<void> tapVerstanden(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pumpAndSettle();
  }

  testWidgets('ein Sprosse-0-Item bekommt zuerst die Erklärungskarte, dann '
      'den Turn (nie kalt)', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    await tester.pumpWidget(
        _wrap(CafeTurnScreen(db: db, guest: CafeGuest.wirtin)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-turn-encounter')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsNothing);

    await tapVerstanden(tester);
    expect((await db.getLearnItem('lang_ja:lexeme:lex_ja_ame'))!.masteryRung, 1);
    expect(find.byKey(const ValueKey('cafe-turn-encounter')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsOneWidget);
    // Der Turn bewertet mit der frischen Zeile (Sprosse 1), kein Absturz.
    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    expect(await db.select(db.reviewLog).get(), hasLength(1));
  });

  testWidgets('„Erklär\'s mir nochmal" öffnet die Karte und zählt als '
      'Hinweis → hard', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 3);
    await tester.pumpWidget(
        _wrap(CafeTurnScreen(db: db, guest: CafeGuest.schulkind)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cafe-turn-explain')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-turn-explain-sheet')), findsOneWidget);
    // Ohne Folgen-Kontext: die nackte Begegnung.
    expect(find.byKey(const ValueKey('cafe-debrief-usage')), findsNothing);
    await tapVerstanden(tester);
    expect(find.byKey(const ValueKey('cafe-turn-explain-sheet')), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('cafe-turn-input')), 'あめ');
    await tester.tap(find.byKey(const ValueKey('cafe-turn-submit')));
    await tester.pumpAndSettle();
    expect((await db.select(db.reviewLog).get()).single.result, 'hard');
  });

  testWidgets('Doppeltipp auf „Erklär\'s mir nochmal" öffnet nur eine Karte '
      '(Re-Entrancy-Guard)', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 3);
    await tester.pumpWidget(
        _wrap(CafeTurnScreen(db: db, guest: CafeGuest.schulkind)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cafe-turn-explain')));
    await tester.tap(find.byKey(const ValueKey('cafe-turn-explain')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-turn-explain-sheet')), findsOneWidget);
  });

  testWidgets('mit Folgen-Kontext zeigt die Karte Gebrauch und Stelle in der '
      'Folge', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 3);
    await tester.pumpWidget(_wrap(CafeTurnScreen(
        db: db, guest: CafeGuest.schulkind, episodes: [_episode()])));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-turn-explain')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-usage')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-panel')), findsOneWidget);
  });

  testWidgets(
      'Doppeltipp auf „Verstanden" vor dem Turn läuft nur einmal '
      '(Re-Entrancy-Guard)', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    await tester.pumpWidget(
        _wrap(CafeTurnScreen(db: db, guest: CafeGuest.wirtin)));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsOneWidget);
    expect((await db.getLearnItem('lang_ja:lexeme:lex_ja_ame'))!.masteryRung, 1);
  });
}
