import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/database.dart';
import '../../core/feature_gate.dart';
import '../../core/theme.dart';
import '../../data/lessons.dart';
import '../../models/lesson.dart';
import '../../models/mascot_state.dart';
import '../../models/progress.dart';
import '../../widgets/progress_bar.dart';
import 'lesson_grid.dart';
import 'mascot_widget.dart';

final userProgressProvider = FutureProvider.family<UserProgress, String>(
  (ref, lang) async {
    final db = ref.read(dbProvider);
    final stats = await db.getUserStats(lang: lang);
    final lessonProgress = await db.getAllLessonProgress(lang: lang);
    final completed = lessonProgress.where((p) => p.status == 3).length;
    return UserProgress(
      languageCode: lang,
      totalXp: stats?.totalXp ?? 0,
      totalCardsLearned: stats?.totalCardsLearned ?? 0,
      completedLessons: completed,
      conversationSessions: stats?.conversationSessions ?? 0,
    );
  },
);

final lessonStatusProvider = FutureProvider.family<Map<int, int>, String>(
  (ref, lang) async {
    final db = ref.read(dbProvider);
    final all = await db.getAllLessonProgress(lang: lang);
    final map = <int, int>{};
    for (final p in all) {
      map[p.lessonId] = p.status;
    }
    // Ensure lesson 1 is always unlocked
    if (!map.containsKey(1)) map[1] = 1;
    return map;
  },
);

final dueCardsProvider = FutureProvider.family<int, String>(
  (ref, lang) async {
    final db = ref.read(dbProvider);
    final cards = await db.getDueCards(lang: lang);
    return cards.length;
  },
);

class HomeScreen extends ConsumerWidget {
  final String lang;

  const HomeScreen({super.key, this.lang = 'ja'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(userProgressProvider(lang));
    final statusAsync = ref.watch(lessonStatusProvider(lang));
    final dueAsync = ref.watch(dueCardsProvider(lang));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '日本語',
                style: AppTheme.jpSmall.copyWith(fontSize: 20),
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
            ),
            actions: [
              progressAsync.when(
                data: (p) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: MascotWidget(
                    progress: p,
                    size: 44,
                    animate: true,
                  ),
                ),
                loading: () => const SizedBox(width: 56),
                error: (_, __) => const SizedBox(width: 56),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // XP bar and due cards
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: progressAsync.when(
                    data: (p) => XpProgressBar(
                      xp: p.totalXp,
                      nextXp: p.xpToNextStage,
                      label: p.tamagoState.label,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
                // Due cards banner
                dueAsync.when(
                  data: (count) => count > 0
                      ? _DueBanner(count: count)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Lektionen',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 8),
                statusAsync.when(
                  data: (statusMap) {
                    final accuracy = <int, int>{};
                    return LessonGrid(
                      lessons: lessons,
                      statusMap: statusMap,
                      accuracyMap: accuracy,
                      onTap: (lesson) =>
                          _openLesson(context, lesson, statusMap),
                    );
                  },
                  loading: () => const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )),
                  error: (e, _) =>
                      Center(child: Text('Fehler: $e')),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TravelBanner(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLesson(
      BuildContext context, Lesson lesson, Map<int, int> statusMap) async {
    final allowed = await FeatureGate.canAccessLesson(lesson, lang: lang);
    if (!context.mounted) return;
    if (allowed) {
      context.push('/lesson/${lesson.id}');
    } else {
      _showPaywall(context);
    }
  }

  void _showPaywall(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lektion gesperrt'),
        content: Text(
          'Lektionen ab Nr. 16 sind Teil des Vollzugangs. '
          'Schalte alle Lektionen für ${_langDisplayName(lang)} frei.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.paper,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/settings');
            },
            child: const Text('Freischalten'),
          ),
        ],
      ),
    );
  }

  String _langDisplayName(String code) {
    switch (code) {
      case 'ko':
        return 'Koreanisch';
      case 'es':
        return 'Spanisch';
      case 'fr':
        return 'Französisch';
      case 'it':
        return 'Italienisch';
      case 'zh':
        return 'Mandarin';
      case 'ja':
      default:
        return 'Japanisch';
    }
  }
}

class _DueBanner extends StatelessWidget {
  final int count;

  const _DueBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.refresh_outlined,
              size: 18, color: AppColors.amber),
          const SizedBox(width: 8),
          Text(
            '$count Karten zur Wiederholung',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.amber,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => context.push('/review'),
            child: const Text(
              'Jetzt',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.amber,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/travel'),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Text('✈', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reise-Schnellkurs',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    '50 Phrasen für dein nächstes Reiseziel',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.ink2),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.ink2),
          ],
        ),
      ),
    );
  }
}
