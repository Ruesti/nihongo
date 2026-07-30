/// Parses SubRip (.srt) subtitle files. Deliberately language-blind —
/// this is the §2.1 "Segmentation" pipeline stage's SRT source, and
/// belongs in core, not a language pack (SPEC_MINING_PIPELINE.md §2.2
/// seam discipline: nothing here branches on language).
library;

/// One subtitle cue: an index, a time range, and its text.
class SrtCue {
  final int index;
  final Duration start;
  final Duration end;
  final String text;

  const SrtCue({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
  });
}

final _timecodePattern = RegExp(
  r'(\d{1,2}):(\d{2}):(\d{2})[,.](\d{1,3})\s*-->\s*'
  r'(\d{1,2}):(\d{2}):(\d{2})[,.](\d{1,3})',
);

// Strips SRT/ASS-style inline markup (<i>, <b>, {\an8}, ...) — dictionary
// lookup and tokenization need plain text, not presentation hints.
final _markupPattern = RegExp(r'<[^>]*>|\{[^}]*\}');

Duration _parseTimecodePart(String h, String m, String s, String ms) {
  // Milliseconds can be 1-3 digits in the wild; normalise to 3.
  final msNormalized = ms.padRight(3, '0').substring(0, 3);
  return Duration(
    hours: int.parse(h),
    minutes: int.parse(m),
    seconds: int.parse(s),
    milliseconds: int.parse(msNormalized),
  );
}

/// Parses the full contents of an .srt file into ordered [SrtCue]s.
/// Tolerant of a leading UTF-8 BOM, `\r\n` line endings, and both `,`
/// and `.` as the millisecond separator (both appear in real-world
/// files despite the spec mandating `,`).
List<SrtCue> parseSrt(String content) {
  final normalized = content
      .replaceFirst('﻿', '') // BOM
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');

  final blocks = normalized.split(RegExp(r'\n\s*\n'));
  final cues = <SrtCue>[];

  for (final block in blocks) {
    final lines =
        block.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) continue;

    // The index line is optional in some malformed files — locate the
    // timecode line instead of assuming a fixed position.
    final timecodeLineIndex =
        lines.indexWhere((l) => _timecodePattern.hasMatch(l));
    if (timecodeLineIndex == -1) continue;

    final match = _timecodePattern.firstMatch(lines[timecodeLineIndex])!;
    final start = _parseTimecodePart(
        match.group(1)!, match.group(2)!, match.group(3)!, match.group(4)!);
    final end = _parseTimecodePart(
        match.group(5)!, match.group(6)!, match.group(7)!, match.group(8)!);

    final indexLine =
        timecodeLineIndex > 0 ? int.tryParse(lines[timecodeLineIndex - 1]) : null;
    final index = indexLine ?? cues.length + 1;

    final textLines = lines.sublist(timecodeLineIndex + 1);
    final text = textLines
        .join('\n')
        .replaceAll(_markupPattern, '')
        .trim();
    if (text.isEmpty) continue;

    cues.add(SrtCue(index: index, start: start, end: end, text: text));
  }

  return cues;
}
