import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../widgets/audio_button.dart';
import 'exercise_base.dart';

class SentenceBuildExercise extends StatefulWidget {
  final String sentence;
  final String translation;
  final OnExerciseDone onDone;

  const SentenceBuildExercise({
    super.key,
    required this.sentence,
    required this.translation,
    required this.onDone,
  });

  @override
  State<SentenceBuildExercise> createState() =>
      _SentenceBuildExerciseState();
}

class _SentenceBuildExerciseState extends State<SentenceBuildExercise> {
  late List<String> _tokens;
  late List<String> _shuffled;
  final List<String> _placed = [];
  bool _submitted = false;
  bool? _correct;

  @override
  void initState() {
    super.initState();
    _tokens = _tokenize(widget.sentence);
    _shuffled = List.of(_tokens)..shuffle();
  }

  List<String> _tokenize(String sentence) {
    // Split Japanese sentence at common boundaries
    final result = <String>[];
    final words = sentence.split(RegExp(r'(?=[をはがにでもとのをからまで])'));
    for (final w in words) {
      if (w.isNotEmpty) result.add(w);
    }
    if (result.length <= 1) {
      // Fallback: split by 2-3 chars
      int i = 0;
      while (i < sentence.length) {
        final end = (i + 3).clamp(0, sentence.length);
        result.add(sentence.substring(i, end));
        i = end;
      }
      return result;
    }
    return result;
  }

  void _tap(String token, bool fromShuffled) {
    if (_submitted) return;
    setState(() {
      if (fromShuffled) {
        _shuffled.remove(token);
        _placed.add(token);
      } else {
        _placed.remove(token);
        _shuffled.add(token);
      }
    });
  }

  void _submit() {
    if (_placed.isEmpty || _submitted) return;
    final userSentence = _placed.join('');
    final correct = userSentence == widget.sentence;
    setState(() {
      _correct = correct;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Bringe die Wörter in die richtige Reihenfolge:',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.ink2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.translation,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 16),
        // Answer area
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minHeight: 60),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _submitted
                  ? (_correct! ? AppColors.green : AppColors.red)
                  : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _placed
                .map(
                  (t) => InkWell(
                    onTap: () => _tap(t, false),
                    child: _TokenChip(text: t, placed: true),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Source tokens
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _shuffled
                .map(
                  (t) => InkWell(
                    onTap: () => _tap(t, true),
                    child: _TokenChip(text: t, placed: false),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (!_submitted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                AudioButton(text: widget.sentence),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _placed.isNotEmpty ? _submit : null,
                    child: const Text('Prüfen'),
                  ),
                ),
              ],
            ),
          ),
        if (_submitted)
          AnswerFeedback(
            correct: _correct!,
            correctAnswer: widget.sentence,
            onContinue: () => widget.onDone(_correct!),
          ),
      ],
    );
  }
}

class _TokenChip extends StatelessWidget {
  final String text;
  final bool placed;

  const _TokenChip({required this.text, required this.placed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: placed ? AppColors.red.withOpacity(0.08) : AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: placed ? AppColors.red.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Text(
        text,
        style: AppTheme.jpBody.copyWith(fontSize: 18),
      ),
    );
  }
}
