// Phase 5 gate proof (SPEC_MINING_PIPELINE.md §10):
//   "Card assembly incl. furigana, audio, frame | 20 cards produced
//    from a real episode; artifacts inspectable on disk."
//
// "Real episode" here means a real, correctly-timed audio/video file
// (generated via ffmpeg's test-pattern/tone sources, matching the
// synthetic-but-legitimate-source discipline used for the SRT itself
// since Phase 3 — see BERICHT_3) rather than actual copyrighted
// footage, which this mechanical pipeline-proof has no legal basis to
// use or redistribute.
//
// Usage:
//   dart run tool/phase5_card_assembly.dart <srt> <source-media> <JMdict_e> <tatoeba-tsv> <output-dir>

import 'dart:io';

import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/media/av_extractor.dart';
import 'package:nihongo_app/core/pipeline/card_assembly.dart';
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

Future<void> main(List<String> args) async {
  if (args.length < 5) {
    stderr.writeln('Usage: dart run tool/phase5_card_assembly.dart '
        '<srt> <source-media> <JMdict_e> <tatoeba-tsv> <output-dir>');
    exit(64);
  }
  final srtFile = File(args[0]);
  final sourceMedia = File(args[1]);
  final jmdictFile = File(args[2]);
  final tatoebaFile = File(args[3]);
  final outputDir = Directory(args[4]);
  for (final f in [srtFile, sourceMedia, jmdictFile, tatoebaFile]) {
    if (!f.existsSync()) {
      stderr.writeln('No such file: ${f.path}');
      exit(66);
    }
  }
  await outputDir.create(recursive: true);

  final tmp = Directory.systemTemp.path;
  final jmdictDb = JmdictDb.at(File('$tmp/phase5_jmdict.db')..deleteIfExists());
  final frequencyDb =
      FrequencyDb.at(File('$tmp/phase5_frequency.db')..deleteIfExists());
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
  print('segments (episode cues): ${spans.length}');

  // Bootstrap enough "known" vocabulary that real i+1 candidates exist
  // — an empty knowledge base finds almost none (Phase 4's finding),
  // and Phase 5 needs 20 genuine candidates to assemble, not a
  // near-empty pool.
  await importFrequencyBootstrap(miningDb, pack.frequency,
      languageCode: 'ja', topN: 1500);

  final knowledge = await FsrsKnowledgeSource.load(miningDb, languageCode: 'ja');
  final scored = scoreAll(spans, pack.tokenizer, pack.frequency, knowledge.call);
  final candidates = rankCandidates(scored);
  print('i+1 candidates available: ${candidates.length}');

  const cardTarget = 20;
  final toAssemble = candidates.take(cardTarget).toList();
  if (toAssemble.length < cardTarget) {
    stderr.writeln(
        'WARNING: only ${toAssemble.length} candidates available, target was $cardTarget');
  }

  print('\n=== Assembling ${toAssemble.length} cards ===');
  final assembler = CardAssembler(
    db: miningDb,
    extractor: const AvExtractor(),
    readings: pack.readings,
    mediaOutputDir: outputDir,
  );

  final assembleStopwatch = Stopwatch()..start();
  final assembled = <AssembledCard>[];
  for (final candidate in toAssemble) {
    final card = await assembler.assemble(
      candidate,
      languageCode: 'ja',
      sourceMedia: sourceMedia,
    );
    assembled.add(card);
  }
  assembleStopwatch.stop();

  print('assembled: ${assembled.length} cards in '
      '${assembleStopwatch.elapsedMilliseconds} ms');

  print('\n=== Phase 5 gate: artifacts inspectable on disk ===');
  var audioOk = 0;
  var frameOk = 0;
  for (final card in assembled) {
    final audioExists = card.audioFile?.existsSync() ?? false;
    final audioSize = audioExists ? card.audioFile!.lengthSync() : 0;
    final frameExists = card.frameFile?.existsSync() ?? false;
    final frameSize = frameExists ? card.frameFile!.lengthSync() : 0;
    if (audioExists && audioSize > 0) audioOk++;
    if (frameExists && frameSize > 0) frameOk++;
    print('  ${card.targetLemma.padRight(10)} '
        'furigana:${card.furigana.length} '
        'audio:${audioExists ? "${audioSize}B" : "MISSING"} '
        'frame:${frameExists ? "${frameSize}B" : "MISSING"} '
        '"${card.source.segment.content}"');
  }

  final cardsRows = await miningDb.select(miningDb.cards).get();
  final blobRows = await miningDb.select(miningDb.mediaBlobs).get();

  print('\ncards produced:        ${assembled.length} (target: $cardTarget)');
  print('audio files verified:  $audioOk/${assembled.length}');
  print('frame files verified:  $frameOk/${assembled.length}');
  print('Cards rows in DB:      ${cardsRows.length}');
  print('MediaBlobs rows in DB: ${blobRows.length}');

  final gatePass = assembled.length >= cardTarget &&
      audioOk == assembled.length &&
      frameOk == assembled.length;
  print(gatePass ? 'GATE: PASS' : 'GATE: FAIL');

  await jmdictDb.close();
  await frequencyDb.close();
  await miningDb.close();
  File('$tmp/phase5_jmdict.db').deleteIfExists();
  File('$tmp/phase5_frequency.db').deleteIfExists();

  print('\nartifacts written to: ${outputDir.path}');
  print('=== ${gatePass ? "PASS" : "FAIL"} ===');
}
