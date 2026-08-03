// Phase 10 gate proof (SPEC_MINING_PIPELINE.md §10):
//   "Opening screen: Then/Now proof renders from real history; graceful
//    empty state verified."
//
// The UI itself (navigation below the fold, no task/due/streak numbers)
// is proven by opening_screen_test.dart. This tool proves the data half
// on real content: the opening state is derived from REAL passage
// history measured from the 羅生門 EPUB, for all three cases — a
// re-presentation delta, the first-reading empty state, and a blank
// slate.
//
// Usage:
//   dart run tool/phase10_opening_screen.dart <epub> <JMdict_e>

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/datum/datum_registry.dart';
import 'package:nihongo_app/core/datum/datum_voice.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/pipeline/passage_snapshot.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart'
    show Knowledge, isContentToken;
import 'package:nihongo_app/core/sources/epub_source_adapter.dart';
import 'package:nihongo_app/features/opening/opening_state.dart';
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

Knowledge Function(String) knownTopN(List<String> byFreq, int n) {
  final known = byFreq.take(n).toSet();
  return (l) => known.contains(l) ? Knowledge.known : Knowledge.unknown;
}

String describe(OpeningState s) => switch (s) {
      RePresentationState(:final delta) =>
        'RePresentation: DAMALS ${(delta.before.unknownRatio * 100).round()}% '
            '→ JETZT ${(delta.after.unknownRatio * 100).round()}%',
      FirstReadingState(:final lastReading) =>
        'FirstReading (empty state): JETZT '
            '${(lastReading.unknownRatio * 100).round()}% unbekannt, kein Vergleich',
      BlankSlateState() => 'BlankSlate: nothing read yet',
    };

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
        'Usage: dart run tool/phase10_opening_screen.dart <epub> <JMdict_e>');
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
  final jmdictDb = JmdictDb.at(File('$tmp/phase10_jmdict.db')..deleteIfExists());

  print('=== Setup ===');
  await importJmdict(jmdictDb, jmdictFile);
  final tokenizer = NativeJaTokenizer();
  final pack = await JaLanguagePack.load(jmdictDb, tokenizerOverride: tokenizer);
  final registry = DatumRegistry.forLocale('de');
  final voice = DatumVoice(registry: registry, enabled: true);

  // Measure a real passage from the EPUB (shared setup for the cases).
  Future<List<Token>> passageTokens() async {
    final scratch = MiningDb.forTesting();
    final workId = await EpubSourceAdapter(scratch).importFile(
        file: epubFile, workTitle: '羅生門', languageCode: 'ja');
    final spans = await (scratch.select(scratch.textSpans)
          ..where((t) => t.workId.equals(workId))
          ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
        .get();
    final body = spans
        .where((s) => pack.tokenizer.tokenize(s.content).any((t) =>
            isContentToken(t) && pack.dictionary.lookup(t.lemma, '').isNotEmpty))
        .toList();
    final toks = body
        .skip(2)
        .take(12)
        .expand((s) => pack.tokenizer.tokenize(s.content))
        .toList();
    await scratch.close();
    return toks;
  }

  final tokens = await passageTokens();
  final freq = <String, int>{};
  for (final t in tokens.where(isContentToken)) {
    if (pack.dictionary.lookup(t.lemma, '').isEmpty) continue;
    freq.update(t.lemma, (c) => c + 1, ifAbsent: () => 1);
  }
  final byFreq = (freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
      .map((e) => e.key)
      .toList();

  // --- Case A: real history → Then/Now ---
  final dbA = MiningDb.forTesting();
  await dbA.into(dbA.works).insert(WorksCompanion.insert(
      id: 'w', title: '羅生門', medium: 'epub', languageCode: 'ja',
      addedAt: DateTime.utc(2026, 1, 1)));
  await recordPassageSnapshot(dbA,
      workId: 'w', passageRef: 'Kapitel 2', tokens: tokens,
      knowledgeOf: knownTopN(byFreq, (byFreq.length * 0.15).round()),
      ts: DateTime.utc(2026, 1, 1));
  await recordPassageSnapshot(dbA,
      workId: 'w', passageRef: 'Kapitel 2', tokens: tokens,
      knowledgeOf: knownTopN(byFreq, (byFreq.length * 0.90).round()),
      ts: DateTime.utc(2026, 2, 12));
  final stateA = await loadOpeningState(dbA);
  final lineA = voice.say(openingDatumObservation(stateA)!);

  // --- Case B: read once → graceful empty state ---
  final dbB = MiningDb.forTesting();
  await dbB.into(dbB.works).insert(WorksCompanion.insert(
      id: 'w', title: '羅生門', medium: 'epub', languageCode: 'ja',
      addedAt: DateTime.utc(2026, 1, 1)));
  await recordPassageSnapshot(dbB,
      workId: 'w', passageRef: 'Kapitel 2', tokens: tokens,
      knowledgeOf: knownTopN(byFreq, (byFreq.length * 0.15).round()),
      ts: DateTime.utc(2026, 1, 1));
  final stateB = await loadOpeningState(dbB);
  final lineB = voice.say(openingDatumObservation(stateB)!);

  // --- Case C: nothing read → blank slate ---
  final dbC = MiningDb.forTesting();
  final stateC = await loadOpeningState(dbC);

  print('\n=== Opening screen from real history ===');
  print('A (read twice):  ${describe(stateA)}');
  print('   Datum: "$lineA"');
  print('B (read once):   ${describe(stateB)}');
  print('   Datum: "$lineB"');
  print('C (never read):  ${describe(stateC)}');
  print('   Datum: ${openingDatumObservation(stateC) == null ? "(none — nothing to prove)" : "?"}');

  final gatePass = stateA is RePresentationState &&
      lineA != null &&
      lineA.contains('Prozent unbekannt') &&
      stateB is FirstReadingState &&
      lineB != null &&
      lineB.contains('kein Vergleich') &&
      stateC is BlankSlateState;

  print('\n=== Phase 10 gate ===');
  print('Then/Now proof from real history:  ${stateA is RePresentationState}');
  print('empty state (read once) graceful:  ${stateB is FirstReadingState}');
  print('blank slate (never read) handled:  ${stateC is BlankSlateState}');
  print(gatePass ? 'GATE: PASS' : 'GATE: FAIL');

  await dbA.close();
  await dbB.close();
  await dbC.close();
  await jmdictDb.close();
  File('$tmp/phase10_jmdict.db').deleteIfExists();
  print('=== ${gatePass ? "PASS" : "FAIL"} ===');
}
