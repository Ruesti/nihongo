import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/feature_gate.dart';
import '../../core/progress/progress_service.dart';
import '../../core/theme.dart';
import '../../data/lessons.dart';
import '../../models/lesson.dart';
import '../../models/mascot_state.dart';
import 'home_providers.dart';
import 'lesson_grid.dart';
import 'mascot_widget.dart';

// ── screen ─────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  final String lang;

  const HomeScreen({super.key, this.lang = 'ja'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masteryAsync = ref.watch(masteryStatsProvider(lang));
    final statusAsync = ref.watch(lessonStatusProvider(lang));
    final dueAsync = ref.watch(dueCountProvider(lang));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _langTitle(lang),
                style: AppTheme.jpSmall.copyWith(fontSize: 20),
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
            ),
            actions: [
              masteryAsync.when(
                data: (stats) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: MascotWidget(
                    state: tamagoStateFromMastery(stats.masteryFraction),
                    size: 44,
                    animate: true,
                  ),
                ),
                loading: () => const SizedBox(width: 56),
                error: (_, _) => const SizedBox(width: 56),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mastery bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: masteryAsync.when(
                    data: (stats) => _MasteryBar(stats: stats),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
                // Due items banner
                dueAsync.when(
                  data: (count) => count > 0
                      ? _DueBanner(count: count)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
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
                    return LessonGrid(
                      lessons: lessons,
                      statusMap: statusMap,
                      accuracyMap: const {},
                      onTap: (lesson) =>
                          _openLesson(context, lesson, statusMap),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Center(child: Text('Fehler: $e')),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _StoryBanner(),
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

  String _langTitle(String code) {
    switch (code) {
      case 'ko':
        return '한국어';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'it':
        return 'Italiano';
      case 'zh':
        return '中文';
      case 'ja':
      default:
        return '日本語';
    }
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

// ── mastery bar ────────────────────────────────────────────────────────────────

class _MasteryBar extends StatelessWidget {
  final MasteryStats stats;

  const _MasteryBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${stats.totalItems} gelernt',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.ink2),
            ),
            Text(
              '${stats.mastered} gemeistert',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.green, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: stats.masteryFraction,
            minHeight: 6,
            backgroundColor: AppColors.border,
            color: AppColors.green,
          ),
        ),
      ],
    );
  }
}

// ── due banner ─────────────────────────────────────────────────────────────────

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
          const Icon(Icons.refresh_outlined, size: 18, color: AppColors.amber),
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

// ── story banner ───────────────────────────────────────────────────────────────

class _StoryBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/story'),
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
            const Text('📖', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Folge 01 — Regen',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Die erste Manga-Folge lesen',
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

// ── travel banner ──────────────────────────────────────────────────────────────

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
