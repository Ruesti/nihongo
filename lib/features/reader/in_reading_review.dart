import 'package:flutter/material.dart';
import 'package:fsrs/fsrs.dart' show Rating;

import '../../core/pipeline/due_in_reading.dart';

/// An inline review prompt embedded in the reading flow
/// (SPEC_MINING_PIPELINE.md §7 — "scheduling woven into reading, no
/// review screen"). When a due item's word is present in the span the
/// reader is on, this panel appears *below the text on the same
/// screen*; grading it calls [onGrade] and the reader never navigates
/// away. It is deliberately a panel, not a route — there is no
/// review screen to push.
///
/// This widget knows about scheduling (it shows FSRS ratings), which is
/// exactly why it is separate from the pure `SpanReader` renderer
/// (Phase 6): the reader screen composes the two, keeping the renderer
/// itself free of vocabulary/scheduling logic.
class InReadingReviewPanel extends StatelessWidget {
  final DueCardInView due;
  final void Function(Rating rating) onGrade;

  const InReadingReviewPanel({
    super.key,
    required this.due,
    required this.onGrade,
  });

  static const _ratings = <(Rating, String)>[
    (Rating.again, 'Nochmal'),
    (Rating.hard, 'Schwer'),
    (Rating.good, 'Gut'),
    (Rating.easy, 'Leicht'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Fällig: 「${due.lemma}」',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (rating, label) in _ratings)
                  OutlinedButton(
                    key: ValueKey('grade-${rating.name}'),
                    onPressed: () => onGrade(rating),
                    child: Text(label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
