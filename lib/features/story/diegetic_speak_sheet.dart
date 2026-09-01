import 'package:flutter/material.dart';

import 'speak_evaluator.dart';

/// The skippable, in-fiction speak-along shown at a `diegetic: true` speak
/// panel (brief P6, Folge 01 P07/P22). The reader can hear the word (TTS,
/// [speak]), say it into the mic ([evaluator]), and see gentle feedback. A
/// score ≥ [threshold] fires [onSuccess] exactly once (the caller turns that
/// into the SRS encounter). Nothing gates the story: [onSkip] dismisses the
/// moment at any time with no consequence (INV-1). No pass/fail lock.
class DiegeticSpeakSheet extends StatefulWidget {
  final String targetText;
  final SpeakEvaluator evaluator;
  final Future<void> Function(String text) speak;
  final VoidCallback onSuccess;
  final VoidCallback onSkip;
  final double threshold;

  const DiegeticSpeakSheet({
    super.key,
    required this.targetText,
    required this.evaluator,
    required this.speak,
    required this.onSuccess,
    required this.onSkip,
    this.threshold = 0.6,
  });

  @override
  State<DiegeticSpeakSheet> createState() => _DiegeticSpeakSheetState();
}

class _DiegeticSpeakSheetState extends State<DiegeticSpeakSheet> {
  String? _feedback;
  bool _succeeded = false;

  Future<void> _attempt() async {
    final score = await widget.evaluator.evaluate(widget.targetText);
    if (!mounted) return;
    if (score >= widget.threshold) {
      setState(() => _feedback = 'よくできました ✓');
      if (!_succeeded) {
        _succeeded = true;
        widget.onSuccess();
      }
    } else {
      setState(() => _feedback = 'もう一度どうぞ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('diegetic-speak-sheet'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.targetText, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                key: const ValueKey('diegetic-speak-listen'),
                icon: const Icon(Icons.volume_up),
                label: const Text('anhören'),
                onPressed: () => widget.speak(widget.targetText),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                key: const ValueKey('diegetic-speak-mic'),
                icon: const Icon(Icons.mic),
                label: const Text('nachsprechen'),
                onPressed: _attempt,
              ),
            ],
          ),
          if (_feedback != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _feedback!,
                key: const ValueKey('diegetic-speak-feedback'),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const ValueKey('diegetic-speak-skip'),
              onPressed: widget.onSkip,
              child: const Text('weiter'),
            ),
          ),
        ],
      ),
    );
  }
}
