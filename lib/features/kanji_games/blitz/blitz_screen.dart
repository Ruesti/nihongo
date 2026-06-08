import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database.dart';
import '../../../core/srs.dart';
import '../../../models/srs_card.dart';
import '../../../core/theme.dart';
import '../kanji_data.dart';
import 'blitz_result.dart';

class BlitzScreen extends ConsumerStatefulWidget {
  const BlitzScreen({super.key});

  @override
  ConsumerState<BlitzScreen> createState() => _BlitzScreenState();
}

class _BlitzScreenState extends ConsumerState<BlitzScreen> {
  static const _totalSeconds = 60;

  late List<KanjiEntry> _shuffled;
  int _currentIndex = 0;
  int _timeLeft = _totalSeconds;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _started = false;
  bool _done = false;
  bool _showCorrect = false;

  final _inputCtrl = TextEditingController();
  final _inputFocus = FocusNode();
  Timer? _timer;

  final List<bool> _history = [];

  @override
  void initState() {
    super.initState();
    _shuffled = kanjiN5.toList()..shuffle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inputCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  KanjiEntry get _current => _shuffled[_currentIndex % _shuffled.length];

  void _startGame() {
    setState(() => _started = true);
    _inputFocus.requestFocus();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft <= 1) {
        _endGame();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() => _done = true);
    _saveHighscore();
  }

  Future<void> _saveHighscore() async {
    final db = ref.read(dbProvider);
    await db.addBlitzHighscore(
      _score,
      _history.where((b) => b).length,
      _bestStreak,
    );
  }

  bool _checkAnswer(String input) {
    final clean = input.trim().toLowerCase();
    if (clean.isEmpty) return false;
    final meanings = _current.meaningDe
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .toList();
    return meanings.any((m) => m.contains(clean) || clean.contains(m));
  }

  void _submit() {
    final correct = _checkAnswer(_inputCtrl.text);
    _history.add(correct);
    _inputCtrl.clear();

    if (correct) {
      setState(() {
        _score++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
      });
      _recordInSrs(true);
      _advance();
    } else {
      setState(() {
        _showCorrect = true;
        _streak = 0;
      });
      _recordInSrs(false);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _showCorrect = false);
          _advance();
        }
      });
    }
  }

  void _advance() {
    setState(() => _currentIndex++);
    if (_currentIndex >= _shuffled.length) {
      _shuffled = kanjiN5.toList()..shuffle();
      _currentIndex = 0;
    }
    _inputFocus.requestFocus();
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
      await db.upsertSrsCard(srsGrade(existing, correct ? 2 : 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return BlitzResult(
        score: _score,
        bestStreak: _bestStreak,
        totalAnswered: _history.length,
        correctAnswered: _history.where((b) => b).length,
      );
    }

    if (!_started) {
      return _StartScreen(onStart: _startGame);
    }

    final timerColor = _timeLeft <= 10 ? AppColors.red : AppColors.ink;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '⏱ $_timeLeft s',
          style: TextStyle(
            color: timerColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_streak >= 5)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Serie: $_streak 🔥',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _timeLeft / _totalSeconds,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(timerColor),
            minHeight: 4,
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      _current.kanji,
                      key: ValueKey(_currentIndex),
                      style: AppTheme.jpLarge.copyWith(fontSize: 96),
                    ),
                  ),
                  if (_showCorrect) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.green.withOpacity(0.4)),
                      ),
                      child: Text(
                        _current.meaningDe,
                        style: TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Punkte: $_score',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.ink2),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    focusNode: _inputFocus,
                    decoration: const InputDecoration(
                      hintText: 'Bedeutung eingeben…',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
          _HistoryRow(history: _history),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StartScreen extends StatelessWidget {
  final VoidCallback onStart;

  const _StartScreen({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blitz-Runde')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⏱', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                '60 Sekunden',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tippe so schnell wie möglich die deutsche Bedeutung der Kanji.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onStart,
                  child: const Text('Starten'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final List<bool> history;

  const _HistoryRow({required this.history});

  @override
  Widget build(BuildContext context) {
    final recent = history.reversed.take(12).toList().reversed.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: recent.map((correct) {
          return Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: correct
                  ? AppColors.green.withOpacity(0.7)
                  : AppColors.red.withOpacity(0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
  }
}
