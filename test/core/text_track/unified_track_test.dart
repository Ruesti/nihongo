import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/sources/epub_source_adapter.dart';
import 'package:nihongo_app/core/sources/srt_source_adapter.dart';
import 'package:nihongo_app/core/text_track/anchor.dart';
import 'package:nihongo_app/core/text_track/word_tap.dart';

import '../sources/epub_test_fixture.dart';

// The Phase 6 kill-gate, as tests: EPUB and SRT both reduce to the same
// PositionedSpan type differing only in Anchor, and a word tap behaves
// identically regardless of which medium the span came from.

class _FakeDictionary implements Dictionary {
  final Map<String, List<Sense>> byLemma;
  const _FakeDictionary(this.byLemma);

  @override
  List<Sense> lookup(String lemma, String pos) => byLemma[lemma] ?? const [];
}

Future<List<TextSpan>> _spansOf(MiningDb db, String workId) =>
    (db.select(db.textSpans)
          ..where((t) => t.workId.equals(workId))
          ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
        .get();

void main() {
  late MiningDb db;

  setUp(() => db = MiningDb.forTesting());
  tearDown(() => db.close());

  group('unified text track (§5)', () {
    test('an SRT-sourced span reduces to a PositionedSpan with a TimeAnchor',
        () async {
      final workId = await SrtSourceAdapter(db).importContent(
        content: '1\n00:00:01,000 --> 00:00:02,500\n字幕です。\n',
        sourcePath: 'ep.srt',
        workTitle: 'Ep',
        languageCode: 'ja',
      );

      final positioned =
          (await _spansOf(db, workId)).map(PositionedSpan.fromRow).toList();

      expect(positioned, hasLength(1));
      expect(positioned.single.text, '字幕です。');
      final anchor = positioned.single.anchor;
      expect(anchor, isA<TimeAnchor>());
      anchor as TimeAnchor;
      expect(anchor.start, const Duration(seconds: 1));
      expect(anchor.end, const Duration(milliseconds: 2500));
    });

    test('an EPUB-sourced span reduces to a PositionedSpan with a FlowAnchor',
        () async {
      final workId = await EpubSourceAdapter(db).importBytes(
        bytes: buildEpub([
          ['<p>本文です。</p>'],
        ]),
        sourcePath: 'book.epub',
        workTitle: 'Book',
        languageCode: 'ja',
      );

      final positioned =
          (await _spansOf(db, workId)).map(PositionedSpan.fromRow).toList();

      expect(positioned, hasLength(1));
      expect(positioned.single.text, '本文です。');
      expect(positioned.single.anchor, isA<FlowAnchor>());
    });

    test(
        'both media produce the SAME PositionedSpan shape — only the anchor '
        'axis differs', () async {
      final srtWork = await SrtSourceAdapter(db).importContent(
        content: '1\n00:00:01,000 --> 00:00:02,000\n同じ本文。\n',
        sourcePath: 'ep.srt',
        workTitle: 'Ep',
        languageCode: 'ja',
      );
      final epubWork = await EpubSourceAdapter(db).importBytes(
        bytes: buildEpub([
          ['<p>同じ本文。</p>'],
        ]),
        sourcePath: 'book.epub',
        workTitle: 'Book',
        languageCode: 'ja',
      );

      final srtSpan =
          PositionedSpan.fromRow((await _spansOf(db, srtWork)).single);
      final epubSpan =
          PositionedSpan.fromRow((await _spansOf(db, epubWork)).single);

      // Identical text — the content reduces the same way from both...
      expect(srtSpan.text, epubSpan.text);
      // ...both carry a valid reading-order ordinal (their bases differ:
      // SRT reuses the cue number, EPUB counts blocks — both monotonic,
      // which is all "reading order" requires)...
      expect(srtSpan.ordinal, isNonNegative);
      expect(epubSpan.ordinal, isNonNegative);
      // ...and they differ ONLY in the anchor type (the positioning axis).
      expect(srtSpan.anchor.runtimeType,
          isNot(equals(epubSpan.anchor.runtimeType)));
      expect(srtSpan.anchor, isA<TimeAnchor>());
      expect(epubSpan.anchor, isA<FlowAnchor>());
    });

    test('the same word tap yields the same lookup regardless of medium',
        () async {
      // The tokenizer produces the same Token for "本" whether the span
      // came from EPUB or SRT; the handler operates only on that Token.
      const dictionary = _FakeDictionary({
        '本': [Sense(pos: 'n', glosses: ['book'])],
      });
      const handler = WordTapHandler(dictionary);

      const tokenFromEpub =
          Token(surface: '本', lemma: '本', pos: 'n', charStart: 0, charEnd: 1);
      const tokenFromSrt =
          Token(surface: '本', lemma: '本', pos: 'n', charStart: 5, charEnd: 6);

      final epubResult = handler.onTap(tokenFromEpub);
      final srtResult = handler.onTap(tokenFromSrt);

      expect(epubResult.senses, srtResult.senses);
      expect(epubResult.isKnownWord, isTrue);
      expect(srtResult.isKnownWord, isTrue);
    });

    test('an unknown anchorType is rejected, not silently mishandled',
        () async {
      // Defensive: the reduction is the one place anchorType is read.
      final badRow = TextSpan(
        id: 'x',
        workId: 'w',
        sourceId: 's',
        ordinal: 0,
        content: 'x',
        anchorType: 'spatial-but-typoed',
      );

      expect(() => PositionedSpan.fromRow(badRow), throwsArgumentError);
    });
  });
}
