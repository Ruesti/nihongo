import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/mining_packs/ja/jmdict_db.dart';
import 'package:nihongo_app/mining_packs/ja/jmdict_importer.dart';

// A minimal but structurally real JMdict fixture: DOCTYPE with custom
// entities (the thing that breaks naive XML parsers), two entries, one
// with two kanji forms sharing a reading and two senses.
const _fixtureXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE JMdict [
<!ENTITY n "noun (common) (futsuumeishi)">
<!ENTITY vs "noun or participle which takes the aux. verb suru">
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
<entry>
<ent_seq>1000010</ent_seq>
<k_ele><keb>勉強</keb></k_ele>
<k_ele><keb>勉強する</keb></k_ele>
<r_ele><reb>べんきょう</reb></r_ele>
<sense>
<pos>&n;</pos>
<pos>&vs;</pos>
<gloss>study</gloss>
<gloss>diligence</gloss>
</sense>
<sense>
<pos>&n;</pos>
<gloss>discount</gloss>
</sense>
</entry>
</JMdict>
''';

void main() {
  late JmdictDb db;
  late Directory tempDir;
  late File fixtureFile;

  setUp(() async {
    db = JmdictDb.forTesting();
    tempDir = await Directory.systemTemp.createTemp('jmdict_test');
    fixtureFile = File('${tempDir.path}/fixture.xml')
      ..writeAsStringSync(_fixtureXml);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  group('importJmdict', () {
    test('resolves custom DTD entities instead of failing to parse',
        () async {
      // If entity resolution were broken, this would throw during XML
      // parsing before ever reaching the assertions below.
      final result = await importJmdict(db, fixtureFile);

      expect(result.entryCount, 2);
    });

    test('imports every kanji and reading form as a lookup lemma',
        () async {
      await importJmdict(db, fixtureFile);

      final lemmas = await db.select(db.jmdictLemmas).get();
      final forms = lemmas.map((l) => l.form).toSet();

      expect(forms, {'日本語', 'にほんご', '勉強', '勉強する', 'べんきょう'});
    });

    test('imports one sense row per <sense> block with joined POS tags',
        () async {
      await importJmdict(db, fixtureFile);

      final senses = await db.select(db.jmdictSenses).get();
      expect(senses, hasLength(3));

      final studySense =
          senses.firstWhere((s) => s.entryId == 1000010 && s.senseOrder == 1);
      expect(studySense.pos, 'n,vs');
      expect(jsonDecode(studySense.glossesJson), ['study', 'diligence']);

      final discountSense =
          senses.firstWhere((s) => s.entryId == 1000010 && s.senseOrder == 2);
      expect(jsonDecode(discountSense.glossesJson), ['discount']);
    });

    test('reports accurate counts', () async {
      final result = await importJmdict(db, fixtureFile);

      expect(result.entryCount, 2);
      expect(result.lemmaCount, 5); // 日本語, にほんご, 勉強, 勉強する, べんきょう
      expect(result.senseCount, 3);
    });
  });
}
