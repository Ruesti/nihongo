import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_debrief_screen.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
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

Map<String, dynamic> _episodeJson() => {
      'id': 'ep_scene',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'weather': 'rain',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
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
    };

void main() {
  late LearningDb db;
  late StoryProgressStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = StoryProgressStore(await SharedPreferences.getInstance());
    db = LearningDb.forTesting();
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_rain', glossKey: 'rain', partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ame', languageId: 'lang_ja', conceptId: 'concept_rain',
        writtenForm: 'あめ', reading: 'あめ'));
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
  });
  tearDown(() async {
    imageCache.clear();
    imageCache.clearLiveImages();
    await db.close();
  });

  String assetOf(WidgetTester tester, String key) =>
      (tester.widget<Image>(find.byKey(ValueKey(key))).image as AssetImage)
          .assetName;

  testWidgets('Akt 1 trägt das Band „Wirtin am Tisch" im übergebenen Licht; '
      'Akt 2 bekommt dasselbe Licht', (tester) async {
    await tester.pumpWidget(_wrap(CafeDebriefScreen(
      db: db,
      episode: Episode.fromJson(_episodeJson()),
      progressStore: store,
      light: CafeLight.regen,
    )));
    await tester.pumpAndSettle();
    expect(assetOf(tester, 'cafe-debrief-band'),
        sceneAsset(CafeMotif.wirtinTisch, CafeLight.regen));
    // Die Panel-Miniatur bleibt das Hauptbild der Karte.
    expect(find.byKey(const ValueKey('cafe-debrief-panel')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pumpAndSettle();
    expect(assetOf(tester, 'cafe-turn-scene'),
        turnScene(CafeGuest.wirtin, CafeLight.regen, 0));
  });

  test('ohne übergebenes Licht: Regen der Folge ersetzt den Tag', () {
    final episode = Episode.fromJson(_episodeJson());
    expect(lightFor(DateTime(2026, 9, 19, 10), rain: episode.weather == 'rain'),
        CafeLight.regen);
  });
}
