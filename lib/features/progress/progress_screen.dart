import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/theme.dart';
import '../../data/kana_data.dart';
import '../../models/mascot_state.dart';
import '../../models/srs_card.dart';
import '../../widgets/progress_bar.dart';
import '../home/home_screen.dart';
import '../home/mascot_widget.dart';

class ProgressScreen extends ConsumerWidget {
  final String lang;

  const ProgressScreen({super.key, this.lang = 'ja'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(userProgressProvider(lang));
    final historyAsync = ref.watch(_historyProvider(lang));
    final cardsAsync = ref.watch(_allCardsProvider(lang));

    return Scaffold(
      appBar: AppBar(title: const Text('Fortschritt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mascot + XP
          progressAsync.when(
            data: (p) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    MascotWidget(progress: p, size: 80, animate: true),
                    const SizedBox(height: 12),
                    Text(
                      p.tamagoState.label,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.totalXp} XP gesamt',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.ink2),
                    ),
                    const SizedBox(height: 12),
                    XpProgressBar(
                      xp: p.totalXp % p.xpToNextStage.clamp(1, 9999),
                      nextXp: p.xpToNextStage.clamp(1, 9999),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Card(
                child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          // Stats row
          progressAsync.when(
            data: (p) => Row(
              children: [
                _StatCard(label: 'Lektionen', value: '${p.completedLessons}'),
                const SizedBox(width: 8),
                _StatCard(label: 'Karten', value: '${p.totalCardsLearned}'),
                const SizedBox(width: 8),
                _StatCard(label: 'Gespräche', value: '${p.conversationSessions}'),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          // Study history chart
          _SectionHeader(title: 'Aktivität (30 Tage)'),
          const SizedBox(height: 8),
          historyAsync.when(
            data: (history) => _StudyHistoryChart(history: history),
            loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          // Kana progress
          if (lang == 'ja') ...[
            _SectionHeader(title: 'Hiragana Fortschritt'),
            const SizedBox(height: 8),
            cardsAsync.when(
              data: (cards) => _KanaProgress(cards: cards),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

final _historyProvider = FutureProvider.family<List<StudyHistoryData>, String>(
  (ref, lang) => ref.read(dbProvider).getStudyHistory(lang: lang),
);

final _allCardsProvider = FutureProvider.family<List<SrsCard>, String>(
  (ref, lang) => ref.read(dbProvider).getAllCards(lang: lang),
);

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(color: AppColors.red),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyHistoryChart extends StatelessWidget {
  final List<StudyHistoryData> history;

  const _StudyHistoryChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            'Noch keine Aktivität',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.ink2),
          ),
        ),
      );
    }

    final maxCards =
        history.map((h) => h.cardsStudied).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: history.map((h) {
          final frac = maxCards > 0 ? h.cardsStudied / maxCards : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FractionallySizedBox(
                heightFactor: frac.clamp(0.05, 1.0),
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.7),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KanaProgress extends StatelessWidget {
  final List<SrsCard> cards;

  const _KanaProgress({required this.cards});

  @override
  Widget build(BuildContext context) {
    final learnedIds =
        cards.where((c) => c.reps > 0).map((c) => c.cardId).toSet();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: hiragana.map((k) {
        final learned = learnedIds.contains(k.cardId);
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: learned
                ? AppColors.green.withOpacity(0.12)
                : AppColors.card,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: learned ? AppColors.green.withOpacity(0.4) : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              k.kana,
              style: AppTheme.jpBody.copyWith(
                fontSize: 12,
                color: learned ? AppColors.green : AppColors.ink2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
