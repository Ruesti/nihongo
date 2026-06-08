import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/tts_service.dart';
import '../../../data/vocab_800.dart';
import 'exercise_base.dart';

/// Audio plays, user types the German meaning
class VocabListenExercise extends StatefulWidget {
  final VocabEntry vocab;
  final OnExerciseDone onDone;

  const VocabListenExercise({
    super.key,
    required this.vocab,
    required this.onDone,
  });

  @override
  State<VocabListenExercise> createState() => _VocabListenExerciseState();
}

class _VocabListenExerciseState extends State<VocabListenExercise> {
  final _controller = TextEditingController();
  bool? _correct;
  bool _submitted = false;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TtsService.instance.speak(widget.vocab.word);
    });
  }

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
      _revealed = true;
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
            'Was hörst du? Gib die Bedeutung auf Deutsch ein.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.ink2),
          ),
        ),
        // Big play button
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
              GestureDetector(
                onTap: () => TtsService.instance.speak(widget.vocab.word),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volume_up,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    TtsService.instance.speakSlow(widget.vocab.word),
                child: Text(
                  'Langsam',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.ink2),
                ),
              ),
              if (_revealed) ...[
                const SizedBox(height: 12),
                Text(widget.vocab.word, style: AppTheme.jpMedium),
                Text(
                  widget.vocab.reading,
                  style:
                      AppTheme.furigana.copyWith(fontSize: 12),
                ),
              ],
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
            onContinue: () => widget.onDone(_correct!),
          ),
      ],
    );
  }
}
