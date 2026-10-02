import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/plan/pool_entry.dart';

void main() {
  test('kanjiIn extracts only CJK ideographs, in order', () {
    expect(kanjiIn('郵便局'), ['郵', '便', '局']);
    expect(kanjiIn('お茶'), ['茶']);
    expect(kanjiIn('コーヒー'), isEmpty);
    expect(kanjiIn(''), isEmpty);
  });

  test('PoolEntry derives kanji and displayForm from written', () {
    const kagi = PoolEntry(
      id: 'lex_ja_kagi',
      kana: 'かぎ',
      written: '鍵',
      meaningDe: 'Schlüssel',
      pos: PartOfSpeech.nomen,
      domain: VocabDomain.werkstatt,
    );
    expect(kagi.kanji, ['鍵']);
    expect(kagi.displayForm, '鍵');
    expect(kagi.status, PoolStatus.geplant);
    expect(kagi.plannedEpisode, isNull);

    const koohii = PoolEntry(
      id: 'lex_ja_koohii',
      kana: 'コーヒー',
      meaningDe: 'Kaffee',
      pos: PartOfSpeech.nomen,
      domain: VocabDomain.cafe,
    );
    expect(koohii.written, '');
    expect(koohii.kanji, isEmpty);
    expect(koohii.displayForm, 'コーヒー');
  });
}
