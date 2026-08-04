import 'package:drift/drift.dart';

import '../../core/language_pack/language_pack.dart';
import 'es_pack_db.dart';

class EsFrequencyImportResult {
  final int sentenceCount;
  final int uniqueLemmaCount;
  final Duration elapsed;
  const EsFrequencyImportResult({
    required this.sentenceCount,
    required this.uniqueLemmaCount,
    required this.elapsed,
  });
}

/// Counts lemma frequency across [sentences] using the ES [tokenizer]
/// and stores ranks into [EsPackDb]. Same shape as JA's frequency
/// import — deliberately self-contained in the ES pack rather than
/// reaching into the JA pack, so this proves a new pack needs no
/// changes anywhere else (not even to sibling packs).
Future<EsFrequencyImportResult> importEsFrequency(
  EsPackDb db,
  Tokenizer tokenizer,
  Iterable<String> sentences,
) async {
  final stopwatch = Stopwatch()..start();
  final counts = <String, int>{};
  var sentenceCount = 0;

  for (final sentence in sentences) {
    final trimmed = sentence.trim();
    if (trimmed.isEmpty) continue;
    sentenceCount++;
    for (final token in tokenizer.tokenize(trimmed)) {
      counts.update(token.lemma, (c) => c + 1, ifAbsent: () => 1);
    }
  }

  final ranked = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  const chunk = 5000;
  for (var i = 0; i < ranked.length; i += chunk) {
    final end = (i + chunk) < ranked.length ? i + chunk : ranked.length;
    await db.batch((b) {
      b.insertAll(
        db.esFrequencyEntries,
        List.generate(
          end - i,
          (j) => EsFrequencyEntriesCompanion.insert(
            lemma: ranked[i + j].key,
            count: ranked[i + j].value,
            rank: i + j + 1,
          ),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  stopwatch.stop();
  return EsFrequencyImportResult(
    sentenceCount: sentenceCount,
    uniqueLemmaCount: ranked.length,
    elapsed: stopwatch.elapsed,
  );
}
