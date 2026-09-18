import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/plan/pool_checks.dart';
import 'package:nihongo_app/features/story/plan/pool_entry.dart';

PoolEntry _e(String id, String kana,
        {String written = '',
        String meaning = 'x',
        PoolStatus status = PoolStatus.geplant,
        int? episode}) =>
    PoolEntry(
      id: id,
      kana: kana,
      written: written,
      meaningDe: meaning,
      pos: PartOfSpeech.nomen,
      domain: VocabDomain.dinge,
      status: status,
      plannedEpisode: episode,
    );

List<String> _codes(List<PoolProblem> p) => p.map((x) => x.code).toList();

void main() {
  test('a clean list has no problems', () {
    final entries = [
      _e('lex_ja_kagi', 'かぎ', written: '鍵', meaning: 'Schlüssel'),
      _e('lex_ja_koohii', 'コーヒー', meaning: 'Kaffee'),
    ];
    expect(checkPool(entries, expectedTotal: 2), isEmpty);
  });

  test('duplicate ids and duplicate words are reported', () {
    final entries = [
      _e('lex_ja_a', 'あ'),
      _e('lex_ja_a', 'い'),
      _e('lex_ja_b', 'あ'),
    ];
    final codes = _codes(checkPool(entries));
    expect(codes, contains('dup_id'));
    expect(codes, contains('dup_word'));
  });

  test('homophones with different written forms are not duplicates', () {
    final entries = [
      _e('lex_ja_kami_paper', 'かみ', written: '紙'),
      _e('lex_ja_kami_hair', 'かみ', written: '髪'),
    ];
    expect(checkPool(entries), isEmpty);
  });

  test('field rules: id shape, empty fields, script of kana and written', () {
    expect(_codes(checkPool([_e('kagi', 'かぎ')])), contains('bad_id'));
    expect(_codes(checkPool([_e('lex_ja_x', '')])), contains('empty_kana'));
    expect(_codes(checkPool([_e('lex_ja_x', 'か', meaning: '')])),
        contains('empty_meaning'));
    expect(_codes(checkPool([_e('lex_ja_x', 'ka')])), contains('bad_kana'));
    expect(_codes(checkPool([_e('lex_ja_x', 'か', written: 'abc')])),
        contains('bad_written'));
    expect(_codes(checkPool([_e('lex_ja_x', 'か', written: 'かな')])),
        contains('written_without_kanji'));
    expect(_codes(checkPool([_e('lex_ja_x', 'か', episode: 0)])),
        contains('bad_episode'));
  });

  test('bank limit and expected total', () {
    final bank = List.generate(
        3, (i) => _e('lex_ja_b$i', 'か$i', status: PoolStatus.bank));
    expect(_codes(checkPool(bank, maxBank: 2)), contains('bank_overflow'));
    final two = [_e('lex_ja_a', 'あ'), _e('lex_ja_i', 'い')];
    expect(_codes(checkPool(two, expectedTotal: 3)), contains('total_mismatch'));
    expect(checkPool(two, expectedTotal: 2), isEmpty);
  });
}
