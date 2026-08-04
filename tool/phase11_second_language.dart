// Phase 11 gate proof (SPEC_MINING_PIPELINE.md §10):
//   "Second language pack with real data: new language added with zero
//    changes to pipeline OR experience code — verified by diff."
//
// This tool drives the ENTIRE existing core pipeline — SRT source
// adapter, sentence scoring, candidate ranking, passage snapshot +
// delta, and Datum — over a REAL Spanish LanguagePack (FreeDict spa-eng
// lexemes + Tatoeba-derived frequency, whitespace tokenizer, null
// readings). Nothing in core/pipeline, core/text_track,
// core/language_pack, or features is touched; the Spanish pack only
// implements the same four seams JA does. The "verified by diff" half
// is a shell check (see BERICHT_11) — this proves the pack runs the
// unchanged pipeline end to end.
//
// Usage:
//   dart run tool/phase11_second_language.dart <spa-eng.tei> <spa_sentences.tsv> <es.srt>

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:nihongo_app/core/datum/datum_registry.dart';
import 'package:nihongo_app/core/datum/datum_voice.dart';
import 'package:nihongo_app/core/datum/observation.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack_registry.dart';
import 'package:nihongo_app/core/pipeline/frequency_knowledge_bootstrap.dart';
import 'package:nihongo_app/core/pipeline/passage_snapshot.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';
import 'package:nihongo_app/core/sources/srt_source_adapter.dart';
import 'package:nihongo_app/mining_packs/es/es_frequency_importer.dart';
import 'package:nihongo_app/mining_packs/es/es_language_pack.dart';
import 'package:nihongo_app/mining_packs/es/es_pack_db.dart';
import 'package:nihongo_app/mining_packs/es/es_whitespace_tokenizer.dart';
import 'package:nihongo_app/mining_packs/es/freedict_importer.dart';

extension on File {
  File deleteIfExists() {
    if (existsSync()) deleteSync();
    return this;
  }
}

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln('Usage: dart run tool/phase11_second_language.dart '
        '<spa-eng.tei> <spa_sentences.tsv> <es.srt>');
    exit(64);
  }
  final teiFile = File(args[0]);
  final tatoebaFile = File(args[1]);
  final srtFile = File(args[2]);
  for (final f in [teiFile, tatoebaFile, srtFile]) {
    if (!f.existsSync()) {
      stderr.writeln('No such file: ${f.path}');
      exit(66);
    }
  }

  final tmp = Directory.systemTemp.path;
  final esDb = EsPackDb.at(File('$tmp/phase11_es.db')..deleteIfExists());
  final miningDb = MiningDb.forTesting();

  print('=== Setup: importing REAL Spanish data ===');
  final dictResult = await importFreeDict(esDb, teiFile.readAsStringSync());
  final sentences = tatoebaFile
      .readAsLinesSync()
      .map((l) => l.split('\t'))
      .where((c) => c.length >= 3)
      .map((c) => c[2]);
  final freqResult = await importEsFrequency(
      esDb, const EsWhitespaceTokenizer(), sentences);
  print('FreeDict lexemes: ${dictResult.entryCount}');
  print('frequency: ${freqResult.sentenceCount} sentences, '
      '${freqResult.uniqueLemmaCount} lemmas');

  // Load the ES pack and register it exactly like any pack — the
  // registry (core/language_pack) is unchanged and generic.
  final pack = await EsLanguagePack.load(esDb);
  final registry = LanguagePackRegistry()..register(pack);
  print('registered language packs: ${registry.registeredCodes}');

  // --- Run the UNCHANGED core pipeline over Spanish ---
  final workId = await SrtSourceAdapter(miningDb).importFile(
      file: srtFile, workTitle: 'ES episode', languageCode: 'es');
  final spans = await (miningDb.select(miningDb.textSpans)
        ..where((t) => t.workId.equals(workId))
        ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
      .get();

  // §0.4.14 bootstrap: top-N frequency words known (core/pipeline).
  final knowledge = FrequencyBootstrapKnowledge(pack.frequency,
      knownRankThreshold: 800);

  // core/pipeline: scoreAll + rankCandidates — no ES-specific code.
  final scored = scoreAll(spans, pack.tokenizer, pack.frequency, knowledge.call);
  final candidates = rankCandidates(scored);

  print('\n=== The unchanged pipeline, running on Spanish ===');
  print('spans: ${spans.length}, i+1 candidates: ${candidates.length}');
  print('top i+1 candidates (real ES words + FreeDict glosses):');
  var shown = 0;
  for (final c in candidates) {
    if (shown >= 8) break;
    final glosses = pack.dictionary.lookup(c.targetLemma!, '');
    if (glosses.isEmpty) continue; // show ones with a dictionary hit
    print('  [rank ${c.targetRank}] ${c.targetLemma} '
        '= ${glosses.first.glosses.take(2).toList()}  ← "${c.segment.content}"');
    shown++;
  }

  // core/pipeline: passage snapshot + delta over Spanish.
  final passageTokens =
      spans.take(15).expand((s) => pack.tokenizer.tokenize(s.content)).toList();
  await miningDb.into(miningDb.works).insertOnConflictUpdate(WorksCompanion.insert(
      id: 'w', title: 'ES', medium: 'srt', languageCode: 'es',
      addedAt: DateTime.utc(2026, 1, 1)));
  final byFreq = pack.frequency.topLemmas(100000);
  final novice = FrequencyBootstrapKnowledge(pack.frequency, knownRankThreshold: 200);
  final learned = FrequencyBootstrapKnowledge(pack.frequency, knownRankThreshold: 5000);
  await recordPassageSnapshot(miningDb,
      workId: 'w', passageRef: 'Capítulo 1', tokens: passageTokens,
      knowledgeOf: novice.call, ts: DateTime.utc(2026, 1, 1));
  await recordPassageSnapshot(miningDb,
      workId: 'w', passageRef: 'Capítulo 1', tokens: passageTokens,
      knowledgeOf: learned.call, ts: DateTime.utc(2026, 2, 12));
  final delta =
      await latestPassageDelta(miningDb, workId: 'w', passageRef: 'Capítulo 1');

  // core/datum: Datum voices the ES measurement in the UI language (DE).
  final voice = DatumVoice(registry: DatumRegistry.forLocale('de'), enabled: true);
  final line = voice.say(Observation(kind: ObservationKind.deltaMeasured, facts: {
    'chapter': 'Capítulo 1',
    'weeks_ago': 6,
    'unknown_before': (delta!.before.unknownRatio * 100).round(),
    'unknown_after': (delta.after.unknownRatio * 100).round(),
  }));

  print('\n=== Re-presentation + Datum, over Spanish ===');
  print('Capítulo 1: ${(delta.before.unknownRatio * 100).round()}% → '
      '${(delta.after.unknownRatio * 100).round()}% unknown');
  print('Datum (UI language DE): "$line"');

  final gatePass = dictResult.entryCount > 1000 &&
      freqResult.uniqueLemmaCount > 1000 &&
      registry.registeredCodes.contains('es') &&
      candidates.isNotEmpty &&
      shown > 0 &&
      delta.isImprovement &&
      line != null &&
      byFreq.isNotEmpty;

  print('\n=== Phase 11 gate ===');
  print('real ES data imported:                ${dictResult.entryCount} lexemes, ${freqResult.uniqueLemmaCount} freq lemmas');
  print('ES pack registered:                   ${registry.registeredCodes.contains('es')}');
  print('unchanged pipeline scored/ranked ES:  ${candidates.isNotEmpty}');
  print('re-presentation delta over ES:        ${delta.isImprovement}');
  print('Datum voiced the ES measurement:      ${line != null}');
  print(gatePass ? 'GATE: PASS' : 'GATE: FAIL');

  await esDb.close();
  await miningDb.close();
  File('$tmp/phase11_es.db').deleteIfExists();
  print('=== ${gatePass ? "PASS" : "FAIL"} ===');
}
