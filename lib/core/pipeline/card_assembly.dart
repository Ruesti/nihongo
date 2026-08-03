import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../db/mining_db.dart';
import '../language_pack/language_pack.dart';
import '../media/av_extractor.dart';
import 'furigana.dart';
import 'sentence_scoring.dart';

/// The §2.1 "Card assembly" pipeline stage: turns a ranked i+1
/// [ScoredSegment] candidate into an actual [Cards] row plus its
/// on-disk artifacts (audio clip, screenshot frame, furigana).
class AssembledCard {
  final String cardId;
  final String targetLemma;
  final ScoredSegment source;
  final List<FuriganaSpan> furigana;
  final File? audioFile;
  final File? frameFile;

  const AssembledCard({
    required this.cardId,
    required this.targetLemma,
    required this.source,
    required this.furigana,
    this.audioFile,
    this.frameFile,
  });
}

class CardAssembler {
  final MiningDb db;
  final AvExtractor extractor;
  final ReadingProvider? readings;
  final Directory mediaOutputDir;

  const CardAssembler({
    required this.db,
    required this.extractor,
    required this.readings,
    required this.mediaOutputDir,
  });

  /// Assembles one card for [candidate], which must have
  /// `unknownCount == 1` (i.e. `targetLemma` set — see
  /// [ScoredSegment]). Extracts audio/frame only when [sourceMedia] is
  /// given and the segment carries a `TimeAnchor`
  /// (`tStartMs`/`tEndMs`) — a flow-anchored (EPUB/plain-text) segment
  /// has neither, and that's a real, expected case, not an error.
  Future<AssembledCard> assemble(
    ScoredSegment candidate, {
    required String languageCode,
    File? sourceMedia,
  }) async {
    final targetLemma = candidate.targetLemma;
    if (targetLemma == null) {
      throw ArgumentError(
          'assemble() requires a candidate with unknownCount == 1 '
          '(targetLemma == null for segment ${candidate.segment.id})');
    }

    final furigana = computeFurigana(candidate.tokens, readings);

    File? audioFile;
    File? frameFile;
    final start = candidate.segment.tStartMs;
    final end = candidate.segment.tEndMs;

    if (sourceMedia != null && start != null && end != null) {
      final startDuration = Duration(milliseconds: start);
      final endDuration = Duration(milliseconds: end);

      audioFile = File(p.join(mediaOutputDir.path, '${candidate.segment.id}.m4a'));
      await extractor.extractAudioClip(
        source: sourceMedia,
        start: startDuration,
        end: endDuration,
        output: audioFile,
      );
      await _persistBlob(kind: 'audio', file: audioFile);

      final mid = startDuration + (endDuration - startDuration) ~/ 2;
      frameFile = File(p.join(mediaOutputDir.path, '${candidate.segment.id}.jpg'));
      await extractor.extractFrame(
        source: sourceMedia,
        at: mid,
        output: frameFile,
      );
      await _persistBlob(kind: 'image', file: frameFile);
    }

    final vocabItemId = 'vocab:$languageCode:$targetLemma';
    final pos = candidate.tokens
        .firstWhere((t) => t.lemma == targetLemma, orElse: () => candidate.tokens.first)
        .pos;
    await db.into(db.vocabItems).insertOnConflictUpdate(
          VocabItemsCompanion.insert(
            id: vocabItemId,
            languageCode: languageCode,
            lemma: targetLemma,
            pos: pos,
            createdAt: DateTime.now(),
          ),
        );

    final cardId = 'card:$vocabItemId';
    final now = DateTime.now().toUtc();
    await db.into(db.cards).insertOnConflictUpdate(
          CardsCompanion.insert(
            id: cardId,
            vocabItemId: vocabItemId,
            contextTextSpanId: Value(candidate.segment.id),
            due: now,
            lastReview: now,
          ),
        );

    return AssembledCard(
      cardId: cardId,
      targetLemma: targetLemma,
      source: candidate,
      furigana: furigana,
      audioFile: audioFile,
      frameFile: frameFile,
    );
  }

  Future<void> _persistBlob({required String kind, required File file}) async {
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes).toString();
    await db.into(db.mediaBlobs).insertOnConflictUpdate(
          MediaBlobsCompanion.insert(
            id: 'blob:$hash',
            kind: kind,
            path: file.path,
            contentHash: hash,
          ),
        );
  }
}
