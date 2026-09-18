import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/plan/legacy_reconciliation.dart';
import 'package:nihongo_app/features/story/plan/vocab_pool_ja.dart';

void main() {
  test('jedes alte N5-Wort ist im Vorrat oder begründet ausgeschlossen', () {
    final poolKana = vocabPoolJa.map((e) => e.kana).toSet();
    final missing = <String>[];
    for (final old in legacyN5Japanese()) {
      final inPool = poolKana.contains(old.reading);
      final excluded = legacyExclusions.containsKey(old.id);
      if (!inPool && !excluded) {
        missing.add('${old.id} (${old.reading}, ${old.meaningDe})');
      }
    }
    expect(missing, isEmpty, reason: 'Weder im Vorrat noch ausgeschlossen:\n${missing.join('\n')}');
  });

  test('die Ausschlussliste nennt nur existierende alte IDs mit Grund', () {
    final oldIds = legacyN5Japanese().map((e) => e.id).toSet();
    for (final entry in legacyExclusions.entries) {
      expect(oldIds, contains(entry.key), reason: entry.key);
      expect(entry.value.trim(), isNotEmpty, reason: entry.key);
    }
  });
}
