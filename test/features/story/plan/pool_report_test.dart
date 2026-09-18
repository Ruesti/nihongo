// test/features/story/plan/pool_report_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/plan/pool_entry.dart';
import 'package:nihongo_app/features/story/plan/pool_report.dart';

const _fixture = [
  PoolEntry(id: 'lex_ja_ame', kana: 'あめ', written: '雨', meaningDe: 'Regen', pos: PartOfSpeech.nomen, domain: VocabDomain.wetter, plannedEpisode: 1, status: PoolStatus.ausgeliefert),
  PoolEntry(id: 'lex_ja_kasa', kana: 'かさ', written: '傘', meaningDe: 'Schirm', pos: PartOfSpeech.nomen, domain: VocabDomain.kleidung),
  PoolEntry(id: 'lex_ja_amagasa', kana: 'あまがさ', written: '雨傘', meaningDe: 'Regenschirm', pos: PartOfSpeech.nomen, domain: VocabDomain.kleidung),
  PoolEntry(id: 'lex_ja_iku', kana: 'いく', written: '行く', meaningDe: 'gehen', pos: PartOfSpeech.verb, domain: VocabDomain.verbenAlltag),
  PoolEntry(id: 'lex_ja_sakura', kana: 'さくら', written: '桜', meaningDe: 'Kirschblüte', pos: PartOfSpeech.nomen, domain: VocabDomain.natur, status: PoolStatus.bank),
];

void main() {
  test('countByDomain and countByPos count what is there', () {
    final byDomain = countByDomain(_fixture);
    expect(byDomain[VocabDomain.kleidung], 2);
    expect(byDomain[VocabDomain.wetter], 1);
    expect(countByPos(_fixture)[PartOfSpeech.verb], 1);
  });

  test('kanjiFrequency counts words per kanji, most frequent first', () {
    final freq = kanjiFrequency(_fixture);
    expect(freq.first.key, anyOf('雨', '傘'));
    expect(freq.first.value, 2);
    expect(freq.map((e) => e.key), contains('行'));
  });

  test('samplePool is deterministic for a seed and never larger than the pool', () {
    final a = samplePool(_fixture, count: 3, seed: 7);
    final b = samplePool(_fixture, count: 3, seed: 7);
    expect(a.map((e) => e.id), b.map((e) => e.id));
    expect(a.length, 3);
    expect(samplePool(_fixture, count: 50, seed: 1).length, _fixture.length);
  });

  test('markdown renderers produce one table row per entry', () {
    final full = renderFullMarkdown(_fixture);
    expect(full, contains('| あめ | 雨 | Regen |'));
    expect(full, contains('## Wetter'));
    final sample = renderSampleMarkdown(_fixture.take(2).toList());
    expect('|'.allMatches(sample).length, greaterThan(6));
    expect(sample, contains('[ ]'));
  });

  test('terminal report names the totals', () {
    final text = renderTerminalReport(_fixture);
    expect(text, contains('Kern: 4'));
    expect(text, contains('Bank: 1'));
    expect(text, contains('Folge 01: 1'));
  });
}
