import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/sources/srt_parser.dart';

void main() {
  group('parseSrt', () {
    test('parses a standard well-formed file', () {
      const srt = '''
1
00:00:20,000 --> 00:00:24,400
Hello there.

2
00:00:24,600 --> 00:00:27,800
General Kenobi.
''';
      final cues = parseSrt(srt);

      expect(cues, hasLength(2));
      expect(cues[0].index, 1);
      expect(cues[0].start, const Duration(seconds: 20));
      expect(cues[0].end, const Duration(seconds: 24, milliseconds: 400));
      expect(cues[0].text, 'Hello there.');
      expect(cues[1].text, 'General Kenobi.');
    });

    test('joins multi-line cue text with newlines', () {
      const srt = '''
1
00:00:01,000 --> 00:00:02,000
Line one
Line two
''';
      final cues = parseSrt(srt);

      expect(cues.single.text, 'Line one\nLine two');
    });

    test('strips HTML-style markup tags', () {
      const srt = '''
1
00:00:01,000 --> 00:00:02,000
<i>Italic text</i> and <b>bold</b>
''';
      final cues = parseSrt(srt);

      expect(cues.single.text, 'Italic text and bold');
    });

    test('strips ASS-style override tags', () {
      const srt = '''
1
00:00:01,000 --> 00:00:02,000
{\\an8}Top of screen
''';
      final cues = parseSrt(srt);

      expect(cues.single.text, 'Top of screen');
    });

    test('accepts "." as the millisecond separator', () {
      const srt = '''
1
00:00:01.500 --> 00:00:02.500
Dot separator
''';
      final cues = parseSrt(srt);

      expect(cues.single.start, const Duration(seconds: 1, milliseconds: 500));
    });

    test('tolerates a leading UTF-8 BOM', () {
      const srt = '﻿1\n00:00:01,000 --> 00:00:02,000\nBOM test\n';
      final cues = parseSrt(srt);

      expect(cues.single.text, 'BOM test');
    });

    test('tolerates CRLF line endings', () {
      const srt = '1\r\n00:00:01,000 --> 00:00:02,000\r\nCRLF test\r\n';
      final cues = parseSrt(srt);

      expect(cues.single.text, 'CRLF test');
    });

    test('skips cues that become empty after markup stripping', () {
      const srt = '''
1
00:00:01,000 --> 00:00:02,000
<i></i>

2
00:00:02,000 --> 00:00:03,000
Real text
''';
      final cues = parseSrt(srt);

      expect(cues, hasLength(1));
      expect(cues.single.text, 'Real text');
    });

    test('assigns a sequential index when the index line is missing', () {
      const srt = '''
00:00:01,000 --> 00:00:02,000
No index line
''';
      final cues = parseSrt(srt);

      expect(cues.single.index, 1);
    });

    test('empty input yields no cues', () {
      expect(parseSrt(''), isEmpty);
    });

    test('preserves reading order across many cues', () {
      final srt = List.generate(
        5,
        (i) => '${i + 1}\n00:00:0$i,000 --> 00:00:0${i + 1},000\nCue $i\n',
      ).join('\n');

      final cues = parseSrt(srt);

      expect(cues.map((c) => c.text).toList(),
          ['Cue 0', 'Cue 1', 'Cue 2', 'Cue 3', 'Cue 4']);
    });
  });
}
