import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../db/mining_db.dart';
import '../db/mining_tables.dart';
import '../media/ocr_engine.dart';

/// Turns a manga page image into a [Works] row, a [Sources] row, and one
/// [TextSpans] row per OCR'd text region — the third source adapter,
/// alongside SRT (TimeAnchor) and EPUB (FlowAnchor), here producing
/// **SpatialAnchor** spans (§5: manga positions by a bounding box on a
/// page). Same Works/Sources/TextSpans output shape as the others,
/// differing only in the positioning axis (`pageId`/`rectJson`), which
/// is the whole unified-track point extended to a third medium.
class MangaSourceAdapter {
  final MiningDb db;
  final OcrEngine ocr;

  const MangaSourceAdapter(this.db, this.ocr);

  Future<String> importImage({
    required File image,
    required String workTitle,
    required String languageCode,
    required String pageId,
  }) async {
    final boxes = await ocr.recognize(image);
    return _store(
      boxes: boxes,
      sourcePath: image.path,
      workTitle: workTitle,
      languageCode: languageCode,
      pageId: pageId,
    );
  }

  /// Exposed for tests: store already-recognized [boxes] without running
  /// OCR (so adapter behaviour is testable without a real OCR engine).
  Future<String> storeBoxes({
    required List<OcrBox> boxes,
    required String sourcePath,
    required String workTitle,
    required String languageCode,
    required String pageId,
  }) =>
      _store(
        boxes: boxes,
        sourcePath: sourcePath,
        workTitle: workTitle,
        languageCode: languageCode,
        pageId: pageId,
      );

  Future<String> _store({
    required List<OcrBox> boxes,
    required String sourcePath,
    required String workTitle,
    required String languageCode,
    required String pageId,
  }) async {
    final now = DateTime.now();
    final stamp = now.microsecondsSinceEpoch;
    final workId = 'work:$stamp';
    final sourceId = 'source:$stamp';

    await db.into(db.works).insert(WorksCompanion.insert(
          id: workId,
          title: workTitle,
          medium: 'ocr',
          languageCode: languageCode,
          addedAt: now,
        ));
    await db.into(db.sources).insert(SourcesCompanion.insert(
          id: sourceId,
          workId: workId,
          kind: 'ocr',
          path: sourcePath,
          importedAt: now,
        ));

    // Reading order on a page is a hard, open problem (§12); a simple
    // deterministic top-to-bottom, left-to-right order is used here.
    // Real manga right-to-left ordering is a refinement inside this
    // adapter, invisible to the pipeline.
    final ordered = [...boxes]
      ..sort((a, b) => a.top != b.top ? a.top - b.top : a.left - b.left);

    if (ordered.isNotEmpty) {
      await db.batch((b) {
        b.insertAll(
          db.textSpans,
          [
            for (var i = 0; i < ordered.length; i++)
              TextSpansCompanion.insert(
                id: '$sourceId:$i',
                workId: workId,
                sourceId: sourceId,
                ordinal: i,
                content: ordered[i].text,
                anchorType: 'spatial',
                pageId: Value(pageId),
                rectJson: Value(jsonEncode(ordered[i].toRect())),
              ),
          ],
        );
      });
    }

    return workId;
  }
}
