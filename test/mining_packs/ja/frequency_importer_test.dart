import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/mining_packs/ja/frequency_db.dart';
import 'package:nihongo_app/mining_packs/ja/frequency_importer.dart';

// A fake tokenizer with deterministic, hand-crafted output — keeps
// this file independent of the native library build, unlike the
// end-to-end test in frequency_import_native_test.dart.
class _FakeTokenizer implements Tokenizer {
  final Map<String, List<Token>> _bySentence;

  const _FakeTokenizer(this._bySentence);

  @override
  List<Token> tokenize(String text) => _bySentence[text] ?? const [];
}

Token _tok(String surface, String lemma, {String pos = '名詞'}) => Token(
      surface: surface,
      lemma: lemma,
      pos: pos,
      charStart: 0,
      charEnd: surface.length,
    );

void main() {
  late FrequencyDb db;

  setUp(() => db = FrequencyDb.forTesting());
  tearDown(() => db.close());

  group('importFrequencyFromSentences', () {
    test('ranks the most frequent lemma first', () async {
      final tokenizer = _FakeTokenizer({
        '猫が好き': [_tok('猫', '猫'), _tok('が', 'が', pos: '助詞'), _tok('好き', '好き')],
        '猫が好き2': [_tok('猫', '猫'), _tok('が', 'が', pos: '助詞'), _tok('嫌い', '嫌い')],
        '猫が好き3': [_tok('猫', '猫')],
      });

      final result = await importFrequencyFromSentences(
        db,
        tokenizer,
        ['猫が好き', '猫が好き2', '猫が好き3'],
      );

      expect(result.sentenceCount, 3);
      final top = await (db.select(db.frequencyEntries)
            ..orderBy([(t) => OrderingTerm.asc(t.rank)]))
          .get();
      expect(top.first.lemma, '猫');
      expect(top.first.count, 3);
      expect(top.first.rank, 1);
    });

    test('excludes symbol/punctuation tokens (IPADIC pos 記号)', () async {
      final tokenizer = _FakeTokenizer({
        'テスト。': [_tok('テスト', 'テスト'), _tok('。', '。', pos: '記号,句点')],
      });

      await importFrequencyFromSentences(db, tokenizer, ['テスト。']);

      final entries = await db.select(db.frequencyEntries).get();
      expect(entries.map((e) => e.lemma), isNot(contains('。')));
    });

    test('skips blank lines without counting them as sentences', () async {
      final tokenizer = _FakeTokenizer({'word': [_tok('word', 'word')]});

      final result =
          await importFrequencyFromSentences(db, tokenizer, ['', '  ', 'word']);

      expect(result.sentenceCount, 1);
    });

    test('reports accurate token and unique-lemma counts', () async {
      final tokenizer = _FakeTokenizer({
        'a b a': [_tok('a', 'a'), _tok('b', 'b'), _tok('a', 'a')],
      });

      final result =
          await importFrequencyFromSentences(db, tokenizer, ['a b a']);

      expect(result.tokenCount, 3);
      expect(result.uniqueLemmaCount, 2);
    });
  });
}
