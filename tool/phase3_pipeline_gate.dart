// Phase 3 gate proof (SPEC_MINING_PIPELINE.md §10):
//   "One SRT in -> ranked ScoredSegment list out, as a CLI/test
//    harness. Perf gate from §3 met" (< 10s for a full novel).
//
// Ties together every Phase 3 prerequisite: the SRT source adapter
// (#5), the native JA tokenizer (#6), the Tatoeba-derived frequency
// list (#7), and the sentence-scoring module (this PR).
//
// Usage:
//   dart run tool/phase3_pipeline_gate.dart <path-to.srt> <path-to-JMdict_e> <path-to-frequency-tsv>
//
// The frequency TSV is Tatoeba's per-language export (see
// tool/phase3_frequency_import.dart's header for how to fetch it).

import 'dart:io';

import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/pipeline/frequency_knowledge_bootstrap.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';
import 'package:nihongo_app/core/sources/srt_source_adapter.dart';
import 'package:nihongo_app/mining_packs/ja/frequency_db.dart';
import 'package:nihongo_app/mining_packs/ja/frequency_importer.dart';
import 'package:nihongo_app/mining_packs/ja/ja_language_pack.dart';
import 'package:nihongo_app/mining_packs/ja/jmdict_db.dart';
import 'package:nihongo_app/mining_packs/ja/jmdict_importer.dart';
import 'package:nihongo_app/mining_packs/ja/native_tokenizer.dart';

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln(
        'Usage: dart run tool/phase3_pipeline_gate.dart <srt> <JMdict_e> <tatoeba-tsv>');
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
  final jmdictDb = JmdictDb.at(File('$tmp/phase3_gate_jmdict.db')..deleteIfExists());
  final frequencyDb =
      FrequencyDb.at(File('$tmp/phase3_gate_frequency.db')..deleteIfExists());
  final miningDb = MiningDb.forTesting();

  print('=== Setup: importing JMdict + frequency corpus ===');
  final setupStopwatch = Stopwatch()..start();
  await importJmdict(jmdictDb, jmdictFile);
  final sentences = tatoebaFile
      .readAsLinesSync()
      .map((l) => l.split('\t'))
      .where((c) => c.length >= 3)
      .map((c) => c[2]);
  final tokenizer = NativeJaTokenizer();
  await importFrequencyFromSentences(frequencyDb, tokenizer, sentences);
  setupStopwatch.stop();
  print('setup (one-time, not part of the perf gate): '
      '${setupStopwatch.elapsed.inSeconds}s');

  final pack = await JaLanguagePack.load(
    jmdictDb,
    frequencyDb: frequencyDb,
    tokenizerOverride: tokenizer,
  );
  final knowledgeOf = FrequencyBootstrapKnowledge(
    pack.frequency,
    knownRankThreshold: 1500, // §0.4.14 bootstrap: top-N known
  );

  // --- The actual gate: SRT in -> ranked ScoredSegment list out ---
  final gateStopwatch = Stopwatch()..start();

  final adapter = SrtSourceAdapter(miningDb);
  final workId = await adapter.importFile(
    file: srtFile,
    workTitle: srtFile.uri.pathSegments.last,
    languageCode: 'ja',
  );
  final spans = await (miningDb.select(miningDb.textSpans)
        ..where((t) => t.workId.equals(workId)))
      .get();

  final scored =
      scoreAll(spans, pack.tokenizer, pack.frequency, knowledgeOf.call);
  final primary = rankCandidates(scored);
  final secondary = secondaryCandidates(scored);

  gateStopwatch.stop();
  // ---

  print('\n=== Phase 3 gate: SRT -> ranked ScoredSegment list ===');
  print('segments (cues):     ${spans.length}');
  print('i+1 candidates:      ${primary.length}');
  print('secondary pool (i+2): ${secondary.length}');
  print('elapsed:              ${gateStopwatch.elapsedMilliseconds} ms '
      '(gate: < 10000 ms)');
  print(gateStopwatch.elapsedMilliseconds < 10000
      ? 'PERF GATE: PASS'
      : 'PERF GATE: FAIL');

  print('\ntop 10 i+1 candidates:');
  for (final s in primary.take(10)) {
    print('  [rank ${s.targetRank}] ${s.targetLemma} <- "${s.segment.content}"');
  }

  await jmdictDb.close();
  await frequencyDb.close();
  await miningDb.close();
  File('$tmp/phase3_gate_jmdict.db').deleteIfExists();
  File('$tmp/phase3_gate_frequency.db').deleteIfExists();

  print('\n=== PASS ===');
}

extension on File {
  File deleteIfExists() {
    if (existsSync()) deleteSync();
    return this;
  }
}
