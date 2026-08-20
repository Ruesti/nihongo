enum CurriculumStepKind { lesson, manga }

/// One authored step on the guided path. Pure data — no Flutter/DB deps.
sealed class CurriculumStep {
  final String id;
  final String chapterRef;
  const CurriculumStep(this.id, this.chapterRef);
}

/// A focused learning step: a few characters + words (+ grammar when content
/// exists), introduced together via the encounter ritual. Never "all kana".
final class LessonStep extends CurriculumStep {
  final List<String> characterIds;
  final List<String> lexemeIds;
  final List<String> grammarIds;
  const LessonStep({
    required String id,
    required String chapterRef,
    required this.characterIds,
    required this.lexemeIds,
    required this.grammarIds,
  }) : super(id, chapterRef);
}

/// A story step: read this installment of the growing comic.
final class MangaStep extends CurriculumStep {
  final String comicAsset; // bundle path to a ComicPack JSON
  const MangaStep({
    required String id,
    required String chapterRef,
    required this.comicAsset,
  }) : super(id, chapterRef);
}

/// A per-language authored path of steps (loaded from assets/curriculum/<lang>.json).
class Curriculum {
  final String languageCode;
  final String title;
  final List<CurriculumStep> steps;
  const Curriculum({
    required this.languageCode,
    required this.title,
    required this.steps,
  });

  factory Curriculum.fromJson(Map<String, dynamic> j) => Curriculum(
        languageCode: j['languageCode'] as String,
        title: j['title'] as String,
        steps: [
          for (final s in (j['steps'] as List? ?? const []))
            _stepFromJson(s as Map<String, dynamic>),
        ],
      );

  static CurriculumStep _stepFromJson(Map<String, dynamic> j) {
    final id = j['id'] as String;
    final chapterRef = j['chapterRef'] as String? ?? '';
    final kind = (j['kind'] as String) == 'manga'
        ? CurriculumStepKind.manga
        : CurriculumStepKind.lesson;
    switch (kind) {
      case CurriculumStepKind.manga:
        return MangaStep(
          id: id,
          chapterRef: chapterRef,
          comicAsset: j['comicAsset'] as String,
        );
      case CurriculumStepKind.lesson:
        return LessonStep(
          id: id,
          chapterRef: chapterRef,
          characterIds: (j['characterIds'] as List?)?.cast<String>() ?? const [],
          lexemeIds: (j['lexemeIds'] as List?)?.cast<String>() ?? const [],
          grammarIds: (j['grammarIds'] as List?)?.cast<String>() ?? const [],
        );
    }
  }
}
