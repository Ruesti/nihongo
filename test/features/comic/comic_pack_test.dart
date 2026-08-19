import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';

const _json = {
  'languageCode': 'ja',
  'title': 'Neko',
  'level': 0,
  'l2Ratio': 0.2,
  'pages': [
    {
      'pageRef': 'p1',
      'imageAsset': 'assets/comic/placeholder_page.png',
      'aspectRatio': 0.7,
      'bubbles': [
        {
          'rect': {'left': 0.1, 'top': 0.1, 'right': 0.5, 'bottom': 0.25},
          'lang': 'l1',
          'text': 'Schau, eine Katze!',
          'tokens': [],
        },
        {
          'rect': {'left': 0.5, 'top': 0.6, 'right': 0.9, 'bottom': 0.75},
          'lang': 'l2',
          'text': '猫',
          'reading': 'ねこ',
          'tokens': [
            {
              'surface': '猫', 'lemma': '猫', 'reading': 'ねこ',
              'pos': 'n', 'charStart': 0, 'charEnd': 1
            }
          ],
        },
      ],
    },
  ],
};

void main() {
  test('parses a pack with L1 and L2 bubbles', () {
    final pack = ComicPack.fromJson(_json);
    expect(pack.languageCode, 'ja');
    expect(pack.l2Ratio, 0.2);
    expect(pack.pages, hasLength(1));

    final bubbles = pack.pages.first.bubbles;
    expect(bubbles[0].lang, BubbleLang.l1);
    expect(bubbles[0].tokens, isEmpty);
    expect(bubbles[1].lang, BubbleLang.l2);
    expect(bubbles[1].tokens.single.lemma, '猫');
    expect(bubbles[1].rect.left, 0.5);
  });
}
