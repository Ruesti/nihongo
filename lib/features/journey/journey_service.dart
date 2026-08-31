import '../../core/db/learning_db.dart';
import '../../core/ladder/rung_defs.dart';
import 'curriculum.dart';

/// Computes the learner's current position on the guided path: starting from a
/// stored index, skip forward over lesson steps whose items are ALL already
/// known (so a vocab-knower isn't re-taught), and stop at the first real step.
/// Manga steps are never skipped — reading is always worthwhile.
class JourneyService {
  final Curriculum curriculum;
  final LearningDb learning;
  final String languageId; // e.g. 'lang_ja'

  const JourneyService({
    required this.curriculum,
    required this.learning,
    required this.languageId,
  });

  Future<int?> resolveStepIndex(int fromIndex) async {
    var i = fromIndex;
    while (i < curriculum.steps.length) {
      final step = curriculum.steps[i];
      if (step is LessonStep && await _lessonAlreadyKnown(step)) {
        i++;
        continue;
      }
      return i;
    }
    return null; // path complete
  }

  Future<bool> _lessonAlreadyKnown(LessonStep step) async {
    final refs = <(RefType, String)>[
      for (final id in step.characterIds) (RefType.character, id),
      for (final id in step.lexemeIds) (RefType.lexeme, id),
      for (final id in step.grammarIds) (RefType.grammar, id),
    ];
    if (refs.isEmpty) return false; // an empty lesson is never "known"
    for (final (refType, refId) in refs) {
      final item =
          await learning.getLearnItem('$languageId:${refType.name}:$refId');
      if (item == null || item.masteryRung < 1) {
        return false; // not yet introduced, or introduced-but-not-encountered
      }
    }
    return true;
  }
}
