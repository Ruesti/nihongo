import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/vocab_800.dart';
import 'exercise_base.dart';

class GenderExercise extends StatefulWidget {
  final VocabEntry noun;
  final List<String> options;
  final OnExerciseDone onDone;

  const GenderExercise({
    super.key,
    required this.noun,
    required this.options,
    required this.onDone,
  });

  @override
  State<GenderExercise> createState() => _GenderExerciseState();
}

class _GenderExerciseState extends State<GenderExercise> {
  String? _selected;
  bool _submitted = false;

  String get _correct => widget.noun.gender ?? widget.options.first;

  void _select(String option) {
    if (_submitted) return;
    setState(() {
      _selected = option;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcher Artikel?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink2,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  widget.noun.word,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.noun.meaningDe,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: widget.options.map((opt) {
              Color? borderColor;
              Color? bgColor;
              if (_submitted) {
                if (opt == _correct) {
                  borderColor = AppColors.green;
                  bgColor = AppColors.green.withOpacity(0.08);
                } else if (opt == _selected && opt != _correct) {
                  borderColor = AppColors.red;
                  bgColor = AppColors.red.withOpacity(0.08);
                }
              }
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: _submitted ? null : () => _select(opt),
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: bgColor ?? AppColors.card,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: borderColor ?? AppColors.border,
                          width: borderColor != null ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        opt,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: borderColor ?? AppColors.ink,
                            ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_submitted) ...[
            const SizedBox(height: 24),
            AnswerFeedback(
              correct: _selected == _correct,
              correctAnswer: '${_correct} ${widget.noun.word}',
              explanation: _selected == _correct
                  ? '${_correct} ${widget.noun.word} — ${widget.noun.meaningDe}'
                  : 'Es heißt: ${_correct} ${widget.noun.word}',
              onContinue: () => widget.onDone(_selected == _correct),
            ),
          ],
        ],
      ),
    );
  }
}
