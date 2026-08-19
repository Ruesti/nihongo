import 'package:flutter/material.dart';

import '../../core/language_pack/language_pack.dart';
import 'comic_pack.dart';

/// Renders one comic page: the panel image with speech bubbles overlaid at
/// their normalized rects. L2 words are tappable (report to [onWordTap])
/// and show their reading above; L1 text is plain and never tappable.
/// Language-blind: [direction] and the reading overlay come from the pack /
/// ScriptProfile, never a language branch. Missing image → neutral frame.
class SpatialReader extends StatelessWidget {
  final ComicPage page;
  final TextDirection direction;
  final void Function(Token token) onWordTap;

  const SpatialReader({
    super.key,
    required this.page,
    required this.direction,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: direction,
      child: AspectRatio(
        aspectRatio: page.aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: [
                _pageImage(page.imageAsset),
                for (final b in page.bubbles)
                  Positioned(
                    left: b.rect.left * w,
                    top: b.rect.top * h,
                    width: (b.rect.right - b.rect.left) * w,
                    height: (b.rect.bottom - b.rect.top) * h,
                    child: _BubbleWidget(bubble: b, onWordTap: onWordTap),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pageImage(String assetPath) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(color: const Color(0xFFEDEDED)),
    );
  }
}

class _BubbleWidget extends StatelessWidget {
  final Bubble bubble;
  final void Function(Token token) onWordTap;
  const _BubbleWidget({required this.bubble, required this.onWordTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black26),
      ),
      child: bubble.lang == BubbleLang.l1
          ? Text(bubble.text, textAlign: TextAlign.center)
          : _l2Content(context),
    );
  }

  Widget _l2Content(BuildContext context) {
    // If tokens are provided, render each as a tappable word with its
    // reading above; otherwise render the whole L2 text as one tappable unit.
    if (bubble.tokens.isEmpty) {
      return GestureDetector(
        onTap: () {},
        child: Text(bubble.text, textAlign: TextAlign.center),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final t in bubble.tokens)
          GestureDetector(
            key: ValueKey('l2-${t.charStart}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onWordTap(t),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (t.reading != null)
                  Text(t.reading!, style: Theme.of(context).textTheme.labelSmall),
                Text(t.surface),
              ],
            ),
          ),
      ],
    );
  }
}
