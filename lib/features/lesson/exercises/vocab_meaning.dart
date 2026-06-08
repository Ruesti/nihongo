import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/vocab_800.dart';
import '../../../widgets/audio_button.dart';
import 'exercise_base.dart';

/// Shows a Japanese word, user types the German meaning
class VocabMeaningExercise extends StatefulWidget {
  final VocabEntry vocab;
  final OnExerciseDone onDone;

  const VocabMeaningExercise({
    super.key,
    required this.vocab,
    required this.onDone,
  });

  @override
  State<VocabMeaningExercise> createState() => _VocabMeaningExerciseState();
}

class _VocabMeaningExerciseState extends State<VocabMeaningExercise> {
  final _controller = TextEditingController();
  bool? _correct;
  bool _submitted = false;

  void _submit() {
    if (_submitted) return;
    final correct = isAnswerCorrect(
      _controller.text,
      widget.vocab.meaningDe,
      partial: true,
    );
    setState(() {
      _correct = correct;
      _submitted = true;
    });
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Was bedeutet dieses Wort auf Deutsch?',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.ink2),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(widget.vocab.word, style: AppTheme.jpLarge),
              const SizedBox(height: 4),
              Text(
                widget.vocab.reading,
                style: AppTheme.furigana.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AudioButton(text: widget.vocab.word),
                  const SizedBox(width: 8),
                  AudioButton(text: widget.vocab.word, slow: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_submitted,
            decoration: InputDecoration(
              hintText: 'Deutsche Bedeutung…',
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
            correctAnswer: widget.vocab.meaningDe,
            explanation: _submitted
                ? '${widget.vocab.example}\n→ ${widget.vocab.exampleDe}'
                : null,
            onContinue: () => widget.onDone(_correct!),
          ),
      ],
    );
  }
}
