import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class StrokePainter extends CustomPainter {
  final List<List<Offset>> referenceStrokes;
  final List<List<Offset>> userStrokes;
  final int completedStrokes;
  final bool showGuide;
  final int? highlightStroke;

  StrokePainter({
    required this.referenceStrokes,
    required this.userStrokes,
    required this.completedStrokes,
    required this.showGuide,
    this.highlightStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    if (showGuide) _drawReference(canvas, size);
    _drawUserStrokes(canvas, size);
    if (highlightStroke != null) _drawNextStrokeHint(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD6C9B5).withOpacity(0.4)
      ..strokeWidth = 0.5;
    // Vertical center
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    // Horizontal center
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    // Diagonals
    paint.color = const Color(0xFFD6C9B5).withOpacity(0.2);
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(0, size.height), paint);
  }

  void _drawReference(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink.withOpacity(0.08)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < referenceStrokes.length; i++) {
      final stroke = referenceStrokes[i];
      if (stroke.length < 2) continue;
      // Already-completed strokes get slightly darker guide
      if (i < completedStrokes) {
        paint.color = AppColors.ink.withOpacity(0.05);
      } else {
        paint.color = AppColors.ink.withOpacity(0.12);
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawUserStrokes(Canvas canvas, Size size) {
    for (int i = 0; i < userStrokes.length; i++) {
      final stroke = userStrokes[i];
      if (stroke.length < 2) continue;
      final isLast = i == userStrokes.length - 1;
      final paint = Paint()
        ..color = isLast ? AppColors.ink : AppColors.ink.withOpacity(0.7)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawNextStrokeHint(Canvas canvas, Size size) {
    final idx = highlightStroke!;
    if (idx >= referenceStrokes.length) return;
    final stroke = referenceStrokes[idx];
    if (stroke.isEmpty) return;

    // Draw animated arrow at start of next stroke
    final paint = Paint()
      ..color = AppColors.red.withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;

    canvas.drawCircle(stroke.first, 6, paint);

    if (stroke.length >= 2) {
      // Small direction arrow
      final dir = (stroke[stroke.length ~/ 4] - stroke.first);
      final angle = dir.direction;
      final arrowPaint = Paint()
        ..color = AppColors.red.withOpacity(0.4)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final arrowEnd = stroke.first + Offset.fromDirection(angle, 20);
      canvas.drawLine(stroke.first, arrowEnd, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(StrokePainter old) =>
      old.userStrokes != userStrokes ||
      old.completedStrokes != completedStrokes ||
      old.showGuide != showGuide ||
      old.highlightStroke != highlightStroke;
}
