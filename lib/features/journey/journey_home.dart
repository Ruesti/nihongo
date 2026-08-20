import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export '../../app/knowledge_providers.dart' show learningDbProvider;
import '../../l10n/app_localizations.dart';
import '../language_select/language_select_screen.dart';
import 'curriculum.dart';
import 'journey_providers.dart';
import 'lesson_step_screen.dart';
import 'manga_step_launcher.dart';

/// The guided path — the app's front door. Shows the current chapter and one
/// calm call-to-action that runs the current step, then advances. No grid,
/// no points, no drill queue.
class JourneyHome extends ConsumerWidget {
  const JourneyHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final stepAsync = ref.watch(currentStepProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: stepAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (step) {
              if (step == null) {
                return Center(child: Text(l.journeyPathComplete));
              }
              final isLesson = step is LessonStep;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(step.chapterRef,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(
                    isLesson ? l.journeyLessonStepTitle : l.journeyMangaStepTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey('journey-start'),
                    onPressed: () => _runStep(context, ref, step),
                    child: Text(l.journeyStart),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _runStep(
      BuildContext context, WidgetRef ref, CurriculumStep step) async {
    final lang = ref.read(activeLanguageProvider);
    bool completed = false;
    if (step is LessonStep) {
      final result = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => LessonStepScreen(
          step: step,
          languageId: 'lang_$lang',
          onDone: () => Navigator.of(context).pop(true),
        ),
      ));
      completed = result == true;
    } else if (step is MangaStep) {
      completed = await openMangaStep(context, ref, step);
    }
    if (!completed) return; // backed out / could not run → do not advance
    // Advance the stored index and refresh the resolved step.
    final progress = await ref.read(journeyProgressProvider.future);
    await progress.setStepIndex(lang, _indexAfter(ref, step));
    ref.invalidate(currentStepProvider);
  }

  /// The next raw index after the given step (progress is a monotonically
  /// advancing cursor; resolveStepIndex handles skipping known steps).
  int _indexAfter(WidgetRef ref, CurriculumStep step) {
    final curriculum = ref.read(curriculumProvider).valueOrNull;
    if (curriculum == null) return 0;
    final i = curriculum.steps.indexWhere((s) => s.id == step.id);
    return i < 0 ? 0 : i + 1;
  }
}
