import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/mascot_state.dart';
import '../../models/progress.dart';

class MascotWidget extends StatefulWidget {
  final UserProgress progress;
  final double size;
  final bool animate;

  const MascotWidget({
    super.key,
    required this.progress,
    this.size = 64,
    this.animate = false,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bobAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bobAnim = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MascotWidget old) {
    super.didUpdateWidget(old);
    if (widget.animate && !old.animate) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.animate && old.animate) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.progress.tamagoState;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, widget.animate ? _bobAnim.value : 0),
          child: child,
        );
      },
      child: _buildMascot(state),
    );
  }

  Widget _buildMascot(TamagoState state) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _TamagoPainter(state: state, size: widget.size),
      ),
    );
  }
}

class _TamagoPainter extends CustomPainter {
  final TamagoState state;
  final double size;

  _TamagoPainter({required this.state, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final s = canvasSize.width;
    final cx = s / 2;
    final cy = s / 2;

    // Egg body
    final eggPaint = Paint()..color = const Color(0xFFFFF9F0);
    final eggBorder = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025;

    final eggRect = RRect.fromRectAndCorners(
      Rect.fromCenter(
          center: Offset(cx, cy + s * 0.05), width: s * 0.7, height: s * 0.8),
      topLeft: const Radius.circular(999),
      topRight: const Radius.circular(999),
      bottomLeft: const Radius.circular(999),
      bottomRight: const Radius.circular(999),
    );
    canvas.drawRRect(eggRect, eggPaint);
    canvas.drawRRect(eggRect, eggBorder);

    // State-specific features
    switch (state) {
      case TamagoState.egg:
        break;
      case TamagoState.cracking:
        _drawCrack(canvas, cx, cy, s);
      case TamagoState.peeking:
        _drawCrack(canvas, cx, cy, s);
        _drawEyes(canvas, cx, cy + s * 0.05, s, peeking: true);
      case TamagoState.halfOut:
        _drawTopHalf(canvas, cx, cy, s);
        _drawEyes(canvas, cx, cy - s * 0.1, s, peeking: false);
        _drawSmile(canvas, cx, cy, s);
      case TamagoState.hatched:
        _drawChick(canvas, cx, cy, s);
    }
  }

  void _drawCrack(Canvas canvas, double cx, double cy, double s) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = s * 0.02
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(cx - s * 0.05, cy - s * 0.05)
      ..lineTo(cx, cy - s * 0.15)
      ..lineTo(cx + s * 0.05, cy - s * 0.05);
    canvas.drawPath(path, paint);
  }

  void _drawEyes(Canvas canvas, double cx, double cy, double s,
      {required bool peeking}) {
    final eyePaint = Paint()..color = AppColors.ink;
    final y = peeking ? cy + s * 0.05 : cy - s * 0.08;
    canvas.drawCircle(Offset(cx - s * 0.1, y), s * 0.04, eyePaint);
    canvas.drawCircle(Offset(cx + s * 0.1, y), s * 0.04, eyePaint);
  }

  void _drawSmile(Canvas canvas, double cx, double cy, double s) {
    final paint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = s * 0.025
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(cx - s * 0.1, cy + s * 0.05)
      ..quadraticBezierTo(cx, cy + s * 0.12, cx + s * 0.1, cy + s * 0.05);
    canvas.drawPath(path, paint);
  }

  void _drawTopHalf(Canvas canvas, double cx, double cy, double s) {
    // Draw cracked top half shifted up
    final halfPaint = Paint()
      ..color = const Color(0xFFFFF9F0);
    final border = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025;
    final rect = RRect.fromRectAndCorners(
      Rect.fromCenter(
          center: Offset(cx, cy - s * 0.25), width: s * 0.65, height: s * 0.55),
      topLeft: const Radius.circular(999),
      topRight: const Radius.circular(999),
      bottomLeft: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
    );
    canvas.drawRRect(rect, halfPaint);
    canvas.drawRRect(rect, border);
  }

  void _drawChick(Canvas canvas, double cx, double cy, double s) {
    // Yellow chick body
    final bodyPaint = Paint()..color = const Color(0xFFFFC107);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + s * 0.05), width: s * 0.65, height: s * 0.7),
      bodyPaint,
    );
    // Head
    canvas.drawCircle(Offset(cx, cy - s * 0.22), s * 0.22, bodyPaint);
    // Eyes
    final eyePaint = Paint()..color = AppColors.ink;
    canvas.drawCircle(Offset(cx - s * 0.08, cy - s * 0.25), s * 0.04, eyePaint);
    canvas.drawCircle(Offset(cx + s * 0.08, cy - s * 0.25), s * 0.04, eyePaint);
    // Beak
    final beakPaint = Paint()..color = const Color(0xFFFF8C00);
    final beak = Path()
      ..moveTo(cx - s * 0.04, cy - s * 0.17)
      ..lineTo(cx + s * 0.04, cy - s * 0.17)
      ..lineTo(cx, cy - s * 0.1)
      ..close();
    canvas.drawPath(beak, beakPaint);
    // Wings
    final wingPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - s * 0.3, cy + s * 0.05),
          width: s * 0.2, height: s * 0.35),
      wingPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + s * 0.3, cy + s * 0.05),
          width: s * 0.2, height: s * 0.35),
      wingPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TamagoPainter old) =>
      old.state != state || old.size != size;
}

// Compact version for use in lesson complete screen
class MascotReward extends StatelessWidget {
  final UserProgress progress;
  final int xpGained;

  const MascotReward({
    super.key,
    required this.progress,
    required this.xpGained,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MascotWidget(
          progress: progress,
          size: 100,
          animate: true,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.amber.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.amber.withOpacity(0.3)),
          ),
          child: Text(
            '+$xpGained XP',
            style: const TextStyle(
              color: AppColors.amber,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
