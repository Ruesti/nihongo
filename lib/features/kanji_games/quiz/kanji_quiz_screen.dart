import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database.dart';
import '../../../core/srs.dart';
import '../../../models/srs_card.dart';
import '../../../core/theme.dart';
import '../../../core/tts_service.dart';
import '../kanji_data.dart';
import 'quiz_card.dart';

class _QuizResult {
  final KanjiEntry kanji;
  final String userAnswer;
  final bool correct;

  _QuizResult({
    required this.kanji,
    required this.userAnswer,
    required this.correct,
  });
}

class KanjiQuizScreen extends ConsumerStatefulWidget {
  final List<KanjiEntry>? deck;
  final int deckSize;

  const KanjiQuizScreen({
    super.key,
    this.deck,
    this.deckSize = 10,
  });

  @override
  ConsumerState<KanjiQuizScreen> createState() => _KanjiQuizScreenState();
}

class _KanjiQuizScreenState extends ConsumerState<KanjiQuizScreen> {
  late List<KanjiEntry> _deck;
  int _index = 0;
  bool _showAnswer = false;
  bool? _lastCorrect;
  final _inputCtrl = TextEditingController();
  final _inputFocus = FocusNode();
  final List<_QuizResult> _results = [];
  bool _done = false;
  bool _setupDone = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final source = widget.deck ?? kanjiN5;
    final shuffled = source.toList()..shuffle();
    _deck = shuffled.take(widget.deckSize).toList();
    _setupDone = true;
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  KanjiEntry get _current => _deck[_index];

  bool _checkAnswer(String input) {
    final clean = input.trim().toLowerCase();
    final meanings = _current.meaningDe
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .toList();
    return meanings.any((m) => m.contains(clean) || clean.contains(m));
  }

  void _submit() {
    if (_showAnswer) {
      _next();
      return;
    }
    final correct = _checkAnswer(_inputCtrl.text);
    setState(() {
      _showAnswer = true;
      _lastCorrect = correct;
    });
    _results.add(_QuizResult(
      kanji: _current,
      userAnswer: _inputCtrl.text.trim(),
      correct: correct,
    ));
    TtsService.instance.speak(_current.onyomi.split('、').first);
    _recordInSrs(correct);
  }

  Future<void> _recordInSrs(bool correct) async {
    final db = ref.read(dbProvider);
    final cardId = _current.cardId;
    final existing = await db.getSrsCard(cardId);
    if (existing == null) {
      await db.upsertSrsCard(SrsCard(
        id: 0,
        cardId: cardId,
        front: _current.kanji,
        back: _current.meaningDe,
        reading: _current.kunyomi,
        ease: 2.5,
        interval: 0,
        reps: correct ? 1 : 0,
        dueAt: correct
            ? DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch
            : DateTime.now().millisecondsSinceEpoch,
        cardType: 'kanji',
        languageCode: 'ja',
      ));
    } else {
      final graded = srsGrade(existing, correct ? 2 : 0);
      await db.upsertSrsCard(graded);
    }
  }

  void _next() {
    if (_index >= _deck.length - 1) {
      setState(() => _done = true);
      return;
    }
    setState(() {
      _index++;
      _showAnswer = false;
      _lastCorrect = null;
    });
    _inputCtrl.clear();
    _inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    if (!_setupDone) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_done) return _ResultScreen(results: _results);

    final correctCount = _results.where((r) => r.correct).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz ${_index + 1}/${_deck.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$correctCount ✓',
                style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_index + 1) / _deck.length,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(AppColors.red),
            minHeight: 3,
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: QuizCard(
                kanji: _current,
                showAnswer: _showAnswer,
                wasCorrect: _lastCorrect,
              ),
            ),
          ),
          if (!_showAnswer) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  TextField(
                    controller: _inputCtrl,
                    focusNode: _inputFocus,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Deutsche Bedeutung…',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Prüfen'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lastCorrect == true
                        ? AppColors.green
                        : AppColors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_index >= _deck.length - 1 ? 'Ergebnis' : 'Weiter'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  final List<_QuizResult> results;

  const _ResultScreen({required this.results});

  @override
  Widget build(BuildContext context) {
    final correct = results.where((r) => r.correct).length;
    final total = results.length;
    final pct = total > 0 ? (correct / total * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Ergebnis')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  '$pct%',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.red,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '$correct von $total richtig',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (results.any((r) => !r.correct)) ...[
            Text(
              'FALSCH BEANTWORTET',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ink2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                  ),
            ),
            const SizedBox(height: 8),
            ...results.where((r) => !r.correct).map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(r.kanji.kanji, style: AppTheme.jpMedium),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.kanji.meaningDe,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.green),
                            ),
                            if (r.userAnswer.isNotEmpty)
                              Text(
                                'Du: ${r.userAnswer}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.red),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fertig'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const KanjiQuizScreen(),
                  ),
                );
              },
              child: const Text('Nochmal'),
            ),
          ),
        ],
      ),
    );
  }
}
