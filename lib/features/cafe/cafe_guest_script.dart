import 'cafe_occupancy.dart';
import 'cafe_turn.dart';

/// A guest's reactions (brief §4.5): at least three lines per outcome, rotated
/// by turn index so a guest never sounds like a flashcard. `followUp` is the
/// part that carries the guest's character — the Wirtin patient and warm, the
/// Schulkind blunt and merciless.
class CafeGuestScript {
  final Map<CafeOutcome, List<String>> lines;

  const CafeGuestScript(this.lines);

  String followUp(CafeOutcome outcome, int turnIndex) {
    final options = lines[outcome]!;
    return options[turnIndex % options.length];
  }
}

/// The Wirtin (rung 1–2): geduldig, langsam, wiederholt gern.
const _wirtin = CafeGuestScript({
  CafeOutcome.correct: [
    'Genau so.',
    'Ja, richtig — du hörst gut zu.',
    'Schön. Das sitzt jetzt.',
  ],
  CafeOutcome.wrong: [
    'Nicht ganz. Wir sehen es uns zusammen an.',
    'Kein Problem, das wiederholen wir einfach.',
    'Fast. Ich zeige es dir gleich noch einmal.',
  ],
  CafeOutcome.hinted: [
    'Nachsehen ist erlaubt. Beim nächsten Mal von allein.',
    'Gut, dass du nachschaust — es prägt sich trotzdem ein.',
    'Schau ruhig nach. Langsam wird es deins.',
  ],
});

/// The Schulkind (rung 3): direkt, kein Keigo, korrigiert schonungslos.
const _schulkind = CafeGuestScript({
  CafeOutcome.correct: [
    'Ha, gewusst!',
    'Klar, easy.',
    'Siehst du, geht doch.',
  ],
  CafeOutcome.wrong: [
    'Nee. Falsch.',
    'Das heißt das gar nicht!',
    'Nochmal — aber richtig diesmal.',
  ],
  CafeOutcome.hinted: [
    'Spicken gilt nicht!',
    'Nachgucken? Schwach.',
    'Nächstes Mal ohne Buch, ja?',
  ],
});

/// The script for a guest. P8 covers only the Wirtin and the Schulkind;
/// Vielredner/Gleichaltrige (rung 4–5) arrive in P9.
CafeGuestScript scriptFor(CafeGuest guest) => switch (guest) {
      CafeGuest.wirtin => _wirtin,
      CafeGuest.schulkind => _schulkind,
      CafeGuest.vielredner => _wirtin, // placeholder until P9
      CafeGuest.gleichaltrige => _wirtin, // placeholder until P9
    };
