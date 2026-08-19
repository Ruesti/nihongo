import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/comic_selector.dart';

Bubble _l2(List<String> lemmas) => Bubble(
      rect: const BubbleRect(left: 0, top: 0, right: 1, bottom: 1),
      lang: BubbleLang.l2,
      text: lemmas.join(),
      tokens: [
        for (var i = 0; i < lemmas.length; i++)
          Token(surface: lemmas[i], lemma: lemmas[i], pos: 'n', charStart: i, charEnd: i + 1),
      ],
    );

ComicPage _page(String ref, List<String> lemmas) => ComicPage(
      pageRef: ref,
      imageAsset: 'x.png',
      aspectRatio: 0.7,
      bubbles: [_l2(lemmas)],
    );

void main() {
  test('l2TokensOf returns only L2 tokens', () {
    final page = ComicPage(
      pageRef: 'p',
      imageAsset: 'x.png',
      aspectRatio: 0.7,
      bubbles: [
        const Bubble(
            rect: BubbleRect(left: 0, top: 0, right: 1, bottom: 1),
            lang: BubbleLang.l1,
            text: 'hallo',
            tokens: []),
        _l2(['猫']),
      ],
    );
    expect(l2TokensOf(page).map((t) => t.lemma), ['猫']);
  });

  test('picks the page whose unknown-ratio sits in the i+1 window', () {
    // known: everything except "難". Page A is all-known (too easy),
    // Page B has one unknown among several (ideal i+1).
    Knowledge knows(String lemma) =>
        lemma == '難' ? Knowledge.unknown : Knowledge.known;

    final easy = _page('A', ['猫', '犬', '鳥', '魚', '本']);
    final ideal = _page('B', ['猫', '犬', '鳥', '魚', '難']); // 1/5 unknown = 0.2

    final next = nextComicPage([easy, ideal], knows);
    expect(next, isNotNull);
    expect(next!.pageRef, 'B');
  });
}
