import 'package:flutter/material.dart';
import 'package:fsrs/fsrs.dart' show Rating;

import '../../core/language_pack/language_pack.dart';
import '../../core/pipeline/due_in_reading.dart';
import 'in_reading_review.dart';
import 'span_reader.dart';

/// The reading flow with scheduling woven in (SPEC_MINING_PIPELINE.md
/// §7). Composes the pure [SpanReader] (text) with an inline
/// [InReadingReviewPanel] (grading) on ONE screen: a due item whose
/// word is in the current span is offered for review right under the
/// text, graded in place, and dismissed — all without a route change.
/// There is no review screen; the reader is the review surface.
///
/// Grading is delegated via [onGrade] (wired to `ReviewScheduler` by
/// the composing screen) so this widget stays testable without a
/// database and free of FSRS write logic itself.
class ReadingView extends StatefulWidget {
  final List<Token> tokens;
  final List<DueCardInView> dueItems;
  final void Function(Token token) onWordTap;
  final Future<void> Function(String cardId, Rating rating) onGrade;
  final Map<int, String>? furiganaByCharStart;

  const ReadingView({
    super.key,
    required this.tokens,
    required this.dueItems,
    required this.onWordTap,
    required this.onGrade,
    this.furiganaByCharStart,
  });

  @override
  State<ReadingView> createState() => _ReadingViewState();
}

class _ReadingViewState extends State<ReadingView> {
  late final List<DueCardInView> _pending = List.of(widget.dueItems);
  bool _grading = false;

  Future<void> _grade(DueCardInView due, Rating rating) async {
    if (_grading) return;
    setState(() => _grading = true);
    await widget.onGrade(due.cardId, rating);
    if (!mounted) return;
    setState(() {
      _pending.remove(due);
      _grading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _pending.isEmpty ? null : _pending.first;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SpanReader(
            tokens: widget.tokens,
            onWordTap: widget.onWordTap,
            furiganaByCharStart: widget.furiganaByCharStart,
          ),
          if (current != null)
            InReadingReviewPanel(
              due: current,
              onGrade: (rating) => _grade(current, rating),
            ),
        ],
      ),
    );
  }
}
