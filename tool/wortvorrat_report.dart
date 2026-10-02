// tool/wortvorrat_report.dart
//
// Usage: dart run tool/wortvorrat_report.dart
// Druckt den Bericht und schreibt docs/story/WORTVORRAT_800.md sowie
// docs/story/WORTVORRAT_STICHPROBE.md (50 Wörter, Seed 20260918).

import 'dart:io';

import 'package:nihongo_app/features/story/plan/pool_entry.dart';
import 'package:nihongo_app/features/story/plan/pool_report.dart';
import 'package:nihongo_app/features/story/plan/vocab_pool_ja.dart';

void main() {
  if (!Directory('docs/story').existsSync()) {
    stderr.writeln('docs/story nicht gefunden — bitte aus dem Repo-Wurzelverzeichnis starten.');
    exitCode = 2;
    return;
  }

  stdout.write(renderTerminalReport(vocabPoolJa,
      expectedTotal: vocabPoolTarget, maxBank: vocabPoolBankMax));

  final core = vocabPoolJa.where((e) => e.status != PoolStatus.bank);
  File('docs/story/WORTVORRAT_800.md').writeAsStringSync(renderFullMarkdown(vocabPoolJa));
  final sample = samplePool(core, count: 50, seed: 20260918);
  File('docs/story/WORTVORRAT_STICHPROBE.md').writeAsStringSync(renderSampleMarkdown(sample));
  stdout.writeln('Geschrieben: docs/story/WORTVORRAT_800.md, docs/story/WORTVORRAT_STICHPROBE.md');
}
