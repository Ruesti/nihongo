import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/sources/epub_parser.dart';

import 'epub_test_fixture.dart';

void main() {
  group('parseEpub', () {
    test('extracts block-level text from a single chapter', () {
      final bytes = buildEpub([
        ['<p>最初の段落。</p>', '<p>二番目の段落。</p>'],
      ]);

      final blocks = parseEpub(bytes);

      expect(blocks.map((b) => b.text), ['最初の段落。', '二番目の段落。']);
    });

    test('preserves spine order across chapters', () {
      final bytes = buildEpub([
        ['<p>第一章。</p>'],
        ['<p>第二章。</p>'],
      ]);

      final blocks = parseEpub(bytes);

      expect(blocks.map((b) => b.text), ['第一章。', '第二章。']);
      expect(blocks[0].ordinal, lessThan(blocks[1].ordinal));
    });

    test('splits a multi-sentence block at Unicode sentence terminators', () {
      final bytes = buildEpub([
        ['<p>一文目です。二文目です。三文目ですか？</p>'],
      ]);

      final blocks = parseEpub(bytes);

      expect(blocks.map((b) => b.text),
          ['一文目です。', '二文目です。', '三文目ですか？']);
    });

    test('a heading with no terminator stays one segment', () {
      final bytes = buildEpub([
        ['<h1>羅生門</h1>', '<p>本文です。</p>'],
      ]);

      final blocks = parseEpub(bytes);

      expect(blocks.map((b) => b.text), ['羅生門', '本文です。']);
    });

    test('normalizes internal whitespace (source line wrapping)', () {
      final bytes = buildEpub([
        ['<p>これは\n  改行を含む\n文です。</p>'],
      ]);

      final blocks = parseEpub(bytes);

      expect(blocks.single.text, 'これは 改行を含む 文です。');
    });

    test('skips empty blocks', () {
      final bytes = buildEpub([
        ['<p>本文。</p>', '<p></p>', '<p>   </p>'],
      ]);

      final blocks = parseEpub(bytes);

      expect(blocks, hasLength(1));
    });

    test('does not double-count a div wrapping block children', () {
      final bytes = buildEpub([
        ['<div><p>内側の段落。</p></div>'],
      ]);

      final blocks = parseEpub(bytes);

      // The <p> is counted, the wrapping <div> is not (no duplicate).
      expect(blocks.map((b) => b.text), ['内側の段落。']);
    });

    test('handles English sentence terminators too (language-blind)', () {
      final bytes = buildEpub([
        ['<p>First sentence. Second one! A third?</p>'],
      ]);

      final blocks = parseEpub(bytes);

      expect(blocks.map((b) => b.text),
          ['First sentence.', 'Second one!', 'A third?']);
    });

    test('throws for bytes that are not a valid EPUB', () {
      expect(
        () => parseEpub(buildBrokenEpub()),
        throwsA(isA<EpubParseException>()),
      );
    });
  });
}
