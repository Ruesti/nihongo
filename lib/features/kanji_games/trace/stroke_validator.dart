import 'dart:math' as math;

import 'package:flutter/material.dart';

// Validates user-drawn strokes against KanjiVG reference strokes.
// Uses a simplified Fréchet-distance approach after normalizing
// both strokes to the same number of sample points.
class StrokeValidator {
  static const _sampleCount = 30;
  static const _acceptanceThreshold = 0.68;

  static double similarity(
    List<Offset> user,
    List<Offset> reference,
  ) {
    if (user.isEmpty || reference.isEmpty) return 0.0;
    final uNorm = _normalize(user);
    final rNorm = _normalize(reference);
    double totalDist = 0;
    for (int i = 0; i < _sampleCount; i++) {
      totalDist += (uNorm[i] - rNorm[i]).distance;
    }
    final avgDist = totalDist / _sampleCount;
    // Map average distance to similarity: 0 dist → 1.0, 50px dist → 0.0
    return (1.0 - avgDist / 50.0).clamp(0.0, 1.0);
  }

  static bool isAcceptable(List<Offset> user, List<Offset> reference) {
    return similarity(user, reference) >= _acceptanceThreshold;
  }

  // Resample a stroke to exactly [_sampleCount] evenly-spaced points
  static List<Offset> _normalize(List<Offset> points) {
    if (points.length == 1) {
      return List.filled(_sampleCount, points.first);
    }
    // Compute cumulative arc length
    final lengths = <double>[0];
    for (int i = 1; i < points.length; i++) {
      lengths.add(lengths.last + (points[i] - points[i - 1]).distance);
    }
    final total = lengths.last;
    if (total == 0) return List.filled(_sampleCount, points.first);

    final result = <Offset>[];
    int j = 0;
    for (int k = 0; k < _sampleCount; k++) {
      final target = total * k / (_sampleCount - 1);
      while (j < lengths.length - 1 && lengths[j + 1] < target) {
        j++;
      }
      if (j >= points.length - 1) {
        result.add(points.last);
      } else {
        final seg = lengths[j + 1] - lengths[j];
        final t = seg > 0 ? (target - lengths[j]) / seg : 0.0;
        result.add(Offset.lerp(points[j], points[j + 1], t)!);
      }
    }
    return result;
  }

  // Checks rough direction match (important: left-to-right, top-to-bottom, etc.)
  static String? directionHint(List<Offset> user, List<Offset> reference) {
    if (user.length < 2 || reference.length < 2) return null;
    final userDir = user.last - user.first;
    final refDir = reference.last - reference.first;
    final angleDiff = (userDir.direction - refDir.direction).abs();
    if (angleDiff > math.pi / 2) {
      // More than 90° off — suggest a direction
      if (refDir.dx.abs() > refDir.dy.abs()) {
        return refDir.dx > 0 ? 'Von links nach rechts' : 'Von rechts nach links';
      } else {
        return refDir.dy > 0 ? 'Von oben nach unten' : 'Von unten nach oben';
      }
    }
    final userLen = userDir.distance;
    final refLen = refDir.distance;
    if (userLen < refLen * 0.4) return 'Strich zu kurz';
    if (userLen > refLen * 2.5) return 'Strich zu lang';
    return null;
  }
}
