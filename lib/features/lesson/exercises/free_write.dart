import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import 'exercise_base.dart';

class FreeWriteExercise extends StatefulWidget {
  final String scenario;
  final String task;
  final String taskJp;
  final OnExerciseDone onDone;

  const FreeWriteExercise({
    super.key,
    required this.scenario,
    required this.task,
    required this.taskJp,
    required this.onDone,
  });

  @override
  State<FreeWriteExercise> createState() => _FreeWriteExerciseState();
}

class _FreeWriteExerciseState extends State<FreeWriteExercise> {
  final _controller = TextEditingController();
  String? _feedback;
  bool _loading = false;
  bool _submitted = false;

  Future<void> _getFeedback() async {
    if (_controller.text.trim().isEmpty || _loading) return;
    setState(() => _loading = true);
    final feedback = await AnthropicClient.getFeedback(
      userInput: _controller.text,
      scenario: widget.scenario,
      task: widget.task,
    );
    if (mounted) {
      setState(() {
        _feedback = feedback;
        _loading = false;
        _submitted = true;
      });
    }
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
            widget.task,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink2,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            widget.taskJp,
            style: AppTheme.jpBody,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_submitted,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '日本語で書いてください…',
              alignLabelWithHint: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!_submitted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _controller.text.trim().isEmpty || _loading
                            ? null
                            : _getFeedback,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: Text(_loading ? 'KI analysiert…' : 'KI-Feedback'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => widget.onDone(false),
                  child: const Text('Überspringen'),
                ),
              ],
            ),
          ),
        if (_feedback != null) ...[
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_outlined,
                        size: 16, color: AppColors.green),
                    const SizedBox(width: 6),
                    Text(
                      'KI-Feedback',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.green,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_feedback!,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => widget.onDone(true),
              child: const Text('Weiter'),
            ),
          ),
        ],
      ],
    );
  }
}
