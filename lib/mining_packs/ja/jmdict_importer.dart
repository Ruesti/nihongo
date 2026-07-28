import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:xml/xml.dart';

import 'jmdict_db.dart';

/// Imports the raw JMdict_e XML file (http://ftp.edrdg.org/pub/Nihongo/
/// JMdict_e.gz) into [JmdictDb]. Idempotent-ish in the sense that it's
/// meant to run against an empty database (see [JmdictDb.isEmpty]); the
/// pipeline as a whole is append-only, importing twice is the caller's
/// mistake to avoid, not something this guards against.
///
/// JMdict's DTD declares ~270 custom entities for part-of-speech and
/// usage tags (`<pos>&n;</pos>`, meaning "noun (common)"). A strict XML
/// parser without DTD support chokes on those as undefined entities, so
/// this does a one-pass text substitution — `&n;` -> `n` — before
/// parsing, using the DTD's own `<!ENTITY n "...">` declarations to
/// know which `&...;` sequences are JMdict's rather than the five
/// standard XML entities (`&amp;` etc., left untouched).
class JmdictImportResult {
  final int entryCount;
  final int lemmaCount;
  final int senseCount;
  final Duration elapsed;

  const JmdictImportResult({
    required this.entryCount,
    required this.lemmaCount,
    required this.senseCount,
    required this.elapsed,
  });
}

final _entityDeclPattern = RegExp(r'<!ENTITY\s+(\S+)\s+"[^"]*">');

Future<JmdictImportResult> importJmdict(JmdictDb db, File jmdictFile) async {
  final stopwatch = Stopwatch()..start();

  final raw = await jmdictFile.readAsString(encoding: utf8);
  final entityNames =
      _entityDeclPattern.allMatches(raw).map((m) => m.group(1)!).toSet();

  final resolved = raw.replaceAllMapped(
    RegExp(r'&([A-Za-z0-9_-]+);'),
    (m) {
      final name = m.group(1)!;
      return entityNames.contains(name) ? name : m.group(0)!;
    },
  );

  final document = XmlDocument.parse(resolved);
  final entries = document.findAllElements('entry');

  var entryCount = 0;
  var lemmaCount = 0;
  var senseCount = 0;

  const chunkSize = 2000;
  var entryRows = <JmdictEntriesCompanion>[];
  var lemmaRows = <JmdictLemmasCompanion>[];
  var senseRows = <JmdictSensesCompanion>[];

  Future<void> flush() async {
    if (entryRows.isEmpty) return;
    await db.batch((b) {
      b.insertAll(db.jmdictEntries, entryRows, mode: InsertMode.insertOrIgnore);
      b.insertAll(db.jmdictLemmas, lemmaRows, mode: InsertMode.insertOrIgnore);
      b.insertAll(db.jmdictSenses, senseRows, mode: InsertMode.insertOrIgnore);
    });
    entryRows = [];
    lemmaRows = [];
    senseRows = [];
  }

  for (final entry in entries) {
    final entSeqText = entry.getElement('ent_seq')?.innerText.trim();
    final entSeq = entSeqText == null ? null : int.tryParse(entSeqText);
    if (entSeq == null) continue;

    entryRows.add(JmdictEntriesCompanion.insert(id: Value(entSeq)));
    entryCount++;

    var lemmaIndex = 0;
    for (final kEle in entry.findElements('k_ele')) {
      final keb = kEle.getElement('keb')?.innerText.trim();
      if (keb == null || keb.isEmpty) continue;
      lemmaRows.add(JmdictLemmasCompanion.insert(
        id: '$entSeq:k:${lemmaIndex++}',
        entryId: entSeq,
        form: keb,
        kind: 'kanji',
      ));
      lemmaCount++;
    }
    for (final rEle in entry.findElements('r_ele')) {
      final reb = rEle.getElement('reb')?.innerText.trim();
      if (reb == null || reb.isEmpty) continue;
      lemmaRows.add(JmdictLemmasCompanion.insert(
        id: '$entSeq:r:${lemmaIndex++}',
        entryId: entSeq,
        form: reb,
        kind: 'reading',
      ));
      lemmaCount++;
    }

    var senseIndex = 0;
    for (final sense in entry.findElements('sense')) {
      final posTags = sense
          .findElements('pos')
          .map((e) => e.innerText.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final glosses = sense
          .findElements('gloss')
          .map((e) => e.innerText.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (glosses.isEmpty) continue;

      senseRows.add(JmdictSensesCompanion.insert(
        id: '$entSeq:s:${senseIndex++}',
        entryId: entSeq,
        senseOrder: senseIndex,
        pos: posTags.join(','),
        glossesJson: jsonEncode(glosses),
      ));
      senseCount++;
    }

    if (entryRows.length >= chunkSize) {
      await flush();
    }
  }
  await flush();

  stopwatch.stop();
  return JmdictImportResult(
    entryCount: entryCount,
    lemmaCount: lemmaCount,
    senseCount: senseCount,
    elapsed: stopwatch.elapsed,
  );
}
