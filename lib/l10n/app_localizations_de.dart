// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get welcomeTitle => 'Willkommen.';

  @override
  String get welcomeBody =>
      'Hier lernst du Japanisch, indem du es liest — in deinem Tempo, Zeichen für Zeichen.';

  @override
  String get methodEncounterFirst =>
      'Jedem Zeichen, Wort und Grammatikpunkt begegnest du zuerst — sehen, hören, nachfahren — bevor du geprüft wirst.';

  @override
  String get methodNoGamification =>
      'Kein Punktesammeln, keine Serien. Dein Fortschritt ist, was du wirklich lesen kannst.';

  @override
  String get methodOffline => 'Alles läuft offline. Du bestimmst das Tempo.';

  @override
  String get placementQuestion => 'Wo stehst du?';

  @override
  String get settingsRerunOnboarding => 'Einführung erneut';

  @override
  String get placementFromZero => 'Ich fange bei null an';

  @override
  String get placementKnowSome => 'Ich kann schon etwas';

  @override
  String get placementHiragana => 'Ich kann Hiragana';

  @override
  String get placementKatakana => 'Ich kann Katakana';

  @override
  String get placementVocabCheck => 'Kennst du dieses Wort?';

  @override
  String get startpointBeginner => 'Wir fangen ganz vorn an.';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get encounterListen => 'Hören';

  @override
  String get encounterTrace => 'Nachfahren';

  @override
  String get encounterNext => 'Verstanden';

  @override
  String get journeyStart => 'Los geht\'s';

  @override
  String get journeyContinue => 'Weiter';

  @override
  String journeyChapterLabel(int n) {
    return 'Kapitel $n';
  }

  @override
  String get journeyPathComplete => 'Geschafft — mehr Geschichte kommt bald.';

  @override
  String get journeyLessonStepTitle => 'Neu lernen';

  @override
  String get journeyMangaStepTitle => 'Weiterlesen';

  @override
  String get vocabCheckIntro => 'Welche Wörter kennst du schon?';

  @override
  String get vocabCheckKnow => 'Kenne ich';

  @override
  String get vocabCheckDont => 'Neu für mich';
}
