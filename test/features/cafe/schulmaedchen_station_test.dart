import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/cafe/cafe_summary.dart';
import 'package:nihongo_app/features/cafe/cafe_turn.dart';
import 'package:nihongo_app/features/cafe/stations/schulmaedchen_station.dart';
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

  Future<List<String>> results() async =>
      (await db.select(db.reviewLog).get()).map((r) => r.result).toList();

  Future<({List<String> spoken})> pump(
      WidgetTester tester, _FakeEvaluator ev, List<String> ids) async {
    final spoken = <String>[];
    records = null;
    await tester.pumpWidget(MaterialApp(
      home: SchulmaedchenStation(
        db: db,
        languageId: 'lang_ja',
        episode: _episode(),
        itemIds: ids,
        startIndex: 0,
        speak: (t) async => spoken.add(t),
        evaluator: ev,
        light: CafeLight.tag,
        onPosition: (_) {},
        onDone: (r) => records = r,
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
    expect(find.byKey(const ValueKey('schul-feedback')), findsOneWidget);
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
    // Eingabe ist geleert; zweiter Versuch
    await typeKana(tester, 'あめ');
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
    final r = await pump(tester, _FakeEvaluator([0.1, 0.1]), ['lex_ja_kasa', 'lex_ja_ame']);
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
}
