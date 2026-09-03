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

/// The Vielredner (rung 4): erzählt viel, prüft freundlich, ob der Kern ankam.
const _vielredner = CafeGuestScript({
  CafeOutcome.correct: [
    'Ha, genau! Wusste ich, dass du es hast.',
    'Siehst du — du verstehst mehr, als du denkst.',
    'Genau das, ja. Bei so viel Gerede muss man ja was mitnehmen.',
  ],
  CafeOutcome.wrong: [
    'Kein Ding, das war auch viel Gerede. Nächstes.',
    'Ich rede halt zu viel — das hört sich noch ein.',
    'Macht nichts, das kriegst du beim nächsten Mal.',
  ],
  CafeOutcome.hinted: [
    'Nachgeschaut, auch gut — Hauptsache, es bleibt hängen.',
    'Klar, schau nach. Bei mir verliert man schon mal den Faden.',
    'Passt, so lernt man es auch.',
  ],
});

/// The Gleichaltrige (rung 5): offenes Gespräch, kein richtig/falsch —
/// reagiert warm auf alles, was du produzierst.
const _gleichaltrige = CafeGuestScript({
  CafeOutcome.freeProduced: [
    'Schön gesagt. Weiter geht es.',
    'Ja, so ungefähr würde ich es auch sagen.',
    'Gefällt mir. Nächstes?',
    'Cool, du traust dich was.',
  ],
});

/// The script for a guest.
CafeGuestScript scriptFor(CafeGuest guest) => switch (guest) {
      CafeGuest.wirtin => _wirtin,
      CafeGuest.schulkind => _schulkind,
      CafeGuest.vielredner => _vielredner,
      CafeGuest.gleichaltrige => _gleichaltrige,
    };
