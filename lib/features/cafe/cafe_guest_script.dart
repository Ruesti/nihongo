import 'cafe_occupancy.dart';
import 'cafe_turn.dart';

/// Die Stimme eines Gastes (Spec Café-Szenen-und-Stimmen §4): Reaktionen je
/// Ergebnis (Brief §4.5: mindestens drei, rotierend), Stimm-Zeilen je
/// Übungsform und Einstiegszeilen beim Blockwechsel. Alles rotiert
/// deterministisch nach Index — nie zufällig, damit Tests es festnageln.
///
/// Die Stimm-Zeile steht ÜBER dem groß gezeigten Wort (bzw. der Bedeutung
/// beim Schreiben) und setzt nichts ein: Sie kann strukturell nie die
/// Antwort verraten (INV-9). Eine Stimme ändert nie die Übungsform — die
/// kommt aus der Sprosse (`kindForRung`), egal wer fragt (Spec §6).
class CafeGuestScript {
  final Map<CafeOutcome, List<String>> lines;

  /// Stimm-Zeilen je Übungsform. Fehlt eine Form, sagt der Gast dazu
  /// nichts — der Turn zeigt dann nur das Wort, wie vor dieser Spec.
  final Map<CafeExerciseKind, List<String>> voice;

  /// Einstiegszeilen, wenn dieser Gast einen Block übernimmt.
  final List<String> entries;

  const CafeGuestScript(this.lines,
      {this.voice = const {}, this.entries = const []});

  String followUp(CafeOutcome outcome, int turnIndex) {
    final options = lines[outcome]!;
    return options[turnIndex % options.length];
  }

  String? voiceLine(CafeExerciseKind kind, int turnIndex) {
    final options = voice[kind];
    if (options == null || options.isEmpty) return null;
    return options[turnIndex % options.length];
  }

  String? entry(int ordinal) {
    if (entries.isEmpty) return null;
    return entries[ordinal % entries.length];
  }
}

/// Die Wirtin (Sprosse 1–2). Steckbrief: geduldig, langsam, wiederholt
/// gern; „du", warm, nie belehrend; kurze Sätze mit Pausen; Tic: sie sagt
/// das Wort einmal vor. Sie eröffnet und schließt die Nachbesprechung.
const _wirtin = CafeGuestScript(
  {
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
  },
  voice: {
    CafeExerciseKind.recognition: [
      'Das hier. Was heißt das?',
      'Hör noch einmal hin. Und was bedeutet es?',
      'Das kennst du. Sag mir, was es heißt.',
    ],
    CafeExerciseKind.readingInput: [
      'Wie liest man das? Lass dir Zeit.',
      'Lies es mir vor. Langsam ist gut.',
      'Und wie spricht man das aus? Keine Eile.',
    ],
  },
  entries: [
    'So. Jetzt wieder ich.',
    'Danke. Den Rest nehme ich.',
    'Gut. Weiter bei mir.',
  ],
);

/// Das Schulkind (Sprosse 3). Steckbrief: direkt, kein Keigo, korrigiert
/// schonungslos; „du", frech, von unten nach oben; sehr kurze Sätze, oft
/// ein Wort; Tic: „Schnell!", „Easy.", „Nee." Im normalen Besuch fragt es
/// nur Schreiben (Sprosse 3); in der Nachbesprechung fragt es „mit" —
/// Erkennen und Lesen in seinem Ton, die Übungsform bleibt die der Sprosse.
const _schulkind = CafeGuestScript(
  {
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
  },
  voice: {
    CafeExerciseKind.recognition: [
      'Was heißt das? Schnell!',
      'Das da. Weißt du das? Los.',
      'Easy. Was heißt es?',
    ],
    CafeExerciseKind.readingInput: [
      'Lies mal vor. Ohne Stottern.',
      'Wie liest man das? Zack.',
      'Vorlesen! Ich hör zu.',
    ],
    CafeExerciseKind.productionInput: [
      'Wie sagt man das? Schreib es hin.',
      'Auf Japanisch, bitte. Schnell.',
      'Das Wort dazu — du kannst das. Los.',
    ],
  },
  entries: [
    'Darf ich auch mal? Die leichten nehm ich.',
    'Jetzt ich! Pass auf.',
  ],
);

/// Der Vielredner (Sprosse 4). Steckbrief: Monologe, Comprehensible Input;
/// „du", als säße man schon Stunden zusammen; lange, abschweifende Sätze,
/// die IMMER in der Frage enden; Tic: „Ach, weißt du …", „wo wir gerade
/// dabei sind". Sein Monolog auf Sprosse 4 bleibt in `cafe_prompts.dart`.
const _vielredner = CafeGuestScript(
  {
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
  },
  voice: {
    CafeExerciseKind.recognition: [
      'Ach, weißt du, neulich am Tresen fiel genau das hier. '
          'Und was heißt es noch gleich?',
      'Ich sag dir, den ganzen Tag ging es um so was. '
          'Das da — was war das noch?',
      'Wo wir gerade dabei sind: Das hier hab ich gestern dreimal gehört. '
          'Was bedeutet es?',
    ],
    CafeExerciseKind.readingInput: [
      'Stand groß an der Tür, so wie das hier. Wie spricht man das aus?',
      'Ach, weißt du, ich les das immer falsch. Wie liest man das richtig?',
      'Das da hat der Alte von nebenan ständig gesagt. '
          'Wie klingt das, wenn man es liest?',
    ],
  },
  entries: [
    'Ach, wo wir gerade dabei sind — ich hätte da auch was.',
    'Moment, das erinnert mich an etwas. Darf ich?',
  ],
);

/// Die Gleichaltrige (Sprosse 5). Steckbrief: offenes Gespräch, kein
/// richtig/falsch auf Sprosse 5; „du", auf Augenhöhe; mittellange,
/// beiläufige Sätze; Tic: „Sag mal …", „Ich glaub …". Fragt sie in der
/// Nachbesprechung Erkennen oder Lesen, reagiert sie weich auf richtig,
/// falsch und Hinweis (neu). Ihre Eröffnung auf Sprosse 5 bleibt in
/// `cafe_prompts.dart`.
const _gleichaltrige = CafeGuestScript(
  {
    CafeOutcome.freeProduced: [
      'Schön gesagt. Weiter geht es.',
      'Ja, so ungefähr würde ich es auch sagen.',
      'Gefällt mir. Nächstes?',
      'Cool, du traust dich was.',
    ],
    CafeOutcome.correct: [
      'Ja, genau das.',
      'Stimmt. Hätte ich auch gesagt.',
      'Genau. Siehst du, das sitzt.',
    ],
    CafeOutcome.wrong: [
      'Hm, nee — ich glaub, das war was anderes.',
      'Ich glaub nicht. Schau nochmal hin.',
      'Fast, aber nicht ganz. Kommt schon noch.',
    ],
    CafeOutcome.hinted: [
      'Klar, schau nach. Mach ich auch.',
      'Nachgucken ist okay. Nächstes Mal ohne.',
      'Ich glaub, das merkst du dir jetzt.',
    ],
  },
  voice: {
    CafeExerciseKind.recognition: [
      'Sag mal, das hier — was hieß das gleich?',
      'Ich glaub, das hatten wir. Was heißt es?',
      'Kennst du das noch? Was bedeutet es?',
    ],
    CafeExerciseKind.readingInput: [
      'Wie sagt man das? Ich hab es neulich falsch gelesen.',
      'Sag mal, wie liest man das eigentlich?',
      'Ich glaub, ich spreche das immer falsch aus. Wie geht es richtig?',
    ],
  },
  entries: [
    'Ich hab da auch noch was.',
    'Sag mal, darf ich kurz?',
  ],
);

/// The script for a guest.
CafeGuestScript scriptFor(CafeGuest guest) => switch (guest) {
      CafeGuest.wirtin => _wirtin,
      CafeGuest.schulkind => _schulkind,
      CafeGuest.vielredner => _vielredner,
      CafeGuest.gleichaltrige => _gleichaltrige,
    };
