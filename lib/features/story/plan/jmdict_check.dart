// lib/features/story/plan/jmdict_check.dart
//
// Abgleich des Wortvorrats gegen JMdict_e, zeilenweise, ohne DOM.

import 'pool_entry.dart';

class JmdictForms {
  /// 'keb|reb' für jede Kombination innerhalb eines Eintrags.
  final Set<String> pairs = {};

  /// Alle Lesungen (reb) über alle Einträge.
  final Set<String> readings = {};
}

final RegExp _keb = RegExp(r'<keb>([^<]+)</keb>');
final RegExp _reb = RegExp(r'<reb>([^<]+)</reb>');

Future<JmdictForms> loadJmdictForms(Stream<String> lines) async {
  final forms = JmdictForms();
  var kebs = <String>[];
  var rebs = <String>[];
  await for (final line in lines) {
    if (line.contains('<entry>')) {
      kebs = [];
      rebs = [];
    }
    for (final m in _keb.allMatches(line)) {
      kebs.add(m.group(1)!);
    }
    for (final m in _reb.allMatches(line)) {
      rebs.add(m.group(1)!);
    }
    if (line.contains('</entry>')) {
      forms.readings.addAll(rebs);
      for (final k in kebs) {
        for (final r in rebs) {
          forms.pairs.add('$k|$r');
        }
      }
    }
  }
  return forms;
}

/// Einträge, deren Schreibung+Lesung (oder Lesung allein bei Kana-Wörtern)
/// JMdict nicht kennt. する-Verben gelten auch als gefunden, wenn der Stamm
/// ohne する als Paar in JMdict steht (JMdict führt meist nur das Nomen).
/// Reihenfolge wie im Vorrat.
List<PoolEntry> unmatchedInJmdict(Iterable<PoolEntry> pool, JmdictForms forms) {
  bool isKnown(PoolEntry e) {
    if (e.written.isEmpty) return forms.readings.contains(e.kana);
    if (forms.pairs.contains('${e.written}|${e.kana}')) return true;
    if (e.written.endsWith('する') && e.kana.endsWith('する')) {
      final writtenStem = e.written.substring(0, e.written.length - 'する'.length);
      final kanaStem = e.kana.substring(0, e.kana.length - 'する'.length);
      if (forms.pairs.contains('$writtenStem|$kanaStem')) return true;
    }
    return false;
  }

  return [for (final e in pool) if (!isKnown(e)) e];
}
