import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/cafe/stations/wirtin_station.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';

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
          {'id': 'lex_ja_eki', 'refType': 'lexeme'},
          {'id': 'lex_ja_ghost', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'debrief': {
        'lex_ja_ame': {'usage': 'Regen. Das Wort vom Zettel.', 'variants': []},
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0, 'asset': 'assets/story/folge01/p03.jpg',
              'bubbles': [
                {
                  'speakerId': 'x', 'text': 'あめ！',
                  'hitArea': [{'x': 0.1, 'y': 0.1}, {'x': 0.5, 'y': 0.1}, {'x': 0.5, 'y': 0.2}, {'x': 0.1, 'y': 0.2}],
                  'tokens': [{'surface': 'あめ', 'itemId': 'lex_ja_ame'}],
                },
                {
                  'speakerId': 'signage', 'text': '駅',
                  'hitArea': [{'x': 0.1, 'y': 0.3}, {'x': 0.5, 'y': 0.3}, {'x': 0.5, 'y': 0.4}, {'x': 0.1, 'y': 0.4}],
                  'tokens': [{'surface': '駅', 'itemId': 'lex_ja_eki'}],
                },
              ],
              'thoughts': [], 'interactions': [],
            },
          ],
        },
      ],
    });

class _Result {
  final List<String> spoken, slow;
  final List<int> positions;
  final Set<String>? Function() _wobbly;
  _Result(this.spoken, this.slow, this.positions, this._wobbly);
  Set<String>? get wobbly => _wobbly();
}

/// Das Nachladen liest echt aus der DB (nicht FakeAsync) und zeigt solange
/// einen drehenden Spinner, daher reicht pumpAndSettle nicht.
Future<void> settleLoad(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pump();
  await tester.pump();
}

void main() {
  late LearningDb db;
  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_rain', glossKey: 'rain', partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ame', languageId: 'lang_ja', conceptId: 'concept_rain',
        writtenForm: 'あめ', reading: 'あめ'));
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_station', glossKey: 'station', partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_eki', languageId: 'lang_ja', conceptId: 'concept_station',
        writtenForm: '駅', reading: 'えき'));
  });
  tearDown(() => db.close());

  Future<_Result> pump(WidgetTester tester, _FakeEvaluator ev, List<String> ids) async {
    final spoken = <String>[], slow = <String>[], positions = <int>[];
    Set<String>? wobbly;
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: WirtinStation(
        db: db,
        episode: _episode(),
        itemIds: ids,
        startIndex: 0,
        speak: (t) async => spoken.add(t),
        speakSlow: (t) async => slow.add(t),
        evaluator: ev,
        grammarNotes: const {'lex_ja_ame': 'Keine Form, nur das Wort.'},
        light: CafeLight.tag,
        onPosition: positions.add,
        onDone: (w) => wobbly = w,
        onLater: () {},
      ),
    ));
    await tester.pumpAndSettle();
    return _Result(spoken, slow, positions, () => wobbly);
  }

  testWidgets('zeigt Wort, Kacheln mit Laut, Bedeutung, Erklärung, Grammatik; '
      'liest beim Öffnen ganz und langsam vor', (tester) async {
    final r = await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_ame']);
    expect(find.byKey(const ValueKey('wirtin-word')), findsOneWidget);
    expect(find.byKey(const ValueKey('wirtin-kanji')), findsNothing);
    expect(find.byKey(const ValueKey('wirtin-tile-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('wirtin-tile-1')), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('me'), findsOneWidget);
    expect(find.text('Regen'), findsOneWidget);
    expect(find.text('Regen. Das Wort vom Zettel.'), findsOneWidget);
    expect(find.byKey(const ValueKey('wirtin-grammar')), findsOneWidget);
    expect(find.byKey(const ValueKey('wirtin-panel')), findsOneWidget);
    expect(r.spoken, ['あめ']);
    expect(r.slow, ['あめ']);
  });

  testWidgets('Tipp auf eine Kachel spricht nur diesen Laut', (tester) async {
    final r = await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_ame']);
    await tester.tap(find.byKey(const ValueKey('wirtin-tile-1')));
    await tester.pump();
    expect(r.spoken.last, 'め');
  });

  testWidgets('Kanji-Wort: Kanji groß, Kana darunter, Kacheln aus der Lesung',
      (tester) async {
    await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_eki']);
    expect(find.byKey(const ValueKey('wirtin-kanji')), findsOneWidget);
    expect(find.text('えき'), findsWidgets);
    expect(find.text('e'), findsOneWidget);
    expect(find.text('ki'), findsOneWidget);
  });

  testWidgets('Nachsprechen: geschafft → Weiter frei; zweimal nicht → Wort '
      'wackelig, es geht trotzdem weiter', (tester) async {
    final r = await pump(tester, _FakeEvaluator([0.2, 0.2]), ['lex_ja_ame']);
    await tester.tap(find.byKey(const ValueKey('wirtin-mic')));
    await tester.pumpAndSettle();
    expect(r.slow.length, 2); // einmal beim Öffnen, einmal nach dem Fehlversuch
    await tester.tap(find.byKey(const ValueKey('wirtin-mic')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await settleLoad(tester);
    expect(r.wobbly, {'lex_ja_ame'});
  });

  testWidgets('ein Fehlversuch, dann Weiter → wackelig', (tester) async {
    final r = await pump(tester, _FakeEvaluator([0.2]), ['lex_ja_ame']);
    await tester.tap(find.byKey(const ValueKey('wirtin-mic')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await settleLoad(tester);
    expect(r.wobbly, {'lex_ja_ame'});
  });

  testWidgets('Item ohne Lexem wird übersprungen, Position wird gemeldet',
      (tester) async {
    final r = await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_ghost', 'lex_ja_ame']);
    expect(find.text('Regen'), findsOneWidget); // direkt beim zweiten
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await settleLoad(tester);
    expect(r.positions, contains(2));
    expect(r.wobbly, isEmpty);
  });
}
