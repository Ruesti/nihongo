import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database.dart';
import '../../../core/theme.dart';
import 'blitz_screen.dart';

class BlitzResult extends ConsumerWidget {
  final int score;
  final int bestStreak;
  final int totalAnswered;
  final int correctAnswered;

  const BlitzResult({
    super.key,
    required this.score,
    required this.bestStreak,
    required this.totalAnswered,
    required this.correctAnswered,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accuracy =
        totalAnswered > 0 ? (correctAnswered / totalAnswered * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Ergebnis')),
      body: FutureBuilder<List<BlitzHighscore>>(
        future: ref.read(dbProvider).getBlitzHighscores(limit: 5),
        builder: (context, snap) {
          final scores = snap.data ?? [];
          final isHighscore =
              scores.isNotEmpty && scores.first.score <= score;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (isHighscore)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏆 '),
                      Text(
                        'Neuer Highscore!',
                        style: TextStyle(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              _ScoreCard(
                score: score,
                accuracy: accuracy,
                bestStreak: bestStreak,
                totalAnswered: totalAnswered,
              ),
              if (scores.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'BESTENLISTE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.ink2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: scores.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, i) {
                      final s = scores[i];
                      final isThis = s.score == score && i == 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Text(
                              '${i + 1}.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.ink2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${s.score} Punkte',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: isThis
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: isThis ? AppColors.red : null,
                                  ),
                            ),
                            const Spacer(),
                            Text(
                              'Serie ${s.bestStreak}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.amber),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const BlitzScreen()),
                  ),
                  child: const Text('Nochmal'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Zurück'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final int accuracy;
  final int bestStreak;
  final int totalAnswered;

  const _ScoreCard({
    required this.score,
    required this.accuracy,
    required this.bestStreak,
    required this.totalAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            '$score',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.red,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            'Punkte',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.ink2),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(label: 'Genauigkeit', value: '$accuracy%'),
              _Stat(label: 'Beste Serie', value: '$bestStreak'),
              _Stat(label: 'Gesamt', value: '$totalAnswered'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.red,
              ),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.ink2),
        ),
      ],
    );
  }
}
