/// The first-meeting content for a new learn-item (rung 0), polymorphic
/// over refType. Pure data — no Flutter/DB deps. Rendered ungraded by
/// EncounterView; every optional field degrades gracefully when its asset
/// is missing (Asset-Doktrin §6).
sealed class Encounter {
  const Encounter();
}

/// character: see the glyph, hear it, watch/trace the stroke order.
final class CharacterEncounter extends Encounter {
  final String glyph;
  final String reading;
  final String audioText; // what TTS speaks (usually the glyph)
  final String? strokeOrderAssetId; // KanjiVG asset path, null → no trace
  final String? mnemonic;

  const CharacterEncounter({
    required this.glyph,
    required this.reading,
    required this.audioText,
    this.strokeOrderAssetId,
    this.mnemonic,
  });
}

/// lexeme: experience the meaning — form + reading + concept image + use.
final class LexemeEncounter extends Encounter {
  final String writtenForm;
  final String reading;
  final String audioText;
  final String meaning;
  final String? conceptImagePath; // Assets.path (type image), null → text only
  final String? exampleSentence; // all-known example, null → omitted

  const LexemeEncounter({
    required this.writtenForm,
    required this.reading,
    required this.audioText,
    required this.meaning,
    this.conceptImagePath,
    this.exampleSentence,
  });
}

/// grammar: grasp the pattern, framed by the can-do goal.
final class GrammarEncounter extends Encounter {
  final String pattern;
  final String plainExplanation;
  final String example;
  final String canDoDescription;
  final String? contrast;

  const GrammarEncounter({
    required this.pattern,
    required this.plainExplanation,
    required this.example,
    required this.canDoDescription,
    this.contrast,
  });
}
