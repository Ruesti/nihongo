import 'language_pack.dart';

/// Resolves a [LanguagePack] by BCP-47 code. Adding a language is
/// registering an instance here plus its data package — never a branch
/// in pipeline code (§2.2 seam discipline).
class LanguagePackRegistry {
  final Map<String, LanguagePack> _packs = {};

  void register(LanguagePack pack) {
    _packs[pack.code] = pack;
  }

  LanguagePack? operator [](String code) => _packs[code];

  List<String> get registeredCodes => _packs.keys.toList(growable: false);
}
