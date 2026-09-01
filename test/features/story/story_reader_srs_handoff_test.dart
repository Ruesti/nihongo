import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episode_srs_handoff.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/story/folge_01_dictionary_fixture.dart';
import '../../fixtures/story/pilot_01_regen_fixture.dart';

Future<StoryProgressStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return StoryProgressStore(await SharedPreferences.getInstance());
}

void main() {
  testWidgets(
      'reading Folge 01 to the end hands every budgeted word to the SRS '
      'ladder at rung 0 (P5a seed + P5b handoff, end to end)', (tester) async {
    final learning = LearningDb.forTesting();
    addTearDown(() async => learning.close());
    await seedJaPack(learning);

    final handoff = EpisodeSrsHandoff(
      ladder: LadderReview(learning),
      languageId: 'lang_ja',
    );
    final episode = Episode.fromJson(pilot01RegenJson);
    final store = await _freshStore();

    Future<void>? handoffDone;
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: (_) async {},
        dictionaryEntries: folge01DictionaryEntries,
        knownIds: const {},
        onEpisodeComplete: () async {
          handoffDone = handoff.introduceEpisode(episode);
          await handoffDone;
        },
      ),
    ));
    await tester.pump();

    // Nothing has entered the SRS before the episode is finished (INV-5).
    expect(await learning.select(learning.learnItems).get(), isEmpty);

    // Read to the last panel. P09 auto-opens the dictionary; dismiss it by
    // tapping above the sheet, exactly as the existing read-through test does.
    for (var i = 0; i < 23; i++) {
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      if (find.byKey(const ValueKey('dictionary-sheet')).evaluate().isNotEmpty) {
        await tester.tapAt(const Offset(400, 50));
        await tester.pumpAndSettle();
      }
    }
    await handoffDone; // await the fire-and-forget batch introduce

    // Every budgeted item now has a rung-0 learn_item referencing the real
    // lexeme P5a seeded.
    expect(episode.budget.items, isNotEmpty);
    for (final ref in episode.budget.items) {
      final item = await (learning.select(learning.learnItems)
            ..where((t) => t.refId.equals(ref.id)))
          .getSingleOrNull();
      expect(item, isNotNull, reason: '${ref.id} not handed to the ladder');
      expect(item!.masteryRung, 0);
    }
  });
}
