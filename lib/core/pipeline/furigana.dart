import '../language_pack/language_pack.dart';

/// One furigana annotation: [surface] (usually kanji) paired with its
/// [reading], positioned at [charStart]/[charEnd] in the source
/// sentence — the char offsets Token already carries "required for
/// furigana + highlight" (§2.3).
class FuriganaSpan {
  final String surface;
  final String reading;
  final int charStart;
  final int charEnd;

  const FuriganaSpan({
    required this.surface,
    required this.reading,
    required this.charStart,
    required this.charEnd,
  });
}

/// Computes furigana spans for [tokens] via [readings] — language-blind
/// (any [ReadingProvider] works; `null` for languages without a
/// reading layer per §2.2, which correctly yields no spans at all
/// rather than an error). A token whose reading equals its own surface
/// (already kana, or a language without meaningful kanji/reading
/// divergence) is skipped — nothing to annotate.
List<FuriganaSpan> computeFurigana(List<Token> tokens, ReadingProvider? readings) {
  if (readings == null) return const [];

  final spans = <FuriganaSpan>[];
  for (final token in tokens) {
    final reading = readings.reading(token);
    if (reading == null || reading.text == token.surface) continue;
    spans.add(FuriganaSpan(
      surface: token.surface,
      reading: reading.text,
      charStart: token.charStart,
      charEnd: token.charEnd,
    ));
  }
  return spans;
}
