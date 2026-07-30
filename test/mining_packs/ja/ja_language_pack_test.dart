import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/mining_packs/ja/ja_language_pack.dart';
import 'package:nihongo_app/mining_packs/ja/jmdict_db.dart';
import 'package:nihongo_app/mining_packs/ja/jmdict_importer.dart';

const _fixtureXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE JMdict [
<!ENTITY n "noun (common) (futsuumeishi)">
]>
<JMdict>
<entry>
<ent_seq>1000000</ent_seq>
<k_ele><keb>日本語</keb></k_ele>
<r_ele><reb>にほんご</reb></r_ele>
<sense>
<pos>&n;</pos>
<gloss>Japanese (language)</gloss>
</sense>
</entry>
</JMdict>
''';

void main() {
  late JmdictDb db;
  late Directory tempDir;
  late JaLanguagePack pack;

  setUp(() async {
    db = JmdictDb.forTesting();
    tempDir = await Directory.systemTemp.createTemp('ja_pack_test');
    final fixtureFile = File('${tempDir.path}/fixture.xml')
      ..writeAsStringSync(_fixtureXml);
    await importJmdict(db, fixtureFile);
    pack = await JaLanguagePack.load(db);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('code is "ja"', () {
    expect(pack.code, 'ja');
  });

  test('dictionary looks up a kanji form and returns its gloss', () {
    final senses = pack.dictionary.lookup('日本語', '');

    expect(senses, hasLength(1));
    expect(senses.first.glosses, ['Japanese (language)']);
  });

  test('dictionary looks up a reading form too, not just kanji', () {
    final senses = pack.dictionary.lookup('にほんご', '');

    expect(senses, hasLength(1));
  });

  test('dictionary returns empty for an unknown lemma', () {
    expect(pack.dictionary.lookup('未知の単語', ''), isEmpty);
  });

  test('readings resolves the kanji form to its JMdict reading', () {
    final token = Token(
      surface: '日本語',
      lemma: '日本語',
      pos: 'n',
      charStart: 0,
      charEnd: 3,
    );

    expect(pack.readings.reading(token)?.text, 'にほんご');
  });

  test('tokenizer is a documented stub pending Android FFI integration',
      () {
    expect(() => pack.tokenizer.tokenize('日本語'), throwsUnimplementedError);
  });

  test('frequency has no imported corpus yet', () {
    expect(pack.frequency.rank('日本語'), isNull);
  });
}
