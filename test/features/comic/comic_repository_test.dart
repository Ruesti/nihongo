import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/comic_repository.dart';

class _EmptyDict implements Dictionary {
  const _EmptyDict();
  @override
  List<Sense> lookup(String lemma, String pos) => const [];
}

ComicPack _pack() => const ComicPack(
      languageCode: 'ja',
      title: 'T',
      level: 0,
      l2Ratio: 0.2,
      pages: [
        ComicPage(
          pageRef: 'p1',
          imageAsset: 'x.png',
          aspectRatio: 0.7,
          bubbles: [
            Bubble(
              rect: BubbleRect(left: 0, top: 0, right: 1, bottom: 1),
              lang: BubbleLang.l2,
              text: '猫',
              tokens: [
                Token(surface: '猫', lemma: '猫', pos: 'n', charStart: 0, charEnd: 1)
              ],
            ),
          ],
        ),
      ],
    );

void main() {
  late MiningDb db;
  setUp(() => db = MiningDb.forTesting());
  tearDown(() => db.close());

  test('nextPage returns a page for an empty known-set (everything i+1)',
      () async {
    final repo = ComicRepository(db: db, pack: _pack(), dictionary: const _EmptyDict());
    final page = await repo.nextPage();
    expect(page, isNotNull);
    expect(page!.pageRef, 'p1');
  });

  test('finishPage records a passage snapshot with the page unknown-ratio',
      () async {
    final repo = ComicRepository(db: db, pack: _pack(), dictionary: const _EmptyDict());
    final page = (await repo.nextPage())!;
    await repo.finishPage(page, lookups: 1);

    final snaps = await db.select(db.passageSnapshots).get();
    expect(snaps, hasLength(1));
    expect(snaps.first.passageRef, 'p1');
    // No known cards → the single L2 lemma is unknown → ratio 1.0.
    expect(snaps.first.unknownRatio, closeTo(1.0, 0.001));
  });
}
