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
