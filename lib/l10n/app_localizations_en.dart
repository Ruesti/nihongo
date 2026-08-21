// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome.';

  @override
  String get welcomeBody =>
      'Here you learn Japanese by reading it — at your pace, character by character.';

  @override
  String get methodEncounterFirst =>
      'You meet every character, word and grammar point first — see it, hear it, trace it — before you are ever tested.';

  @override
  String get methodNoGamification =>
      'No points, no streaks. Your progress is what you can actually read.';

  @override
  String get methodOffline => 'Everything works offline. You set the pace.';

  @override
  String get placementQuestion => 'Where do you stand?';

  @override
  String get settingsRerunOnboarding => 'Introduction again';

  @override
  String get placementFromZero => 'I\'m starting from zero';

  @override
  String get placementKnowSome => 'I already know some';

  @override
  String get placementHiragana => 'I can read Hiragana';

  @override
  String get placementKatakana => 'I can read Katakana';

  @override
  String get placementVocabCheck => 'Do you know this word?';

  @override
  String get startpointBeginner => 'We start at the very beginning.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get encounterListen => 'Listen';

  @override
  String get encounterTrace => 'Trace it';

  @override
  String get encounterNext => 'Got it';

  @override
  String get journeyStart => 'Let\'s go';

  @override
  String get journeyContinue => 'Continue';

  @override
  String journeyChapterLabel(int n) {
    return 'Chapter $n';
  }

  @override
  String get journeyPathComplete => 'Done — more story coming soon.';

  @override
  String get journeyLessonStepTitle => 'Learn something new';

  @override
  String get journeyMangaStepTitle => 'Read on';

  @override
  String get vocabCheckIntro => 'Which words do you already know?';

  @override
  String get vocabCheckKnow => 'I know it';

  @override
  String get vocabCheckDont => 'New to me';

  @override
  String traceStrokeProgress(int current, int total) {
    return 'Trace the character — stroke $current of $total';
  }

  @override
  String get traceRetryHint => 'Try again';
}
