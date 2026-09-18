// Regeln für den Wortvorrat (Spec §2, §9 Punkt 1). Tests und der Bericht
// nutzen dieselbe Funktion, damit „grün" und „Bericht sauber" dasselbe heißt.

import 'pool_entry.dart';

class PoolProblem {
  final String code;
  final String message;
  const PoolProblem(this.code, this.message);

  @override
  String toString() => '$code: $message';
}

final RegExp _idShape = RegExp(r'^lex_ja_[a-z0-9_]+$');

bool _isHiragana(int r) => r >= 0x3041 && r <= 0x3096;
bool _isKatakana(int r) => r >= 0x30A1 && r <= 0x30FA;
bool _isKanaExtra(int r) => r == 0x30FC || r == 0x3005; // ー 々

bool _kanaOnly(String s) => s.runes
    .every((r) => _isHiragana(r) || _isKatakana(r) || _isKanaExtra(r));

bool _japaneseOnly(String s) => s.runes.every((r) =>
    _isHiragana(r) || _isKatakana(r) || _isKanaExtra(r) || isKanjiRune(r));

List<PoolProblem> checkPool(
  List<PoolEntry> entries, {
  int? expectedTotal,
  int maxBank = 40,
}) {
  final problems = <PoolProblem>[];
  final seenIds = <String>{};
  final seenWords = <String>{};

  for (final e in entries) {
    if (!seenIds.add(e.id)) {
      problems.add(PoolProblem('dup_id', e.id));
    }
    final wordKey = '${e.kana}|${e.written}';
    if (!seenWords.add(wordKey)) {
      problems.add(PoolProblem('dup_word', '${e.id}: $wordKey'));
    }
    if (!_idShape.hasMatch(e.id)) {
      problems.add(PoolProblem('bad_id', e.id));
    }
    if (e.kana.isEmpty) {
      problems.add(PoolProblem('empty_kana', e.id));
    } else if (!_kanaOnly(e.kana)) {
      problems.add(PoolProblem('bad_kana', '${e.id}: ${e.kana}'));
    }
    if (e.meaningDe.trim().isEmpty) {
      problems.add(PoolProblem('empty_meaning', e.id));
    }
    if (e.written.isNotEmpty) {
      if (!_japaneseOnly(e.written)) {
        problems.add(PoolProblem('bad_written', '${e.id}: ${e.written}'));
      } else if (kanjiIn(e.written).isEmpty) {
        problems.add(
            PoolProblem('written_without_kanji', '${e.id}: ${e.written}'));
      }
    }
    final ep = e.plannedEpisode;
    if (ep != null && ep < 1) {
      problems.add(PoolProblem('bad_episode', '${e.id}: $ep'));
    }
  }

  final bankCount = entries.where((e) => e.status == PoolStatus.bank).length;
  if (bankCount > maxBank) {
    problems.add(PoolProblem('bank_overflow', '$bankCount > $maxBank'));
  }
  if (expectedTotal != null) {
    final total = entries.length - bankCount;
    if (total != expectedTotal) {
      problems.add(PoolProblem(
          'total_mismatch', 'Nicht-Bank: $total, erwartet $expectedTotal'));
    }
  }
  return problems;
}
