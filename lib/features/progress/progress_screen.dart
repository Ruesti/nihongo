import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/knowledge_providers.dart';
import '../../core/db/learning_db.dart';
import '../../core/progress/progress_service.dart';
import '../../core/theme.dart';

// ── providers ────────────────────────────────────────────────────────────────

final _masteryProvider = FutureProvider.family<MasteryStats, String>(
  (ref, lang) =>
      ref.watch(progressServiceProvider).masteryStats('lang_$lang'),
);

final _retentionProvider = FutureProvider.family<double, String>(
  (ref, lang) =>
      ref.watch(progressServiceProvider).retentionRate('lang_$lang'),
);

final _canDoProvider = FutureProvider.family<List<CanDoGoal>, String>(
  (ref, lang) =>
      ref.watch(progressServiceProvider).achievedGoals('lang_$lang'),
);

final _charProgressProvider =
    FutureProvider.family<List<(Character, int)>, String>((ref, lang) async {
  final db = ref.watch(learningDbProvider);
  final chars = await (db.select(db.characters)
        ..where((t) => t.languageId.equals('lang_$lang')))
      .get();
  if (chars.isEmpty) return [];
  final charIds = chars.map((c) => c.id).toList();
  final items = await (db.select(db.learnItems)
        ..where((t) =>
            t.languageId.equals('lang_$lang') &
            t.refType.equals('character') &
            t.refId.isIn(charIds)))
      .get();
  final rungByRef = {for (final i in items) i.refId: i.masteryRung};
  return chars.map((c) => (c, rungByRef[c.id] ?? 0)).toList();
});

// ── screen ───────────────────────────────────────────────────────────────────

class ProgressScreen extends ConsumerWidget {
  final String lang;

  const ProgressScreen({super.key, this.lang = 'ja'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masteryAsync = ref.watch(_masteryProvider(lang));
    final retentionAsync = ref.watch(_retentionProvider(lang));
    final canDoAsync = ref.watch(_canDoProvider(lang));
    final charsAsync = ref.watch(_charProgressProvider(lang));

    return Scaffold(
      appBar: AppBar(title: const Text('Fortschritt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          masteryAsync.when(
            data: (stats) => _MasteryCard(stats: stats),
            loading: () => const _LoadingCard(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          retentionAsync.when(
            data: (rate) => _RetentionCard(rate: rate),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Was ich kann'),
          const SizedBox(height: 8),
          canDoAsync.when(
            data: (goals) => goals.isEmpty
                ? _EmptyGoals()
                : Column(
                    children: goals.map((g) => _CanDoTile(goal: g)).toList(),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          charsAsync.when(
            data: (entries) {
              if (entries.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const _SectionHeader(title: 'Zeichen'),
                  const SizedBox(height: 8),
                  _CharacterGrid(entries: entries),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── mastery card ─────────────────────────────────────────────────────────────

class _MasteryCard extends StatelessWidget {
  final MasteryStats stats;

  const _MasteryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatPill(label: 'Gelernt', value: '${stats.totalItems}'),
              const SizedBox(width: 8),
              _StatPill(label: 'Produktiv', value: '${stats.productive}'),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Gemeistert',
                value: '${stats.mastered}',
                highlight: true,
              ),
            ],
          ),
          if (stats.totalItems > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: stats.masteryFraction,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.green),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(stats.masteryFraction * 100).round()} % gemeistert',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.ink2),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatPill({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.green.withValues(alpha: 0.08)
              : AppColors.paper2,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: highlight
                ? AppColors.green.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: highlight ? AppColors.green : AppColors.ink,
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
        ),
      ),
    );
  }
}

// ── retention card ────────────────────────────────────────────────────────────

class _RetentionCard extends StatelessWidget {
  final double rate;

  const _RetentionCard({required this.rate});

  @override
  Widget build(BuildContext context) {
    if (rate == 0.0) return const SizedBox.shrink();
    final pct = (rate * 100).round();
    final color = pct >= 80
        ? AppColors.green
        : pct >= 60
            ? AppColors.amber
            : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Behaltensrate (30 Tage)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '$pct %',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ── can-do goals ──────────────────────────────────────────────────────────────

class _CanDoTile extends StatelessWidget {
  final CanDoGoal goal;

  const _CanDoTile({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              goal.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Noch keine Ziele erreicht — weiter üben!',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.ink2),
      ),
    );
  }
}

// ── character grid ────────────────────────────────────────────────────────────

class _CharacterGrid extends StatelessWidget {
  final List<(Character, int)> entries;

  const _CharacterGrid({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: entries
          .map((e) => _CharTile(glyph: e.$1.glyph, rung: e.$2))
          .toList(),
    );
  }
}

class _CharTile extends StatelessWidget {
  final String glyph;
  final int rung;

  const _CharTile({required this.glyph, required this.rung});

  Color get _bg => switch (rung) {
        0 => AppColors.paper2,
        1 || 2 => AppColors.amber.withValues(alpha: 0.12),
        3 || 4 => AppColors.green.withValues(alpha: 0.12),
        _ => AppColors.green.withValues(alpha: 0.25),
      };

  Color get _border => switch (rung) {
        0 => AppColors.border,
        1 || 2 => AppColors.amber.withValues(alpha: 0.4),
        3 || 4 => AppColors.green.withValues(alpha: 0.4),
        _ => AppColors.green,
      };

  Color get _text => switch (rung) {
        0 => AppColors.ink2,
        1 || 2 => AppColors.amber,
        _ => AppColors.green,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Text(
          glyph,
          style: AppTheme.jpBody.copyWith(fontSize: 14, color: _text),
        ),
      ),
    );
  }
}

// ── shared ────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
}
