// Abgleich des Wortvorrats mit der alten Lektionsliste lib/data/vocab_800.dart.
// Die alte Liste bleibt unangetastet; hier steht nur, welche ihrer N5-Wörter
// bewusst NICHT in den Vorrat übernommen wurden, und warum.

import '../../../data/vocab_800.dart';

/// Alte japanische Einträge der Stufe N5.
List<VocabEntry> legacyN5Japanese() => vocab800
    .where((e) => e.languageCode == 'ja' && e.jlpt == 'N5')
    .toList();

/// Alte ID → Grund für den Ausschluss. Erlaubte Gründe (Wortlaut frei):
/// „Variante von …", „andere Lesung von … im Vorrat", „N4-Wort", „nicht Alltag".
const Map<String, String> legacyExclusions = {
  // Zahlen mit zwei Lesungen: die alte Liste schreibt beide Lesungen in ein
  // Feld (z. B. reading „しよん"), der Vorrat führt pro Zahl nur die im
  // Alltag gebräuchliche Lesung als eigenen Eintrag.
  'shi': 'andere Lesung von lex_ja_yon im Vorrat',
  'nana': 'andere Lesung von lex_ja_nana im Vorrat',
  'ku': 'andere Lesung von lex_ja_kyuu im Vorrat',
};
