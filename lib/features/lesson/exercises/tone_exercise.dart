import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/tts_service.dart';
import '../../../data/vocab_800.dart';
import 'exercise_base.dart';

// Shows a Mandarin character + pinyin without tone marks; user picks tone 1–4.
class ToneExercise extends StatefulWidget {
  final VocabEntry word;
  final OnExerciseDone onDone;

  const ToneExercise({super.key, required this.word, required this.onDone});

  @override
  State<ToneExercise> createState() => _ToneExerciseState();
}

class _ToneExerciseState extends State<ToneExercise> {
  int? _selected;
  bool _submitted = false;

  int get _correct => widget.word.tonePattern?.first ?? 1;

  String get _pinyinNoTone {
    final p = widget.word.toneMarked ?? widget.word.romaji;
    return p
        .replaceAll(RegExp(r'[āáǎà]'), 'a')
        .replaceAll(RegExp(r'[ēéěè]'), 'e')
        .replaceAll(RegExp(r'[īíǐì]'), 'i')
        .replaceAll(RegExp(r'[ōóǒò]'), 'o')
        .replaceAll(RegExp(r'[ūúǔù]'), 'u')
        .replaceAll(RegExp(r'[ǖǘǚǜ]'), 'ü');
  }

  static const _toneLabels = ['1. Ton ¯', '2. Ton /', '3. Ton ∨', '4. Ton \\'];
  static const _toneDescriptions = ['hoch, gleichmäßig', 'steigend', 'fallend-steigend', 'fallend'];

  void _select(int tone) {
    if (_submitted) return;
    setState(() {
      _selected = tone;
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
            'Welcher Ton?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink2),
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
                  widget.word.word,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        fontFamily: 'NotoSerifJP',
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _pinyinNoTone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'DMMono',
                        color: AppColors.ink2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.word.meaningDe,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.volume_up_outlined),
                  color: AppColors.ink2,
                  onPressed: () => TtsService.instance.speak(widget.word.word),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: List.generate(4, (i) {
              final tone = i + 1;
              Color? borderColor;
              Color? bgColor;
              if (_submitted) {
                if (tone == _correct) {
                  borderColor = AppColors.green;
                  bgColor = AppColors.green.withValues(alpha: 0.08);
                } else if (tone == _selected && tone != _correct) {
                  borderColor = AppColors.red;
                  bgColor = AppColors.red.withValues(alpha: 0.08);
                }
              }
              return InkWell(
                onTap: _submitted ? null : () => _select(tone),
                borderRadius: BorderRadius.circular(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor ?? AppColors.card,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: borderColor ?? AppColors.border,
                      width: borderColor != null ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _toneLabels[i],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: borderColor ?? AppColors.ink,
                            ),
                      ),
                      Text(
                        _toneDescriptions[i],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: AppColors.ink2,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          if (_submitted) ...[
            const SizedBox(height: 16),
            AnswerFeedback(
              correct: _selected == _correct,
              correctAnswer: '${_correct}. Ton: ${widget.word.toneMarked ?? widget.word.romaji}',
              explanation: '${widget.word.word} = ${widget.word.toneMarked} (${_toneLabels[_correct - 1]})',
              onContinue: () => widget.onDone(_selected == _correct),
            ),
          ],
        ],
      ),
    );
  }
}
