import 'dart:io';

import 'package:drift/drift.dart';

import '../db/mining_db.dart';
import '../db/mining_tables.dart';
import 'srt_parser.dart';

/// Turns a parsed .srt file into a [Works] row, one [Sources] row, and
/// one [TextSpans] row per cue (TimeAnchor — §5's table: subtitles
/// position by time interval, and carry `tStartMs`/`tEndMs` so audio is
/// extractable per §0.3.9).
class SrtSourceAdapter {
  final MiningDb db;

  const SrtSourceAdapter(this.db);

  /// Imports [file] as a new work titled [workTitle]. Returns the new
  /// work's id. Empty files (zero parseable cues) still create a
  /// [Works]/[Sources] row — an empty result is real information, not
  /// an error to hide.
  Future<String> importFile({
    required File file,
    required String workTitle,
    required String languageCode,
  }) async {
    final content = await file.readAsString();
    return importContent(
      content: content,
      sourcePath: file.path,
      workTitle: workTitle,
      languageCode: languageCode,
    );
  }

  Future<String> importContent({
    required String content,
    required String sourcePath,
    required String workTitle,
    required String languageCode,
  }) async {
    final cues = parseSrt(content);
    final now = DateTime.now();
    final stamp = now.microsecondsSinceEpoch;
    final workId = 'work:$stamp';
    final sourceId = 'source:$stamp';

    await db.into(db.works).insert(WorksCompanion.insert(
          id: workId,
          title: workTitle,
          medium: 'srt',
          languageCode: languageCode,
          addedAt: now,
        ));

    await db.into(db.sources).insert(SourcesCompanion.insert(
          id: sourceId,
          workId: workId,
          kind: 'srt',
          path: sourcePath,
          importedAt: now,
        ));

    if (cues.isNotEmpty) {
      await db.batch((b) {
        b.insertAll(
          db.textSpans,
          cues.map((cue) => TextSpansCompanion.insert(
                id: '$sourceId:${cue.index}',
                workId: workId,
                sourceId: sourceId,
                ordinal: cue.index,
                content: cue.text,
                anchorType: 'time',
                tStartMs: Value(cue.start.inMilliseconds),
                tEndMs: Value(cue.end.inMilliseconds),
              )),
        );
      });
    }

    return workId;
  }
}
