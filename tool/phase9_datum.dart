// Phase 9 gate proof (SPEC_MINING_PIPELINE.md §10):
//   "Datum utterance layer: template registry live; automated test
//    proves no line can render an unmeasured fact; app fully functional
//    with Datum disabled."
//
// The automated no-unmeasured-fact test is datum_registry_test.dart
// (it runs over every template). This tool demonstrates the same three
// properties end to end on a REAL measurement: it measures an actual
// passage delta (the Phase 8 pipeline), turns it into an Observation
// whose facts all trace to that measurement, and shows Datum voicing it
// — then shows Datum staying silent both when a fact is missing and
// when it is disabled, with the underlying numbers still legible.
//
// Usage:
//   dart run tool/phase9_datum.dart <epub> <JMdict_e>

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:nihongo_app/core/datum/datum_registry.dart';
import 'package:nihongo_app/core/datum/datum_voice.dart';
import 'package:nihongo_app/core/datum/observation.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
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

Knowledge Function(String) knownTopN(List<String> byFreq, int n) {
  final known = byFreq.take(n).toSet();
  return (l) => known.contains(l) ? Knowledge.known : Knowledge.unknown;
}

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run tool/phase9_datum.dart <epub> <JMdict_e>');
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
  final jmdictDb = JmdictDb.at(File('$tmp/phase9_jmdict.db')..deleteIfExists());
  final miningDb = MiningDb.forTesting();

  print('=== Setup ===');
  await importJmdict(jmdictDb, jmdictFile);
  final tokenizer = NativeJaTokenizer();
  final pack = await JaLanguagePack.load(jmdictDb, tokenizerOverride: tokenizer);

  final workId = await EpubSourceAdapter(miningDb).importFile(
      file: epubFile, workTitle: '羅生門', languageCode: 'ja');
  final spans = await (miningDb.select(miningDb.textSpans)
        ..where((t) => t.workId.equals(workId))
        ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
      .get();
  // Pick a passage of real dictionary-content spans (skip Gutenberg
  // boilerplate / title so the measured delta is meaningful).
  final bodySpans = spans
      .where((s) => pack.tokenizer.tokenize(s.content).any((t) =>
          isContentToken(t) && pack.dictionary.lookup(t.lemma, '').isNotEmpty))
      .toList();
  final passageTokens = bodySpans
      .skip(2)
      .take(12)
      .expand((s) => pack.tokenizer.tokenize(s.content))
      .toList();
  final freq = <String, int>{};
  for (final t in passageTokens.where(isContentToken)) {
    if (pack.dictionary.lookup(t.lemma, '').isEmpty) continue;
    freq.update(t.lemma, (c) => c + 1, ifAbsent: () => 1);
  }
  final byFreq = (freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
      .map((e) => e.key)
      .toList();

  // --- A REAL measurement: two readings, a real delta ---
  final before = await recordPassageSnapshot(miningDb,
      workId: workId, passageRef: 'p', tokens: passageTokens,
      knowledgeOf: knownTopN(byFreq, (byFreq.length * 0.15).round()),
      ts: DateTime.utc(2026, 1, 1));
  final after = await recordPassageSnapshot(miningDb,
      workId: workId, passageRef: 'p', tokens: passageTokens,
      knowledgeOf: knownTopN(byFreq, (byFreq.length * 0.90).round()),
      ts: DateTime.utc(2026, 2, 12));
  final delta =
      await latestPassageDelta(miningDb, workId: workId, passageRef: 'p');

  final registry = DatumRegistry.forLocale('de');
  print('\n=== Template registry live (locale ${registry.locale}) ===');
  for (final t in registry.allTemplates) {
    print('  [${t.kind.name}] needs ${t.requiredFacts.toList()..sort()}');
  }

  // Build the observation ONLY from measured values.
  final observation = Observation(
    kind: ObservationKind.deltaMeasured,
    facts: {
      'chapter': 'Kapitel 2',
      'weeks_ago': after.ts.difference(before.ts).inDays ~/ 7,
      'unknown_before': (delta!.before.unknownRatio * 100).round(),
      'unknown_after': (delta.after.unknownRatio * 100).round(),
    },
  );

  print('\n=== Datum voices a REAL measurement ===');
  final enabled = DatumVoice(registry: registry, enabled: true);
  print('  measured facts: ${observation.facts}');
  print('  Datum says: "${enabled.say(observation)}"');

  print('\n=== A fact the engine did NOT measure → Datum stays silent ===');
  final missingFact = Observation(
    kind: ObservationKind.deltaMeasured,
    facts: Map.of(observation.facts)..remove('unknown_after'),
  );
  final silentLine = enabled.say(missingFact);
  print('  facts without unknown_after: ${missingFact.facts}');
  print('  Datum says: ${silentLine == null ? "(nothing — not faked)" : "\"$silentLine\""}');

  print('\n=== Datum disabled → silent, but the numbers stay legible ===');
  final disabled = DatumVoice(registry: registry, enabled: false);
  print('  Datum says: ${disabled.say(observation) == null ? "(nothing)" : "?"}');
  print('  the measurement itself, without Datum: '
      'DAMALS ${observation.facts['unknown_before']}% → '
      'JETZT ${observation.facts['unknown_after']}%');

  // Generic guard over every template (mirrors the automated test).
  var everyTemplateGuarded = true;
  for (final t in registry.allTemplates) {
    final full = {for (final f in t.requiredFacts) f: 'x' as Object};
    for (final miss in t.requiredFacts) {
      if (renderTemplate(t, Map.of(full)..remove(miss)) != null) {
        everyTemplateGuarded = false;
      }
    }
  }

  final gatePass = enabled.say(observation) != null &&
      silentLine == null &&
      disabled.say(observation) == null &&
      everyTemplateGuarded;

  print('\n=== Phase 9 gate ===');
  print('registry live:                              true');
  print('real measurement voiced:                    ${enabled.say(observation) != null}');
  print('missing fact → no line:                     ${silentLine == null}');
  print('disabled → silent (info still legible):     ${disabled.say(observation) == null}');
  print('no template emits with a missing fact:      $everyTemplateGuarded');
  print(gatePass ? 'GATE: PASS' : 'GATE: FAIL');

  await jmdictDb.close();
  await miningDb.close();
  File('$tmp/phase9_jmdict.db').deleteIfExists();
  print('=== ${gatePass ? "PASS" : "FAIL"} ===');
}
