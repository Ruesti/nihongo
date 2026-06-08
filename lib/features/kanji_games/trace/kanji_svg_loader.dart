import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

// Parses KanjiVG SVG files into lists of stroke point sequences.
// KanjiVG SVG paths use the standard SVG path format; we sample them
// into discrete Offset lists suitable for CustomPainter.
class KanjiSvgLoader {
  static final Map<String, List<List<Offset>>> _cache = {};

  static Future<List<List<Offset>>?> loadStrokes(
    String assetPath, {
    double canvasSize = 300,
  }) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath];

    try {
      final svgString = await rootBundle.loadString(assetPath);
      final strokes = _parseSvg(svgString, canvasSize);
      _cache[assetPath] = strokes;
      return strokes;
    } catch (_) {
      return null;
    }
  }

  static List<List<Offset>> _parseSvg(String svgString, double canvasSize) {
    final document = XmlDocument.parse(svgString);
    final paths = document.findAllElements('path')
        .where((e) => e.getAttribute('d') != null)
        .toList();

    // KanjiVG uses a 109x109 viewBox
    const sourceSize = 109.0;
    final scale = canvasSize / sourceSize;

    return paths.map((p) {
      final d = p.getAttribute('d')!;
      return _samplePath(d, scale);
    }).where((s) => s.isNotEmpty).toList();
  }

  static List<Offset> _samplePath(String d, double scale) {
    final points = <Offset>[];
    final segments = _tokenizePath(d);
    Offset current = Offset.zero;
    Offset start = Offset.zero;

    int i = 0;
    while (i < segments.length) {
      final cmd = segments[i++];
      switch (cmd) {
        case 'M':
          final x = double.parse(segments[i++]);
          final y = double.parse(segments[i++]);
          current = Offset(x * scale, y * scale);
          start = current;
          points.add(current);
        case 'm':
          final dx = double.parse(segments[i++]);
          final dy = double.parse(segments[i++]);
          current = Offset(current.dx + dx * scale, current.dy + dy * scale);
          start = current;
          points.add(current);
        case 'L':
          final x = double.parse(segments[i++]);
          final y = double.parse(segments[i++]);
          final end = Offset(x * scale, y * scale);
          points.addAll(_sampleLine(current, end));
          current = end;
        case 'l':
          final dx = double.parse(segments[i++]);
          final dy = double.parse(segments[i++]);
          final end = Offset(current.dx + dx * scale, current.dy + dy * scale);
          points.addAll(_sampleLine(current, end));
          current = end;
        case 'C':
          final cx1 = double.parse(segments[i++]);
          final cy1 = double.parse(segments[i++]);
          final cx2 = double.parse(segments[i++]);
          final cy2 = double.parse(segments[i++]);
          final ex = double.parse(segments[i++]);
          final ey = double.parse(segments[i++]);
          final cp1 = Offset(cx1 * scale, cy1 * scale);
          final cp2 = Offset(cx2 * scale, cy2 * scale);
          final end = Offset(ex * scale, ey * scale);
          points.addAll(_sampleCubicBezier(current, cp1, cp2, end));
          current = end;
        case 'c':
          final dx1 = double.parse(segments[i++]);
          final dy1 = double.parse(segments[i++]);
          final dx2 = double.parse(segments[i++]);
          final dy2 = double.parse(segments[i++]);
          final dex = double.parse(segments[i++]);
          final dey = double.parse(segments[i++]);
          final cp1 = Offset(
              current.dx + dx1 * scale, current.dy + dy1 * scale);
          final cp2 = Offset(
              current.dx + dx2 * scale, current.dy + dy2 * scale);
          final end = Offset(
              current.dx + dex * scale, current.dy + dey * scale);
          points.addAll(_sampleCubicBezier(current, cp1, cp2, end));
          current = end;
        case 'S':
          // Smooth cubic bezier — treat first CP as reflection
          final cx2 = double.parse(segments[i++]);
          final cy2 = double.parse(segments[i++]);
          final ex = double.parse(segments[i++]);
          final ey = double.parse(segments[i++]);
          final cp2 = Offset(cx2 * scale, cy2 * scale);
          final end = Offset(ex * scale, ey * scale);
          points.addAll(_sampleCubicBezier(current, current, cp2, end));
          current = end;
        case 'Z':
        case 'z':
          points.addAll(_sampleLine(current, start));
          current = start;
        default:
          // Skip unknown commands
          break;
      }
    }
    return points;
  }

  static List<Offset> _sampleLine(Offset from, Offset to, {int steps = 10}) {
    return List.generate(
      steps,
      (i) => Offset.lerp(from, to, (i + 1) / steps)!,
    );
  }

  static List<Offset> _sampleCubicBezier(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3, {
    int steps = 20,
  }) {
    return List.generate(steps, (i) {
      final t = (i + 1) / steps;
      final mt = 1 - t;
      return Offset(
        mt * mt * mt * p0.dx +
            3 * mt * mt * t * p1.dx +
            3 * mt * t * t * p2.dx +
            t * t * t * p3.dx,
        mt * mt * mt * p0.dy +
            3 * mt * mt * t * p1.dy +
            3 * mt * t * t * p2.dy +
            t * t * t * p3.dy,
      );
    });
  }

  // Tokenizes SVG path d-attribute into commands and numeric strings
  static List<String> _tokenizePath(String d) {
    final result = <String>[];
    final numBuffer = StringBuffer();

    void flushNum() {
      if (numBuffer.isNotEmpty) {
        result.add(numBuffer.toString());
        numBuffer.clear();
      }
    }

    for (int i = 0; i < d.length; i++) {
      final c = d[i];
      if (RegExp(r'[MmLlCcSsZz]').hasMatch(c)) {
        flushNum();
        result.add(c);
      } else if (c == ' ' || c == ',') {
        flushNum();
      } else if (c == '-' && numBuffer.isNotEmpty) {
        flushNum();
        numBuffer.write(c);
      } else {
        numBuffer.write(c);
      }
    }
    flushNum();
    return result;
  }
}
