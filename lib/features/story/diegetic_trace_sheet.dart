import 'package:flutter/material.dart';

import 'trace_evaluator.dart';

/// The skippable, in-fiction handwriting canvas shown at a `diegetic: true`
/// trace panel (brief P6, Folge 01 P24). The reader traces [targetText] and
/// taps "fertig"; [evaluator] judges the attempt. An accepted trace fires
/// [onSuccess] exactly once (the caller turns that into the SRS encounter).
/// Nothing gates the story: [onSkip] dismisses at any time with no
/// consequence (INV-1). No pass/fail lock.
class DiegeticTraceSheet extends StatefulWidget {
  final String targetText;
  final TraceEvaluator evaluator;
  final VoidCallback onSuccess;
  final VoidCallback onSkip;

  const DiegeticTraceSheet({
    super.key,
    required this.targetText,
    required this.evaluator,
    required this.onSuccess,
    required this.onSkip,
  });

  @override
  State<DiegeticTraceSheet> createState() => _DiegeticTraceSheetState();
}

class _DiegeticTraceSheetState extends State<DiegeticTraceSheet> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  String? _feedback;
  bool _succeeded = false;

  void _panStart(DragStartDetails d) => _current = [d.localPosition];

  void _panUpdate(DragUpdateDetails d) =>
      setState(() => _current.add(d.localPosition));

  void _panEnd(DragEndDetails d) {
    setState(() {
      _strokes.add(List.of(_current));
      _current = [];
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _current = [];
      _feedback = null;
    });
  }

  Future<void> _submit() async {
    final ok = await widget.evaluator.evaluate(widget.targetText, _strokes);
    if (!mounted) return;
    if (ok) {
      setState(() => _feedback = 'よくできました ✓');
      if (!_succeeded) {
        _succeeded = true;
        widget.onSuccess();
      }
    } else {
      setState(() => _feedback = 'もう一度どうぞ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('diegetic-trace-sheet'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('なぞって: ${widget.targetText}',
              style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 12),
          GestureDetector(
            key: const ValueKey('diegetic-trace-canvas'),
            onPanStart: _panStart,
            onPanUpdate: _panUpdate,
            onPanEnd: _panEnd,
            child: Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(color: const Color(0xFFBBBBBB)),
              ),
              child: CustomPaint(
                painter: _InkPainter(_strokes, _current),
                size: Size.infinite,
              ),
            ),
          ),
          if (_feedback != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_feedback!,
                  key: const ValueKey('diegetic-trace-feedback')),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                key: const ValueKey('diegetic-trace-clear'),
                onPressed: _clear,
                child: const Text('löschen'),
              ),
              const Spacer(),
              TextButton(
                key: const ValueKey('diegetic-trace-done'),
                onPressed: _submit,
                child: const Text('fertig'),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const ValueKey('diegetic-trace-skip'),
                onPressed: widget.onSkip,
                child: const Text('weiter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  _InkPainter(this.strokes, this.current);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final stroke in [...strokes, current]) {
      for (var i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter old) => true;
}
