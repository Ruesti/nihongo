import 'dart:io';

import 'package:drift/drift.dart';

import '../db/mining_db.dart';
import '../db/mining_tables.dart';
import 'epub_parser.dart';

/// Turns an EPUB into a [Works] row, one [Sources] row, and one
/// [TextSpans] row per block (FlowAnchor — §5's table: EPUB/plain text
/// position by character offset in the work's flow). The exact
/// counterpart of [SrtSourceAdapter]: identical [Works]/[Sources]/
/// [TextSpans] output shape, differing only in the positioning axis
/// (`charStart`/`charEnd` instead of `tStartMs`/`tEndMs`) — which is
/// precisely the unified-text-track claim (§5) made concrete.
class EpubSourceAdapter {
  final MiningDb db;

  const EpubSourceAdapter(this.db);

  Future<String> importFile({
    required File file,
    required String workTitle,
    required String languageCode,
  }) async {
    final bytes = await file.readAsBytes();
    return importBytes(
      bytes: bytes,
      sourcePath: file.path,
      workTitle: workTitle,
      languageCode: languageCode,
    );
  }

  Future<String> importBytes({
    required Uint8List bytes,
    required String sourcePath,
    required String workTitle,
    required String languageCode,
  }) async {
    final blocks = parseEpub(bytes);
    final now = DateTime.now();
    final stamp = now.microsecondsSinceEpoch;
    final workId = 'work:$stamp';
    final sourceId = 'source:$stamp';

    await db.into(db.works).insert(WorksCompanion.insert(
          id: workId,
          title: workTitle,
          medium: 'epub',
          languageCode: languageCode,
          addedAt: now,
        ));

    await db.into(db.sources).insert(SourcesCompanion.insert(
          id: sourceId,
          workId: workId,
          kind: 'epub',
          path: sourcePath,
          importedAt: now,
        ));

    if (blocks.isNotEmpty) {
      // FlowAnchor offsets are into the work's continuous character
      // flow: each block occupies [flowCursor, flowCursor + len), with
      // a single separator char between blocks so offsets never overlap.
      var flowCursor = 0;
      final companions = <TextSpansCompanion>[];
      for (final block in blocks) {
        final start = flowCursor;
        final end = start + block.text.length;
        companions.add(TextSpansCompanion.insert(
          id: '$sourceId:${block.ordinal}',
          workId: workId,
          sourceId: sourceId,
          ordinal: block.ordinal,
          content: block.text,
          anchorType: 'flow',
          charStart: Value(start),
          charEnd: Value(end),
        ));
        flowCursor = end + 1; // +1 separator
      }
      await db.batch((b) => b.insertAll(db.textSpans, companions));
    }

    return workId;
  }
}
