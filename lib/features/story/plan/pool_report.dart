// lib/features/story/plan/pool_report.dart
//
// Zählungen und Markdown-Ausgaben über den Wortvorrat. Kein Flutter-Import,
// damit tool/wortvorrat_report.dart mit `dart run` läuft.

import 'dart:math';

import 'pool_checks.dart';
import 'pool_entry.dart';

Map<VocabDomain, int> countByDomain(Iterable<PoolEntry> entries) {
  final out = <VocabDomain, int>{};
  for (final e in entries) {
    out[e.domain] = (out[e.domain] ?? 0) + 1;
  }
  return out;
}

Map<PartOfSpeech, int> countByPos(Iterable<PoolEntry> entries) {
  final out = <PartOfSpeech, int>{};
  for (final e in entries) {
    out[e.pos] = (out[e.pos] ?? 0) + 1;
  }
  return out;
}

/// Wie viele Wörter jedes Kanji tragen; häufigste zuerst, dann nach Zeichen.
List<MapEntry<String, int>> kanjiFrequency(Iterable<PoolEntry> entries) {
  final counts = <String, int>{};
  for (final e in entries) {
    for (final k in e.kanji.toSet()) {
      counts[k] = (counts[k] ?? 0) + 1;
    }
  }
  final list = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return list;
}

/// Feste Zufallsauswahl: gleicher Seed, gleiche Auswahl.
List<PoolEntry> samplePool(Iterable<PoolEntry> entries,
    {required int count, required int seed}) {
  final list = entries.toList()..shuffle(Random(seed));
  return list.take(min(count, list.length)).toList();
}

String _domainTitle(VocabDomain d) {
  const titles = {
    VocabDomain.zahlen: 'Zahlen',
    VocabDomain.zeit: 'Zeit',
    VocabDomain.cafe: 'Café und Essen',
    VocabDomain.einkaufen: 'Einkaufen',
    VocabDomain.kleidung: 'Kleidung',
    VocabDomain.menschen: 'Menschen',
    VocabDomain.familie: 'Familie',
    VocabDomain.koerper: 'Körper',
    VocabDomain.gefuehl: 'Befinden und Gefühl',
    VocabDomain.orte: 'Orte',
    VocabDomain.haus: 'Haus',
    VocabDomain.verkehr: 'Verkehr',
    VocabDomain.wetter: 'Wetter',
    VocabDomain.natur: 'Natur',
    VocabDomain.verbenAlltag: 'Verben',
    VocabDomain.adjektive: 'Adjektive',
    VocabDomain.adverbien: 'Adverbien',
    VocabDomain.fragen: 'Fragewörter und Pronomen',
    VocabDomain.ausdruecke: 'Ausdrücke',
    VocabDomain.werkstatt: 'Werkstatt',
    VocabDomain.post: 'Post und Telefon',
    VocabDomain.schule: 'Schule',
    VocabDomain.sprache: 'Sprache',
    VocabDomain.dinge: 'Dinge',
    VocabDomain.erinnerung: 'Erinnerung',
  };
  return titles[d] ?? d.name;
}

String _statusCell(PoolEntry e) {
  if (e.status == PoolStatus.bank) return 'Bank';
  if (e.plannedEpisode != null) return 'Folge ${e.plannedEpisode.toString().padLeft(2, '0')}';
  return '';
}

String _row(PoolEntry e) =>
    '| ${e.kana} | ${e.written} | ${e.meaningDe} | ${e.pos.name} | ${_statusCell(e)} |';

/// Die ganze Liste, nach Lebensbereich gruppiert.
String renderFullMarkdown(Iterable<PoolEntry> entries) {
  final b = StringBuffer()
    ..writeln('# Wortvorrat 800')
    ..writeln()
    ..writeln('*Generiert von `dart run tool/wortvorrat_report.dart`. Quelle: `lib/features/story/plan/`.*')
    ..writeln();
  for (final d in VocabDomain.values) {
    final rows = entries.where((e) => e.domain == d).toList();
    if (rows.isEmpty) continue;
    b
      ..writeln('## ${_domainTitle(d)} (${rows.length})')
      ..writeln()
      ..writeln('| Kana | Schreibung | Bedeutung | Wortart | Stand |')
      ..writeln('|---|---|---|---|---|');
    for (final e in rows) {
      b.writeln(_row(e));
    }
    b.writeln();
  }
  return b.toString();
}

/// Die Stichprobe für Ulis Sichtung, mit Ankreuzspalte.
String renderSampleMarkdown(List<PoolEntry> sample) {
  final sorted = [...sample]..sort((a, b) => a.domain.index.compareTo(b.domain.index));
  final b = StringBuffer()
    ..writeln('# Wortvorrat — Stichprobe zur Sichtung')
    ..writeln()
    ..writeln('${sorted.length} Wörter, feste Zufallsauswahl. Bitte ankreuzen, was nicht passt, und kurz sagen warum.')
    ..writeln()
    ..writeln('| Passt? | Bereich | Kana | Schreibung | Bedeutung | Wortart |')
    ..writeln('|---|---|---|---|---|---|');
  for (final e in sorted) {
    b.writeln('| [ ] | ${_domainTitle(e.domain)} | ${e.kana} | ${e.written} | ${e.meaningDe} | ${e.pos.name} |');
  }
  return b.toString();
}

/// Terminal-Bericht: Zahlen, Probleme, Verteilung, Kanji-Vorschau.
String renderTerminalReport(List<PoolEntry> all,
    {int expectedTotal = 800, int maxBank = 40}) {
  final core = all.where((e) => e.status != PoolStatus.bank).toList();
  final bank = all.length - core.length;
  final folge01 = core.where((e) => e.plannedEpisode == 1).length;
  final problems = checkPool(all, expectedTotal: expectedTotal, maxBank: maxBank);
  final b = StringBuffer()
    ..writeln('Wortvorrat — Kern: ${core.length}  Bank: $bank  Folge 01: $folge01')
    ..writeln(problems.isEmpty ? 'Regeln: keine Probleme' : 'Regeln: ${problems.length} Probleme')
    ..writeln();
  for (final p in problems) {
    b.writeln('  ! $p');
  }
  b.writeln('Nach Lebensbereich:');
  for (final entry in countByDomain(core).entries) {
    b.writeln('  ${_domainTitle(entry.key).padRight(28)} ${entry.value}');
  }
  b.writeln('Nach Wortart:');
  for (final entry in countByPos(core).entries) {
    b.writeln('  ${entry.key.name.padRight(28)} ${entry.value}');
  }
  final freq = kanjiFrequency(core);
  b
    ..writeln('Kanji im Kern: ${freq.length} verschiedene')
    ..writeln('Häufigste 30: ${freq.take(30).map((e) => '${e.key}${e.value}').join(' ')}');
  return b.toString();
}
