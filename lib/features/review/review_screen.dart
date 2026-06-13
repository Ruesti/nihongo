import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/learning_db.dart';
import '../../core/ladder/exercise_content.dart';
import '../../core/ladder/exercise_loader.dart';
import '../../core/ladder/ladder_service.dart';
import '../../core/script_profile.dart';
import '../../core/script_profile_mapper.dart';
import '../../core/srs/scheduler.dart';
import '../../core/theme.dart';
import '../../widgets/audio_button.dart';
import '../../widgets/grade_buttons.dart';
import '../../widgets/progress_bar.dart';

// ── screen ────────────────────────────────────────────────────────────────────

class ReviewScreen extends ConsumerStatefulWidget {
  final String lang;

  const ReviewScreen({super.key, this.lang = 'ja'});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late LearningDb _db;
  late ExerciseLoader _loader;

  List<LearnItem> _queue = [];
  ScriptProfile? _profile;
  ExerciseContent? _content;

  int _index = 0;
  int _correct = 0;
  int _total = 0;
  bool _loading = true;
  bool _done = false;
  bool _revealed = false;
  final TextEditingController _inputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _db = ref.read(learningDbProvider);
    _loader = ExerciseLoader(_db);
    _init();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final langId = 'lang_${widget.lang}';

    final langs = await (_db.select(_db.languages)
          ..where((t) => t.id.equals(langId)))
        .get();

    if (langs.isNotEmpty) {
      final spRows = await (_db.select(_db.scriptProfiles)
            ..where((t) => t.id.equals(langs.first.scriptProfileId)))
          .get();
      if (spRows.isNotEmpty) _profile = profileFromRow(spRows.first);
    }

    if (_profile == null) {
      setState(() {
        _loading = false;
        _done = true;
      });
      return;
    }

    final items = await _db.getDueItems(langId);
    items.shuffle();

    if (items.isEmpty) {
      setState(() {
        _loading = false;
        _done = true;
        _total = 0;
      });
      return;
    }

    _queue = items;
    _total = items.length;
    await _loadContent();
  }

  Future<void> _loadContent() async {
    final content = await _loader.load(_queue[_index], _profile!);
    setState(() {
      _content = content;
      _revealed = false;
      _loading = false;
      _inputCtrl.clear();
    });
  }

  Future<void> _grade(int grade) async {
    final result = switch (grade) {
      0 => ReviewResult.again,
      1 => ReviewResult.hard,
      2 => ReviewResult.good,
      _ => ReviewResult.easy,
    };

    if (result == ReviewResult.good || result == ReviewResult.easy) _correct++;

    final item = _queue[_index];
    final ladderResult = processResult(
      currentRung: item.masteryRung,
      consecutiveCorrect: item.consecutiveCorrect,
      scheduleInput: ScheduleInput(
        ease: item.ease,
        intervalDays: item.intervalDays,
        reps: item.reps,
      ),
      result: result,
    );

    await _db.applyReviewResult(item, ladderResult, result);

    _index++;
    if (_index >= _queue.length) {
      setState(() => _done = true);
    } else {
      await _loadContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_done) {
      return _DoneScreen(
        correct: _correct,
        total: _total,
        onContinue: () => Navigator.of(context).pop(),
      );
    }

    final content = _content!;

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
                child: switch (content) {
                  RecognitionContent() => _RecognitionExercise(
                      content: content,
                      revealed: _revealed,
                      onReveal: () => setState(() => _revealed = true),
                    ),
                  ReadingInputContent() => _ReadingInputExercise(
                      content: content,
                      revealed: _revealed,
                      controller: _inputCtrl,
                      onReveal: () => setState(() => _revealed = true),
                    ),
                  ProductionInputContent() => _ProductionExercise(
                      content: content,
                      revealed: _revealed,
                      controller: _inputCtrl,
                      onReveal: () => setState(() => _revealed = true),
                    ),
                  WriteTraceContent() => _WriteTraceExercise(
                      content: content,
                      revealed: _revealed,
                      onReveal: () => setState(() => _revealed = true),
                    ),
                },
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

// ── exercise widgets ──────────────────────────────────────────────────────────

class _RecognitionExercise extends StatelessWidget {
  final RecognitionContent content;
  final bool revealed;
  final VoidCallback onReveal;

  const _RecognitionExercise({
    required this.content,
    required this.revealed,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _FrontCard(
          displayForm: content.displayForm,
          style: AppTheme.jpLarge,
        ),
        const SizedBox(height: 16),
        if (!revealed)
          _RevealButton(onReveal: onReveal)
        else
          _BackCard(
            child: Text(
              content.answer,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _ReadingInputExercise extends StatelessWidget {
  final ReadingInputContent content;
  final bool revealed;
  final TextEditingController controller;
  final VoidCallback onReveal;

  const _ReadingInputExercise({
    required this.content,
    required this.revealed,
    required this.controller,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _FrontCard(
          displayForm: content.displayForm,
          style: AppTheme.jpLarge,
        ),
        const SizedBox(height: 16),
        if (!revealed) ...[
          _AnswerField(
            controller: controller,
            hint: 'Lesung eingeben',
            onSubmit: onReveal,
          ),
          const SizedBox(height: 8),
          _RevealButton(onReveal: onReveal),
        ] else
          _BackCard(
            child: Column(
              children: [
                if (controller.text.isNotEmpty) ...[
                  _AnswerComparison(
                    typed: controller.text,
                    expected: content.expectedReading,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  content.expectedReading,
                  style: AppTheme.furigana.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProductionExercise extends StatelessWidget {
  final ProductionInputContent content;
  final bool revealed;
  final TextEditingController controller;
  final VoidCallback onReveal;

  const _ProductionExercise({
    required this.content,
    required this.revealed,
    required this.controller,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _FrontCard(
          displayForm: content.prompt,
          style: Theme.of(context).textTheme.headlineLarge!,
        ),
        const SizedBox(height: 16),
        if (!revealed) ...[
          _AnswerField(
            controller: controller,
            hint: 'Schreib die Zielform',
            onSubmit: onReveal,
          ),
          const SizedBox(height: 8),
          _RevealButton(onReveal: onReveal),
        ] else
          _BackCard(
            child: Column(
              children: [
                if (controller.text.isNotEmpty) ...[
                  _AnswerComparison(
                    typed: controller.text,
                    expected: content.expectedForm,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  content.expectedForm,
                  style: AppTheme.jpLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WriteTraceExercise extends StatelessWidget {
  final WriteTraceContent content;
  final bool revealed;
  final VoidCallback onReveal;

  const _WriteTraceExercise({
    required this.content,
    required this.revealed,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _FrontCard(
          displayForm: content.glyph,
          style: AppTheme.jpLarge.copyWith(fontSize: 72),
        ),
        const SizedBox(height: 16),
        if (!revealed)
          _RevealButton(label: 'Fertig', onReveal: onReveal)
        else
          _BackCard(
            child: Text(
              content.expectedReading,
              style: AppTheme.furigana.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

// ── shared sub-widgets ────────────────────────────────────────────────────────

class _FrontCard extends StatelessWidget {
  final String displayForm;
  final TextStyle style;

  const _FrontCard({required this.displayForm, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(displayForm, style: style, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          AudioButton(text: displayForm),
        ],
      ),
    );
  }
}

class _BackCard extends StatelessWidget {
  final Widget child;

  const _BackCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _RevealButton extends StatelessWidget {
  final String label;
  final VoidCallback onReveal;

  const _RevealButton({this.label = 'Antwort zeigen', required this.onReveal});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onReveal,
        child: Text(label),
      ),
    );
  }
}

class _AnswerField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSubmit;

  const _AnswerField({
    required this.controller,
    required this.hint,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      decoration: InputDecoration(hintText: hint),
      onSubmitted: (_) => onSubmit(),
    );
  }
}

class _AnswerComparison extends StatelessWidget {
  final String typed;
  final String expected;

  const _AnswerComparison({required this.typed, required this.expected});

  @override
  Widget build(BuildContext context) {
    final correct =
        typed.trim().toLowerCase() == expected.trim().toLowerCase();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          correct ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: correct ? AppColors.green : AppColors.red,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          typed,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: correct ? AppColors.green : AppColors.red,
              ),
        ),
      ],
    );
  }
}

// ── done screen ───────────────────────────────────────────────────────────────

class _DoneScreen extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onContinue;

  const _DoneScreen({
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
                  _StatRow(label: 'Genauigkeit', value: '$accuracy %'),
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
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
