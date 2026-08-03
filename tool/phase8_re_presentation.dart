// Phase 8 gate proof (SPEC_MINING_PIPELINE.md §10):
//   "passage_snapshot + re-presentation: a passage read in Phase 6 is
//    re-offered and a real delta is computed and displayed, including a
//    negative one."
//
// Reads a real EPUB passage twice with a changed knowledge state
// between readings, records an immutable snapshot each time, computes
// the delta, and renders it Then/Now — for both an improvement AND a
// regression, the latter shown honestly (§0.9.29). The widget half of
// the display is proven separately by re_presentation_test.dart; this
// proves the data round-trip on real content.
//
// Usage:
//   dart run tool/phase8_re_presentation.dart <epub> <JMdict_e>

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/passage_snapshot.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart'
    show Knowledge, isContentToken;
import 'package:nihongo_app/core/sources/epub_source_adapter.dart';
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

/// A knowledge state defined by "the N most frequent lemmas in the
/// passage are known" — a plausible stand-in for a reader's vocabulary
/// at a point in time (common words are learned first). Varying N
/// models learning (N up) or forgetting (N down) between readings.
Knowledge Function(String) knownTopN(List<String> lemmasByFreq, int n) {
  final known = lemmasByFreq.take(n).toSet();
  return (lemma) => known.contains(lemma) ? Knowledge.known : Knowledge.unknown;
}

String pct(double r) => '${(r * 100).round()}%';

void showDelta(String title, PassageDelta d) {
  print('\n=== $title ===');
  print('  DAMALS ${pct(d.before.unknownRatio)}   →   JETZT ${pct(d.after.unknownRatio)}'
      '   ${d.isRegression ? "↑ schwerer geworden" : d.isImprovement ? "↓ leichter" : "= unverändert"}');
  print('  isImprovement=${d.isImprovement}  isRegression=${d.isRegression}  '
      'Δ=${(d.unknownRatioChange * 100).toStringAsFixed(0)}pp');
}

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
        'Usage: dart run tool/phase8_re_presentation.dart <epub> <JMdict_e>');
    exit(64);
  }
  final epubFile = File(args[0]);
  final jmdictFile = File(args[1]);
  for (final f in [epubFile, jmdictFile]) {
    if (!f.existsSync()) {
      stderr.writeln('No such file: ${f.path}');
      exit(66);
    }
  }

  final tmp = Directory.systemTemp.path;
  final jmdictDb = JmdictDb.at(File('$tmp/phase8_jmdict.db')..deleteIfExists());
  final miningDb = MiningDb.forTesting();

  print('=== Setup ===');
  await importJmdict(jmdictDb, jmdictFile);
  final tokenizer = NativeJaTokenizer();
  final pack =
      await JaLanguagePack.load(jmdictDb, tokenizerOverride: tokenizer);

  final workId = await EpubSourceAdapter(miningDb).importFile(
      file: epubFile, workTitle: '羅生門', languageCode: 'ja');
  final spans = await (miningDb.select(miningDb.textSpans)
        ..where((t) => t.workId.equals(workId))
        ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
      .get();

  // A passage = a contiguous run of content-bearing spans from the body.
  final bodySpans = spans
      .where((s) => pack.tokenizer
          .tokenize(s.content)
          .any((t) => isContentToken(t) && pack.dictionary.lookup(t.lemma, '').isNotEmpty))
      .toList();
  final passageSpans = bodySpans.skip(2).take(12).toList();
  final passageTokens =
      passageSpans.expand((s) => pack.tokenizer.tokenize(s.content)).toList();

  // Frequency order of the passage's own lemmas (for the knowledge model).
  final freq = <String, int>{};
  for (final t in passageTokens.where(isContentToken)) {
    if (pack.dictionary.lookup(t.lemma, '').isEmpty) continue;
    freq.update(t.lemma, (c) => c + 1, ifAbsent: () => 1);
  }
  final lemmasByFreq = (freq.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
      .map((e) => e.key)
      .toList();
  print('passage: ${passageSpans.length} spans, '
      '${lemmasByFreq.length} distinct dictionary lemmas');

  // --- IMPROVEMENT: read novice, learn, read again ---
  await recordPassageSnapshot(miningDb,
      workId: workId,
      passageRef: 'p-improve',
      tokens: passageTokens,
      knowledgeOf: knownTopN(lemmasByFreq, (lemmasByFreq.length * 0.15).round()),
      metrics: const PassageMetrics(dwellMs: 134000, lookupCount: 7),
      ts: DateTime.utc(2026, 1, 1));
  await recordPassageSnapshot(miningDb,
      workId: workId,
      passageRef: 'p-improve',
      tokens: passageTokens,
      knowledgeOf: knownTopN(lemmasByFreq, (lemmasByFreq.length * 0.90).round()),
      metrics: const PassageMetrics(dwellMs: 41000, lookupCount: 1),
      ts: DateTime.utc(2026, 2, 15));
  final improve =
      await latestPassageDelta(miningDb, workId: workId, passageRef: 'p-improve');

  // --- REGRESSION: read while knowing it, forget, read again ---
  await recordPassageSnapshot(miningDb,
      workId: workId,
      passageRef: 'p-regress',
      tokens: passageTokens,
      knowledgeOf: knownTopN(lemmasByFreq, (lemmasByFreq.length * 0.85).round()),
      ts: DateTime.utc(2026, 1, 1));
  await recordPassageSnapshot(miningDb,
      workId: workId,
      passageRef: 'p-regress',
      tokens: passageTokens,
      knowledgeOf: knownTopN(lemmasByFreq, (lemmasByFreq.length * 0.30).round()),
      ts: DateTime.utc(2026, 7, 1));
  final regress =
      await latestPassageDelta(miningDb, workId: workId, passageRef: 'p-regress');

  showDelta('Re-presentation — improvement', improve!);
  showDelta('Re-presentation — REGRESSION (shown, not hidden)', regress!);

  final snapshotCount =
      (await miningDb.select(miningDb.passageSnapshots).get()).length;

  final gatePass = improve.isImprovement &&
      regress.isRegression &&
      regress.unknownRatioChange > 0 &&
      snapshotCount == 4;

  print('\n=== Phase 8 gate ===');
  print('immutable snapshots recorded: $snapshotCount');
  print('improvement delta computed:   ${improve.isImprovement}');
  print('regression delta shown:       ${regress.isRegression} '
      '(Δ +${(regress.unknownRatioChange * 100).toStringAsFixed(0)}pp)');
  print(gatePass ? 'GATE: PASS' : 'GATE: FAIL');

  await jmdictDb.close();
  await miningDb.close();
  File('$tmp/phase8_jmdict.db').deleteIfExists();

  print('=== ${gatePass ? "PASS" : "FAIL"} ===');
}
