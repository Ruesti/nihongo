import 'package:flutter/material.dart';

import '../kanji_games/trace/kanji_svg_loader.dart';
import '../kanji_games/trace/stroke_painter.dart';
import '../kanji_games/trace/stroke_validator.dart';

/// Interactive "trace the character" beat (nachzeichnen). Loads the KanjiVG
/// reference strokes, shows them as a faint guide, and lets the learner draw
/// each stroke; a stroke is accepted when it is close enough to the reference
/// (StrokeValidator). Calls [onDone] when all strokes are traced — or
/// immediately if the asset has no strokes (graceful degrade).
class TracePractice extends StatefulWidget {
  final String assetPath;
  final VoidCallback onDone;
  const TracePractice({super.key, required this.assetPath, required this.onDone});

  @override
  State<TracePractice> createState() => _TracePracticeState();
}

const double _canvas = 300;

class _TracePracticeState extends State<TracePractice> {
  List<List<Offset>>? _reference; // null while loading
  bool _resolved = false;
  final List<List<Offset>> _userStrokes = [];
  List<Offset> _current = [];
  int _completed = 0;
  String? _hint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final strokes =
        await KanjiSvgLoader.loadStrokes(widget.assetPath, canvasSize: _canvas);
    if (!mounted) return;
    if (strokes == null || strokes.isEmpty) {
      widget.onDone(); // nothing to trace → degrade
      return;
    }
    setState(() {
      _reference = strokes;
      _resolved = true;
    });
  }

  void _onPanStart(DragStartDetails d) {
    if (_reference == null) return;
    _current = [d.localPosition];
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_reference == null) return;
    setState(() => _current = [..._current, d.localPosition]);
  }

  void _onPanEnd(DragEndDetails d) {
    final ref = _reference;
    if (ref == null || _completed >= ref.length) return;
    final target = ref[_completed];
    if (StrokeValidator.isAcceptable(_current, target)) {
      setState(() {
        _userStrokes.add(_current);
        _current = [];
        _completed++;
        _hint = null;
      });
      if (_completed >= ref.length) widget.onDone();
    } else {
      setState(() {
        _hint = StrokeValidator.directionHint(_current, target) ??
            'Noch mal versuchen';
        _current = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return const SizedBox(
        height: _canvas,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final ref = _reference!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Fahr das Zeichen nach — Strich ${_completed + 1} von ${ref.length}',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Container(
            width: _canvas,
            height: _canvas,
            decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
            child: CustomPaint(
              painter: StrokePainter(
                referenceStrokes: ref,
                userStrokes: [..._userStrokes, if (_current.isNotEmpty) _current],
                completedStrokes: _completed,
                showGuide: true,
                highlightStroke: _completed < ref.length ? _completed : null,
              ),
            ),
          ),
        ),
        if (_hint != null) ...[
          const SizedBox(height: 8),
          Text(_hint!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
