import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/media/ocr_engine.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';
import 'package:nihongo_app/core/sources/manga_source_adapter.dart';
import 'package:nihongo_app/core/text_track/anchor.dart';

/// A fake OCR engine returning fixed boxes — lets the adapter and the
/// SpatialAnchor pipeline path be tested without a real OCR binary.
class _FakeOcr implements OcrEngine {
  final List<OcrBox> boxes;
  const _FakeOcr(this.boxes);
  @override
  Future<List<OcrBox>> recognize(File image) async => boxes;
}

class _WordTokenizer implements Tokenizer {
  const _WordTokenizer();
  @override
  List<Token> tokenize(String text) => text
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => Token(
          surface: w, lemma: w, pos: 'n', charStart: 0, charEnd: w.length))
      .toList();
}

class _NoFreq implements FrequencyList {
  const _NoFreq();
  @override
  int? rank(String lemma) => null;
  @override
  List<String> topLemmas(int n) => const [];
}

void main() {
  late MiningDb db;
  setUp(() => db = MiningDb.forTesting());
  tearDown(() => db.close());

  Future<List<TextSpan>> spansOf(String workId) => (db.select(db.textSpans)
        ..where((t) => t.workId.equals(workId))
        ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
      .get();

  group('MangaSourceAdapter', () {
    test('creates a Works row with medium "ocr"', () async {
      final adapter = MangaSourceAdapter(db, const _FakeOcr([]));
      final workId = await adapter.importImage(
        image: File('page1.png'),
        workTitle: 'Manga',
        languageCode: 'ja',
        pageId: 'p1',
      );

      final work =
          await (db.select(db.works)..where((t) => t.id.equals(workId))).getSingle();
      expect(work.medium, 'ocr');
    });

    test('creates one TextSpans row per OCR box with a SpatialAnchor',
        () async {
      final adapter = MangaSourceAdapter(
          db,
          const _FakeOcr([
            OcrBox(text: '本', left: 10, top: 10, right: 40, bottom: 60),
            OcrBox(text: '猫', left: 10, top: 100, right: 40, bottom: 150),
          ]));
      final workId = await adapter.importImage(
        image: File('page1.png'),
        workTitle: 'Manga',
        languageCode: 'ja',
        pageId: 'p1',
      );

      final spans = await spansOf(workId);
      expect(spans, hasLength(2));
      expect(spans[0].anchorType, 'spatial');
      expect(spans[0].pageId, 'p1');
      expect(jsonDecode(spans[0].rectJson!),
          {'left': 10, 'top': 10, 'right': 40, 'bottom': 60});
      // No time/flow anchor columns — this is the spatial medium.
      expect(spans[0].tStartMs, isNull);
      expect(spans[0].charStart, isNull);
    });

    test('orders boxes top-to-bottom, then left-to-right', () async {
      final adapter = MangaSourceAdapter(
          db,
          const _FakeOcr([
            OcrBox(text: 'lower', left: 10, top: 200, right: 40, bottom: 250),
            OcrBox(text: 'upper', left: 10, top: 10, right: 40, bottom: 60),
          ]));
      final workId = await adapter.importImage(
        image: File('page1.png'), workTitle: 'M', languageCode: 'ja', pageId: 'p1');

      final spans = await spansOf(workId);
      expect(spans.map((s) => s.content), ['upper', 'lower']);
    });

    test('an image with no text still creates Work/Source rows', () async {
      final adapter = MangaSourceAdapter(db, const _FakeOcr([]));
      final workId = await adapter.importImage(
        image: File('blank.png'), workTitle: 'M', languageCode: 'ja', pageId: 'p1');

      expect((await db.select(db.works).get()), hasLength(1));
      expect((await spansOf(workId)), isEmpty);
    });
  });

  group('SpatialAnchor path end to end', () {
    test('an OCR span reduces to a PositionedSpan with a SpatialAnchor',
        () async {
      final adapter = MangaSourceAdapter(
          db,
          const _FakeOcr([
            OcrBox(text: '本 が すき', left: 5, top: 5, right: 80, bottom: 40),
          ]));
      final workId = await adapter.importImage(
        image: File('p.png'), workTitle: 'M', languageCode: 'ja', pageId: 'page-3');

      final positioned =
          (await spansOf(workId)).map(PositionedSpan.fromRow).toList();

      expect(positioned.single.anchor, isA<SpatialAnchor>());
      final anchor = positioned.single.anchor as SpatialAnchor;
      expect(anchor.pageId, 'page-3');
      expect(jsonDecode(anchor.rectJson)['right'], 80);
    });

    test('OCR spans run through the unchanged scoring pipeline', () async {
      final adapter = MangaSourceAdapter(
          db,
          const _FakeOcr([
            OcrBox(text: 'known unknownword', left: 0, top: 0, right: 50, bottom: 20),
          ]));
      final workId = await adapter.importImage(
        image: File('p.png'), workTitle: 'M', languageCode: 'ja', pageId: 'p1');
      final spans = await spansOf(workId);

      // The exact same core scoring code (no OCR-specific branch).
      final scored = scoreAll(spans, const _WordTokenizer(), const _NoFreq(),
          (lemma) => lemma == 'known' ? Knowledge.known : Knowledge.unknown);

      expect(scored.single.unknownCount, 1);
      expect(scored.single.targetLemma, 'unknownword');
    });
  });
}
