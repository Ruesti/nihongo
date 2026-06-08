import 'package:flutter/material.dart';

import '../../core/stt_service.dart';
import '../../core/theme.dart';
import '../../core/tts_service.dart';
import '../../models/conversation.dart';

class ShadowingScreen extends StatefulWidget {
  final ConversationClip clip;

  const ShadowingScreen({super.key, required this.clip});

  @override
  State<ShadowingScreen> createState() => _ShadowingScreenState();
}

class _ShadowingScreenState extends State<ShadowingScreen> {
  int _lineIndex = 0;
  bool _showReading = false;
  bool _showTranslation = false;
  bool _isListening = false;
  String _lastRecognized = '';
  bool? _lastCorrect;

  ClipLine get _current => widget.clip.lines[_lineIndex];
  bool get _isLast => _lineIndex >= widget.clip.lines.length - 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playTts());
  }

  void _playTts() {
    TtsService.instance.speak(_current.text);
  }

  Future<void> _listen() async {
    setState(() {
      _isListening = true;
      _lastRecognized = '';
      _lastCorrect = null;
    });

    final recognized = await SttService.instance.listen(
      locale: 'ja_JP',
      seconds: 6,
    );

    if (!mounted) return;
    setState(() {
      _isListening = false;
      _lastRecognized = recognized;
      if (recognized.isNotEmpty) {
        _lastCorrect = SttService.similarity(recognized, _current.text) >= 0.6;
      }
    });
  }

  void _nextLine() {
    if (_isLast) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _lineIndex++;
      _showReading = false;
      _showTranslation = false;
      _lastRecognized = '';
      _lastCorrect = null;
    });
    _playTts();
  }

  @override
  void dispose() {
    SttService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clip.titleDe),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_lineIndex + 1) / widget.clip.lines.length,
            backgroundColor: AppColors.border,
            color: AppColors.green,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_lineIndex + 1} / ${widget.clip.lines.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ink2,
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    _current.text,
                    style: AppTheme.jpBody.copyWith(fontSize: 28),
                    textAlign: TextAlign.center,
                  ),
                  if (_showReading) ...[
                    const SizedBox(height: 8),
                    Text(
                      _current.reading,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'DMMono',
                            color: AppColors.ink2,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_showTranslation) ...[
                    const SizedBox(height: 8),
                    Text(
                      _current.translationDe,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.ink2,
                            fontStyle: FontStyle.italic,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up_outlined),
                        color: AppColors.ink2,
                        tooltip: 'Abspielen',
                        onPressed: _isListening ? null : _playTts,
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showReading = !_showReading),
                        child: Text(
                          _showReading ? 'Lesung ▲' : 'Lesung ▼',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(
                            () => _showTranslation = !_showTranslation),
                        child: Text(
                          _showTranslation ? 'Übers. ▲' : 'Übers. ▼',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isListening ? null : _listen,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? AppColors.red : AppColors.card,
                        border: Border.all(
                          color:
                              _isListening ? AppColors.red : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: _isListening
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.mic_none_outlined,
                              size: 32,
                              color: AppColors.ink2,
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isListening ? 'Aufnahme läuft…' : 'Tippen zum Sprechen',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.ink2,
                        ),
                  ),
                ],
              ),
            ),
            if (_lastRecognized.isNotEmpty || _lastCorrect != null) ...[
              const SizedBox(height: 16),
              _FeedbackBanner(
                recognized: _lastRecognized,
                correct: _lastCorrect,
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isListening ? null : _nextLine,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.paper,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(_isLast ? 'Fertig' : 'Weiter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String recognized;
  final bool? correct;

  const _FeedbackBanner({required this.recognized, required this.correct});

  @override
  Widget build(BuildContext context) {
    final color = correct == null
        ? AppColors.ink2
        : correct!
            ? AppColors.green
            : AppColors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (correct != null)
            Text(
              correct! ? 'Sehr gut!' : 'Weiter üben',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
          if (recognized.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              recognized,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'NotoSerifJP',
                    color: AppColors.ink,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
