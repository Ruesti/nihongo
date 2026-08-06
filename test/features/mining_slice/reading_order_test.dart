import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/knowledge_bridge.dart';
import 'package:nihongo_app/features/mining_slice/slice_pack.dart';
import 'package:nihongo_app/features/mining_slice/slice_repository.dart';

Token _t(String lemma) =>
    Token(surface: lemma, lemma: lemma, pos: 'n', charStart: 0, charEnd: 1);

SlicePassage _p(String ref, List<Token> tokens) => SlicePassage(
    passageRef: ref, content: ref, furiganaByCharStart: const {}, tokens: tokens);

void main() {
  test('readingOrder ranks by i+1 against the shared knowledge state', () async {
    final db = MiningDb.forTesting();
    addTearDown(() async => db.close());

    // Make 猫 known in the shared mining state, as the on-ramp would.
    await KnowledgeBridge(db)
        .projectLexeme(languageCode: 'ja', lemma: '猫', masteryRung: 4);

    final gentle =
        _p('gentle', [for (var i = 0; i < 9; i++) _t('猫'), _t('新')]); // 0.10 → ideal
    final wall = _p('wall', [for (var i = 0; i < 10; i++) _t('新$i')]); // 1.0 → too hard

    final repo = SliceRepository(
      db: db,
      // Authored order puts the wall first; readingOrder must fix that.
      pack: SlicePack(
        workTitle: 't',
        languageCode: 'ja',
        demoKnownLemmas: const [],
        dictionary: const PrebakedDictionary({}),
        passages: [wall, gentle],
      ),
    );

    final order = await repo.readingOrder();
    expect(order.first.passageRef, 'gentle'); // gentle i+1 before the wall
    expect(order.last.passageRef, 'wall');
  });
}
