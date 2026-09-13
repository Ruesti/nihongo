import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';
import 'package:nihongo_app/features/story/story_route.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LearningDb> _seededDb() async {
  final db = LearningDb.forTesting();
  await seedJaPack(db);
  return db;
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
}
