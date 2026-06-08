import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/kana_data.dart';
import '../../../widgets/audio_button.dart';
import 'exercise_base.dart';

class KanaReadExercise extends StatefulWidget {
  final KanaEntry kana;
  final OnExerciseDone onDone;

  const KanaReadExercise({
    super.key,
    required this.kana,
    required this.onDone,
  });

  @override
  State<KanaReadExercise> createState() => _KanaReadExerciseState();
}

class _KanaReadExerciseState extends State<KanaReadExercise> {
  final _controller = TextEditingController();
  bool? _correct;
  bool _submitted = false;

  void _submit() {
    if (_submitted) return;
    final correct = isAnswerCorrect(_controller.text, widget.kana.romaji);
    setState(() {
      _correct = correct;
      _submitted = true;
    });
  }

  void _next() {
    widget.onDone(_correct ?? false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Wie lautet dieses Zeichen auf Romaji?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink2,
                ),
          ),
        ),
        // Character display
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(widget.kana.kana, style: AppTheme.jpLarge),
              const SizedBox(height: 12),
              AudioButton(text: widget.kana.kana, size: 36),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_submitted,
            decoration: InputDecoration(
              hintText: 'Romaji eingeben…',
              suffixIcon: _submitted
                  ? Icon(
                      _correct! ? Icons.check : Icons.close,
                      color: _correct! ? AppColors.green : AppColors.red,
                    )
                  : null,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: 12),
        if (!_submitted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _controller.text.trim().isEmpty ? null : _submit,
              child: const Text('Prüfen'),
            ),
          ),
        if (_submitted)
          AnswerFeedback(
            correct: _correct!,
            correctAnswer: widget.kana.romaji,
            onContinue: _next,
          ),
      ],
    );
  }
}
