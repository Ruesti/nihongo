// Proof: Manga-Lesen (docs/superpowers/specs/2026-08-17-manga-lesen-design.md)
//   "A real comic page renders with tappable L2 words over a placeholder
//    image; the i+1 selector picks a page from the learner's known-set;
//    reading is measured via a passage snapshot — for ANY target language."
//
// Runs headless for JA and ES ComicPacks (no `if (lang == 'ja')`), asserting
// selection + snapshot for both.
//
// Usage:
//   dart run tool/proof_manga_reading.dart

import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/comic_repository.dart';

class _EmptyDict implements Dictionary {
  const _EmptyDict();
  @override
  List<Sense> lookup(String lemma, String pos) => const [];
}

ComicPack _pack(String lang, String l2Surface) => ComicPack(
      languageCode: lang,
      title: 'proof-$lang',
      level: 0,
      l2Ratio: 0.2,
      pages: [
        ComicPage(
          pageRef: 'p1',
          imageAsset: 'assets/comic/placeholder_page.png',
          aspectRatio: 0.7,
          bubbles: [
            Bubble(
              rect: const BubbleRect(left: 0, top: 0, right: 1, bottom: 1),
              lang: BubbleLang.l2,
              text: l2Surface,
              tokens: [
                Token(surface: l2Surface, lemma: l2Surface, pos: 'n', charStart: 0, charEnd: l2Surface.length),
              ],
            ),
          ],
        ),
      ],
    );

Future<bool> _runFor(String lang, String l2Surface) async {
  final db = MiningDb.forTesting();
  final repo = ComicRepository(db: db, pack: _pack(lang, l2Surface), dictionary: const _EmptyDict());
  final page = await repo.nextPage();
  final selected = page != null;
  if (page != null) await repo.finishPage(page, lookups: 0);
  final snaps = await db.select(db.passageSnapshots).get();
  final snapped = snaps.length == 1;
  await db.close();
  print('  [$lang] page selected: $selected, snapshot written: $snapped');
  return selected && snapped;
}

Future<void> main(List<String> args) async {
  print('=== Manga-Lesen gate (multi-language) ===');
  final ja = await _runFor('ja', '猫');
  final es = await _runFor('es', 'gato');
  final pass = ja && es;
  print('GATE: ${pass ? 'PASS' : 'FAIL'}');
  print(pass ? '=== PASS ===' : '=== FAIL ===');
}
