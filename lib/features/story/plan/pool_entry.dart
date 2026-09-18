// Der Wortvorrat 800 (Spec docs/superpowers/specs/2026-09-18-serienplan-800-design.md §2).
// Reine Daten: ein Eintrag pro Wort des Grundwortschatzes. Kein DB-Bezug.

/// Wortart, so grob wie die Autoren sie brauchen.
enum PartOfSpeech {
  nomen,
  verb,
  iAdjektiv,
  naAdjektiv,
  adverb,
  pronomen,
  zahl,
  zaehlwort,
  ausdruck,
  konjunktion,
}

/// Lebensbereich, nach dem der Staffelplan Wörter auf Folgen verteilt.
enum VocabDomain {
  zahlen,
  zeit,
  cafe,
  einkaufen,
  kleidung,
  menschen,
  familie,
  koerper,
  gefuehl,
  orte,
  haus,
  verkehr,
  wetter,
  natur,
  verbenAlltag,
  adjektive,
  adverbien,
  fragen,
  ausdruecke,
  werkstatt,
  post,
  schule,
  sprache,
  dinge,
  erinnerung,
}

/// Wo ein Wort im Serienplan steht. `bank` = Reservewort außerhalb der 800.
enum PoolStatus { geplant, geschrieben, ausgeliefert, bank }

/// True für CJK-Einheitsideogramme (die Kanji des Alltags).
bool isKanjiRune(int rune) => rune >= 0x4E00 && rune <= 0x9FFF;

/// Die Kanji in [s], in Lesereihenfolge, ohne Duplikat-Entfernung.
List<String> kanjiIn(String s) => [
      for (final r in s.runes)
        if (isKanjiRune(r)) String.fromCharCode(r),
    ];

class PoolEntry {
  final String id;
  final String kana;

  /// Übliche Schreibung mit Kanji; leer, wenn das Wort in Kana bleibt.
  final String written;
  final String meaningDe;
  final PartOfSpeech pos;
  final VocabDomain domain;

  /// Folge, die das Wort einführt; null, solange der Staffelplan es nicht vergibt.
  final int? plannedEpisode;
  final PoolStatus status;

  const PoolEntry({
    required this.id,
    required this.kana,
    this.written = '',
    required this.meaningDe,
    required this.pos,
    required this.domain,
    this.plannedEpisode,
    this.status = PoolStatus.geplant,
  });

  List<String> get kanji => kanjiIn(written);

  String get displayForm => written.isEmpty ? kana : written;
}
