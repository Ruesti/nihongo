import '../../core/db/learning_db.dart';

class LanguageOption {
  final String id;
  final String code;
  final String nameNative;
  final String scriptType;
  final String toneSystem;
  final bool needsScriptTrack;
  final bool isRtl;
  final String ttsVoice;

  const LanguageOption({
    required this.id,
    required this.code,
    required this.nameNative,
    required this.scriptType,
    required this.toneSystem,
    required this.needsScriptTrack,
    required this.isRtl,
    required this.ttsVoice,
  });
}

/// Loads every enabled language from [db], joined with its script profile.
/// Sorted by language code so the UI list order is stable.
Future<List<LanguageOption>> loadAvailableLanguages(LearningDb db) async {
  final languages = await db.select(db.languages).get();
  final options = <LanguageOption>[];
  for (final lang in languages) {
    final profile = await (db.select(db.scriptProfiles)
          ..where((t) => t.id.equals(lang.scriptProfileId)))
        .getSingle();
    options.add(LanguageOption(
      id: lang.id,
      code: lang.id.replaceFirst('lang_', ''),
      nameNative: lang.name,
      scriptType: profile.scriptType,
      toneSystem: profile.toneSystem,
      needsScriptTrack: profile.needsScriptTrack,
      isRtl: profile.direction == 'rtl',
      ttsVoice: lang.ttsVoice,
    ));
  }
  options.sort((a, b) => a.code.compareTo(b.code));
  return options;
}
