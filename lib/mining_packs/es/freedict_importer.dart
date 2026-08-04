import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:xml/xml.dart';

import 'es_pack_db.dart';

class FreeDictImportResult {
  final int entryCount;
  final Duration elapsed;
  const FreeDictImportResult({required this.entryCount, required this.elapsed});
}

/// Imports a FreeDict spa-eng TEI (P5) file into [EsPackDb]. Each
/// `<entry>` has a `<form><orth>` Spanish headword and one or more
/// `<sense><cit type="trans"><quote>` English translations.
Future<FreeDictImportResult> importFreeDict(EsPackDb db, String teiXml) async {
  final stopwatch = Stopwatch()..start();
  final doc = XmlDocument.parse(teiXml);

  final rows = <EsLexemesCompanion>[];
  var i = 0;
  for (final entry in doc.findAllElements('entry')) {
    final orth = entry
        .findAllElements('orth')
        .map((e) => e.innerText.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    if (orth.isEmpty) continue;

    final glosses = entry
        .findAllElements('cit')
        .where((c) => c.getAttribute('type') == 'trans')
        .expand((c) => c.findAllElements('quote'))
        .map((q) => q.innerText.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (glosses.isEmpty) continue;

    rows.add(EsLexemesCompanion.insert(
      id: 'es:${i++}',
      form: orth.toLowerCase(),
      glossesJson: jsonEncode(glosses),
    ));
  }

  const chunk = 2000;
  for (var start = 0; start < rows.length; start += chunk) {
    final end = (start + chunk) < rows.length ? start + chunk : rows.length;
    await db.batch((b) => b.insertAll(db.esLexemes, rows.sublist(start, end),
        mode: InsertMode.insertOrIgnore));
  }

  stopwatch.stop();
  return FreeDictImportResult(entryCount: rows.length, elapsed: stopwatch.elapsed);
}
