import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/features/reader/span_reader.dart';

const _tokens = [
  Token(surface: '私', lemma: '私', pos: 'n', charStart: 0, charEnd: 1),
  Token(surface: 'は', lemma: 'は', pos: 'p', charStart: 1, charEnd: 2),
  Token(surface: '本', lemma: '本', pos: 'n', charStart: 2, charEnd: 3),
];

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SpanReader', () {
    testWidgets('renders every token surface', (tester) async {
      await tester.pumpWidget(_wrap(
        SpanReader(tokens: _tokens, onWordTap: (_) {}),
      ));

      expect(find.text('私'), findsOneWidget);
      expect(find.text('は'), findsOneWidget);
      expect(find.text('本'), findsOneWidget);
    });

    testWidgets('reports the tapped token', (tester) async {
      Token? tapped;
      await tester.pumpWidget(_wrap(
        SpanReader(tokens: _tokens, onWordTap: (t) => tapped = t),
      ));

      await tester.tap(find.text('本'));
      await tester.pump();

      expect(tapped?.lemma, '本');
    });

    testWidgets('draws furigana above a token when supplied', (tester) async {
      await tester.pumpWidget(_wrap(
        SpanReader(
          tokens: _tokens,
          onWordTap: (_) {},
          furiganaByCharStart: const {0: 'わたし'},
        ),
      ));

      expect(find.text('わたし'), findsOneWidget);
    });

    testWidgets(
        'the SAME renderer works for tokens whatever medium they came from',
        (tester) async {
      // Tokens are medium-independent; the renderer cannot tell an
      // EPUB-sourced token from an SRT-sourced one — same widget, same
      // behavior. Here the identical token list stands in for "produced
      // by the tokenizer from either medium's span."
      Token? tapped;
      await tester.pumpWidget(_wrap(
        SpanReader(tokens: _tokens, onWordTap: (t) => tapped = t),
      ));

      await tester.tap(find.text('私'));
      await tester.pump();
      expect(tapped?.lemma, '私');

      // Re-render the exact same widget with the same tokens (as if the
      // other medium yielded them) — behavior is unchanged.
      await tester.pumpWidget(_wrap(
        SpanReader(tokens: _tokens, onWordTap: (t) => tapped = t),
      ));
      await tester.tap(find.text('本'));
      await tester.pump();
      expect(tapped?.lemma, '本');
    });
  });
}
