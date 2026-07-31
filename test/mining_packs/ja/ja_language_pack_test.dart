import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/mining_packs/ja/frequency_db.dart';
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

// This file covers Dictionary/ReadingProvider/FrequencyList only — the
// real tokenizer (native/ja_tokenizer) has its own dedicated test file
// (native_tokenizer_test.dart) since it needs the compiled native
// library. Overriding it here with a trivial fake keeps these tests
// independent of that build step.
class _UnusedTokenizer implements Tokenizer {
  const _UnusedTokenizer();

  @override
  List<Token> tokenize(String text) => const [];
}

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
    pack = await JaLanguagePack.load(
      db,
      tokenizerOverride: const _UnusedTokenizer(),
    );
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

  test('frequency has no imported corpus yet (no frequencyDb passed)', () {
    expect(pack.frequency.rank('日本語'), isNull);
  });

  test('frequency resolves rank once a frequencyDb is passed', () async {
    final frequencyDb = FrequencyDb.forTesting();
    await frequencyDb.into(frequencyDb.frequencyEntries).insert(
          FrequencyEntriesCompanion.insert(lemma: '日本語', count: 42, rank: 1),
        );

    final packWithFrequency = await JaLanguagePack.load(
      db,
      frequencyDb: frequencyDb,
      tokenizerOverride: const _UnusedTokenizer(),
    );

    expect(packWithFrequency.frequency.rank('日本語'), 1);
    expect(packWithFrequency.frequency.rank('未知の単語'), isNull);

    await frequencyDb.close();
  });

  test('load() without an override wires up the real native tokenizer',
      () async {
    final realPack = await JaLanguagePack.load(db);

    final tokens = realPack.tokenizer.tokenize('日本語');

    expect(tokens.single.surface, '日本語');
  });
}
