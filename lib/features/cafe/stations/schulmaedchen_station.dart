import 'package:flutter/material.dart';

import '../../../core/db/learning_db.dart';
import '../../../core/db/lexeme_lookup.dart';
import '../../../core/ladder/ladder_review.dart';
import '../../../core/pipeline/knowledge_bridge.dart';
import '../../../core/srs/scheduler.dart';
import '../../story/episode.dart';
import '../../story/speak_evaluator.dart';
import '../bubble_overlay.dart';
import '../cafe_debrief.dart';
import '../cafe_scenes.dart';
import '../cafe_summary.dart';
import '../cafe_turn.dart';
import '../cafe_visit.dart';
import '../kana_keyboard.dart';
import '../word_decomposition.dart';
import 'station_frame.dart';

enum _Kind { hearWrite, seeSpeak }

class _Word {
  final String itemId;
  final LearnItem learn;
  final String writtenForm;
  final String reading;
  final StoryPanel? panel;
  final StoryBubble? bubble;
  final String surface;
  const _Word(this.itemId, this.learn, this.writtenForm, this.reading,
      this.panel, this.bubble, this.surface);
}

/// Station 2 „Abfrage" (Spec §3.2). Gerade Position: Hören→Schreiben auf der
/// Kana-Tastatur; ungerade: Sehen→Sprechen mit ausgeblendetem Wort in der
/// Blase. Zwei Versuche; Bewertung 1. Versuch richtig good, 2. hard, sonst
/// again — genau ein `LadderReview.submit` je Wort (Spec §7). Keine Auswahl,
/// kein Selbsteinschätzen (I1).
class SchulmaedchenStation extends StatefulWidget {
  final LearningDb db;
  final KnowledgeBridge? bridge;
  final String languageId;
  final Episode? episode;
  final List<String> itemIds;
  final int startIndex;
  final Speak speak;
  final SpeakEvaluator evaluator;
  final CafeLight light;
  final void Function(int nextIndex) onPosition;
  final void Function(List<VisitRecord> records) onDone;
  final VoidCallback onLater;
  final double threshold;

  const SchulmaedchenStation({
    super.key,
    required this.db,
    this.bridge,
    required this.languageId,
    required this.episode,
    required this.itemIds,
    required this.startIndex,
    required this.speak,
    required this.evaluator,
    required this.light,
    required this.onPosition,
    required this.onDone,
    required this.onLater,
    this.threshold = 0.6,
  });

  @override
  State<SchulmaedchenStation> createState() => _SchulmaedchenStationState();
}

class _SchulmaedchenStationState extends State<SchulmaedchenStation> {
  late final LadderReview _ladder =
      LadderReview(widget.db, bridge: widget.bridge);
  int _index = 0;
  _Word? _word;
  String _typed = '';
  int _attempts = 0;
  bool _graded = false;
  String? _feedback;
  bool _showTiles = false;
  bool _writeInstead = false; // Sehen→Sprechen ohne Mikro: Tastatur statt Mikro
  final _records = <VisitRecord>[];

  _Kind get _kind => _index.isEven ? _Kind.hearWrite : _Kind.seeSpeak;

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _loadCurrent();
  }

  Future<_Word?> _load(String id) async {
    final found = await loadLexemeWithConcept(widget.db, id);
    final learn = await widget.db.getLearnItem('${widget.languageId}:lexeme:$id');
    if (found == null || learn == null) return null;
    final ep = widget.episode;
    final panel = ep == null ? null : firstAppearancePanel(ep, id);
    StoryBubble? bubble;
    var surface = found.lexeme.writtenForm;
    if (panel != null) {
      for (final b in panel.bubbles) {
        for (final t in b.tokens) {
          if (t.itemId == id) {
            bubble = b;
            surface = t.surface;
            break;
          }
        }
        if (bubble != null) break;
      }
    }
    return _Word(id, learn, found.lexeme.writtenForm, found.lexeme.reading,
        panel, bubble, surface);
  }

  Future<void> _say(String text) async {
    try {
      await widget.speak(text);
    } catch (e) {
      debugPrint('schulmaedchen: Vorlesen fehlgeschlagen: $e');
    }
  }

  Future<void> _loadCurrent() async {
    while (_index < widget.itemIds.length) {
      _Word? w;
      try {
        w = await _load(widget.itemIds[_index]);
      } catch (e) {
        debugPrint('schulmaedchen: Laden fehlgeschlagen: $e');
        w = null; // wie ein Item ohne Lexem: überspringen
      }
      if (w != null) {
        if (!mounted) return;
        setState(() {
          _word = w;
          _typed = '';
          _attempts = 0;
          _graded = false;
          _feedback = null;
          _showTiles = false;
          _writeInstead = false;
        });
        if (_kind == _Kind.hearWrite) await _say(w.reading);
        return;
      }
      _index++;
    }
    if (!mounted) return;
    setState(() => _finished = true); // statt endlosem Spinner
    widget.onDone(List.unmodifiable(_records));
  }

  bool _busy = false;
  bool _finished = false;
  bool _listening = false; // Erkennung läuft: Mikro gesperrt

  Future<void> _grade(bool correct) async {
    if (_busy || _graded) return;
    _busy = true;
    try {
      await _gradeInner(correct);
    } catch (e) {
      debugPrint('schulmaedchen: Bewerten fehlgeschlagen: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> _gradeInner(bool correct) async {
    final w = _word!;
    _attempts++;
    if (correct) {
      final result = _attempts == 1 ? ReviewResult.good : ReviewResult.hard;
      final res = await _ladder.submit(w.learn, result,
          languageCode: widget.languageId.replaceFirst('lang_', ''));
      _records.add(VisitRecord(
          itemId: w.itemId, writtenForm: w.writtenForm,
          outcome: CafeOutcome.correct, firstTry: _attempts == 1,
          dueAt: res.scheduleOutput.dueAt));
      if (!mounted) return;
      setState(() {
        _graded = true;
        _feedback = _attempts == 1 ? 'Ha, gewusst!' : 'Siehst du, geht doch.';
      });
      return;
    }
    if (_attempts == 1) {
      if (!mounted) return;
      setState(() {
        _feedback = 'Nee. Nochmal — aber richtig diesmal.';
        _showTiles = true;
        _typed = '';
      });
      await _say(w.reading);
      return;
    }
    final res = await _ladder.submit(w.learn, ReviewResult.again,
        languageCode: widget.languageId.replaceFirst('lang_', ''));
    _records.add(VisitRecord(
        itemId: w.itemId, writtenForm: w.writtenForm,
        outcome: CafeOutcome.wrong, firstTry: false,
        dueAt: res.scheduleOutput.dueAt));
    if (!mounted) return;
    setState(() {
      _graded = true;
      _feedback = 'Das heißt ${w.reading}. Kommt wieder dran.';
    });
  }

  void _submitTyped() {
    final w = _word!;
    _grade(normalizeKana(_typed) == normalizeKana(w.reading));
  }

  Future<void> _attemptSpeak() async {
    if (_busy || _listening || _graded) return;
    setState(() => _listening = true);
    double score;
    try {
      score = await widget.evaluator.evaluate(_word!.reading);
    } catch (e) {
      debugPrint('schulmaedchen: Erkennung fehlgeschlagen: $e');
      if (!mounted) return;
      // Kein Fehlschlag werten: zum Schreiben ausweichen (Spec §8).
      setState(() {
        _listening = false;
        _writeInstead = true;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _listening = false);
    await _grade(score >= widget.threshold);
  }

  void _next() {
    _index++;
    widget.onPosition(_index);
    setState(() => _word = null);
    _loadCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final w = _word;
    if (w == null) {
      if (_finished) return const Scaffold(body: SizedBox.shrink());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final hearWrite = _kind == _Kind.hearWrite;
    return StationFrame(
      station: CafeStation.schulmaedchen,
      light: widget.light,
      voiceLine: hearWrite ? 'Hör zu und schreib es. Schnell!' : 'Was steht da? Sag es. Los.',
      onNext: _graded ? _next : null,
      onLater: widget.onLater,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hearWrite) ...[
              Row(
                key: const ValueKey('schul-hear-write'),
                children: [
                  TextButton.icon(
                    key: const ValueKey('schul-listen'),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('nochmal hören'),
                    onPressed: () => _say(w.reading),
                  ),
                ],
              ),
              if (!_graded) ...[
                KanaKeyboard(value: _typed, onChanged: (v) => setState(() => _typed = v)),
                FilledButton(
                  key: const ValueKey('schul-submit'),
                  onPressed: _typed.isEmpty ? null : _submitTyped,
                  child: const Text('So heißt es'),
                ),
              ],
            ] else ...[
              if (w.panel != null && w.bubble != null)
                SizedBox(
                  key: const ValueKey('schul-panel'),
                  height: 260,
                  child: PanelWithBubble(
                    panel: w.panel!,
                    bubble: w.bubble!,
                    targetSurface: w.surface,
                    mode: BubbleOverlayMode.blank,
                  ),
                ),
              Row(
                key: const ValueKey('schul-see-speak'),
                children: [
                  FilledButton.tonalIcon(
                    key: const ValueKey('schul-mic'),
                    icon: const Icon(Icons.mic),
                    label: const Text('sagen'),
                    onPressed: _graded || _writeInstead || _listening ? null : _attemptSpeak,
                  ),
                  const SizedBox(width: 8),
                  if (!_graded && !_writeInstead)
                    TextButton(
                      key: const ValueKey('schul-write-instead'),
                      onPressed: () => setState(() => _writeInstead = true),
                      child: const Text('lieber schreiben'),
                    ),
                ],
              ),
              if (_writeInstead && !_graded) ...[
                KanaKeyboard(value: _typed, onChanged: (v) => setState(() => _typed = v)),
                FilledButton(
                  key: const ValueKey('schul-submit'),
                  onPressed: _typed.isEmpty ? null : _submitTyped,
                  child: const Text('So heißt es'),
                ),
              ],
            ],
            if (_showTiles && !_graded)
              Wrap(
                key: const ValueKey('schul-tiles'),
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  for (final u in decompose(w.reading))
                    Chip(label: Text('${u.text} ${u.romaji}')),
                ],
              ),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_feedback!, key: const ValueKey('schul-feedback')),
              ),
          ],
        ),
      ),
    );
  }
}
