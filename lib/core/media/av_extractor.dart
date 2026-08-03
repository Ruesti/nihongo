import 'dart:io';

/// Audio-clip and screenshot-frame extraction from a source video/audio
/// file, via `ffmpeg`/`ffprobe` on `PATH`. Language-blind and
/// medium-generic — this only knows about time offsets into a media
/// file, never about text, tokens, or any language pack (§2.2 seam
/// discipline extends to this being "core," not JA-specific, even
/// though A/V mining only matters for time-anchored sources today).
///
/// §0.1.10 decided `ffmpeg` is bundled with the shipped app on every
/// platform; this wrapper shells out to a `ffmpeg`/`ffprobe` on
/// `PATH` rather than bundling a binary itself — bundling is a build/
/// packaging concern for later, not something core extraction logic
/// should own.
class AvExtractionException implements Exception {
  final String message;
  final String ffmpegStderr;

  const AvExtractionException(this.message, this.ffmpegStderr);

  @override
  String toString() => 'AvExtractionException: $message\n$ffmpegStderr';
}

class AvExtractor {
  final String ffmpegPath;

  const AvExtractor({this.ffmpegPath = 'ffmpeg'});

  /// Extracts the audio between [start] and [end] from [source] into
  /// [output] (container/codec inferred from the output file's
  /// extension by ffmpeg, e.g. `.m4a`).
  Future<void> extractAudioClip({
    required File source,
    required Duration start,
    required Duration end,
    required File output,
  }) async {
    await output.parent.create(recursive: true);
    final duration = end - start;
    final result = await Process.run(ffmpegPath, [
      '-y',
      '-ss', _formatTimestamp(start),
      '-i', source.path,
      '-t', _formatTimestamp(duration),
      '-vn', // no video
      '-map', '0:a:0',
      output.path,
    ]);
    if (result.exitCode != 0) {
      throw AvExtractionException(
        'Failed to extract audio clip from ${source.path}',
        result.stderr.toString(),
      );
    }
  }

  /// Extracts a single frame at [at] from [source] into [output] (e.g.
  /// a `.jpg`/`.png` path).
  Future<void> extractFrame({
    required File source,
    required Duration at,
    required File output,
  }) async {
    await output.parent.create(recursive: true);
    final result = await Process.run(ffmpegPath, [
      '-y',
      '-ss', _formatTimestamp(at),
      '-i', source.path,
      '-frames:v', '1',
      output.path,
    ]);
    if (result.exitCode != 0) {
      throw AvExtractionException(
        'Failed to extract frame from ${source.path}',
        result.stderr.toString(),
      );
    }
  }

  String _formatTimestamp(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final ms = d.inMilliseconds.remainder(1000);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}.'
        '${ms.toString().padLeft(3, '0')}';
  }
}
