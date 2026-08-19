import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/media/ocr_engine.dart';
import 'package:nihongo_app/core/sources/manga_source_adapter.dart';

class _FakeOcr implements OcrEngine {
  const _FakeOcr();
  @override
  Future<List<OcrBox>> recognize(File image) async =>
      const [OcrBox(text: '猫', left: 10, top: 10, right: 40, bottom: 40)];
}

void main() {
  late MiningDb db;
  setUp(() => db = MiningDb.forTesting());
  tearDown(() => db.close());

  test('storeBoxes records a MediaBlobs image row for the page', () async {
    final adapter = MangaSourceAdapter(db, const _FakeOcr());
    await adapter.storeBoxes(
      boxes: const [OcrBox(text: '猫', left: 10, top: 10, right: 40, bottom: 40)],
      sourcePath: '/tmp/page1.png',
      workTitle: 'Manga',
      languageCode: 'ja',
      pageId: 'page-1',
    );

    final blobs = await db.select(db.mediaBlobs).get();
    expect(blobs, hasLength(1));
    expect(blobs.first.kind, 'image');
    expect(blobs.first.path, '/tmp/page1.png');
    expect(blobs.first.contentHash, isNotEmpty);
  });
}
