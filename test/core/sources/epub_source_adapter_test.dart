import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/sources/epub_source_adapter.dart';

import 'epub_test_fixture.dart';

void main() {
  late MiningDb db;
  late EpubSourceAdapter adapter;

  setUp(() {
    db = MiningDb.forTesting();
    adapter = EpubSourceAdapter(db);
  });

  tearDown(() => db.close());

  group('EpubSourceAdapter', () {
    test('creates a Works row with medium "epub"', () async {
      final bytes = buildEpub([
        ['<p>本文です。</p>'],
      ]);

      final workId = await adapter.importBytes(
        bytes: bytes,
        sourcePath: 'book.epub',
        workTitle: 'Book',
        languageCode: 'ja',
      );

      final work = await (db.select(db.works)
            ..where((t) => t.id.equals(workId)))
          .getSingle();
      expect(work.medium, 'epub');
      expect(work.title, 'Book');
    });

    test('creates one TextSpans row per sentence with a FlowAnchor', () async {
      final bytes = buildEpub([
        ['<p>一文目。二文目。</p>'],
      ]);

      await adapter.importBytes(
        bytes: bytes,
        sourcePath: 'book.epub',
        workTitle: 'Book',
        languageCode: 'ja',
      );

      final spans = await (db.select(db.textSpans)
            ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
          .get();

      expect(spans, hasLength(2));
      expect(spans[0].content, '一文目。');
      expect(spans[0].anchorType, 'flow');
      expect(spans[0].charStart, isNotNull);
      expect(spans[0].charEnd, isNotNull);
      // No time anchor — this is the flow medium.
      expect(spans[0].tStartMs, isNull);
      expect(spans[0].tEndMs, isNull);
    });

    test('flow offsets are monotonically increasing and non-overlapping',
        () async {
      final bytes = buildEpub([
        ['<p>あ。いい。ううう。</p>'],
      ]);

      await adapter.importBytes(
        bytes: bytes,
        sourcePath: 'book.epub',
        workTitle: 'Book',
        languageCode: 'ja',
      );

      final spans = await (db.select(db.textSpans)
            ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
          .get();

      for (var i = 0; i < spans.length; i++) {
        // Each span's charEnd - charStart matches its own text length.
        expect(spans[i].charEnd! - spans[i].charStart!, spans[i].content.length);
        if (i > 0) {
          // No overlap: this span starts after the previous one ends.
          expect(spans[i].charStart!, greaterThan(spans[i - 1].charEnd!));
        }
      }
    });

    test('an empty EPUB still creates Work/Source rows, no spans', () async {
      final bytes = buildEpub([
        ['<p>   </p>'], // whitespace-only, yields no blocks
      ]);

      final workId = await adapter.importBytes(
        bytes: bytes,
        sourcePath: 'empty.epub',
        workTitle: 'Empty',
        languageCode: 'ja',
      );

      expect((await db.select(db.works).get()), hasLength(1));
      expect((await db.select(db.sources).get()), hasLength(1));
      expect((await db.select(db.textSpans).get()), isEmpty);
      expect(workId, isNotEmpty);
    });
  });
}
