// Phase 7 gate proof (SPEC_MINING_PIPELINE.md §10):
//   "Scheduling woven into reading (no review screen): a due item is
//    surfaced in reading flow and graded without leaving the reader."
//
// The UI half of the gate — that grading happens inline with no route
// change — is proven by reading_view_test.dart (a NavigatorObserver
// asserts zero pushes). This tool proves the data half end to end on
// real content: reading a real EPUB span by span, due items are
// surfaced FROM the text in view, graded, and their FSRS state
// actually advances so they leave the due set.
//
// Usage:
//   dart run tool/phase7_review_in_reading.dart <epub> <JMdict_e>

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/due_in_reading.dart';
import 'package:nihongo_app/core/pipeline/review_scheduler.dart';
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

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
        'Usage: dart run tool/phase7_review_in_reading.dart <epub> <JMdict_e>');
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
  final jmdictDb = JmdictDb.at(File('$tmp/phase7_jmdict.db')..deleteIfExists());
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
  print('EPUB spans (reading order): ${spans.length}');

  // Give the "reader" a plausible existing knowledge base: create a due
  // card for each of the 30 most common lemmas across the first chunk
  // of the book, all due yesterday (as a real returning reader would
  // have). No separate deck — these are just words this reader has seen.
  final freq = <String, int>{};
  for (final span in spans.take(60)) {
    for (final t in pack.tokenizer.tokenize(span.content)) {
      if (pack.dictionary.lookup(t.lemma, '').isEmpty) continue; // real words only
      freq.update(t.lemma, (c) => c + 1, ifAbsent: () => 1);
    }
  }
  final dueLemmas = (freq.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
      .take(30)
      .map((e) => e.key)
      .toList();

  final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));
  for (final lemma in dueLemmas) {
    final vocabId = 'vocab:ja:$lemma';
    await miningDb.into(miningDb.vocabItems).insertOnConflictUpdate(
          VocabItemsCompanion.insert(
            id: vocabId,
            languageCode: 'ja',
            lemma: lemma,
            pos: '',
            createdAt: yesterday,
          ),
        );
    await miningDb.into(miningDb.cards).insertOnConflictUpdate(
          CardsCompanion.insert(
            id: 'card:$vocabId',
            vocabItemId: vocabId,
            state: const Value('review'),
            stability: const Value(2.0),
            due: yesterday, // due now
            lastReview: yesterday.subtract(const Duration(days: 2)),
          ),
        );
  }
  print('due cards this reader has: ${dueLemmas.length}');

  // --- Read span by span; surface + grade due items in the flow ---
  final dueInReading = DueInReading(miningDb);
  final scheduler = ReviewScheduler(miningDb);
  final now = DateTime.now().toUtc();

  var spansWithReview = 0;
  var itemsGraded = 0;
  final advanced = <String>[];

  print('\n=== Reading — reviews surface from the text, graded in flow ===');
  for (final span in spans) {
    final tokens = pack.tokenizer.tokenize(span.content);
    final due = await dueInReading.dueInView(
        languageCode: 'ja', tokens: tokens, now: now);
    if (due.isEmpty) continue;

    spansWithReview++;
    final item = due.first; // grade the most-overdue item present
    final outcome = await scheduler.grade(item.cardId, fsrs.Rating.good, now: now);
    itemsGraded++;
    advanced.add(item.lemma);

    if (spansWithReview <= 5) {
      print('  reading 「${span.content.length > 24 ? "${span.content.substring(0, 24)}…" : span.content}」');
      print('    due word in view: 「${item.lemma}」 → graded good → '
          'due ${outcome.newDue.toIso8601String().substring(0, 10)}, '
          'stability ${outcome.stabilityBefore.toStringAsFixed(1)}→${outcome.stabilityAfter.toStringAsFixed(1)}');
    }
  }

  // --- Verify the graded items genuinely left the due set ---
  final stillDue = await (miningDb.select(miningDb.cards)
        ..where((c) => c.due.isSmallerOrEqualValue(now)))
      .get();
  final gradedStillDue = stillDue
      .where((c) => advanced.contains(c.vocabItemId.replaceFirst('vocab:ja:', '')))
      .length;

  final reviewLogCount = (await miningDb.select(miningDb.reviewLogs).get()).length;

  print('\n=== Phase 7 gate ===');
  print('spans where a review surfaced from the text: $spansWithReview');
  print('items graded in the reading flow:            $itemsGraded');
  print('review-log rows appended:                    $reviewLogCount');
  print('graded items still due (should be 0):        $gradedStillDue');

  final gatePass = itemsGraded > 0 &&
      reviewLogCount == itemsGraded &&
      gradedStillDue == 0;
  print(gatePass ? 'GATE: PASS' : 'GATE: FAIL');

  await jmdictDb.close();
  await miningDb.close();
  File('$tmp/phase7_jmdict.db').deleteIfExists();

  print('=== ${gatePass ? "PASS" : "FAIL"} ===');
}
