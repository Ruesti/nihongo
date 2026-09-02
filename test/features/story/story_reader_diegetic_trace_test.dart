import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/story/diegetic_encounter.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:nihongo_app/features/story/trace_evaluator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTraceEvaluator implements TraceEvaluator {
  final bool ok;
  _FakeTraceEvaluator(this.ok);
  @override
  Future<bool> evaluate(String target, List<List<Offset>> userStrokes) async =>
      ok;
}

Future<StoryProgressStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return StoryProgressStore(await SharedPreferences.getInstance());
}

Episode _episode() => Episode.fromJson({
      'id': 'ep_trace_int',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'Trace',
      'locale': 'ja',
      'era': '1996',
      'budget': {'items': [], 'glyphs': []},
      'pages': [
        {
          'index': 1,
          'panels': [
            {
              'index': 1,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {'speakerId': 'n', 'text': 'First', 'tokens': []},
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 2,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'buch',
                  'text': 'あめ',
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [
                {'type': 'trace', 'diegetic': true},
              ],
            },
          ],
        },
      ],
    });

void main() {
  testWidgets('a successful diegetic trace moves the traced item to rung 1 in '
      'the real ladder', (tester) async {
    final learning = LearningDb.forTesting();
    addTearDown(() async => learning.close());
    final enc =
        DiegeticEncounter(ladder: LadderReview(learning), languageId: 'lang_ja');
    final store = await _freshStore();

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episode(),
        progressStore: store,
        speak: (_) async {},
        dictionaryEntries: const [],
        knownIds: const {},
        traceEvaluator: _FakeTraceEvaluator(true),
        onDiegeticTraceSuccess: (ids) async {
          for (final id in ids) {
            await enc.encounter(RefType.lexeme, id);
          }
        },
      ),
    ));
    await tester.pump();

    expect(await learning.select(learning.learnItems).get(), isEmpty);

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byKey(const ValueKey('diegetic-trace-canvas')), const Offset(60, 40));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('diegetic-trace-done')));
    await tester.pumpAndSettle();

    final item = await (learning.select(learning.learnItems)
          ..where((t) => t.refId.equals('lex_ja_ame')))
        .getSingleOrNull();
    expect(item, isNotNull);
    expect(item!.masteryRung, 1);
  });
}
