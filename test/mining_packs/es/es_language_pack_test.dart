import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/mining_packs/es/es_language_pack.dart';
import 'package:nihongo_app/mining_packs/es/es_pack_db.dart';
import 'package:nihongo_app/mining_packs/es/freedict_importer.dart';

const _teiFixture = '''
<?xml version="1.0" encoding="UTF-8"?>
<TEI xmlns="http://www.tei-c.org/ns/1.0">
<text><body>
<entry><form><orth>casa</orth></form>
  <sense><cit type="trans"><quote>house</quote></cit>
         <cit type="trans"><quote>home</quote></cit></sense></entry>
<entry><form><orth>perro</orth></form>
  <sense><cit type="trans"><quote>dog</quote></cit></sense></entry>
</body></text>
</TEI>
''';

void main() {
  late EsPackDb db;

  setUp(() async {
    db = EsPackDb.forTesting();
    await importFreeDict(db, _teiFixture);
  });
  tearDown(() => db.close());

  group('EsLanguagePack', () {
    test('code is "es"', () async {
      final pack = await EsLanguagePack.load(db);
      expect(pack.code, 'es');
    });

    test('has no reading layer (whitespace language, §2.2)', () async {
      final pack = await EsLanguagePack.load(db);
      expect(pack.readings, isNull);
    });

    test('tokenizer splits on whitespace and lowercases the lemma', () async {
      final pack = await EsLanguagePack.load(db);
      final tokens = pack.tokenizer.tokenize('La CASA es grande.');

      expect(tokens.map((t) => t.surface), ['La', 'CASA', 'es', 'grande']);
      expect(tokens.map((t) => t.lemma), ['la', 'casa', 'es', 'grande']);
    });

    test('dictionary looks up a headword and returns its glosses', () async {
      final pack = await EsLanguagePack.load(db);
      final senses = pack.dictionary.lookup('casa', '');

      expect(senses, hasLength(1));
      expect(senses.single.glosses, ['house', 'home']);
    });

    test('dictionary returns empty for an unknown word', () async {
      final pack = await EsLanguagePack.load(db);
      expect(pack.dictionary.lookup('inexistente', ''), isEmpty);
    });

    test('frequency resolves rank once frequency data is present', () async {
      await db.into(db.esFrequencyEntries).insert(
            EsFrequencyEntriesCompanion.insert(lemma: 'la', count: 999, rank: 1),
          );
      final pack = await EsLanguagePack.load(db);

      expect(pack.frequency.rank('la'), 1);
      expect(pack.frequency.rank('inexistente'), isNull);
    });

    test('topLemmas returns the most frequent lemmas in order', () async {
      await db.batch((b) => b.insertAll(db.esFrequencyEntries, [
            EsFrequencyEntriesCompanion.insert(lemma: 'la', count: 999, rank: 1),
            EsFrequencyEntriesCompanion.insert(lemma: 'de', count: 800, rank: 2),
            EsFrequencyEntriesCompanion.insert(lemma: 'que', count: 700, rank: 3),
          ]));
      final pack = await EsLanguagePack.load(db);

      expect(pack.frequency.topLemmas(2), ['la', 'de']);
    });
  });

  group('importFreeDict', () {
    test('imports each headword lowercased with its glosses', () async {
      final lexemes = await db.select(db.esLexemes).get();
      expect(lexemes.map((l) => l.form), containsAll(['casa', 'perro']));
    });
  });
}
