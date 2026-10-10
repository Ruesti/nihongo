import 'package:flutter/material.dart';

import '../story/episode.dart';
import '../story/panel_geometry.dart';

/// Wie die Blase über dem Panel gezeichnet wird (Spec §6.3): Zielwort
/// hervorgehoben (Wirtin) oder ausgeblendet (Schulmädchen, Sehen→Sprechen).
enum BubbleOverlayMode { highlight, blank }

/// Der Blasentext als Spans: [target] farbig/fett oder durch „___" ersetzt.
List<InlineSpan> bubbleSpans(
    String text, String target, BubbleOverlayMode mode, TextStyle base) {
  final spans = <InlineSpan>[];
  var rest = text;
  while (rest.isNotEmpty) {
    final at = target.isEmpty ? -1 : rest.indexOf(target);
    if (at < 0) {
      spans.add(TextSpan(text: rest, style: base));
      break;
    }
    if (at > 0) spans.add(TextSpan(text: rest.substring(0, at), style: base));
    spans.add(switch (mode) {
      BubbleOverlayMode.highlight => TextSpan(
          text: target,
          style: base.copyWith(
              color: const Color(0xFFB3261E), fontWeight: FontWeight.bold)),
      BubbleOverlayMode.blank => TextSpan(text: '___', style: base),
    });
    rest = rest.substring(at + target.length);
  }
  return spans;
}

/// Panelbild (Hochformat, `assetFor`) mit einer weißen Blase an der Stelle
/// des Blasen-Rechtecks (`hitAreaFor`) — die gelesene Blase darunter bleibt
/// verdeckt. Kein neues Rendern, keine zusätzlichen Bilddateien.
class PanelWithBubble extends StatelessWidget {
  final StoryPanel panel;
  final StoryBubble bubble;
  final String targetSurface;
  final BubbleOverlayMode mode;
  final PanelFormat format;

  const PanelWithBubble({
    super.key,
    required this.panel,
    required this.bubble,
    required this.targetSurface,
    required this.mode,
    this.format = PanelFormat.portrait,
  });

  Rect _bbox() {
    final pts = bubble.hitAreaFor(format).points;
    if (pts.isEmpty) return const Rect.fromLTWH(0.05, 0.05, 0.9, 0.12);
    var l = 1.0, t = 1.0, r = 0.0, b = 0.0;
    for (final p in pts) {
      if (p.x < l) l = p.x;
      if (p.y < t) t = p.y;
      if (p.x > r) r = p.x;
      if (p.y > b) b = p.y;
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  @override
  Widget build(BuildContext context) {
    final box = _bbox();
    return AspectRatio(
      aspectRatio: aspectOf(format),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              panel.assetFor(format),
              key: const ValueKey('bubble-overlay-panel'),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) =>
                  Container(color: const Color(0xFF2A3035)),
            ),
            Positioned(
              left: box.left * w,
              top: box.top * h,
              width: box.width * w,
              height: box.height * h,
              child: Container(
                key: const ValueKey('bubble-overlay'),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    key: const ValueKey('bubble-overlay-text'),
                    textAlign: TextAlign.center,
                    TextSpan(
                      children: bubbleSpans(
                          bubble.text,
                          targetSurface,
                          mode,
                          const TextStyle(
                              color: Colors.black, fontSize: 16, height: 1.2)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
