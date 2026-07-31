// Phase 3 prerequisite: builds the JA frequency corpus from Tatoeba
// (CC-BY, approved per SPEC_MINING_PIPELINE.md §0.5.17 — see
// frequency_tables.dart for why Tatoeba stands in for BCCWJ/JPDB).
//
// Usage:
//   curl -sL http://downloads.tatoeba.org/exports/per_language/jpn/jpn_sentences.tsv.bz2 \
//     | bunzip2 > /tmp/jpn_sentences.tsv
//   cd native/ja_tokenizer && cargo build --release && cd ../..
//   dart run tool/phase3_frequency_import.dart /tmp/jpn_sentences.tsv

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:nihongo_app/mining_packs/ja/frequency_db.dart';
import 'package:nihongo_app/mining_packs/ja/frequency_importer.dart';
import 'package:nihongo_app/mining_packs/ja/native_tokenizer.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
        'Usage: dart run tool/phase3_frequency_import.dart <path-to-tatoeba-jpn-sentences.tsv>');
    exit(64);
  }
  final tsvFile = File(args.first);
  if (!tsvFile.existsSync()) {
    stderr.writeln('No such file: ${tsvFile.path}');
    exit(66);
  }

  // Tatoeba's per-language export is `id\tlang\ttext`.
  final sentences = tsvFile
      .readAsLinesSync()
      .map((line) => line.split('\t'))
      .where((cols) => cols.length >= 3)
      .map((cols) => cols[2]);

  final dbFile = File('${Directory.systemTemp.path}/phase3_frequency.db');
  if (dbFile.existsSync()) dbFile.deleteSync();
  final db = FrequencyDb.at(dbFile);
  final tokenizer = NativeJaTokenizer();

  print('=== Importing frequency data from Tatoeba ===');
  final result = await importFrequencyFromSentences(db, tokenizer, sentences);
  print('sentences:       ${result.sentenceCount}');
  print('tokens counted:  ${result.tokenCount}');
  print('unique lemmas:   ${result.uniqueLemmaCount}');
  print('elapsed:         ${result.elapsed.inMilliseconds} ms');

  final top20 = await (db.select(db.frequencyEntries)
        ..orderBy([(t) => OrderingTerm.asc(t.rank)])
        ..limit(20))
      .get();
  print('\ntop 20 by frequency:');
  for (final e in top20) {
    print('  ${e.rank}. ${e.lemma} (${e.count})');
  }

  await db.close();
  dbFile.deleteSync();
  print('\n=== PASS ===');
}
