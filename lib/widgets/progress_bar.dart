import 'package:flutter/material.dart';

import '../core/theme.dart';

class LessonProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const LessonProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.red),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$current/$total',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class XpProgressBar extends StatelessWidget {
  final int xp;
  final int nextXp;
  final String label;

  const XpProgressBar({
    super.key,
    required this.xp,
    required this.nextXp,
    this.label = 'XP',
  });

  @override
  Widget build(BuildContext context) {
    final fraction = nextXp == 0 ? 1.0 : (xp / nextXp).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text('$xp / $nextXp XP',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.amber),
          ),
        ),
      ],
    );
  }
}
