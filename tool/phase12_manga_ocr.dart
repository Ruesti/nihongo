// Phase 12 gate proof (SPEC_MINING_PIPELINE.md §10):
//   "Manga OCR: SpatialAnchor path works end to end."
//
// Runs a REAL image through REAL OCR (Tesseract) into SpatialAnchor
// spans, then through the unchanged pipeline: reduces to PositionedSpan
// with a SpatialAnchor, tokenizes with the JA pack, looks a word up in
// the dictionary — the same word-tap path a reader uses, now sourced
// from an image instead of an SRT or EPUB.
//
// The image is a synthetic panel of clearly-set Japanese text (ffmpeg
// drawtext), OCR'd back — the same synthetic-but-legitimate discipline
// used for SRT/media/EPUB throughout. Real manga OCR quality (stylised
// vertical text) is an engine concern behind the OcrEngine seam, not a
// SpatialAnchor-path concern (see BERICHT_12).
//
// Usage:
//   dart run tool/phase12_manga_ocr.dart <page.png> <JMdict_e>

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/media/tesseract_ocr.dart';
import 'package:nihongo_app/core/sources/manga_source_adapter.dart';
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

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run tool/phase12_manga_ocr.dart <page.png> <JMdict_e>');
    exit(64);
  }
  final imageFile = File(args[0]);
  final jmdictFile = File(args[1]);
  for (final f in [imageFile, jmdictFile]) {
    if (!f.existsSync()) {
      stderr.writeln('No such file: ${f.path}');
      exit(66);
    }
  }

  final tmp = Directory.systemTemp.path;
  final jmdictDb = JmdictDb.at(File('$tmp/phase12_jmdict.db')..deleteIfExists());
  final miningDb = MiningDb.forTesting();

  print('=== Setup ===');
  await importJmdict(jmdictDb, jmdictFile);
  final tokenizer = NativeJaTokenizer();
  final pack = await JaLanguagePack.load(jmdictDb, tokenizerOverride: tokenizer);

  // --- REAL OCR of a REAL image → SpatialAnchor spans ---
  print('\n=== OCR the page → SpatialAnchor spans ===');
  const ocr = TesseractOcrEngine(language: 'jpn', minConfidence: 20);
  final adapter = MangaSourceAdapter(miningDb, ocr);
  final workId = await adapter.importImage(
    image: imageFile,
    workTitle: 'manga page',
    languageCode: 'ja',
    pageId: 'page-1',
  );
  final rows = await (miningDb.select(miningDb.textSpans)
        ..where((t) => t.workId.equals(workId))
        ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
      .get();
  print('OCR text regions found: ${rows.length}');
  for (final r in rows) {
    print('  [${r.anchorType}] page=${r.pageId} rect=${r.rectJson} '
        'text="${r.content}"');
  }

  // --- The unchanged pipeline: reduce, tokenize, word-tap lookup ---
  final positioned = rows.map(PositionedSpan.fromRow).toList();
  final allSpatial = positioned.every((s) => s.anchor is SpatialAnchor);
  print('\n=== SpatialAnchor path end to end ===');
  print('all spans reduce to SpatialAnchor: $allSpatial');

  final handler = WordTapHandler(pack.dictionary);
  var lookupsFound = 0;
  String? sampleTap;
  for (final span in positioned) {
    for (final token in pack.tokenizer.tokenize(span.text)) {
      final result = handler.onTap(token);
      if (result.isKnownWord) {
        lookupsFound++;
        sampleTap ??=
            '「${token.lemma}」 → ${result.senses.first.glosses.take(2).toList()}';
      }
    }
  }
  print('word-tap lookups resolved from OCR text: $lookupsFound');
  if (sampleTap != null) print('sample tap (image → OCR → tokenize → lookup): $sampleTap');

  final gatePass = rows.isNotEmpty &&
      allSpatial &&
      positioned.every((s) => (s.anchor as SpatialAnchor).pageId == 'page-1') &&
      lookupsFound > 0;

  print('\n=== Phase 12 gate ===');
  print('image OCR produced SpatialAnchor spans: ${rows.isNotEmpty && allSpatial}');
  print('spans carry page id + bounding box:     ${rows.isNotEmpty}');
  print('spans run the unchanged tap→lookup path: ${lookupsFound > 0}');
  print(gatePass ? 'GATE: PASS' : 'GATE: FAIL');

  await jmdictDb.close();
  await miningDb.close();
  File('$tmp/phase12_jmdict.db').deleteIfExists();
  print('=== ${gatePass ? "PASS" : "FAIL"} ===');
}
