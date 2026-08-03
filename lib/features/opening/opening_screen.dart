import 'package:flutter/material.dart';

import '../datum/datum_line.dart';
import '../reader/re_presentation.dart';
import 'opening_state.dart';

/// The opening screen (SPEC_MINING_PIPELINE.md §8): "a proof, not a
/// menu." Exactly one artifact — the Then/Now re-presentation of the
/// most recently read passage — with a Datum line beneath it and
/// navigation kept below the fold.
///
/// Hard rules from §8, all structural here:
///  - **No task count, no due-card number, no streak.** This widget
///    renders none of those; it takes an [OpeningState] derived purely
///    from passage history (see `loadOpeningState`), which carries no
///    such numbers to begin with. (A test asserts none appear.)
///  - **Graceful empty state.** A passage read once shows the passage
///    and a plain Datum line; a blank slate shows an entry point. No
///    fabricated proof.
///  - **Navigation below the fold.** Continue/Library live at the
///    bottom, never above the proof.
class OpeningScreen extends StatelessWidget {
  final OpeningState state;
  final String? datumLine;
  final VoidCallback onContinueReading;
  final VoidCallback onLibrary;

  const OpeningScreen({
    super.key,
    required this.state,
    required this.datumLine,
    required this.onContinueReading,
    required this.onLibrary,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(child: _proof(context)),
            ),
            DatumLine(line: datumLine),
            const SizedBox(height: 16),
            // Navigation, below the fold, always (§8).
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('continue-reading'),
                    onPressed: onContinueReading,
                    child: const Text('Weiterlesen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('library'),
                    onPressed: onLibrary,
                    child: const Text('Bibliothek'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _proof(BuildContext context) {
    return switch (state) {
      RePresentationState(:final delta) => RePresentationView(delta: delta),
      FirstReadingState(:final lastReading) => _FirstReadingProof(
          unknownPercent: (lastReading.unknownRatio * 100).round()),
      BlankSlateState() => Text(
          'Beginne zu lesen.',
          key: const ValueKey('blank-slate'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
    };
  }
}

/// The empty-state proof: the most recently read passage's own unknown
/// ratio, shown once. No Then/Now (there is no "then" yet) — the
/// honest picture of a single reading.
class _FirstReadingProof extends StatelessWidget {
  final int unknownPercent;
  const _FirstReadingProof({required this.unknownPercent});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('first-reading-proof'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('JETZT', style: Theme.of(context).textTheme.labelSmall),
        Text('$unknownPercent%',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('unbekannt', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
