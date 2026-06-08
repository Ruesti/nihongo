import '../data/grammar_tips.dart';
import '../data/kana_data.dart';
import '../data/lessons.dart' show lessons, koLessons, esLessons, zhLessons, frLessons, itLessons;
import '../data/vocab_800.dart';
import '../models/lesson.dart';

abstract class LanguageModule {
  String get code;
  String get nameDE;
  String get nameNative;
  String get flagEmoji;
  String get ttsLocale;
  String get sttLocale;
  bool get isRtl;

  bool get hasScript;
  bool get hasStrokeOrder;
  bool get hasToneSystem;
  bool get hasRomanization;
  bool get hasGender;
  bool get hasConjugation;

  List<VocabEntry> get vocab;
  List<Lesson> get curriculum;
  List<GrammarTip> get grammarTips;
  List<ScriptGroup>? get scriptGroups;

  String get aiSystemLanguage;
  String get targetLanguageName;
}

class ScriptGroup {
  final String name;
  final List<String> characters;
  final List<String> romanizations;

  const ScriptGroup({
    required this.name,
    required this.characters,
    required this.romanizations,
  });
}

// ---- Japanisch ----

class JapaneseModule implements LanguageModule {
  const JapaneseModule();

  @override
  String get code => 'ja';
  @override
  String get nameDE => 'Japanisch';
  @override
  String get nameNative => '日本語';
  @override
  String get flagEmoji => '🇯🇵';
  @override
  String get ttsLocale => 'ja-JP';
  @override
  String get sttLocale => 'ja_JP';
  @override
  bool get isRtl => false;

  @override
  bool get hasScript => true;
  @override
  bool get hasStrokeOrder => true;
  @override
  bool get hasToneSystem => false;
  @override
  bool get hasRomanization => true;
  @override
  bool get hasGender => false;
  @override
  bool get hasConjugation => true;

  @override
  List<VocabEntry> get vocab => vocab800;
  @override
  List<Lesson> get curriculum => lessons;
  @override
  List<GrammarTip> get grammarTips => allGrammarTips;
  @override
  List<ScriptGroup> get scriptGroups => hiraganaGroups + katakanaGroups;

  @override
  String get aiSystemLanguage => 'Deutsch';
  @override
  String get targetLanguageName => 'Japanisch';
}

// ---- Koreanisch ----

class KoreanModule implements LanguageModule {
  const KoreanModule();

  @override
  String get code => 'ko';
  @override
  String get nameDE => 'Koreanisch';
  @override
  String get nameNative => '한국어';
  @override
  String get flagEmoji => '🇰🇷';
  @override
  String get ttsLocale => 'ko-KR';
  @override
  String get sttLocale => 'ko_KR';
  @override
  bool get isRtl => false;

  @override
  bool get hasScript => true;
  @override
  bool get hasStrokeOrder => false;
  @override
  bool get hasToneSystem => false;
  @override
  bool get hasRomanization => true;
  @override
  bool get hasGender => false;
  @override
  bool get hasConjugation => true;

  @override
  List<VocabEntry> get vocab => koVocab;
  @override
  List<Lesson> get curriculum => koLessons;
  @override
  List<GrammarTip> get grammarTips => koGrammarTips;
  @override
  List<ScriptGroup> get scriptGroups => hangulGroups;

  @override
  String get aiSystemLanguage => 'Deutsch';
  @override
  String get targetLanguageName => 'Koreanisch';
}

// ---- Spanisch ----

class SpanishModule implements LanguageModule {
  const SpanishModule();

  @override
  String get code => 'es';
  @override
  String get nameDE => 'Spanisch';
  @override
  String get nameNative => 'Español';
  @override
  String get flagEmoji => '🇪🇸';
  @override
  String get ttsLocale => 'es-ES';
  @override
  String get sttLocale => 'es_ES';
  @override
  bool get isRtl => false;

  @override
  bool get hasScript => false;
  @override
  bool get hasStrokeOrder => false;
  @override
  bool get hasToneSystem => false;
  @override
  bool get hasRomanization => false;
  @override
  bool get hasGender => true;
  @override
  bool get hasConjugation => true;

  @override
  List<VocabEntry> get vocab => esVocab;
  @override
  List<Lesson> get curriculum => esLessons;
  @override
  List<GrammarTip> get grammarTips => esGrammarTips;
  @override
  List<ScriptGroup>? get scriptGroups => null;

  @override
  String get aiSystemLanguage => 'Deutsch';
  @override
  String get targetLanguageName => 'Spanisch';
}

// ---- Mandarin ----

class MandarinModule implements LanguageModule {
  const MandarinModule();

  @override
  String get code => 'zh';
  @override
  String get nameDE => 'Mandarin';
  @override
  String get nameNative => '普通话';
  @override
  String get flagEmoji => '🇨🇳';
  @override
  String get ttsLocale => 'zh-CN';
  @override
  String get sttLocale => 'zh_CN';
  @override
  bool get isRtl => false;

  @override
  bool get hasScript => true;
  @override
  bool get hasStrokeOrder => true;
  @override
  bool get hasToneSystem => true;
  @override
  bool get hasRomanization => true;
  @override
  bool get hasGender => false;
  @override
  bool get hasConjugation => false;

  @override
  List<VocabEntry> get vocab => zhVocab;
  @override
  List<Lesson> get curriculum => zhLessons;
  @override
  List<GrammarTip> get grammarTips => zhGrammarTips;
  @override
  List<ScriptGroup> get scriptGroups => pinyinGroups;

  @override
  String get aiSystemLanguage => 'Deutsch';
  @override
  String get targetLanguageName => 'Mandarin';
}

// ---- Französisch ----

class FrenchModule implements LanguageModule {
  const FrenchModule();

  @override String get code => 'fr';
  @override String get nameDE => 'Französisch';
  @override String get nameNative => 'Français';
  @override String get flagEmoji => '🇫🇷';
  @override String get ttsLocale => 'fr-FR';
  @override String get sttLocale => 'fr_FR';
  @override bool get isRtl => false;

  @override bool get hasScript => false;
  @override bool get hasStrokeOrder => false;
  @override bool get hasToneSystem => false;
  @override bool get hasRomanization => false;
  @override bool get hasGender => true;
  @override bool get hasConjugation => true;

  @override List<VocabEntry> get vocab => frVocab;
  @override List<Lesson> get curriculum => frLessons;
  @override List<GrammarTip> get grammarTips => frGrammarTips;
  @override List<ScriptGroup>? get scriptGroups => null;

  @override String get aiSystemLanguage => 'Deutsch';
  @override String get targetLanguageName => 'Französisch';
}

// ---- Italienisch ----

class ItalianModule implements LanguageModule {
  const ItalianModule();

  @override String get code => 'it';
  @override String get nameDE => 'Italienisch';
  @override String get nameNative => 'Italiano';
  @override String get flagEmoji => '🇮🇹';
  @override String get ttsLocale => 'it-IT';
  @override String get sttLocale => 'it_IT';
  @override bool get isRtl => false;

  @override bool get hasScript => false;
  @override bool get hasStrokeOrder => false;
  @override bool get hasToneSystem => false;
  @override bool get hasRomanization => false;
  @override bool get hasGender => true;
  @override bool get hasConjugation => true;

  @override List<VocabEntry> get vocab => itVocab;
  @override List<Lesson> get curriculum => itLessons;
  @override List<GrammarTip> get grammarTips => itGrammarTips;
  @override List<ScriptGroup>? get scriptGroups => null;

  @override String get aiSystemLanguage => 'Deutsch';
  @override String get targetLanguageName => 'Italienisch';
}

const List<LanguageModule> allModules = [
  JapaneseModule(),
  KoreanModule(),
  SpanishModule(),
  FrenchModule(),
  ItalianModule(),
  MandarinModule(),
];

LanguageModule moduleForCode(String code) =>
    allModules.firstWhere((m) => m.code == code,
        orElse: () => const JapaneseModule());
