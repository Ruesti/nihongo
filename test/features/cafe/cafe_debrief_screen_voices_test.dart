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

const _words = ['あめ', 'かさ', 'えき', 'みせ', 'ここ', 'はい'];

/// Sechs Wörter in einer Blase → sechs Items, zwei Blöcke → die Wirtin und
/// eine zweite Stimme (Spec §3.1: zwei Blöcke rahmen nicht).
Map<String, dynamic> _episodeJson() => {
      'id': 'ep_test_voices',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          for (var i = 0; i < _words.length; i++)
            {'id': 'lex_ja_$i', 'refType': 'lexeme'},
        ],
        'glyphs': [],
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
                  'text': _words.join('、'),
                  'tokens': [
                    for (var i = 0; i < _words.length; i++)
                      {'surface': _words[i], 'itemId': 'lex_ja_$i'},
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

void main() {
  late LearningDb db;
  late StoryProgressStore store;
  late Episode episode;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = StoryProgressStore(await SharedPreferences.getInstance());
    db = LearningDb.forTesting();
    episode = Episode.fromJson(_episodeJson());
    for (var i = 0; i < _words.length; i++) {
      await db.into(db.concepts).insert(ConceptsCompanion.insert(
          id: 'concept_$i',
          glossKey: 'gloss_$i',
          partOfSpeech: 'noun',
          defaultAssetType: const Value('image')));
      await db.into(db.lexemes).insert(LexemesCompanion.insert(
          id: 'lex_ja_$i',
          languageId: 'lang_ja',
          conceptId: 'concept_$i',
          writtenForm: _words[i],
          reading: _words[i]));
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_$i',
          rung: 0);
    }
  });
  tearDown(() async => db.close());

  Future<void> tapVerstanden(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pumpAndSettle();
  }

  Future<void> answerKnown(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
    await tester.pumpAndSettle();
  }

  testWidgets('Akt 2: Block 1 fragt die Wirtin, Block 2 eine andere Stimme '
      '(Übergabe + Einstieg), am Ende die Schlusszeile', (tester) async {
    await tester.pumpWidget(_wrap(CafeDebriefScreen(
        db: db, episode: episode, progressStore: store)));
    await tester.pumpAndSettle();
    for (var i = 0; i < _words.length; i++) {
      await tapVerstanden(tester);
    }
    expect(find.byKey(const ValueKey('cafe-turn-screen')), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-voice')), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await answerKnown(tester);
    }
    // Welche der drei Stimmen, hängt vom Sitzungs-Offset ab — aber nie die
    // Wirtin, und immer mit Übergabe und Einstieg.
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsNothing);
    expect(find.byKey(const ValueKey('cafe-turn-handover')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-entry')), findsOneWidget);
    // Sprosse 1 → Erkennen, egal wer fragt (Stimme ≠ Sprosse).
    expect(find.byKey(const ValueKey('cafe-turn-known')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-input')), findsNothing);

    for (var i = 0; i < 3; i++) {
      await answerKnown(tester);
    }
    expect(find.byKey(const ValueKey('cafe-turn-done-line')), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    expect(await db.select(db.reviewLog).get(), hasLength(6));
  });
}
