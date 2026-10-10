import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_debrief.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_visit_screen.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LearningDb db;
  setUp(() async {
    db = LearningDb.forTesting();
    // A lexeme + concept EXIST in the pack, but the learner has NEVER been
    // introduced to it — there is no learn_item for it. INV-9: it must never
    // surface in the café.
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_secret', glossKey: 'secret', partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_himitsu', languageId: 'lang_ja',
        conceptId: 'concept_secret', writtenForm: 'ひみつ', reading: 'ひみつ'));
  });
  tearDown(() async => db.close());

  test('an un-introduced item (no learn_item) is not due — the café has no '
      'source for it', () async {
    // The café's ONLY item source is getDueItems, which selects learn_items.
    final due = await db.getDueItems('lang_ja', limit: 500);
    expect(due.where((i) => i.refId == 'lex_ja_himitsu'), isEmpty);
    // Occupancy is empty: no guest is present for an item that was never read.
    expect(CafeOccupancy.fromDueItems(due).isEmpty, isTrue);
  });

  testWidgets('with only an un-introduced item in the pack, the café is empty '
      'and no station can reach it (INV-9)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = StoryProgressStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(MaterialApp(
      home: CafeVisitScreen.free(
        db: db, languageId: 'lang_ja', episodes: const [], store: store,
        speak: (_) async {}, speakSlow: (_) async {},
        evaluator: const _NeverHeard(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-visit-start')), findsNothing);
    expect(find.text('ひみつ'), findsNothing);
  });

  test('once introduced (a learn_item exists), the SAME word becomes due — '
      'the café gate is exactly introduction, nothing else', () async {
    // Positive control: introduce it → now it is due → now it can appear.
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_himitsu',
        rung: 1);
    final due = await db.getDueItems('lang_ja', limit: 500);
    expect(due.where((i) => i.refId == 'lex_ja_himitsu'), isNotEmpty);
    expect(CafeOccupancy.fromDueItems(due).present, contains(CafeGuest.wirtin));
  });

  test('die Nachbesprechung hat dieselbe einzige Quelle: ein Budget-Item ohne '
      'learn_item erscheint auch dort nicht (INV-11)', () async {
    final episode = Episode.fromJson({
      'id': 'ep_inv',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_himitsu', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [],
    });
    expect(await debriefItemsFor(db, episode, 'lang_ja'), isEmpty);
    // Positiv-Kontrolle: erst die Übergabe (learn_item) legt es auf den Tisch.
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_himitsu',
        rung: 0);
    expect((await debriefItemsFor(db, episode, 'lang_ja')).single.refId,
        'lex_ja_himitsu');
  });
}

class _NeverHeard implements SpeakEvaluator {
  const _NeverHeard();
  @override
  Future<double> evaluate(String target) async => 0;
}
