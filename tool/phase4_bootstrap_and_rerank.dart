// Phase 4 gate proof (SPEC_MINING_PIPELINE.md §10):
//   "Existing knowledge importable; re-running Phase 3 over the same
//    source yields a demonstrably different ranking."
//
// Scores the same SRT twice: once with an empty knowledge base
// (baseline — everything unknown), once after a real frequency-
// bootstrap import (§0.4.14) writes genuine FSRS "known" Cards rows.
// Diffs the two ranked candidate lists to prove the import actually
// feeds back into scoring, not just that both runs happen to work.
//
// Usage:
//   dart run tool/phase4_bootstrap_and_rerank.dart <srt> <JMdict_e> <tatoeba-tsv>

import 'dart:io';

import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/pipeline/fsrs_bootstrap_import.dart';
import 'package:nihongo_app/core/pipeline/fsrs_knowledge_source.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';
import 'package:nihongo_app/core/sources/srt_source_adapter.dart';
import 'package:nihongo_app/mining_packs/ja/frequency_db.dart';
import 'package:nihongo_app/mining_packs/ja/frequency_importer.dart';
import 'package:nihongo_app/mining_packs/ja/ja_language_pack.dart';
import 'package:nihongo_app/mining_packs/ja/jmdict_db.dart';
import 'package:nihongo_app/mining_packs/ja/jmdict_importer.dart';
import 'package:nihongo_app/mining_packs/ja/native_tokenizer.dart';

extension on File {
  File deleteIfExists() {
    if (existsSync()) deleteSync();
    return this;
  }
}

Set<String> _candidateKey(List<ScoredSegment> candidates) =>
    candidates.map((s) => '${s.segment.id}:${s.targetLemma}').toSet();

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln(
        'Usage: dart run tool/phase4_bootstrap_and_rerank.dart <srt> <JMdict_e> <tatoeba-tsv>');
    exit(64);
  }
  final srtFile = File(args[0]);
  final jmdictFile = File(args[1]);
  final tatoebaFile = File(args[2]);
  for (final f in [srtFile, jmdictFile, tatoebaFile]) {
    if (!f.existsSync()) {
      stderr.writeln('No such file: ${f.path}');
      exit(66);
    }
  }

  final tmp = Directory.systemTemp.path;
  final jmdictDb = JmdictDb.at(File('$tmp/phase4_jmdict.db')..deleteIfExists());
  final frequencyDb =
      FrequencyDb.at(File('$tmp/phase4_frequency.db')..deleteIfExists());
  final miningDb = MiningDb.forTesting();

  print('=== Setup ===');
  await importJmdict(jmdictDb, jmdictFile);
  final sentences = tatoebaFile
      .readAsLinesSync()
      .map((l) => l.split('\t'))
      .where((c) => c.length >= 3)
      .map((c) => c[2]);
  final tokenizer = NativeJaTokenizer();
  await importFrequencyFromSentences(frequencyDb, tokenizer, sentences);

  final pack = await JaLanguagePack.load(
    jmdictDb,
    frequencyDb: frequencyDb,
    tokenizerOverride: tokenizer,
  );

  final adapter = SrtSourceAdapter(miningDb);
  final workId = await adapter.importFile(
    file: srtFile,
    workTitle: srtFile.uri.pathSegments.last,
    languageCode: 'ja',
  );
  final spans = await (miningDb.select(miningDb.textSpans)
        ..where((t) => t.workId.equals(workId)))
      .get();
  print('segments: ${spans.length}');

  // --- Pass 1: baseline, empty knowledge base ---
  final baselineKnowledge =
      await FsrsKnowledgeSource.load(miningDb, languageCode: 'ja');
  final baselineScored =
      scoreAll(spans, pack.tokenizer, pack.frequency, baselineKnowledge.call);
  final baselineCandidates = rankCandidates(baselineScored);

  print('\n=== Pass 1: baseline (no knowledge imported) ===');
  print('i+1 candidates: ${baselineCandidates.length}');

  // --- Bootstrap import: mark top-1500 frequency words as known ---
  const knownWordCount = 1500;
  final importResult = await importFrequencyBootstrap(
    miningDb,
    pack.frequency,
    languageCode: 'ja',
    topN: knownWordCount,
  );
  print('\n=== Bootstrap import ===');
  print('lemmas marked known: ${importResult.lemmaCount}');
  print('elapsed: ${importResult.elapsed.inMilliseconds} ms');

  // --- Pass 2: re-run the SAME scoring over the SAME source ---
  final afterKnowledge =
      await FsrsKnowledgeSource.load(miningDb, languageCode: 'ja');
  final afterScored =
      scoreAll(spans, pack.tokenizer, pack.frequency, afterKnowledge.call);
  final afterCandidates = rankCandidates(afterScored);

  print('\n=== Pass 2: after bootstrap import (same SRT, same source) ===');
  print('i+1 candidates: ${afterCandidates.length}');

  // --- The gate: is the ranking demonstrably different? ---
  final beforeKeys = _candidateKey(baselineCandidates);
  final afterKeys = _candidateKey(afterCandidates);
  final onlyBefore = beforeKeys.difference(afterKeys);
  final onlyAfter = afterKeys.difference(beforeKeys);

  print('\n=== Phase 4 gate: demonstrably different ranking? ===');
  print('candidates only in baseline:        ${onlyBefore.length}');
  print('candidates only after import:       ${onlyAfter.length}');
  print('top-10 identical before vs after:   '
      '${baselineCandidates.take(10).map((s) => s.segment.id).toList().toString() == afterCandidates.take(10).map((s) => s.segment.id).toList().toString()}');

  final demonstrablyDifferent =
      onlyBefore.isNotEmpty || onlyAfter.isNotEmpty;
  print(demonstrablyDifferent
      ? 'GATE: PASS (ranking changed)'
      : 'GATE: FAIL (ranking identical)');

  print('\nsample: a sentence whose status flipped from baseline to after:');
  final flippedToKnownFully = baselineScored.where((s) =>
      s.unknownCount >= 1 &&
      afterScored.firstWhere((a) => a.segment.id == s.segment.id).unknownCount == 0);
  if (flippedToKnownFully.isNotEmpty) {
    final example = flippedToKnownFully.first;
    print('  "${example.segment.content}"');
    print('  baseline unknownCount: ${example.unknownCount} -> '
        'after: 0 (fully known now)');
  } else {
    print('  (none in this sample — see candidate-set diff above instead)');
  }

  await jmdictDb.close();
  await frequencyDb.close();
  await miningDb.close();
  File('$tmp/phase4_jmdict.db').deleteIfExists();
  File('$tmp/phase4_frequency.db').deleteIfExists();

  print('\n=== ${demonstrablyDifferent ? "PASS" : "FAIL"} ===');
}
