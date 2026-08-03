import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' show Rating;
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/due_in_reading.dart';
import 'package:nihongo_app/features/reader/reading_view.dart';

const _tokens = [
  Token(surface: '私', lemma: '私', pos: 'n', charStart: 0, charEnd: 1),
  Token(surface: 'は', lemma: 'は', pos: 'p', charStart: 1, charEnd: 2),
  Token(surface: '本', lemma: '本', pos: 'n', charStart: 2, charEnd: 3),
  Token(surface: 'を', lemma: 'を', pos: 'p', charStart: 3, charEnd: 4),
  Token(surface: '読む', lemma: '読む', pos: 'v', charStart: 4, charEnd: 6),
];

const _due = DueCardInView(cardId: 'card:本', vocabItemId: 'v:本', lemma: '本');

/// Counts route pushes/pops so a test can assert the reader never
/// navigates away during review.
class _CountingObserver extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route route, Route? previousRoute) => pushes++;
}

void main() {
  group('ReadingView — scheduling woven into reading (§7)', () {
    testWidgets('renders the text and, inline below it, the due item',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ReadingView(
            tokens: _tokens,
            dueItems: const [_due],
            onWordTap: (_) {},
            onGrade: (_, _) async {},
          ),
        ),
      ));

      // The reading text is present...
      expect(find.text('本'), findsWidgets);
      // ...and so is the inline review prompt, on the same screen.
      expect(find.text('Fällig: 「本」'), findsOneWidget);
      expect(find.byKey(const ValueKey('grade-good')), findsOneWidget);
    });

    testWidgets(
        'grading a due item calls onGrade and dismisses the prompt WITHOUT '
        'any navigation', (tester) async {
      final observer = _CountingObserver();
      String? gradedCard;
      Rating? gradedRating;

      await tester.pumpWidget(MaterialApp(
        navigatorObservers: [observer],
        home: Scaffold(
          body: ReadingView(
            tokens: _tokens,
            dueItems: const [_due],
            onWordTap: (_) {},
            onGrade: (cardId, rating) async {
              gradedCard = cardId;
              gradedRating = rating;
            },
          ),
        ),
      ));

      final pushesBeforeGrading = observer.pushes;

      await tester.tap(find.byKey(const ValueKey('grade-good')));
      await tester.pumpAndSettle();

      // The grade was recorded...
      expect(gradedCard, 'card:本');
      expect(gradedRating, Rating.good);
      // ...the prompt is gone (reviewed in place)...
      expect(find.text('Fällig: 「本」'), findsNothing);
      // ...the text is still there (we never left the reader)...
      expect(find.text('本'), findsWidgets);
      // ...and NOTHING was pushed onto the navigator. No review screen.
      expect(observer.pushes, pushesBeforeGrading);
    });

    testWidgets('with no due items, only the text renders (no prompt)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ReadingView(
            tokens: _tokens,
            dueItems: const [],
            onWordTap: (_) {},
            onGrade: (_, _) async {},
          ),
        ),
      ));

      expect(find.textContaining('Fällig'), findsNothing);
      expect(find.text('読む'), findsOneWidget);
    });

    testWidgets('tapping a word still works while a review is offered',
        (tester) async {
      Token? tapped;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ReadingView(
            tokens: _tokens,
            dueItems: const [_due],
            onWordTap: (t) => tapped = t,
            onGrade: (_, _) async {},
          ),
        ),
      ));

      await tester.tap(find.text('読む'));
      await tester.pump();

      expect(tapped?.lemma, '読む');
    });
  });
}
