import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/bubble_overlay.dart';
import 'package:nihongo_app/features/story/episode.dart';

StoryPanel _panel() => StoryPanel.fromJson({
      'index': 0,
      'asset': 'assets/story/folge01/p03.jpg',
      'assetPortrait': 'assets/story/folge01/p03_hoch.jpg',
      'bubbles': [
        {
          'speakerId': 'passant_a',
          'text': 'すみません！あめ！さむい！',
          'hitArea': [
            {'x': 0.725, 'y': 0.1}, {'x': 0.96, 'y': 0.1},
            {'x': 0.96, 'y': 0.22}, {'x': 0.725, 'y': 0.22},
          ],
          'hitAreaPortrait': [
            {'x': 0.6, 'y': 0.212}, {'x': 0.9, 'y': 0.212},
            {'x': 0.9, 'y': 0.277}, {'x': 0.6, 'y': 0.277},
          ],
          'tokens': [
            {'surface': 'すみません', 'itemId': 'lex_ja_sumimasen'},
            {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
            {'surface': 'さむい', 'itemId': 'lex_ja_samui'},
          ],
        },
      ],
      'thoughts': [],
      'interactions': [],
    });

String _plain(List<InlineSpan> spans) =>
    spans.map((s) => (s as TextSpan).text ?? '').join();

void main() {
  const base = TextStyle(fontSize: 14);

  test('highlight lässt den Text ganz und färbt nur das Zielwort', () {
    final spans = bubbleSpans('すみません！あめ！さむい！', 'あめ',
        BubbleOverlayMode.highlight, base);
    expect(_plain(spans), 'すみません！あめ！さむい！');
    final hit = spans.cast<TextSpan>().where((s) => s.text == 'あめ').single;
    expect(hit.style?.color, isNot(base.color));
    expect(hit.style?.fontWeight, FontWeight.bold);
  });

  test('blank ersetzt genau das Zielwort durch ___', () {
    final spans = bubbleSpans('すみません！あめ！さむい！', 'あめ',
        BubbleOverlayMode.blank, base);
    expect(_plain(spans), 'すみません！___！さむい！');
  });

  testWidgets('die Überlagerung sitzt auf dem Rechteck der Hochformat-Blase',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 270,
          height: 484, // 1080:1936
          child: PanelWithBubble(
            panel: _panel(),
            bubble: _panel().bubbles.first,
            targetSurface: 'あめ',
            mode: BubbleOverlayMode.blank,
          ),
        ),
      ),
    ));
    await tester.pump();
    final overlay = tester.getRect(find.byKey(const ValueKey('bubble-overlay')));
    final panel = tester.getRect(find.byKey(const ValueKey('bubble-overlay-panel')));
    expect(overlay.left, closeTo(panel.left + 0.6 * panel.width, 1));
    expect(overlay.top, closeTo(panel.top + 0.212 * panel.height, 1));
    expect(overlay.width, closeTo(0.3 * panel.width, 1));
    expect(
        find.byWidgetPredicate((w) =>
            w is RichText && w.text.toPlainText() == 'すみません！___！さむい！'),
        findsOneWidget);
  });
}
