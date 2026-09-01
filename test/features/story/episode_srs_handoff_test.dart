import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episode_srs_handoff.dart';

import '../../fixtures/story/pilot_01_regen_fixture.dart';

void main() {
  late LearningDb learning;
  late EpisodeSrsHandoff handoff;
  late Episode episode;

  setUp(() {
    learning = LearningDb.forTesting();
    handoff = EpisodeSrsHandoff(
      ladder: LadderReview(learning),
      languageId: 'lang_ja',
    );
    episode = Episode.fromJson(pilot01RegenJson);
  });

  tearDown(() async => learning.close());

  Future<LearnItem?> itemFor(String refId) =>
      (learning.select(learning.learnItems)..where((t) => t.refId.equals(refId)))
          .getSingleOrNull();

  test('introduces every budgeted item as a rung-0 learn_item', () async {
    await handoff.introduceEpisode(episode);

    expect(episode.budget.items, isNotEmpty);
    for (final ref in episode.budget.items) {
      final item = await itemFor(ref.id);
      expect(item, isNotNull, reason: '${ref.id} was not introduced');
      expect(item!.masteryRung, 0);
      expect(item.refType, ref.refType.name);
      expect(item.languageId, 'lang_ja');
    }
  });

  test('is idempotent — re-running does not duplicate any item', () async {
    await handoff.introduceEpisode(episode);
    await handoff.introduceEpisode(episode);

    for (final ref in episode.budget.items) {
      final rows = await (learning.select(learning.learnItems)
            ..where((t) => t.refId.equals(ref.id)))
          .get();
      expect(rows, hasLength(1), reason: '${ref.id} duplicated on re-run');
    }
  });

  test('never disturbs an item already advanced beyond rung 0 (INV-6)',
      () async {
    final ref = episode.budget.items.first;
    // The learner already mastered this item in a prior episode.
    await learning.addLearnItemAtRung('lang_ja', ref.refType, ref.id, rung: 4);

    await handoff.introduceEpisode(episode);

    final item = await itemFor(ref.id);
    expect(item!.masteryRung, 4, reason: 'handoff demoted a mastered item');
  });
}
