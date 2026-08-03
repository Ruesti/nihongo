import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/media/av_extractor.dart';

// Requires `ffmpeg`/`ffprobe` on PATH (same environment prerequisite
// as the native tokenizer needing its .so built — see
// native/ja_tokenizer/README.md).

Future<bool> _ffmpegAvailable() async {
  try {
    final result = await Process.run('ffmpeg', ['-version']);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

Future<int> _probeDurationMs(File file) async {
  final result = await Process.run('ffprobe', [
    '-v', 'error',
    '-show_entries', 'format=duration',
    '-of', 'default=noprint_wrappers=1:nokey=1',
    file.path,
  ]);
  final seconds = double.parse((result.stdout as String).trim());
  return (seconds * 1000).round();
}

void main() {
  late Directory tempDir;
  late File sourceMedia;
  const extractor = AvExtractor();

  setUpAll(() async {
    if (!await _ffmpegAvailable()) {
      return; // individual tests skip via the same check
    }
    tempDir = await Directory.systemTemp.createTemp('av_extractor_test');
    sourceMedia = File('${tempDir.path}/source.mp4');
    // A short (5s) synthetic test-pattern + tone clip, generated fresh
    // per test run rather than committed — keeps the repo free of
    // binary fixtures and takes well under a second to generate.
    final result = await Process.run('ffmpeg', [
      '-y',
      '-f', 'lavfi', '-i', 'testsrc=size=320x240:rate=10:duration=5',
      '-f', 'lavfi', '-i', 'sine=frequency=440:duration=5',
      '-c:v', 'libx264', '-preset', 'ultrafast',
      '-c:a', 'aac', '-shortest',
      sourceMedia.path,
    ]);
    if (result.exitCode != 0) {
      throw StateError('Failed to generate test fixture: ${result.stderr}');
    }
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  group('AvExtractor', () {
    test('extractAudioClip produces a playable file of roughly the requested duration',
        () async {
      if (!await _ffmpegAvailable()) {
        markTestSkipped('ffmpeg not on PATH');
        return;
      }
      final output = File('${tempDir.path}/clip.m4a');

      await extractor.extractAudioClip(
        source: sourceMedia,
        start: const Duration(seconds: 1),
        end: const Duration(seconds: 3),
        output: output,
      );

      expect(output.existsSync(), isTrue);
      expect(output.lengthSync(), greaterThan(0));
      final durationMs = await _probeDurationMs(output);
      expect(durationMs, closeTo(2000, 300)); // ~2s requested, some encoder slack
    });

    test('extractFrame produces a non-empty image file', () async {
      if (!await _ffmpegAvailable()) {
        markTestSkipped('ffmpeg not on PATH');
        return;
      }
      final output = File('${tempDir.path}/frame.jpg');

      await extractor.extractFrame(
        source: sourceMedia,
        at: const Duration(seconds: 2),
        output: output,
      );

      expect(output.existsSync(), isTrue);
      expect(output.lengthSync(), greaterThan(0));
    });

    test('extractAudioClip throws AvExtractionException for a nonexistent source',
        () async {
      if (!await _ffmpegAvailable()) {
        markTestSkipped('ffmpeg not on PATH');
        return;
      }
      final output = File('${tempDir.path}/should-not-exist.m4a');

      expect(
        () => extractor.extractAudioClip(
          source: File('${tempDir.path}/does-not-exist.mp4'),
          start: Duration.zero,
          end: const Duration(seconds: 1),
          output: output,
        ),
        throwsA(isA<AvExtractionException>()),
      );
    });

    test('creates the output directory if it does not exist yet', () async {
      if (!await _ffmpegAvailable()) {
        markTestSkipped('ffmpeg not on PATH');
        return;
      }
      final output = File('${tempDir.path}/nested/dir/frame.jpg');

      await extractor.extractFrame(
        source: sourceMedia,
        at: const Duration(seconds: 1),
        output: output,
      );

      expect(output.existsSync(), isTrue);
    });
  });
}
