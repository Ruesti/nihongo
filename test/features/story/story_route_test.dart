import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/pipeline/fsrs_knowledge_source.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart' show Knowledge;
import 'package:nihongo_app/features/story/diegetic_speak_sheet.dart'
    show kDiegeticSuccessAutoClose;
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';
import 'package:nihongo_app/features/story/story_route.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LearningDb> _seededDb() async {
  final db = LearningDb.forTesting();
  await seedJaPack(db);
  return db;
}

Future<Knowledge> _knows(MiningDb db, String lemma,
        {required String languageCode}) async =>
    (await FsrsKnowledgeSource.load(db, languageCode: languageCode))
        .call(lemma);

class _FakeSpeakEvaluator implements SpeakEvaluator {
  final double score;
  _FakeSpeakEvaluator(this.score);
  @override
  Future<double> evaluate(String target) async => score;
}

void main() {
  testWidgets('die Route baut den Reader ueber die echten Provider',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final learning = await _seededDb();
    addTearDown(() async => learning.close());

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWithValue(learning)],
      child: const MaterialApp(home: StoryRoute()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-reader-panel')), findsOneWidget);
  });

  testWidgets('Durchlesen bis zum Ende fuehrt jedes Budget-Item auf '
      'Sprosse 0 ein — ueber die echte Route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final learning = await _seededDb();
    addTearDown(() async => learning.close());

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWithValue(learning)],
      child: const MaterialApp(home: StoryRoute()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

    // Bis zum letzten Panel lesen. P09 oeffnet das Woerterbuch automatisch,
    // P07/P22 den echten Sprech-Sheet (StoryRoute verdrahtet immer einen
    // SttSpeakEvaluator) und P24 den Nachzeichnen-Sheet (KanaTraceEvaluator)
    // — anders als die isolierten StoryReaderScreen-Tests, die diese
    // Evaluatoren typischerweise weglassen, haengt die echte Route sie immer
    // ein. Jeder dieser Sheets wird, wie im Muster
    // story_reader_srs_handoff_test.dart fuer das Woerterbuch, per Tap
    // oberhalb des Sheets geschlossen, statt eine Antwort abzugeben.
    const sheetKeys = [
      ValueKey('dictionary-sheet'),
      ValueKey('diegetic-speak-sheet'),
      ValueKey('diegetic-trace-sheet'),
    ];
    for (var i = 0; i < 23; i++) {
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      for (final key in sheetKeys) {
        if (find.byKey(key).evaluate().isNotEmpty) {
          await tester.tapAt(const Offset(400, 50));
          await tester.pumpAndSettle();
        }
      }
    }
    await tester.pumpAndSettle();

    final episode = loadFolge01();
    for (final ref in episode.budget.items) {
      final item = await learning
          .getLearnItem('lang_ja:${ref.refType.name}:${ref.id}');
      expect(item, isNotNull, reason: '${ref.id} wurde nicht eingefuehrt');
      expect(item!.masteryRung, 0);
    }
  });

  test('knownIds enthaelt genau die schon eingefuehrten Budget-Items',
      () async {
    SharedPreferences.setMockInitialValues({});
    final learning = await _seededDb();
    addTearDown(() async => learning.close());
    await learning.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame',
        rung: 0);

    final container = ProviderContainer(
        overrides: [learningDbProvider.overrideWithValue(learning)]);
    addTearDown(container.dispose);

    final deps = await container.read(storyReaderDepsProvider.future);
    expect(deps.knownIds, contains('lex_ja_ame'));
    expect(deps.knownIds, isNot(contains('lex_ja_sumimasen')));
  });

  testWidgets(
      'ein erfolgreicher diegetischer Speak durch die echte Route hebt das '
      'Item auf Sprosse 1 und projiziert es unter ja, nicht lang_ja',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final learning = await _seededDb();
    final mining = MiningDb.forTesting();
    addTearDown(() async {
      await learning.close();
      await mining.close();
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [
        learningDbProvider.overrideWithValue(learning),
        miningDbProvider.overrideWithValue(mining),
      ],
      child: MaterialApp(
        home: StoryRoute(speakEvaluator: _FakeSpeakEvaluator(0.9)),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

    // P07 (die erste diegetische Sprech-Gelegenheit) liegt an Panel-Position
    // 6 (0-indiziert) — die ersten sechs Panels tragen keine Interaktionen,
    // also oeffnet sich vorher kein Sheet, das weggetappt werden muesste.
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('diegetic-speak-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pumpAndSettle();

    // The sheet shows success feedback, then auto-closes 900ms later
    // (not a gate — INV-1). Give the auto-close room to fire, and only
    // tap "weiter" ourselves if the sheet is somehow still around —
    // mirrors the defensive sheet-dismiss loop above.
    await tester.pump(kDiegeticSuccessAutoClose);
    await tester.pumpAndSettle();
    if (find.byKey(const ValueKey('diegetic-speak-sheet')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('diegetic-speak-skip')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('diegetic-speak-sheet')), findsNothing);

    final item = await learning.getLearnItem('lang_ja:lexeme:lex_ja_sumimasen');
    expect(item, isNotNull);
    expect(item!.masteryRung, 1);

    expect(await _knows(mining, 'すみません', languageCode: 'ja'),
        Knowledge.learning);
    expect(await _knows(mining, 'すみません', languageCode: 'lang_ja'),
        Knowledge.unknown);
  });
}
