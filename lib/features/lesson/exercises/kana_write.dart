import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/tts_service.dart';
import '../../../data/kana_data.dart';
import 'exercise_base.dart';

/// User hears romaji pronunciation, selects the correct kana
class KanaWriteExercise extends StatefulWidget {
  final KanaEntry kana;
  final List<KanaEntry> distractors;
  final OnExerciseDone onDone;

  const KanaWriteExercise({
    super.key,
    required this.kana,
    required this.distractors,
    required this.onDone,
  });

  @override
  State<KanaWriteExercise> createState() => _KanaWriteExerciseState();
}

class _KanaWriteExerciseState extends State<KanaWriteExercise> {
  String? _selected;
  bool _submitted = false;
  late List<KanaEntry> _options;

  @override
  void initState() {
    super.initState();
    _options = [widget.kana, ...widget.distractors]..shuffle();
    // Auto-play the romaji via TTS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TtsService.instance.speak(widget.kana.romaji);
    });
  }

  void _select(String kana) {
    if (_submitted) return;
    setState(() => _selected = kana);
  }

  void _submit() {
    if (_selected == null || _submitted) return;
    setState(() => _submitted = true);
    TtsService.instance.speak(widget.kana.kana);
  }

  void _next() {
    widget.onDone(_selected == widget.kana.kana);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Welches Zeichen klingt wie „${widget.kana.romaji}"?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink2,
                ),
          ),
        ),
        const SizedBox(height: 8),
        // Options grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.5,
            ),
            itemCount: _options.length,
            itemBuilder: (ctx, i) {
              final opt = _options[i];
              final isSelected = _selected == opt.kana;
              final isCorrect = opt.kana == widget.kana.kana;
              Color borderColor = AppColors.border;
              Color bgColor = AppColors.card;
              if (_submitted) {
                if (isCorrect) {
                  borderColor = AppColors.green;
                  bgColor = AppColors.green.withOpacity(0.08);
                } else if (isSelected && !isCorrect) {
                  borderColor = AppColors.red;
                  bgColor = AppColors.red.withOpacity(0.08);
                }
              } else if (isSelected) {
                borderColor = AppColors.red;
                bgColor = AppColors.red.withOpacity(0.06);
              }
              return InkWell(
                onTap: () => _select(opt.kana),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Center(
                    child: Text(opt.kana, style: AppTheme.jpMedium),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (!_submitted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _selected != null ? _submit : null,
              child: const Text('Prüfen'),
            ),
          ),
        if (_submitted)
          AnswerFeedback(
            correct: _selected == widget.kana.kana,
            correctAnswer: widget.kana.kana,
            onContinue: _next,
          ),
      ],
    );
  }
}
