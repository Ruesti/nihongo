import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/lesson.dart';

class LessonGrid extends StatelessWidget {
  final List<Lesson> lessons;
  final Map<int, int> statusMap; // lessonId -> status (0=locked,1=unlocked,2=inProgress,3=completed)
  final Map<int, int> accuracyMap;
  final void Function(Lesson) onTap;

  const LessonGrid({
    super.key,
    required this.lessons,
    required this.statusMap,
    required this.accuracyMap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.4,
      ),
      itemCount: lessons.length,
      itemBuilder: (ctx, i) {
        final lesson = lessons[i];
        final status = statusMap[lesson.id] ?? 0;
        final accuracy = accuracyMap[lesson.id] ?? 0;
        return LessonCard(
          lesson: lesson,
          status: status,
          accuracy: accuracy,
          onTap: () => onTap(lesson),
        );
      },
    );
  }
}

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final int status;
  final int accuracy;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.status,
    required this.accuracy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = status == 0;
    final isCompleted = status == 3;

    return Opacity(
      opacity: isLocked ? 0.45 : 1.0,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isCompleted
                  ? AppColors.green.withOpacity(0.4)
                  : AppColors.border,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryIcon(category: lesson.category),
                  const Spacer(),
                  if (isCompleted)
                    const Icon(Icons.check_circle_outline,
                        size: 14, color: AppColors.green)
                  else if (isLocked)
                    const Icon(Icons.lock_outline,
                        size: 14, color: AppColors.ink2),
                ],
              ),
              const Spacer(),
              Text(
                lesson.titleJp,
                style: AppTheme.jpSmall.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                lesson.titleDe,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.ink2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (status > 0 && accuracy > 0) ...[
                const SizedBox(height: 6),
                _AccuracyBar(accuracy: accuracy),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final LessonCategory category;

  const _CategoryIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (category) {
      case LessonCategory.kana:
        icon = Icons.auto_stories_outlined;
        color = AppColors.red;
      case LessonCategory.vocab:
        icon = Icons.translate_outlined;
        color = AppColors.amber;
      case LessonCategory.grammar:
        icon = Icons.rule_outlined;
        color = AppColors.green;
      case LessonCategory.listening:
        icon = Icons.headphones_outlined;
        color = AppColors.amber;
      case LessonCategory.speaking:
        icon = Icons.mic_none_outlined;
        color = AppColors.red;
      case LessonCategory.story:
        icon = Icons.menu_book_outlined;
        color = AppColors.amber;
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}

class _AccuracyBar extends StatelessWidget {
  final int accuracy;

  const _AccuracyBar({required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final frac = accuracy / 100;
    return ClipRRect(
      borderRadius: BorderRadius.circular(1),
      child: LinearProgressIndicator(
        value: frac,
        minHeight: 3,
        backgroundColor: AppColors.border,
        valueColor: AlwaysStoppedAnimation<Color>(
          frac >= 0.8 ? AppColors.green : AppColors.amber,
        ),
      ),
    );
  }
}
