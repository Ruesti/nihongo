// Phase 6 kill-gate proof (SPEC_MINING_PIPELINE.md §10):
//   "EPUB and SRT both reduce to TextSpan_; tapping a word behaves
//    identically in both; renderer contains zero vocabulary logic —
//    verified by inspection."
//
// Runs a real EPUB (Project Gutenberg's 羅生門, public domain) and a
// real SRT through the two source adapters, reduces both to the unified
// PositionedSpan track, and shows a word tap resolving identically
// regardless of which medium the span came from.
//
// Usage:
//   dart run tool/phase6_unified_track.dart <rashomon.epub> <some.srt> <JMdict_e>

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/sources/epub_source_adapter.dart';
import 'package:nihongo_app/core/sources/srt_source_adapter.dart';
import 'package:nihongo_app/core/text_track/anchor.dart';
import 'package:nihongo_app/core/text_track/word_tap.dart';
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

Future<List<PositionedSpan>> _positioned(MiningDb db, String workId) async {
  final rows = await (db.select(db.textSpans)
        ..where((t) => t.workId.equals(workId))
        ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
      .get();
  return rows.map(PositionedSpan.fromRow).toList();
}

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln(
        'Usage: dart run tool/phase6_unified_track.dart <epub> <srt> <JMdict_e>');
    exit(64);
  }
  final epubFile = File(args[0]);
  final srtFile = File(args[1]);
  final jmdictFile = File(args[2]);
  for (final f in [epubFile, srtFile, jmdictFile]) {
    if (!f.existsSync()) {
      stderr.writeln('No such file: ${f.path}');
      exit(66);
    }
  }

  final tmp = Directory.systemTemp.path;
  final jmdictDb = JmdictDb.at(File('$tmp/phase6_jmdict.db')..deleteIfExists());
  final miningDb = MiningDb.forTesting();

  print('=== Setup ===');
  await importJmdict(jmdictDb, jmdictFile);
  final tokenizer = NativeJaTokenizer();
  final pack =
      await JaLanguagePack.load(jmdictDb, tokenizerOverride: tokenizer);

  // --- Both media through their adapters ---
  final epubWork = await EpubSourceAdapter(miningDb).importFile(
      file: epubFile, workTitle: '羅生門', languageCode: 'ja');
  final srtWork = await SrtSourceAdapter(miningDb).importFile(
      file: srtFile, workTitle: 'episode', languageCode: 'ja');

  final epubSpans = await _positioned(miningDb, epubWork);
  final srtSpans = await _positioned(miningDb, srtWork);

  print('\n=== Both media reduce to the unified PositionedSpan track ===');
  print('EPUB (羅生門): ${epubSpans.length} spans, anchor type: '
      '${epubSpans.isEmpty ? "n/a" : epubSpans.first.anchor.runtimeType}');
  print('SRT (episode): ${srtSpans.length} spans, anchor type: '
      '${srtSpans.isEmpty ? "n/a" : srtSpans.first.anchor.runtimeType}');

  final epubAllFlow = epubSpans.every((s) => s.anchor is FlowAnchor);
  final srtAllTime = srtSpans.every((s) => s.anchor is TimeAnchor);
  print('EPUB spans all FlowAnchor: $epubAllFlow');
  print('SRT spans all TimeAnchor:  $srtAllTime');

  // --- Same word, tapped in each medium, same lookup ---
  print('\n=== A word tap behaves identically regardless of medium ===');
  final handler = WordTapHandler(pack.dictionary);

  // Find a lemma that appears in a real span of BOTH works.
  String? sharedLemma;
  Token? epubToken;
  Token? srtToken;
  outer:
  for (final es in epubSpans) {
    for (final et in pack.tokenizer.tokenize(es.text)) {
      if (pack.dictionary.lookup(et.lemma, '').isEmpty) continue;
      for (final ss in srtSpans) {
        for (final st in pack.tokenizer.tokenize(ss.text)) {
          if (st.lemma == et.lemma) {
            sharedLemma = et.lemma;
            epubToken = et;
            srtToken = st;
            break outer;
          }
        }
      }
    }
  }

  var tapIdentical = false;
  if (sharedLemma != null) {
    final epubResult = handler.onTap(epubToken!);
    final srtResult = handler.onTap(srtToken!);
    tapIdentical = epubResult.senses.length == srtResult.senses.length &&
        epubResult.senses.isNotEmpty &&
        epubResult.senses.first.glosses.join() ==
            srtResult.senses.first.glosses.join();
    print('shared lemma tapped in both: 「$sharedLemma」');
    print('  from EPUB span (FlowAnchor) -> ${epubResult.senses.first.glosses}');
    print('  from SRT span  (TimeAnchor) -> ${srtResult.senses.first.glosses}');
    print('  identical lookup result: $tapIdentical');
  } else {
    print('  (no shared dictionary lemma found between the two sources)');
  }

  // --- Renderer purity: verified by inspection (mechanically) ---
  print('\n=== Renderer contains zero vocabulary logic (by inspection) ===');
  final rendererSrc =
      File('lib/features/reader/span_reader.dart').readAsStringSync();
  final rendererImports = rendererSrc
      .split('\n')
      .where((l) => l.trimLeft().startsWith('import '))
      .toList();
  const forbidden = ['db/', 'pipeline/', 'mining_packs/', 'datum', 'srs', 'scheduler'];
  final rendererClean = rendererImports.every(
      (imp) => !forbidden.any((needle) => imp.contains(needle)));
  print('renderer imports: ${rendererImports.length}');
  for (final imp in rendererImports) {
    print('  $imp');
  }
  print('renderer free of vocabulary/scheduling/db/Datum imports: $rendererClean');

  final gatePass = epubSpans.isNotEmpty &&
      srtSpans.isNotEmpty &&
      epubAllFlow &&
      srtAllTime &&
      tapIdentical &&
      rendererClean;

  print('\n=== Phase 6 kill-gate ===');
  print(gatePass ? 'GATE: PASS' : 'GATE: FAIL');

  await jmdictDb.close();
  await miningDb.close();
  File('$tmp/phase6_jmdict.db').deleteIfExists();

  print('=== ${gatePass ? "PASS" : "FAIL"} ===');
}
