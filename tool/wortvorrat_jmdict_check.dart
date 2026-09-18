// tool/wortvorrat_jmdict_check.dart
//
// Usage: dart run tool/wortvorrat_jmdict_check.dart <pfad-zu-JMdict_e>
// Listet Vorrats-Wörter, deren Schreibung/Lesung JMdict nicht kennt.

import 'dart:convert';
import 'dart:io';

import 'package:nihongo_app/features/story/plan/jmdict_check.dart';
import 'package:nihongo_app/features/story/plan/vocab_pool_ja.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || !File(args.first).existsSync()) {
    stderr.writeln('JMdict_e nicht gefunden. Aufruf: dart run tool/wortvorrat_jmdict_check.dart <pfad-zu-JMdict_e>');
    exitCode = 2;
    return;
  }
  final lines = File(args.first)
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  final forms = await loadJmdictForms(lines);
  final missing = unmatchedInJmdict(vocabPoolJa, forms);
  stdout.writeln('JMdict: ${forms.readings.length} verschiedene Lesungen, ${forms.pairs.length} Schreibung-Lesung-Paare');
  stdout.writeln('Nicht gefunden: ${missing.length}');
  for (final e in missing) {
    stdout.writeln('  ${e.id}  ${e.kana}  ${e.written}  ${e.meaningDe}');
  }
}
