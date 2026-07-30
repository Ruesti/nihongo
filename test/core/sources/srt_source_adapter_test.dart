import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/sources/srt_source_adapter.dart';

const _srt = '''
1
00:00:01,000 --> 00:00:02,000
最初の字幕

2
00:00:03,500 --> 00:00:05,200
二番目の字幕
''';

void main() {
  late MiningDb db;
  late SrtSourceAdapter adapter;

  setUp(() {
    db = MiningDb.forTesting();
    adapter = SrtSourceAdapter(db);
  });

  tearDown(() => db.close());

  group('SrtSourceAdapter', () {
    test('creates a Works row for the imported file', () async {
      final workId = await adapter.importContent(
        content: _srt,
        sourcePath: 'episode1.srt',
        workTitle: 'Episode 1',
        languageCode: 'ja',
      );

      final works = await db.select(db.works).get();
      expect(works, hasLength(1));
      expect(works.single.id, workId);
      expect(works.single.title, 'Episode 1');
      expect(works.single.medium, 'srt');
      expect(works.single.languageCode, 'ja');
    });

    test('creates a Sources row pointing at the original path', () async {
      await adapter.importContent(
        content: _srt,
        sourcePath: 'episode1.srt',
        workTitle: 'Episode 1',
        languageCode: 'ja',
      );

      final sources = await db.select(db.sources).get();
      expect(sources, hasLength(1));
      expect(sources.single.kind, 'srt');
      expect(sources.single.path, 'episode1.srt');
    });

    test('creates one TextSpans row per cue with a TimeAnchor', () async {
      await adapter.importContent(
        content: _srt,
        sourcePath: 'episode1.srt',
        workTitle: 'Episode 1',
        languageCode: 'ja',
      );

      final spans = await (db.select(db.textSpans)
            ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
          .get();

      expect(spans, hasLength(2));
      expect(spans[0].content, '最初の字幕');
      expect(spans[0].anchorType, 'time');
      expect(spans[0].tStartMs, 1000);
      expect(spans[0].tEndMs, 2000);
      expect(spans[0].ordinal, 1);
      expect(spans[1].content, '二番目の字幕');
      expect(spans[1].tStartMs, 3500);
      expect(spans[1].tEndMs, 5200);
    });

    test('text spans reference both the work and the source', () async {
      final workId = await adapter.importContent(
        content: _srt,
        sourcePath: 'episode1.srt',
        workTitle: 'Episode 1',
        languageCode: 'ja',
      );
      final sourceId = (await db.select(db.sources).getSingle()).id;

      final spans = await db.select(db.textSpans).get();

      expect(spans.every((s) => s.workId == workId), isTrue);
      expect(spans.every((s) => s.sourceId == sourceId), isTrue);
    });

    test('an SRT with zero parseable cues still creates Work/Source rows',
        () async {
      final workId = await adapter.importContent(
        content: 'not a valid srt file at all',
        sourcePath: 'broken.srt',
        workTitle: 'Broken',
        languageCode: 'ja',
      );

      expect((await db.select(db.works).get()), hasLength(1));
      expect((await db.select(db.textSpans).get()), isEmpty);
      expect(workId, isNotEmpty);
    });
  });
}
