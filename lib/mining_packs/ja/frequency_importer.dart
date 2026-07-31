import 'package:drift/drift.dart';

import '../../core/language_pack/language_pack.dart';
import 'frequency_db.dart';

class FrequencyImportResult {
  final int sentenceCount;
  final int tokenCount;
  final int uniqueLemmaCount;
  final Duration elapsed;

  const FrequencyImportResult({
    required this.sentenceCount,
    required this.tokenCount,
    required this.uniqueLemmaCount,
    required this.elapsed,
  });
}

/// Tokenizes every sentence in [sentences] with [tokenizer], counts
/// lemma occurrences, and stores the resulting rank into [db]. Skips
/// punctuation/symbol tokens (IPADIC POS `記号`) — they'd otherwise
/// dominate the top of the ranking without being a word anyone looks
/// up or mines a card for.
Future<FrequencyImportResult> importFrequencyFromSentences(
  FrequencyDb db,
  Tokenizer tokenizer,
  Iterable<String> sentences,
) async {
  final stopwatch = Stopwatch()..start();
  final counts = <String, int>{};
  var sentenceCount = 0;
  var tokenCount = 0;

  for (final sentence in sentences) {
    final trimmed = sentence.trim();
    if (trimmed.isEmpty) continue;
    sentenceCount++;

    for (final token in tokenizer.tokenize(trimmed)) {
      if (token.pos.startsWith('記号')) continue;
      tokenCount++;
      counts.update(token.lemma, (c) => c + 1, ifAbsent: () => 1);
    }
  }

  final ranked = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  const chunkSize = 5000;
  for (var i = 0; i < ranked.length; i += chunkSize) {
    final end =
        (i + chunkSize) < ranked.length ? i + chunkSize : ranked.length;
    final chunk = ranked.sublist(i, end);
    await db.batch((b) {
      b.insertAll(
        db.frequencyEntries,
        List.generate(
          chunk.length,
          (j) => FrequencyEntriesCompanion.insert(
            lemma: chunk[j].key,
            count: chunk[j].value,
            rank: i + j + 1,
          ),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  stopwatch.stop();
  return FrequencyImportResult(
    sentenceCount: sentenceCount,
    tokenCount: tokenCount,
    uniqueLemmaCount: ranked.length,
    elapsed: stopwatch.elapsed,
  );
}
