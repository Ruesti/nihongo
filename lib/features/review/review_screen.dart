import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/srs.dart';
import '../../core/theme.dart';
import '../../models/srs_card.dart';
import '../../widgets/audio_button.dart';
import '../../widgets/grade_buttons.dart';
import '../../widgets/progress_bar.dart';
import '../home/home_screen.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String lang;

  const ReviewScreen({super.key, this.lang = 'ja'});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<SrsCard> _cards = [];
  int _index = 0;
  bool _revealed = false;
  bool _loading = true;
  int _correct = 0;
  int _total = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final db = ref.read(dbProvider);
    final cards = await db.getDueCards(lang: widget.lang);
    cards.shuffle();
    setState(() {
      _cards = cards;
      _total = cards.length;
      _loading = false;
    });
  }

  Future<void> _grade(int grade) async {
    final db = ref.read(dbProvider);
    final card = _cards[_index];
    final updated = srsGrade(card, grade);
    await db.upsertSrsCard(updated);
    if (grade >= 2) _correct++;
    setState(() {
      if (_index + 1 >= _cards.length) {
        _done = true;
        _finishSession();
      } else {
        _index++;
        _revealed = false;
      }
    });
  }

  Future<void> _finishSession() async {
    final db = ref.read(dbProvider);
    await db.recordStudySession(
      _total,
      _correct,
      (_total * 0.4).round(),
      lang: widget.lang,
    );
    await db.incrementCardsLearned(_correct, lang: widget.lang);
    ref.invalidate(userProgressProvider(widget.lang));
    ref.invalidate(dueCardsProvider(widget.lang));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_done || _cards.isEmpty) {
      return _ReviewDoneScreen(
        correct: _correct,
        total: _total,
        onContinue: () => Navigator.of(context).pop(),
      );
    }

    final card = _cards[_index];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wiederholung'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: LessonProgressBar(current: _index, total: _total),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Card front
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Text(card.front, style: AppTheme.jpLarge),
                          const SizedBox(height: 12),
                          AudioButton(text: card.front),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_revealed)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _revealed = true),
                          child: const Text('Antwort zeigen'),
                        ),
                      )
                    else ...[
                      // Card back
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              card.back,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            if (card.reading != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                card.reading!,
                                style: AppTheme.furigana
                                    .copyWith(fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_revealed)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Wie gut erinnerst du dich?',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    GradeButtons(onGrade: _grade),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewDoneScreen extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onContinue;

  const _ReviewDoneScreen({
    required this.correct,
    required this.total,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = total > 0 ? (correct * 100 / total).round() : 0;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  total == 0
                      ? 'Keine fälligen Karten'
                      : 'Wiederholung fertig!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                if (total > 0) ...[
                  const SizedBox(height: 24),
                  _StatRow(label: 'Karten', value: '$total'),
                  _StatRow(label: 'Richtig', value: '$correct'),
                  _StatRow(label: 'Genauigkeit', value: '$accuracy%'),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    child: const Text('Zurück'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
