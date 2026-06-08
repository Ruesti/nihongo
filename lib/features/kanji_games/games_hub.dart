import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';
import 'blitz/blitz_screen.dart';
import 'kanji_data.dart';
import 'memory/memory_screen.dart';
import 'quiz/kanji_quiz_screen.dart';
import 'trace/trace_screen.dart';

class GamesHub extends ConsumerWidget {
  const GamesHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(userProgressProvider('ja'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('遊  Kanji-Spiele'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          progressAsync.when(
            data: (p) => _TamagoGreeting(totalXp: p.totalXp),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              _GameCard(
                title: 'Quiz',
                subtitle: 'Kanji → Bedeutung',
                icon: '日?',
                iconStyle: AppTheme.jpMedium.copyWith(color: AppColors.red),
                description: 'Tippe die deutsche Bedeutung',
                onTap: () => _startQuiz(context),
              ),
              _GameCard(
                title: 'Blitz',
                subtitle: '60 Sekunden',
                icon: '⏱',
                iconStyle: const TextStyle(fontSize: 28),
                description: 'So viele Kanji wie möglich',
                onTap: () => _startBlitz(context),
              ),
              _GameCard(
                title: 'Schreiben',
                subtitle: 'Strichfolge',
                icon: '✏',
                iconStyle: const TextStyle(fontSize: 28),
                description: 'Kanji mit dem Finger nachzeichnen',
                onTap: () => _startTrace(context),
              ),
              _GameCard(
                title: 'Paare',
                subtitle: 'Memory',
                icon: '🀄',
                iconStyle: const TextStyle(fontSize: 28),
                description: 'Kanji und Bedeutung zusammenfinden',
                onTap: () => _startMemory(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _HighscoreSection(ref: ref),
        ],
      ),
    );
  }

  void _startQuiz(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KanjiQuizScreen()),
    );
  }

  void _startBlitz(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BlitzScreen()),
    );
  }

  void _startTrace(BuildContext context) {
    final kanji = (kanjiN5.toList()..shuffle()).first;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TraceScreen(kanji: kanji)),
    );
  }

  void _startMemory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MemoryScreen()),
    );
  }
}

class _TamagoGreeting extends StatelessWidget {
  final int totalXp;

  const _TamagoGreeting({required this.totalXp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('🥚', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kanji-Übungen',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Erkannte Kanji fließen ins SRS-System ein.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final TextStyle iconStyle;
  final String description;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconStyle,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: iconStyle),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ink2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighscoreSection extends StatelessWidget {
  final WidgetRef ref;

  const _HighscoreSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final db = ref.read(dbProvider);
    return FutureBuilder<List<BlitzHighscore>>(
      future: db.getBlitzHighscores(limit: 5),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        final scores = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BLITZ BESTZEITEN',
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
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${s.bestStreak} Serie',
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
        );
      },
    );
  }
}
