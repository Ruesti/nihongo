import '../../core/language_pack/language_pack.dart';

enum BubbleLang { l1, l2 }

/// Normalized (0..1) bounding box within the page image.
class BubbleRect {
  final double left, top, right, bottom;
  const BubbleRect(
      {required this.left,
      required this.top,
      required this.right,
      required this.bottom});

  factory BubbleRect.fromJson(Map<String, dynamic> j) => BubbleRect(
        left: (j['left'] as num).toDouble(),
        top: (j['top'] as num).toDouble(),
        right: (j['right'] as num).toDouble(),
        bottom: (j['bottom'] as num).toDouble(),
      );
}

class Bubble {
  final BubbleRect rect;
  final BubbleLang lang;
  final String text;
  final List<Token> tokens; // empty for L1 (plain, non-tappable, not mined)
  final String? reading;

  const Bubble({
    required this.rect,
    required this.lang,
    required this.text,
    required this.tokens,
    this.reading,
  });

  factory Bubble.fromJson(Map<String, dynamic> j) => Bubble(
        rect: BubbleRect.fromJson(j['rect'] as Map<String, dynamic>),
        lang: (j['lang'] as String) == 'l2' ? BubbleLang.l2 : BubbleLang.l1,
        text: j['text'] as String,
        reading: j['reading'] as String?,
        tokens: [
          for (final t in (j['tokens'] as List? ?? const []))
            Token(
              surface: t['surface'] as String,
              lemma: t['lemma'] as String,
              reading: t['reading'] as String?,
              pos: t['pos'] as String,
              charStart: t['charStart'] as int,
              charEnd: t['charEnd'] as int,
            ),
        ],
      );
}

class ComicPage {
  final String pageRef;
  final String imageAsset;
  final double aspectRatio; // width / height
  final List<Bubble> bubbles;

  const ComicPage({
    required this.pageRef,
    required this.imageAsset,
    required this.aspectRatio,
    required this.bubbles,
  });

  factory ComicPage.fromJson(Map<String, dynamic> j) => ComicPage(
        pageRef: j['pageRef'] as String,
        imageAsset: j['imageAsset'] as String,
        aspectRatio: (j['aspectRatio'] as num?)?.toDouble() ?? 0.7,
        bubbles: [
          for (final b in (j['bubbles'] as List? ?? const []))
            Bubble.fromJson(b as Map<String, dynamic>),
        ],
      );
}

/// A graded comic for one target language. `l2Ratio` is the immersion-ramp
/// dial: fraction of bubble text in L2 (0 = all L1, 1 = all L2).
class ComicPack {
  final String languageCode;
  final String title;
  final int level;
  final double l2Ratio;
  final List<ComicPage> pages;

  const ComicPack({
    required this.languageCode,
    required this.title,
    required this.level,
    required this.l2Ratio,
    required this.pages,
  });

  factory ComicPack.fromJson(Map<String, dynamic> j) => ComicPack(
        languageCode: j['languageCode'] as String,
        title: j['title'] as String,
        level: j['level'] as int? ?? 0,
        l2Ratio: (j['l2Ratio'] as num?)?.toDouble() ?? 0.0,
        pages: [
          for (final p in (j['pages'] as List? ?? const []))
            ComicPage.fromJson(p as Map<String, dynamic>),
        ],
      );
}
