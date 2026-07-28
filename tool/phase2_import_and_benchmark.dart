// Phase 2 proof tool (SPEC_MINING_PIPELINE.md §10):
//   "Full JMdict imported; lemma lookup benchmarked; second stub
//    LanguagePack (no real data) compiles and registers — proves the
//    seam."
//
// Usage: dart run tool/phase2_import_and_benchmark.dart <path-to-JMdict_e>
//
// Runs outside the Flutter binding (plain `dart run`), so it opens
// JmdictDb at an explicit file path rather than via path_provider.

import 'dart:io';
import 'dart:math';

import 'package:nihongo_app/core/language_pack/language_pack_registry.dart';
import 'package:nihongo_app/mining_packs/ja/ja_language_pack.dart';
import 'package:nihongo_app/mining_packs/ja/jmdict_db.dart';
import 'package:nihongo_app/mining_packs/ja/jmdict_importer.dart';
import 'package:nihongo_app/mining_packs/stub/stub_language_pack.dart';

double _percentile(List<double> sortedUs, double p) {
  if (sortedUs.isEmpty) return 0;
  final idx = ((sortedUs.length - 1) * p).round();
  return sortedUs[idx];
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
        'Usage: dart run tool/phase2_import_and_benchmark.dart <path-to-JMdict_e>');
    exit(64);
  }
  final jmdictFile = File(args.first);
  if (!jmdictFile.existsSync()) {
    stderr.writeln('No such file: ${jmdictFile.path}');
    exit(66);
  }

  final dbFile = File('${Directory.systemTemp.path}/phase2_jmdict.db');
  if (dbFile.existsSync()) dbFile.deleteSync();
  final db = JmdictDb.at(dbFile);

  print('=== Importing JMdict ===');
  final importResult = await importJmdict(db, jmdictFile);
  print('entries:  ${importResult.entryCount}');
  print('lemmas:   ${importResult.lemmaCount}');
  print('senses:   ${importResult.senseCount}');
  print('elapsed:  ${importResult.elapsed.inMilliseconds} ms');

  print('\n=== Loading JA LanguagePack (in-memory index) ===');
  final loadStopwatch = Stopwatch()..start();
  final ja = await JaLanguagePack.load(db);
  loadStopwatch.stop();
  print('index build: ${loadStopwatch.elapsedMilliseconds} ms');

  print('\n=== Benchmarking lemma lookup ===');
  final sampleForms = await (db.select(db.jmdictLemmas)
        ..limit(2000))
      .get();
  final rng = Random(42);
  final probeForms = List.generate(
    2000,
    (_) => sampleForms[rng.nextInt(sampleForms.length)].form,
  );

  final timingsUs = <double>[];
  var totalSenses = 0;
  for (final form in probeForms) {
    final sw = Stopwatch()..start();
    final senses = ja.dictionary.lookup(form, '');
    sw.stop();
    timingsUs.add(sw.elapsedMicroseconds.toDouble());
    totalSenses += senses.length;
  }
  timingsUs.sort();
  print('probes:        ${probeForms.length}');
  print('senses found:  $totalSenses total (sanity check, should be > 0)');
  print('p50:           ${_percentile(timingsUs, 0.50).toStringAsFixed(2)} µs');
  print('p99:           ${_percentile(timingsUs, 0.99).toStringAsFixed(2)} µs');
  print('max:           ${timingsUs.last.toStringAsFixed(2)} µs');

  // Spot check: a common kanji word should resolve to a sensible gloss.
  final spotCheck = ja.dictionary.lookup('日本語', '');
  print('\nSpot check 日本語 -> ${spotCheck.isEmpty ? "NOT FOUND" : spotCheck.first.glosses}');

  print('\n=== Second stub LanguagePack: compiles and registers ===');
  final registry = LanguagePackRegistry();
  registry.register(ja);
  registry.register(const StubLanguagePack());
  print('registered codes: ${registry.registeredCodes}');

  final stub = registry['xx']!;
  final stubTokens = stub.tokenizer.tokenize('hello world, this is a test.');
  print('stub tokenizer on a real sentence -> '
      '${stubTokens.map((t) => t.surface).toList()}');

  final jaFromRegistry = registry['ja']!;
  print('ja pack resolved from registry: code=${jaFromRegistry.code}, '
      'readings=${jaFromRegistry.readings != null}');

  await db.close();
  dbFile.deleteSync();

  print('\n=== PASS ===');
}
