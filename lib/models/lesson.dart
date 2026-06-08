enum LessonCategory {
  kana,
  vocab,
  grammar,
  listening,
  speaking,
  story,
}

enum LessonStatus {
  locked,
  unlocked,
  inProgress,
  completed,
}

class Lesson {
  final int id;
  final String titleJp;
  final String titleDe;
  final String goal;
  final LessonCategory category;
  final List<String> cardIds;
  final int xpReward;
  final String languageCode;

  const Lesson({
    required this.id,
    required this.titleJp,
    required this.titleDe,
    required this.goal,
    required this.category,
    required this.cardIds,
    this.xpReward = 50,
    this.languageCode = 'ja',
  });

  String get categoryLabel {
    switch (category) {
      case LessonCategory.kana:
        return 'Schrift';
      case LessonCategory.vocab:
        return 'Vokabeln';
      case LessonCategory.grammar:
        return 'Grammatik';
      case LessonCategory.listening:
        return 'Hören';
      case LessonCategory.speaking:
        return 'Sprechen';
      case LessonCategory.story:
        return 'Story';
    }
  }
}

class StoryLesson {
  final int id;
  final String title;
  final String titleDe;
  final List<StorySentence> sentences;
  final List<String> vocabUsed;
  final List<StoryQuestion> questions;

  const StoryLesson({
    required this.id,
    required this.title,
    required this.titleDe,
    required this.sentences,
    required this.vocabUsed,
    required this.questions,
  });
}

class StorySentence {
  final String japanese;
  final String reading;
  final String german;
  final bool showTranslation;

  const StorySentence({
    required this.japanese,
    required this.reading,
    required this.german,
    this.showTranslation = false,
  });
}

class StoryQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const StoryQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}
