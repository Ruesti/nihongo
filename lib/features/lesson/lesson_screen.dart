import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../core/theme.dart';
import '../../data/lessons.dart';
import '../../data/vocab_800.dart';
import '../../models/lesson.dart';
import '../../models/srs_card.dart';
import '../../widgets/furigana_text.dart';
import '../../widgets/progress_bar.dart';
import '../home/home_screen.dart';
import '../home/mascot_widget.dart';
import 'exercise_factory.dart';
import 'exercises/exercise_base.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final int lessonId;
  final String lang;

  const LessonScreen({super.key, required this.lessonId, this.lang = 'ja'});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  Lesson? _lesson;
  StoryLesson? _storyLesson;
  List<Widget Function(OnExerciseDone)> _exercises = [];
  int _currentIndex = 0;
  int _correct = 0;
  int _total = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _lesson = lessons.firstWhere(
      (l) => l.id == widget.lessonId,
      orElse: () => lessons.first,
    );
    if (_lesson!.category == LessonCategory.story) {
      _storyLesson = storyLessons.firstWhere(
        (s) => s.id == widget.lessonId,
        orElse: () => storyLessons.first,
      );
    } else {
      final factory = ExerciseFactory(
        lesson: _lesson!,
        vocabPool: vocab800,
        userLevel: 1,
      );
      _exercises = factory.buildSession();
      _total = _exercises.length;
    }
  }

  void _onExerciseDone(bool correct) {
    if (correct) _correct++;
    setState(() {
      if (_currentIndex + 1 >= _total) {
        _done = true;
        _saveLessonProgress();
      } else {
        _currentIndex++;
      }
    });
  }

  Future<void> _saveLessonProgress() async {
    final db = ref.read(dbProvider);
    final accuracy = _total > 0 ? (_correct * 100 / _total).round() : 0;
    final xp = _lesson!.xpReward;
    await db.setLessonStatus(
      widget.lessonId,
      3, // completed
      accuracy: accuracy,
      xp: xp,
      lang: widget.lang,
    );
    await db.addXp(xp, lang: widget.lang);
    // Unlock next lesson if accuracy >= 70%
    if (accuracy >= 70) {
      final nextId = widget.lessonId + 1;
      final nextProgress = await db.getLessonProgress(nextId, lang: widget.lang);
      if (nextProgress == null || nextProgress.status == 0) {
        await db.setLessonStatus(nextId, 1, lang: widget.lang);
      }
    }
    // Add vocab to SRS
    for (final cardId in _lesson!.cardIds) {
      final existing = await db.getSrsCard(cardId, lang: widget.lang);
      if (existing == null) {
        await db.upsertSrsCard(SrsCard(
          cardId: cardId,
          front: cardId,
          back: cardId,
          cardType: _lesson!.category.name,
          languageCode: widget.lang,
          dueAt: DateTime.now()
              .add(const Duration(days: 1))
              .millisecondsSinceEpoch,
        ));
      }
    }
    ref.invalidate(userProgressProvider(widget.lang));
    ref.invalidate(lessonStatusProvider(widget.lang));
    ref.invalidate(dueCardsProvider(widget.lang));
  }

  @override
  Widget build(BuildContext context) {
    if (_lesson == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_done) {
      return _LessonCompleteScreen(
        lesson: _lesson!,
        correct: _correct,
        total: _total,
        lang: widget.lang,
        onContinue: () =>
            Navigator.of(context).pushReplacementNamed('/'),
      );
    }

    if (_lesson!.category == LessonCategory.story && _storyLesson != null) {
      return _StoryLessonScreen(
        story: _storyLesson!,
        lesson: _lesson!,
        lang: widget.lang,
        onDone: () {
          setState(() => _done = true);
          _saveLessonProgress();
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson!.titleDe),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: LessonProgressBar(
              current: _currentIndex,
              total: _total,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _exercises.isEmpty
            ? const Center(child: Text('Keine Übungen'))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: _exercises[_currentIndex](_onExerciseDone),
                ),
              ),
      ),
    );
  }
}

// --- Story Lesson ---

class _StoryLessonScreen extends StatefulWidget {
  final StoryLesson story;
  final Lesson lesson;
  final String lang;
  final VoidCallback onDone;

  const _StoryLessonScreen({
    required this.story,
    required this.lesson,
    required this.lang,
    required this.onDone,
  });

  @override
  State<_StoryLessonScreen> createState() => _StoryLessonScreenState();
}

class _StoryLessonScreenState extends State<_StoryLessonScreen> {
  int _step = 0; // 0..sentences.length = story, then questions
  final Map<int, int> _answers = {};
  bool _showTranslation = false;

  bool get _inQuestions => _step >= widget.story.sentences.length;

  int get _questionIndex => _step - widget.story.sentences.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.story.titleDe)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _inQuestions
              ? _buildQuestion()
              : _buildSentence(),
        ),
      ),
    );
  }

  Widget _buildSentence() {
    final sentence = widget.story.sentences[_step];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_step + 1} / ${widget.story.sentences.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              FuriganaText.parse(
                sentence.reading,
                style: AppTheme.jpMedium,
                showFurigana: true,
              ),
              if (_showTranslation || sentence.showTranslation) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  sentence.german,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!_showTranslation && !sentence.showTranslation)
          OutlinedButton(
            onPressed: () => setState(() => _showTranslation = true),
            child: const Text('Übersetzung zeigen'),
          ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => setState(() {
            _step++;
            _showTranslation = false;
          }),
          child: _step + 1 < widget.story.sentences.length
              ? const Text('Weiter')
              : const Text('Zur Aufgabe'),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    if (_questionIndex >= widget.story.questions.length) {
      // All questions done
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return const Center(child: CircularProgressIndicator());
    }
    final q = widget.story.questions[_questionIndex];
    final answered = _answers.containsKey(_questionIndex);
    final selected = _answers[_questionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Frage ${_questionIndex + 1} / ${widget.story.questions.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(q.question, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        ...q.options.asMap().entries.map((e) {
          final idx = e.key;
          final opt = e.value;
          final isSelected = selected == idx;
          final isCorrect = idx == q.correctIndex;
          Color color = AppColors.border;
          if (answered) {
            if (isCorrect) color = AppColors.green;
            else if (isSelected) color = AppColors.red;
          } else if (isSelected) {
            color = AppColors.red;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: answered ? null : () {
                setState(() => _answers[_questionIndex] = idx);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: answered && isCorrect
                      ? AppColors.green.withOpacity(0.08)
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Text(opt,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        if (answered)
          ElevatedButton(
            onPressed: () => setState(() => _step++),
            child: _questionIndex + 1 < widget.story.questions.length
                ? const Text('Nächste Frage')
                : const Text('Lektion beenden'),
          ),
      ],
    );
  }
}

// --- Lesson Complete Screen ---

class _LessonCompleteScreen extends ConsumerWidget {
  final Lesson lesson;
  final int correct;
  final int total;
  final String lang;
  final VoidCallback onContinue;

  const _LessonCompleteScreen({
    required this.lesson,
    required this.correct,
    required this.total,
    required this.lang,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(userProgressProvider(lang));
    final accuracy = total > 0 ? (correct * 100 / total).round() : 0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                progressAsync.when(
                  data: (p) => MascotReward(
                    progress: p,
                    xpGained: lesson.xpReward,
                  ),
                  loading: () => const SizedBox(height: 100),
                  error: (_, __) => const SizedBox(height: 100),
                ),
                const SizedBox(height: 24),
                Text(
                  'Lektion abgeschlossen!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  lesson.titleDe,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.ink2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _StatRow(label: 'Richtig', value: '$correct / $total'),
                _StatRow(label: 'Genauigkeit', value: '$accuracy%'),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    child: const Text('Weiter'),
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
