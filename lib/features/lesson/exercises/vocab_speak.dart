import 'package:flutter/material.dart';

import '../../../core/stt_service.dart';
import '../../../core/theme.dart';
import '../../../core/tts_service.dart';
import '../../../data/vocab_800.dart';
import '../../../widgets/audio_button.dart';
import 'exercise_base.dart';

class VocabSpeakExercise extends StatefulWidget {
  final VocabEntry vocab;
  final OnExerciseDone onDone;

  const VocabSpeakExercise({
    super.key,
    required this.vocab,
    required this.onDone,
  });

  @override
  State<VocabSpeakExercise> createState() => _VocabSpeakExerciseState();
}

class _VocabSpeakExerciseState extends State<VocabSpeakExercise> {
  bool _listening = false;
  String _recognized = '';
  bool _submitted = false;
  bool? _correct;

  Future<void> _listen() async {
    if (_listening) return;
    setState(() => _listening = true);
    final result = await SttService.instance.listen(locale: 'ja_JP');
    if (!mounted) return;
    final sim = SttService.similarity(result, widget.vocab.reading);
    setState(() {
      _listening = false;
      _recognized = result;
      _correct = sim >= 0.7;
      _submitted = result.isNotEmpty;
    });
    if (result.isNotEmpty) {
      // Play feedback TTS
      await TtsService.instance.speak(widget.vocab.word);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Sprich dieses Wort laut aus:',
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
              const SizedBox(height: 8),
              AudioButton(text: widget.vocab.word),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Microphone button
        if (!_submitted) ...[
          Center(
            child: GestureDetector(
              onTap: _listen,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color:
                      _listening ? AppColors.red : AppColors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.red, width: 2),
                ),
                child: Icon(
                  _listening ? Icons.mic : Icons.mic_none,
                  color: _listening ? Colors.white : AppColors.red,
                  size: 40,
                ),
              ),
            ),
          ),
          if (_listening)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  'Spreche jetzt…',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.red),
                ),
              ),
            ),
        ],
        if (_submitted && _recognized.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Erkannt: ',
                    style: Theme.of(context).textTheme.bodySmall),
                Text(
                  _recognized,
                  style: AppTheme.jpBody.copyWith(
                    color: _correct! ? AppColors.green : AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AnswerFeedback(
            correct: _correct!,
            correctAnswer: widget.vocab.reading,
            onContinue: () => widget.onDone(_correct!),
          ),
        ],
        if (_submitted && _recognized.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const Text('Nichts erkannt. Nochmal versuchen?'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _submitted = false;
                      _recognized = '';
                    });
                  },
                  child: const Text('Nochmal'),
                ),
                TextButton(
                  onPressed: () => widget.onDone(false),
                  child: const Text('Überspringen'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
