import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lindera_spike/src/rust/api/simple.dart';
import 'package:lindera_spike/src/rust/frb_generated.dart';

double _percentile(List<double> sortedMs, double p) {
  if (sortedMs.isEmpty) return 0;
  final idx = ((sortedMs.length - 1) * p).round();
  return sortedMs[idx];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());

  testWidgets('Phase 1 kill-gate: Lindera JA tokenization benchmark',
      (WidgetTester tester) async {
    final raw = await rootBundle.loadString('assets/jpn_10k.txt');
    final sentences =
        raw.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final coldStartMs = initTokenizer();

    final result = benchmarkBatch(sentences: sentences);

    final sorted = List<double>.from(result.perSentenceMs)..sort();
    final p50 = _percentile(sorted, 0.50);
    final p99 = _percentile(sorted, 0.99);
    final mean = sorted.reduce((a, b) => a + b) / sorted.length;
    final maxMs = sorted.last;

    final report = {
      'coldStartMs': coldStartMs,
      'sentenceCount': result.sentenceCount,
      'totalTokenizeMs': result.totalTokenizeMs,
      'totalTokens': result.totalTokens,
      'perSentenceMeanMs': mean,
      'perSentenceP50Ms': p50,
      'perSentenceP99Ms': p99,
      'perSentenceMaxMs': maxMs,
    };

    // Machine-readable line, greppable from the on-device test log.
    // ignore: avoid_print
    print('PHASE1_BENCHMARK_RESULT ${jsonEncode(report)}');

    expect(result.sentenceCount, sentences.length);
    expect(result.totalTokens, greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
