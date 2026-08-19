import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/spatial_reader.dart';

ComicPage _page() => const ComicPage(
      pageRef: 'p1',
      imageAsset: 'assets/comic/placeholder_page.png',
      aspectRatio: 0.7,
      bubbles: [
        Bubble(
          rect: BubbleRect(left: 0.1, top: 0.1, right: 0.5, bottom: 0.2),
          lang: BubbleLang.l1,
          text: 'Eine Katze!',
          tokens: [],
        ),
        Bubble(
          rect: BubbleRect(left: 0.5, top: 0.6, right: 0.9, bottom: 0.7),
          lang: BubbleLang.l2,
          text: '猫',
          reading: 'ねこ',
          tokens: [
            Token(surface: '猫', lemma: '猫', reading: 'ねこ', pos: 'n', charStart: 0, charEnd: 1),
          ],
        ),
      ],
    );

void main() {
  testWidgets('renders L1 text plainly and L2 word tappably', (tester) async {
    Token? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SpatialReader(
          page: _page(),
          direction: TextDirection.ltr,
          onWordTap: (t) => tapped = t,
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Eine Katze!'), findsOneWidget); // L1 present
    expect(find.text('猫'), findsOneWidget); // L2 present
    expect(find.text('ねこ'), findsOneWidget); // reading overlay (generic)

    await tester.tap(find.text('猫'));
    await tester.pump();
    expect(tapped, isNotNull); // L2 is tappable
    expect(tapped!.lemma, '猫');
  });

  testWidgets('tapping L1 text does nothing (not mineable)', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SpatialReader(
          page: _page(),
          direction: TextDirection.ltr,
          onWordTap: (_) => taps++,
        ),
      ),
    ));
    await tester.pump();
    await tester.tap(find.text('Eine Katze!'));
    await tester.pump();
    expect(taps, 0);
  });
}
