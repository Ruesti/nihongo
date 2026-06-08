import 'package:flutter/material.dart';

import '../core/theme.dart';

class GradeButtons extends StatelessWidget {
  final void Function(int grade) onGrade;

  const GradeButtons({super.key, required this.onGrade});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GradeBtn(
          label: 'Nochmal',
          sublabel: '<1 Min.',
          color: AppColors.red,
          grade: 0,
          onTap: onGrade,
          flex: 3,
        ),
        const SizedBox(width: 6),
        _GradeBtn(
          label: 'Schwer',
          sublabel: '',
          color: AppColors.amber,
          grade: 1,
          onTap: onGrade,
          flex: 2,
        ),
        const SizedBox(width: 6),
        _GradeBtn(
          label: 'Gut',
          sublabel: '',
          color: AppColors.green,
          grade: 2,
          onTap: onGrade,
          flex: 2,
        ),
        const SizedBox(width: 6),
        _GradeBtn(
          label: 'Leicht',
          sublabel: '',
          color: AppColors.green,
          grade: 3,
          onTap: onGrade,
          flex: 2,
        ),
      ],
    );
  }
}

class _GradeBtn extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final int grade;
  final void Function(int) onTap;
  final int flex;

  const _GradeBtn({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.grade,
    required this.onTap,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onTap(grade),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              if (sublabel.isNotEmpty)
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
