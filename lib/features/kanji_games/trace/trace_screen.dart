import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database.dart';
import '../../../core/srs.dart';
import '../../../models/srs_card.dart';
import '../../../core/theme.dart';
import '../../../core/tts_service.dart';
import '../kanji_data.dart';
import 'kanji_svg_loader.dart';
import 'stroke_painter.dart';
import 'stroke_validator.dart';

enum _Difficulty { easy, medium, hard }

class TraceScreen extends ConsumerStatefulWidget {
  final KanjiEntry kanji;

  const TraceScreen({super.key, required this.kanji});

  @override
  ConsumerState<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends ConsumerState<TraceScreen> {
  List<List<Offset>>? _referenceStrokes;
  final List<List<Offset>> _userStrokes = [];
  List<Offset> _currentStroke = [];
  int _completedStrokes = 0;
  bool _showGuide = true;
  _Difficulty _difficulty = _Difficulty.easy;
  bool _loading = true;
  bool _done = false;
  int _goodStrokes = 0;
  String? _hintMessage;
  bool _showingError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final strokes = await KanjiSvgLoader.loadStrokes(
      widget.kanji.svgAssetPath,
      canvasSize: 300,
    );
    setState(() {
      _referenceStrokes = strokes ?? [];
      _loading = false;
    });
  }

  void _onPanStart(DragStartDetails d) {
    _currentStroke = [d.localPosition];
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _currentStroke.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails d) {
    if (_currentStroke.length < 3) {
      setState(() => _currentStroke = []);
      return;
    }
    _validateStroke();
  }

  void _validateStroke() {
    final ref = _referenceStrokes;
    if (ref == null || ref.isEmpty) {
      // No SVG available — accept all strokes freely
      setState(() {
        _userStrokes.add(List.from(_currentStroke));
        _completedStrokes++;
        _goodStrokes++;
        _currentStroke = [];
      });
      if (_completedStrokes >= widget.kanji.strokeCount) _finish();
      return;
    }

    if (_completedStrokes >= ref.length) {
      _finish();
      return;
    }

    final refStroke = ref[_completedStrokes];
    final hint = StrokeValidator.directionHint(_currentStroke, refStroke);
    final ok = StrokeValidator.isAcceptable(_currentStroke, refStroke);

    if (ok) {
      setState(() {
        _userStrokes.add(List.from(_currentStroke));
        _completedStrokes++;
        _goodStrokes++;
        _currentStroke = [];
        _hintMessage = null;
        _showingError = false;
      });
      if (_completedStrokes >= ref.length) {
        _finish();
      }
    } else {
      setState(() {
        _hintMessage = hint ?? 'Nochmal versuchen';
        _showingError = true;
        _currentStroke = [];
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _showingError = false);
      });
    }
  }

  void _finish() {
    setState(() => _done = true);
    _recordInSrs();
    TtsService.instance.speak(widget.kanji.onyomi.split('、').first);
  }

  Future<void> _recordInSrs() async {
    final db = ref.read(dbProvider);
    final total =
        _referenceStrokes?.length ?? widget.kanji.strokeCount;
    final accuracy = total > 0 ? _goodStrokes / total : 1.0;
    final correct = accuracy >= 0.7;

    final existing = await db.getSrsCard(widget.kanji.cardId);
    if (existing == null) {
      await db.upsertSrsCard(SrsCard(
        id: 0,
        cardId: widget.kanji.cardId,
        front: widget.kanji.kanji,
        back: widget.kanji.meaningDe,
        reading: widget.kanji.kunyomi,
        ease: 2.5,
        interval: 0,
        reps: correct ? 1 : 0,
        dueAt: correct
            ? DateTime.now()
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch
            : DateTime.now().millisecondsSinceEpoch,
        cardType: 'kanji',
        languageCode: 'ja',
      ));
    } else {
      await db.upsertSrsCard(srsGrade(existing, correct ? 2 : 0));
    }
  }

  int get _totalStrokes =>
      _referenceStrokes?.length ?? widget.kanji.strokeCount;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (_done) return _DoneScreen(kanji: widget.kanji, goodStrokes: _goodStrokes, totalStrokes: _totalStrokes);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.kanji.kanji} — Schreiben'),
        actions: [
          IconButton(
            icon: Icon(_showGuide ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _showGuide = !_showGuide),
            tooltip: 'Vorlage',
          ),
          PopupMenuButton<_Difficulty>(
            onSelected: (d) => setState(() => _difficulty = d),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: _Difficulty.easy, child: Text('Einfach (Vorlage)')),
              const PopupMenuItem(
                  value: _Difficulty.medium, child: Text('Mittel')),
              const PopupMenuItem(
                  value: _Difficulty.hard, child: Text('Schwer')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.paper2,
            child: Row(
              children: [
                Text(
                  widget.kanji.meaningDe,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  'Strich $_completedStrokes / $_totalStrokes',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.ink2),
                ),
              ],
            ),
          ),
          if (_hintMessage != null)
            AnimatedOpacity(
              opacity: _showingError ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: AppColors.red.withOpacity(0.1),
                child: Text(
                  _hintMessage!,
                  style: TextStyle(
                      color: AppColors.red, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // Canvas
          Expanded(
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: StrokePainter(
                        referenceStrokes: _referenceStrokes ?? [],
                        userStrokes: [
                          ..._userStrokes,
                          if (_currentStroke.isNotEmpty) _currentStroke,
                        ],
                        completedStrokes: _completedStrokes,
                        showGuide: _showGuide &&
                            _difficulty != _Difficulty.hard,
                        highlightStroke: _completedStrokes <
                                (_referenceStrokes?.length ?? 0)
                            ? _completedStrokes
                            : null,
                      ),
                      size: const Size(300, 300),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom: readings + clear
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'On: ${widget.kanji.onyomi}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Kun: ${widget.kanji.kunyomi}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _userStrokes.clear();
                          _currentStroke = [];
                          _completedStrokes = 0;
                          _goodStrokes = 0;
                        }),
                        child: const Text('Löschen'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            TtsService.instance.speak(widget.kanji.kanji),
                        child: const Text('Anhören'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneScreen extends StatelessWidget {
  final KanjiEntry kanji;
  final int goodStrokes;
  final int totalStrokes;

  const _DoneScreen({
    required this.kanji,
    required this.goodStrokes,
    required this.totalStrokes,
  });

  int get _brushes {
    final ratio = totalStrokes > 0 ? goodStrokes / totalStrokes : 1.0;
    if (ratio >= 0.9) return 3;
    if (ratio >= 0.7) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fertig!')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(kanji.kanji, style: AppTheme.jpLarge.copyWith(fontSize: 96)),
              const SizedBox(height: 16),
              Text(
                kanji.meaningDe,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Text(
                '${'🖌' * _brushes}${'  ' * (3 - _brushes)}',
                style: const TextStyle(fontSize: 36),
              ),
              Text(
                '$goodStrokes / $totalStrokes Striche korrekt',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.ink2),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final next = (kanjiN5.toList()..shuffle()).first;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => TraceScreen(kanji: next),
                      ),
                    );
                  },
                  child: const Text('Nächstes Kanji'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Zurück'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
