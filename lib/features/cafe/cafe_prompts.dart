/// Template-based café prompts (PHASE_0 §8): the Vielredner's rambling
/// Comprehensible-Input monologues and the Gleichaltrige's open conversation
/// starters. Each rotates by turn index and slots the due word. The German
/// scaffolding builds context AROUND the Japanese word — it never states the
/// meaning, so these need no German meaning table (the meaning surfaces only
/// on the comprehension reveal).
String vielrednerMonologue(String word, int index) {
  final templates = [
    'Ach, weißt du... neulich ging es die ganze Zeit um $word. '
        '$word hier, $word da — man kommt gar nicht drumherum. '
        'Und jetzt sag mir: $word — was war das noch gleich?',
    'Also, ich muss dir was erzählen. Gestern, mitten am Tag: $word. '
        'Ich sag dir, $word, überall $word. Kaum zu glauben. '
        'Du weißt schon, was $word bedeutet, oder?',
    'Kennst du das? Da sitzt man, und plötzlich — $word. '
        'Dann noch mal $word. Das halbe Viertel redet von nichts anderem. '
        'Aber $word, das hast du doch, hm?',
  ];
  return templates[index % templates.length];
}

String gleichaltrigeOpener(String word, int index) {
  final openers = [
    'Sag mal, $word — was fällt dir dazu ein? Einfach drauflos.',
    'Erzähl mir irgendwas mit $word. Muss nicht perfekt sein.',
    '$word. Los, ein Satz, egal welcher — ich hör zu.',
  ];
  return openers[index % openers.length];
}

/// Die Wirtin lädt zur Nachbesprechung ein (Belegung, Spec
/// Café-Nachbesprechung §3.6) — kein Zähler, keine Zahl, nur ein Satz.
const String wirtinDebriefInvite = 'Wollen wir über die Folge reden?';

/// Was die Wirtin vor einer Erklärungskarte sagt; rotiert nach Kartenindex.
/// „Setz dich." ist die Eröffnung und fällt genau einmal — ab der zweiten
/// Karte rotieren die Anschlusszeilen.
String wirtinDebriefLine(int index) {
  if (index <= 0) return 'Setz dich. Das hier hattest du in der Folge:';
  const lines = [
    'Und dann war da noch das — erinnerst du dich?',
    'Das nächste. Lass dir Zeit.',
    'Das hier kam auch vor. Hör noch einmal hin.',
  ];
  return lines[(index - 1) % lines.length];
}

/// Schlusszeile nach Akt 2 (mindestens drei, rotierend — Brief §4.5).
String wirtinDebriefClosing(int index) {
  const lines = [
    'So. Das war die Folge. Der Tee ist noch warm.',
    'Gut. Mehr muss es heute nicht sein.',
    'Das sitzt fürs Erste. Komm wieder, wenn dir etwas fällig ist.',
  ];
  return lines[index % lines.length];
}

/// Die Wirtin gibt in der Nachbesprechung einen Block an einen Gast ab
/// (Spec Café-Szenen-und-Stimmen §3.1) — eine Zeile im selben Bildschirm,
/// kein Zwischenscreen (Brief §6). Rotiert nach Blocknummer.
String wirtinHandoverLine(int index) {
  const lines = [
    'Frag du mal.',
    'Nimm du die nächsten.',
    'Mach du weiter, ich hol Tee.',
  ];
  return lines[index % lines.length];
}
