import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/plan/pool_checks.dart';
import 'package:nihongo_app/features/story/plan/pool_entry.dart';
import 'package:nihongo_app/features/story/plan/vocab_pool_ja.dart';

void main() {
  test('der Wortvorrat hat genau 800 Wörter und höchstens 40 in der Bank', () {
    final problems = checkPool(vocabPoolJa,
        expectedTotal: vocabPoolTarget, maxBank: vocabPoolBankMax);
    expect(problems, isEmpty, reason: problems.join('\n'));
    expect(vocabPoolCore.length, 800);
  });

  test('die 18 Wörter aus Folge 01 stehen drin, mit Folge 1 und Status ausgeliefert', () {
    expect(folge01ItemIds.length, 18);
    for (final id in folge01ItemIds) {
      final e = poolEntryById(id);
      expect(e, isNotNull, reason: id);
      expect(e!.plannedEpisode, 1, reason: id);
      expect(e.status, PoolStatus.ausgeliefert, reason: id);
    }
    final withEpisode = vocabPoolJa.where((e) => e.plannedEpisode != null);
    expect(withEpisode.length, 18);
    expect(withEpisode.every((e) => e.plannedEpisode == 1), isTrue);
  });

  test('die fünf Alt-Lexeme des Seeds stehen drin', () {
    for (final id in legacySeedIds) {
      expect(poolEntryById(id), isNotNull, reason: id);
    }
  });

  test('jeder Lebensbereich kommt im Kern vor', () {
    final used = vocabPoolCore.map((e) => e.domain).toSet();
    for (final d in VocabDomain.values) {
      expect(used, contains(d), reason: d.name);
    }
  });

  test('poolEntryById findet Bekanntes und liefert null für Unbekanntes', () {
    expect(poolEntryById('lex_ja_ame')?.written, '雨');
    expect(poolEntryById('lex_ja_gibt_es_nicht'), isNull);
  });
}
