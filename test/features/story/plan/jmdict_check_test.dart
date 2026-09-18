// test/features/story/plan/jmdict_check_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/plan/jmdict_check.dart';
import 'package:nihongo_app/features/story/plan/pool_entry.dart';

const _xml = '''
<JMdict>
<entry>
<ent_seq>1</ent_seq>
<k_ele><keb>雨</keb></k_ele>
<r_ele><reb>あめ</reb></r_ele>
</entry>
<entry>
<ent_seq>2</ent_seq>
<k_ele><keb>珈琲</keb></k_ele>
<r_ele><reb>コーヒー</reb></r_ele>
</entry>
<entry>
<ent_seq>3</ent_seq>
<k_ele><keb>早い</keb></k_ele>
<k_ele><keb>速い</keb></k_ele>
<r_ele><reb>はやい</reb></r_ele>
</entry>
</JMdict>
''';

PoolEntry _e(String id, String kana, String written) => PoolEntry(
      id: id, kana: kana, written: written, meaningDe: 'x',
      pos: PartOfSpeech.nomen, domain: VocabDomain.dinge);

void main() {
  test('loadJmdictForms collects keb|reb pairs and readings per entry', () async {
    final forms = await loadJmdictForms(Stream.fromIterable(_xml.split('\n')));
    expect(forms.pairs, containsAll(['雨|あめ', '珈琲|コーヒー', '早い|はやい', '速い|はやい']));
    expect(forms.readings, containsAll(['あめ', 'コーヒー', 'はやい']));
    expect(forms.pairs, isNot(contains('雨|コーヒー')));
  });

  test('unmatchedInJmdict reports only what JMdict does not know', () async {
    final forms = await loadJmdictForms(Stream.fromIterable(_xml.split('\n')));
    final pool = [
      _e('lex_ja_ame', 'あめ', '雨'),
      _e('lex_ja_koohii', 'コーヒー', ''),
      _e('lex_ja_hayai_fast', 'はやい', '速い'),
      _e('lex_ja_kasa', 'かさ', '傘'),
      _e('lex_ja_yukkuri', 'ゆっくり', ''),
    ];
    final missing = unmatchedInJmdict(pool, forms).map((e) => e.id).toList();
    expect(missing, ['lex_ja_kasa', 'lex_ja_yukkuri']);
  });
}
