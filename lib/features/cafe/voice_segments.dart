/// Sprache eines Sprachstücks.
enum VoiceLang { de, ja }

/// Ein Stück einer Zeile in genau einer Sprache.
class VoiceSegment {
  const VoiceSegment(this.text, this.lang);

  final String text;
  final VoiceLang lang;

  @override
  bool operator ==(Object other) =>
      other is VoiceSegment && other.text == text && other.lang == lang;

  @override
  int get hashCode => Object.hash(text, lang);

  @override
  String toString() => 'VoiceSegment($text, $lang)';
}

bool _isJa(int c) =>
    (c >= 0x3041 && c <= 0x309F) || // Hiragana
    (c >= 0x30A0 && c <= 0x30FF) || // Katakana inkl. ー (U+30FC)
    (c >= 0x4E00 && c <= 0x9FFF); // Kanji

final _leadingPunctuation = RegExp(r'^[.,;:!?…。、！？\s]+');

final _onlyPunctuation = RegExp(r'^[\p{P}\p{S}\s]*$', unicode: true);

/// Zerlegt eine Zeile in deutsche und japanische Stücke.
///
/// Japanische Stücke tragen nur die Schrift. Deutsche Stücke werden
/// getrimmt; leere oder reine Satzzeichen-Stücke entfallen.
List<VoiceSegment> splitSegments(String line) {
  final out = <VoiceSegment>[];
  final buf = StringBuffer();
  VoiceLang? cur;

  void flush() {
    final raw = buf.toString();
    buf.clear();
    if (cur == null) return;
    var text = cur == VoiceLang.de ? raw.trim() : raw;
    // Satzzeichen, die direkt an einem japanischen Stück hängen, gehören
    // nicht an den Anfang des folgenden deutschen Stücks.
    if (cur == VoiceLang.de &&
        out.isNotEmpty &&
        out.last.lang == VoiceLang.ja) {
      text = text.replaceFirst(_leadingPunctuation, '');
    }
    if (text.isEmpty) return;
    if (cur == VoiceLang.de && _onlyPunctuation.hasMatch(text)) return;
    out.add(VoiceSegment(text, cur));
  }

  for (final rune in line.runes) {
    final lang = _isJa(rune) ? VoiceLang.ja : VoiceLang.de;
    if (lang != cur) {
      flush();
      cur = lang;
    }
    buf.writeCharCode(rune);
  }
  flush();
  return out;
}
