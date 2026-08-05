// Prebake the vertical-slice content asset (see lib/features/mining_slice).
//
// The mining app's tokenizer (Lindera) and dictionary (JMdict, 218k
// entries) are host-native / large; wiring Lindera into a device build
// (flutter_rust_bridge) and shipping a full JMdict DB are their own
// integration phases. The vertical slice's job is different: prove the
// *reading experience* — real widgets, real pipeline (MiningDb, FSRS
// scheduler, passage snapshots, Datum) — end to end on any device.
//
// So we run the REAL host pipeline ONCE, here, and freeze its output:
// real Lindera tokens + real JMdict senses + real furigana for a short
// passage, emitted as a small JSON the app bundles. This is exactly what
// the `Tokenizer`/`Dictionary` seams are for — the app consumes prebaked
// `Token`s and a prebaked `Dictionary`, with no native dependency. The
// tokens are genuine Lindera output; the glosses are genuine JMdict —
// only *when* they're computed moves from runtime to build time.
//
// Usage (run from the main checkout, which has the built .so):
//   dart run tool/prebake_slice.dart <rashomon.epub> <JMdict_e> <libja_tokenizer.so> <out.json>

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart' show Token;
import 'package:nihongo_app/core/pipeline/furigana.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart' show isContentToken;
import 'package:nihongo_app/core/sources/epub_source_adapter.dart';
import 'package:nihongo_app/mining_packs/ja/ja_language_pack.dart';
import 'package:nihongo_app/mining_packs/ja/jmdict_db.dart';
import 'package:nihongo_app/mining_packs/ja/jmdict_importer.dart';
import 'package:nihongo_app/mining_packs/ja/native_tokenizer.dart';
import 'package:nihongo_app/mining_packs/ja/native_tokenizer_bindings.dart';

const _passageCount = 6;
const _demoKnownCount = 24;

Future<void> main(List<String> args) async {
  if (args.length < 4) {
    stderr.writeln('Usage: dart run tool/prebake_slice.dart '
        '<epub> <JMdict_e> <libja_tokenizer.so> <out.json>');
    exit(64);
  }
  final epubFile = File(args[0]);
  final jmdictFile = File(args[1]);
  final soPath = args[2];
  final outFile = File(args[3]);
  for (final f in [epubFile, jmdictFile, File(soPath)]) {
    if (!f.existsSync()) {
      stderr.writeln('No such file: ${f.path}');
      exit(66);
    }
  }

  final tmp = Directory.systemTemp.createTempSync('prebake_slice_');
  final jmdictDb = JmdictDb.at(File('${tmp.path}/jmdict.db'));
  final miningDb = MiningDb.forTesting();

  stderr.writeln('Importing JMdict…');
  await importJmdict(jmdictDb, jmdictFile);
  final tokenizer = NativeJaTokenizer(
      bindings: NativeTokenizerBindings.load(libraryPath: soPath));
  final pack =
      await JaLanguagePack.load(jmdictDb, tokenizerOverride: tokenizer);

  stderr.writeln('Importing EPUB → spans…');
  final workId = await EpubSourceAdapter(miningDb)
      .importFile(file: epubFile, workTitle: '羅生門', languageCode: 'ja');
  final spanRows = await (miningDb.select(miningDb.textSpans)
        ..where((t) => t.workId.equals(workId))
        ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
      .get();

  // Score every span by dictionary-backed content tokens and keep the
  // first few (in reading order) that clear a bar. The opening pages of
  // a Gutenberg EPUB are English licence boilerplate with zero JA
  // dictionary hits, so this naturally skips them and lands on a
  // continuous run of real Japanese prose — long enough to be
  // interesting, short enough to sit on a phone screen.
  final selected = <({String content, List<Token> tokens})>[];
  for (final r in spanRows) {
    final content = r.content.trim();
    if (content.length < 12 || content.length > 220) continue;
    final tokens = pack.tokenizer.tokenize(content);
    final hits = tokens
        .where((t) =>
            isContentToken(t) && pack.dictionary.lookup(t.lemma, '').isNotEmpty)
        .length;
    if (hits < 5) continue;
    selected.add((content: content, tokens: tokens));
    if (selected.length >= _passageCount) break;
  }
  if (selected.isEmpty) {
    stderr.writeln('No suitable Japanese prose spans found in EPUB.');
    exit(70);
  }

  final dictionary = <String, List<Map<String, Object>>>{};
  final lemmaFreq = <String, int>{};
  final passages = <Map<String, Object>>[];

  for (var i = 0; i < selected.length; i++) {
    final content = selected[i].content;
    final tokens = selected[i].tokens;
    final furiganaSpans = computeFurigana(tokens, pack.readings);
    final furigana = <String, String>{
      for (final f in furiganaSpans) '${f.charStart}': f.reading,
    };

    final tokenJson = <Map<String, Object?>>[];
    for (final t in tokens) {
      tokenJson.add({
        'surface': t.surface,
        'lemma': t.lemma,
        'reading': t.reading,
        'pos': t.pos,
        'charStart': t.charStart,
        'charEnd': t.charEnd,
      });
      final senses = pack.dictionary.lookup(t.lemma, '');
      if (senses.isNotEmpty) {
        dictionary.putIfAbsent(
            t.lemma,
            () => senses
                .map((s) => {'pos': s.pos, 'glosses': s.glosses})
                .toList());
        if (isContentToken(t)) {
          lemmaFreq.update(t.lemma, (c) => c + 1, ifAbsent: () => 1);
        }
      }
    }

    passages.add({
      'passageRef': 'Absatz ${i + 1}',
      'content': content,
      'tokens': tokenJson,
      'furigana': furigana,
    });
    stderr.writeln('  Absatz ${i + 1}: ${tokens.length} Tokens, '
        '${furigana.length} Furigana');
  }

  // A small "returning reader already saw these" seed: the most common
  // content lemmas that have a dictionary entry. These become due cards
  // so the inline in-reading review has something real to surface. This
  // is seeded *starting knowledge*, never a fabricated measurement — all
  // snapshots/deltas the app shows come from real reading actions.
  final demoKnown = (lemmaFreq.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
      .take(_demoKnownCount)
      .map((e) => e.key)
      .toList();

  final out = {
    'workTitle': '羅生門 (Auszug)',
    'languageCode': 'ja',
    'passages': passages,
    'dictionary': dictionary,
    'demoKnownLemmas': demoKnown,
  };

  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
  stderr.writeln('Wrote ${outFile.path}: ${passages.length} passages, '
      '${dictionary.length} dictionary lemmas, ${demoKnown.length} demo-known.');

  await jmdictDb.close();
  await miningDb.close();
  tmp.deleteSync(recursive: true);
}
