import 'package:flutter/material.dart';

/// Renders one Datum utterance, or nothing at all. [line] comes from
/// `DatumVoice.say()` and is null when Datum is disabled or has no
/// backable line — in which case this renders `SizedBox.shrink()`.
///
/// That silent path is the point (SPEC_MINING_PIPELINE.md §0.24):
/// Datum is an ornament on state that is legible without it, so its
/// absence must leave the surrounding UI untouched — never a gap, a
/// placeholder, or a "Datum has nothing to say" notice.
class DatumLine extends StatelessWidget {
  final String? line;

  const DatumLine({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    final text = line;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      key: const ValueKey('datum-line'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.straighten,
              size: 16, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
