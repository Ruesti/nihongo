import 'package:flutter/material.dart';

import '../../core/pipeline/passage_snapshot.dart';

/// The Then/Now re-presentation proof (SPEC_MINING_PIPELINE.md §7/§8):
/// the measured change between two readings of the same passage, shown
/// honestly. The unknown-ratio delta is the headline; lookups and dwell
/// are secondary (§7 — dwell is noisy, shown with less weight). A
/// regression (the passage got *harder*) is displayed plainly, never
/// hidden (§0.9.29) — that honesty is the whole point of the
/// instrument, so this widget has no "hide if negative" path.
///
/// No score, no streak (I3): these are real measurements of retention,
/// not invented currency.
class RePresentationView extends StatelessWidget {
  final PassageDelta delta;

  const RePresentationView({super.key, required this.delta});

  static String _pct(double ratio) => '${(ratio * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final regressed = delta.isRegression;
    final unchanged = !delta.isImprovement && !delta.isRegression;
    final accent = regressed
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Card(
      key: const ValueKey('re-presentation'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ThenNow(label: 'DAMALS', value: _pct(delta.before.unknownRatio)),
                Icon(regressed ? Icons.arrow_upward : Icons.arrow_downward,
                    color: accent),
                _ThenNow(label: 'JETZT', value: _pct(delta.after.unknownRatio)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              key: const ValueKey('delta-headline'),
              regressed
                  ? 'Unbekannt: ${_pct(delta.before.unknownRatio)} → '
                      '${_pct(delta.after.unknownRatio)} — schwerer geworden.'
                  : unchanged
                      ? 'Unbekannt unverändert bei ${_pct(delta.after.unknownRatio)}.'
                      : 'Unbekannt: ${_pct(delta.before.unknownRatio)} → '
                          '${_pct(delta.after.unknownRatio)}.',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: accent),
            ),
            const SizedBox(height: 8),
            // Secondary signals, less prominent (§7).
            DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.bodySmall!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nachschlagen: ${delta.before.lookupCount} → '
                      '${delta.after.lookupCount}'),
                  if (delta.dwellMsChange != null)
                    Text('Verweildauer: '
                        '${_secs(delta.before.dwellMs!)} → '
                        '${_secs(delta.after.dwellMs!)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _secs(int ms) => '${(ms / 1000).round()}s';
}

class _ThenNow extends StatelessWidget {
  final String label;
  final String value;
  const _ThenNow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}
