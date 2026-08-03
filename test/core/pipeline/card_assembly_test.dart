import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/media/av_extractor.dart';
import 'package:nihongo_app/core/pipeline/card_assembly.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';

Future<bool> _ffmpegAvailable() async {
  try {
    return (await Process.run('ffmpeg', ['-version'])).exitCode == 0;
  } catch (_) {
    return false;
  }
}

class _FixedReadings implements ReadingProvider {
  const _FixedReadings();

  @override
  Reading? reading(Token token) =>
      token.lemma == '日本語' ? const Reading('にほんご') : null;
}

TextSpan _timeSpan(String id, {int? tStartMs, int? tEndMs}) => TextSpan(
      id: id,
      workId: 'w1',
      sourceId: 'src1',
      ordinal: 1,
      content: '日本語です',
      anchorType: tStartMs == null ? 'flow' : 'time',
      tStartMs: tStartMs,
      tEndMs: tEndMs,
    );

ScoredSegment _i1Candidate(TextSpan span) => ScoredSegment(
      segment: span,
      tokens: [
        Token(surface: '日本語', lemma: '日本語', pos: 'noun', charStart: 0, charEnd: 3),
        Token(surface: 'です', lemma: 'です', pos: 'aux', charStart: 3, charEnd: 5),
      ],
      unknownCount: 1,
      knownRatio: 0.5,
      targetRank: 42,
      targetLemma: '日本語',
    );

void main() {
  late MiningDb db;
  late Directory tempDir;

  setUp(() async {
    db = MiningDb.forTesting();
    tempDir = await Directory.systemTemp.createTemp('card_assembly_test');
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  group('CardAssembler', () {
    test('creates a VocabItems row for the target lemma', () async {
      final assembler = CardAssembler(
        db: db,
        extractor: const AvExtractor(),
        readings: const _FixedReadings(),
        mediaOutputDir: tempDir,
      );
      final span = _timeSpan('span1');

      await assembler.assemble(_i1Candidate(span), languageCode: 'ja');

      final items = await db.select(db.vocabItems).get();
      expect(items.single.lemma, '日本語');
    });

    test('creates a Cards row referencing the source segment', () async {
      final assembler = CardAssembler(
        db: db,
        extractor: const AvExtractor(),
        readings: const _FixedReadings(),
        mediaOutputDir: tempDir,
      );
      final span = _timeSpan('span1');

      final assembled = await assembler.assemble(_i1Candidate(span), languageCode: 'ja');

      final cards = await db.select(db.cards).get();
      expect(cards.single.id, assembled.cardId);
      expect(cards.single.contextTextSpanId, 'span1');
    });

    test('computes furigana for the assembled card', () async {
      final assembler = CardAssembler(
        db: db,
        extractor: const AvExtractor(),
        readings: const _FixedReadings(),
        mediaOutputDir: tempDir,
      );

      final assembled =
          await assembler.assemble(_i1Candidate(_timeSpan('span1')), languageCode: 'ja');

      expect(assembled.furigana, hasLength(1));
      expect(assembled.furigana.single.reading, 'にほんご');
    });

    test('throws ArgumentError for a candidate with unknownCount != 1',
        () async {
      final assembler = CardAssembler(
        db: db,
        extractor: const AvExtractor(),
        readings: const _FixedReadings(),
        mediaOutputDir: tempDir,
      );
      final notI1 = ScoredSegment(
        segment: _timeSpan('span1'),
        tokens: const [],
        unknownCount: 2,
        knownRatio: 0.0,
        targetRank: null,
        targetLemma: null,
      );

      expect(
        () => assembler.assemble(notI1, languageCode: 'ja'),
        throwsArgumentError,
      );
    });

    test('a flow-anchored segment (no TimeAnchor) skips audio/frame gracefully',
        () async {
      final assembler = CardAssembler(
        db: db,
        extractor: const AvExtractor(),
        readings: const _FixedReadings(),
        mediaOutputDir: tempDir,
      );
      final flowSpan = _timeSpan('span1'); // tStartMs/tEndMs both null

      final assembled = await assembler.assemble(_i1Candidate(flowSpan), languageCode: 'ja');

      expect(assembled.audioFile, isNull);
      expect(assembled.frameFile, isNull);
      expect((await db.select(db.mediaBlobs).get()), isEmpty);
    });

    test(
        'extracts real audio + frame files and MediaBlobs rows when '
        'sourceMedia + TimeAnchor are both present', () async {
      if (!await _ffmpegAvailable()) {
        markTestSkipped('ffmpeg not on PATH');
        return;
      }
      final sourceMedia = File('${tempDir.path}/source.mp4');
      final genResult = await Process.run('ffmpeg', [
        '-y',
        '-f', 'lavfi', '-i', 'testsrc=size=320x240:rate=10:duration=5',
        '-f', 'lavfi', '-i', 'sine=frequency=440:duration=5',
        '-c:v', 'libx264', '-preset', 'ultrafast',
        '-c:a', 'aac', '-shortest',
        sourceMedia.path,
      ]);
      expect(genResult.exitCode, 0, reason: 'fixture generation failed');

      final assembler = CardAssembler(
        db: db,
        extractor: const AvExtractor(),
        readings: const _FixedReadings(),
        mediaOutputDir: tempDir,
      );
      final timedSpan = _timeSpan('span1', tStartMs: 1000, tEndMs: 3000);

      final assembled = await assembler.assemble(
        _i1Candidate(timedSpan),
        languageCode: 'ja',
        sourceMedia: sourceMedia,
      );

      expect(assembled.audioFile?.existsSync(), isTrue);
      expect(assembled.frameFile?.existsSync(), isTrue);
      final blobs = await db.select(db.mediaBlobs).get();
      expect(blobs.map((b) => b.kind), unorderedEquals(['audio', 'image']));
    });
  });
}
