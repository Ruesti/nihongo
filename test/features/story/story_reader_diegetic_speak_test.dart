import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/story/diegetic_encounter.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSpeakEvaluator implements SpeakEvaluator {
  final double score;
  _FakeSpeakEvaluator(this.score);
  @override
  Future<double> evaluate(String target) async => score;
}

Future<StoryProgressStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return StoryProgressStore(await SharedPreferences.getInstance());
}

Episode _episode() => Episode.fromJson({
      'id': 'ep_speak_int',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'Speak',
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
                  'speakerId': 'her',
                  'text': 'すみません',
                  'tokens': [
                    {
                      'surface': 'すみません',
                      'itemId': 'lex_ja_sumimasen',
                      'lookupable': true,
                    },
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [
                {'type': 'speak', 'diegetic': true},
              ],
            },
          ],
        },
      ],
    });

void main() {
  testWidgets('a successful diegetic speak moves the spoken item to rung 1 in '
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
        speakEvaluator: _FakeSpeakEvaluator(0.9),
        onDiegeticSpeakSuccess: (ids) async {
          for (final id in ids) {
            await enc.encounter(RefType.lexeme, id);
          }
        },
      ),
    ));
    await tester.pump();

    // Nothing in the SRS before the diegetic moment.
    expect(await learning.select(learning.learnItems).get(), isEmpty);

    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pumpAndSettle();

    final item = await (learning.select(learning.learnItems)
          ..where((t) => t.refId.equals('lex_ja_sumimasen')))
        .getSingleOrNull();
    expect(item, isNotNull);
    expect(item!.masteryRung, 1);
  });
}
