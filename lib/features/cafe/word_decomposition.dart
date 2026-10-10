import '../../data/kana_data.dart';

/// Eine Laut-Einheit für die Kacheln der Wirtin (Spec §3.1 Punkt 3 / §6.2):
/// das Stück Kana, wie es gesprochen wird, und seine Lautschrift.
class SoundUnit {
  final String text;
  final String romaji;
  const SoundUnit(this.text, this.romaji);

  @override
  bool operator ==(Object o) =>
      o is SoundUnit && o.text == text && o.romaji == romaji;
  @override
  int get hashCode => Object.hash(text, romaji);
  @override
  String toString() => 'SoundUnit($text $romaji)';
}

const _small = {'ゃ', 'ゅ', 'ょ', 'ャ', 'ュ', 'ョ'};
const _smallVowel = {'ゃ': 'a', 'ゅ': 'u', 'ょ': 'o', 'ャ': 'a', 'ュ': 'u', 'ョ': 'o'};
const _sokuon = {'っ', 'ッ'};
const _longMark = 'ー';
const _macron = {'a': 'ā', 'i': 'ī', 'u': 'ū', 'e': 'ē', 'o': 'ō'};

final Map<String, String> _romajiOf = {
  for (final e in hiragana) e.kana: e.romaji,
  for (final e in katakana) e.kana: e.romaji,
};

/// Dehnung: der Vokal, den ein Folgezeichen verlängert, oder null.
/// う nach o/u, い nach e/i, あ nach a, Strich ー immer.
String? _lengthens(String prevRomaji, String next) {
  if (prevRomaji.isEmpty) return null;
  final v = prevRomaji[prevRomaji.length - 1];
  if (next == _longMark) return v;
  if ((next == 'う' || next == 'ウ') && (v == 'o' || v == 'u')) return v;
  if ((next == 'い' || next == 'イ') && (v == 'e' || v == 'i')) return v;
  if ((next == 'あ' || next == 'ア') && v == 'a') return v;
  return null;
}

/// Zerlegt ein Kana-Wort in Laut-Einheiten (Spec §6.2). Regeln:
/// Grundzeichen = eine Kachel; Zeichen + kleines ゃゅょ = eine Kachel
/// (きょ kyo, しゃ sha, じょ jo); kleines っ = Kachel mit verdoppeltem
/// Folgekonsonanten; ん = n; Dehnung (う nach o/u, い nach e/i, ー) wird an
/// die Kachel davor angehängt und als Makron geschrieben (とう tō).
/// Unbekannte Zeichen (Kanji) bleiben als Kachel ohne Laut.
List<SoundUnit> decompose(String kana) {
  final chars = kana.runes.map(String.fromCharCode).toList();
  final units = <SoundUnit>[];
  var i = 0;
  while (i < chars.length) {
    final c = chars[i];
    if (_sokuon.contains(c)) {
      final next = i + 1 < chars.length ? _romajiOf[chars[i + 1]] : null;
      final consonant = (next != null && next.isNotEmpty) ? next[0] : '';
      units.add(SoundUnit(c, consonant));
      i++;
      continue;
    }
    var text = c;
    var romaji = _romajiOf[c] ?? '';
    // Yōon: Konsonant des Grundzeichens + Vokal des kleinen Zeichens.
    if (i + 1 < chars.length && _small.contains(chars[i + 1]) && romaji.isNotEmpty) {
      final base = romaji.substring(0, romaji.length - 1); // ki → k, shi → sh, ji → j
      final stem = (base == 'sh' || base == 'ch' || base == 'j') ? base : '${base}y';
      romaji = '$stem${_smallVowel[chars[i + 1]]}';
      text = c + chars[i + 1];
      i++;
    }
    // Dehnung an die Kachel hängen.
    if (i + 1 < chars.length) {
      final v = _lengthens(romaji, chars[i + 1]);
      if (v != null) {
        text += chars[i + 1];
        romaji = romaji.substring(0, romaji.length - 1) + _macron[v]!;
        i++;
      }
    }
    units.add(SoundUnit(text, romaji));
    i++;
  }
  return units;
}
