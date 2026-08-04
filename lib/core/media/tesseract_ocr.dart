import 'dart:io';

import 'ocr_engine.dart';

/// An [OcrEngine] backed by the `tesseract` CLI on PATH. Requests TSV
/// output, groups word rows into lines, and returns one [OcrBox] per
/// recognized line — a reasonable text unit for a manga panel (a speech
/// bubble is usually a few lines). Japanese words carry no spaces, so
/// a line's words are joined without separators.
///
/// Like `AvExtractor`, this shells out rather than bundling a binary;
/// §0.1.10's "ffmpeg bundled" packaging decision has a Tesseract
/// analogue that is a shipping concern, not this adapter's.
class TesseractOcrEngine implements OcrEngine {
  final String tesseractPath;
  final String language;
  final int minConfidence;

  const TesseractOcrEngine({
    this.tesseractPath = 'tesseract',
    this.language = 'jpn',
    this.minConfidence = 30,
  });

  @override
  Future<List<OcrBox>> recognize(File image) async {
    final result = await Process.run(tesseractPath, [
      image.path,
      'stdout',
      '-l', language,
      '--psm', '3', // automatic page segmentation
      'tsv',
    ]);
    if (result.exitCode != 0) {
      throw OcrException(
          'tesseract failed on ${image.path}', result.stderr.toString());
    }
    return _parseTsv(result.stdout as String);
  }

  List<OcrBox> _parseTsv(String tsv) {
    final lines = tsv.split('\n');
    if (lines.isEmpty) return const [];

    // Accumulate word rows per (block, par, line) group.
    final groups = <String, _LineAcc>{};
    for (final row in lines.skip(1)) {
      final cols = row.split('\t');
      if (cols.length < 12) continue;
      final level = int.tryParse(cols[0]);
      if (level != 5) continue; // word level
      final conf = double.tryParse(cols[10]) ?? -1;
      final text = cols[11].trim();
      if (text.isEmpty || conf < minConfidence) continue;

      final left = int.parse(cols[6]);
      final top = int.parse(cols[7]);
      final width = int.parse(cols[8]);
      final height = int.parse(cols[9]);
      final key = '${cols[2]}:${cols[3]}:${cols[4]}'; // block:par:line

      final acc = groups.putIfAbsent(key, () => _LineAcc());
      acc.add(text, left, top, left + width, top + height);
    }

    return groups.values
        .where((a) => a.text.isNotEmpty)
        .map((a) => a.toBox())
        .toList();
  }
}

class OcrException implements Exception {
  final String message;
  final String stderr;
  const OcrException(this.message, this.stderr);
  @override
  String toString() => 'OcrException: $message\n$stderr';
}

class _LineAcc {
  final StringBuffer _text = StringBuffer();
  int _left = 1 << 30, _top = 1 << 30, _right = 0, _bottom = 0;

  void add(String word, int l, int t, int r, int b) {
    _text.write(word); // JP: no separator between words
    if (l < _left) _left = l;
    if (t < _top) _top = t;
    if (r > _right) _right = r;
    if (b > _bottom) _bottom = b;
  }

  String get text => _text.toString();

  OcrBox toBox() => OcrBox(
        text: text,
        left: _left,
        top: _top,
        right: _right,
        bottom: _bottom,
      );
}
