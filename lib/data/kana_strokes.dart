import '../data/kana_data.dart';

/// The set of kana codepoints whose KanjiVG stroke SVG is bundled under
/// assets/kanji_svg/. Extend as more SVGs are added. Absence → null, so
/// the encounter degrades (no trace step) rather than crashing.
const Set<int> _bundledKanaCodepoints = {
  0x3042, 0x3044, 0x3046, 0x3048, 0x304a, // あいうえお
};

String _hex(int codeUnit) => codeUnit.toRadixString(16);

/// Asset path for a kana's stroke order, or null if not bundled.
String? strokeAssetForKana(String kana) {
  if (kana.isEmpty) return null;
  final cp = kana.runes.first;
  if (!_bundledKanaCodepoints.contains(cp)) return null;
  return 'assets/kanji_svg/${_hex(cp)}.svg';
}

/// True if any bundled kana exists (guards tooling). Uses [hiragana] so the
/// import is meaningful and the map can be cross-checked against the pack.
bool get hasBundledKana =>
    hiragana.any((k) => _bundledKanaCodepoints.contains(k.kana.runes.first));
