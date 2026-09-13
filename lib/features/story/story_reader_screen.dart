import 'package:flutter/material.dart';

import 'dictionary.dart';
import 'dictionary_sheet.dart';
import 'diegetic_speak_sheet.dart';
import 'diegetic_trace_sheet.dart';
import 'episode.dart';
import 'speak_evaluator.dart';
import 'story_progress_store.dart';
import 'trace_evaluator.dart';

/// Default panel aspect ratio (width / height) — matches the default used
/// for the earlier comic-page model (`comic_pack.dart`). Real per-panel
/// dimensions don't exist yet; every panel currently renders the shared
/// placeholder image.
const double _panelAspectRatio = 0.7;

/// Axis-aligned bounding box of a bubble's `hitArea` polygon, in the same
/// normalized 0..1 panel space — the tap target is the box, not the exact
/// polygon (good enough until real polygon hit-testing is worth the cost).
Rect _bboxOf(StoryPolygon polygon) {
  var minX = 1.0, minY = 1.0, maxX = 0.0, maxY = 0.0;
  for (final p in polygon.points) {
    if (p.x < minX) minX = p.x;
    if (p.y < minY) minY = p.y;
    if (p.x > maxX) maxX = p.x;
    if (p.y > maxY) maxY = p.y;
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

/// Reads an [Episode] panel by panel, tap to advance. Tapping a lookupable
/// token plays its audio and shows its reading (INV-2: audio + kana, never
/// meaning). Tokens marked `lookupable: false` render as inert text — no
/// tap handler, no visual hint, no lock indicator (INV-7). Resumes from the
/// last panel the reader reached, persisted via [progressStore]. A panel
/// carrying a `dictionary` interaction (e.g. Folge 01's P09) automatically
/// opens [DictionarySheet] as a dismissible sheet — no gate, no forced
/// resolution (INV-1): the reader can dismiss it and keep reading exactly
/// as with any other panel.
class StoryReaderScreen extends StatefulWidget {
  final Episode episode;
  final StoryProgressStore progressStore;
  final Future<void> Function(String text) speak;
  final List<DictionaryEntry> dictionaryEntries;
  final Set<String> knownIds;

  /// Fired exactly once, the first time the reader reaches the final panel of
  /// the episode (P5b — hand the episode's vocabulary to the SRS ladder).
  /// Optional: the reader is fully functional without it (INV-1, no gate) —
  /// nothing about reading depends on this firing. Fire-and-forget: the
  /// returned Future is not awaited, so a slow handoff never blocks reading.
  final Future<void> Function()? onEpisodeComplete;

  /// Scores a spoken attempt at a `diegetic: true` speak panel (P6a). When
  /// null, diegetic-speak panels open no overlay — the reader stays fully
  /// readable standalone (INV-1). The real implementation wraps the mic;
  /// tests inject a fake.
  final SpeakEvaluator? speakEvaluator;

  /// Called with the panel's item ids when a diegetic speak attempt succeeds
  /// (P6a). The caller turns this into the SRS encounter (rung 1). Optional;
  /// the reader never depends on it.
  final Future<void> Function(List<String> itemIds)? onDiegeticSpeakSuccess;

  /// Judges a handwriting attempt at a `diegetic: true` trace panel (P6b).
  /// When null, diegetic-trace panels open no overlay — the reader stays
  /// fully readable standalone (INV-1). Tests inject a fake.
  final TraceEvaluator? traceEvaluator;

  /// Called with the panel's item ids when a diegetic trace attempt is
  /// accepted (P6b). The caller turns this into the SRS encounter (rung 1).
  final Future<void> Function(List<String> itemIds)? onDiegeticTraceSuccess;

  const StoryReaderScreen({
    super.key,
    required this.episode,
    required this.progressStore,
    required this.speak,
    required this.dictionaryEntries,
    required this.knownIds,
    this.onEpisodeComplete,
    this.speakEvaluator,
    this.onDiegeticSpeakSuccess,
    this.traceEvaluator,
    this.onDiegeticTraceSuccess,
  });

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

/// Screen-level phase: a fresh or completed episode opens on the title
/// card, then reads panel by panel, then closes on the end card once the
/// last panel has been tapped again (Spec Reader-Erleben §2.1/§2.6/§2.7).
enum _ReaderPhase { title, reading, end }

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  late final List<StoryPanel> _panels = widget.episode.allPanels.toList();
  int? _position;
  bool _completionFired = false;
  _ReaderPhase _phase = _ReaderPhase.title;

  @override
  void initState() {
    super.initState();
    _restorePosition();
  }

  Future<void> _restorePosition() async {
    final done = await widget.progressStore.isCompleted(widget.episode.id);
    final saved =
        done ? null : await widget.progressStore.lastPosition(widget.episode.id);
    if (!mounted) return;
    final clamped = saved == null ? 0 : saved.clamp(0, _panels.length - 1);
    final resumeMidway = !done && saved != null && clamped > 0;
    setState(() {
      _position = clamped;
      _phase = resumeMidway ? _ReaderPhase.reading : _ReaderPhase.title;
    });
    if (resumeMidway) {
      _maybeShowDictionary(clamped);
      _maybeShowSpeak(clamped);
      _maybeShowTrace(clamped);
      _maybeFireCompletion(clamped);
    }
  }

  void _beginReading() {
    setState(() => _phase = _ReaderPhase.reading);
    _maybeShowDictionary(_position ?? 0);
    _maybeShowSpeak(_position ?? 0);
    _maybeShowTrace(_position ?? 0);
    _maybeFireCompletion(_position ?? 0);
  }

  void _advance() {
    final current = _position;
    if (current == null) return;
    if (current >= _panels.length - 1) {
      setState(() => _phase = _ReaderPhase.end);
      return;
    }
    _goTo(current + 1);
  }

  void _goBack() {
    final current = _position;
    if (current == null || current <= 0) return;
    _goTo(current - 1);
  }

  void _goTo(int position) {
    setState(() => _position = position);
    widget.progressStore.savePosition(widget.episode.id, position);
    _maybeShowDictionary(position);
    _maybeShowSpeak(position);
    _maybeShowTrace(position);
    _maybeFireCompletion(position);
  }

  void _maybeShowDictionary(int position) {
    final panel = _panels[position];
    final hasDictionaryInteraction =
        panel.interactions.any((i) => i.type == InteractionType.dictionary);
    if (!hasDictionaryInteraction) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openDictionary();
    });
  }

  void _openDictionary() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SizedBox(
        key: const ValueKey('dictionary-sheet'),
        height: MediaQuery.of(sheetContext).size.height * 0.7,
        child: DictionarySheet(
          entries: widget.dictionaryEntries,
          knownIds: widget.knownIds,
        ),
      ),
    );
  }

  void _maybeShowSpeak(int position) {
    final evaluator = widget.speakEvaluator;
    if (evaluator == null) return;
    final panel = _panels[position];
    final hasSpeak = panel.interactions
        .any((i) => i.type == InteractionType.speak && i.diegetic);
    if (!hasSpeak) return;

    final targetText = panel.bubbles.map((b) => b.text).join(' ');
    final itemIds = <String>[
      for (final b in panel.bubbles)
        for (final t in b.tokens)
          if (t.itemId != null) t.itemId!,
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => DiegeticSpeakSheet(
          targetText: targetText,
          evaluator: evaluator,
          speak: widget.speak,
          onSuccess: () => widget.onDiegeticSpeakSuccess?.call(itemIds),
          onSkip: () => Navigator.of(sheetContext).pop(),
        ),
      );
    });
  }

  void _maybeShowTrace(int position) {
    final evaluator = widget.traceEvaluator;
    if (evaluator == null) return;
    final panel = _panels[position];
    final hasTrace = panel.interactions
        .any((i) => i.type == InteractionType.trace && i.diegetic);
    if (!hasTrace) return;

    // Derive the trace target from tokens (surface + itemId), NOT bubble
    // text — P24 carries an inert margin-note bubble with no tokens that
    // must be excluded.
    final tokens = [
      for (final b in panel.bubbles)
        for (final t in b.tokens)
          if (t.itemId != null) t,
    ];
    if (tokens.isEmpty) return;
    final targetText = tokens.map((t) => t.surface).join();
    final itemIds = tokens.map((t) => t.itemId!).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => DiegeticTraceSheet(
          targetText: targetText,
          evaluator: evaluator,
          onSuccess: () => widget.onDiegeticTraceSuccess?.call(itemIds),
          onSkip: () => Navigator.of(sheetContext).pop(),
        ),
      );
    });
  }

  void _maybeFireCompletion(int position) {
    if (position < _panels.length - 1 || _completionFired) return;
    _completionFired = true;
    // Fire-and-forget: the reader must not stall reading to wait for a
    // SharedPreferences write, and setBool practically never throws.
    widget.progressStore.markCompleted(widget.episode.id);
    widget.onEpisodeComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    if (position == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_phase == _ReaderPhase.title) {
      return Scaffold(
        body: GestureDetector(
          key: const ValueKey('story-title-card'),
          behavior: HitTestBehavior.opaque,
          onTap: _beginReading,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.episode.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  if (widget.episode.intro != null) ...[
                    const SizedBox(height: 16),
                    Text(widget.episode.intro!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 32),
                  Text('Tippe, um zu beginnen',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_phase == _ReaderPhase.end) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              key: const ValueKey('story-end-card'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Ende der Folge',
                    style: Theme.of(context).textTheme.titleLarge),
                if (widget.episode.outro != null) ...[
                  const SizedBox(height: 16),
                  Text(widget.episode.outro!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  key: const ValueKey('story-end-done'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Zurück zum Lesen'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final panel = _panels[position];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.episode.title),
        leading: IconButton(
          key: const ValueKey('story-reader-back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: position > 0 ? _goBack : null,
        ),
      ),
      body: GestureDetector(
        key: const ValueKey('story-reader-panel'),
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: SingleChildScrollView(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: _panelAspectRatio,
                child: LayoutBuilder(builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Stack(fit: StackFit.expand, children: [
                    Image.asset(
                      panel.asset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: const Color(0xFFEDEDED)),
                    ),
                    if (panel.thoughts.isNotEmpty)
                      Positioned(
                        top: 8, left: 8, right: 8,
                        child: Container(
                          key: const ValueKey('story-thought-box'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xF2FFF8E7),
                            border: Border.all(color: const Color(0xFF444444)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final thought in panel.thoughts)
                                Text(thought.text,
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ),
                    for (var i = 0; i < panel.bubbles.length; i++)
                      if (panel.bubbles[i].hitArea.points.isNotEmpty)
                        Positioned(
                          left: _bboxOf(panel.bubbles[i].hitArea).left * w,
                          top: _bboxOf(panel.bubbles[i].hitArea).top * h,
                          width: _bboxOf(panel.bubbles[i].hitArea).width * w,
                          height: _bboxOf(panel.bubbles[i].hitArea).height * h,
                          child: GestureDetector(
                            key: ValueKey('story-bubble-hit-$i'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              widget.speak(panel.bubbles[i].text);
                              _openDictionary();
                            },
                          ),
                        ),
                  ]);
                }),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final bubble in panel.bubbles)
                      if (bubble.hitArea.points.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _BubbleContent(
                            bubble: bubble,
                            speak: widget.speak,
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders one bubble's content. A bubble with no tokens (e.g. an
/// environmental note with nothing tappable in it) renders as plain text,
/// unchanged from phase P2. Otherwise each token renders individually:
/// lookupable tokens are tappable and play audio (INV-2); non-lookupable
/// tokens render as inert text with no gesture handler at all (INV-7 — not
/// merely disabled, but genuinely absent as an interactive element, so a
/// tap on one falls through to the panel's own advance gesture, same as
/// tapping empty space). Text between/after tokens is reconstructed from
/// `bubble.text` so punctuation isn't lost (phase P3 fix).
class _BubbleContent extends StatelessWidget {
  final StoryBubble bubble;
  final Future<void> Function(String text) speak;

  const _BubbleContent({required this.bubble, required this.speak});

  @override
  Widget build(BuildContext context) {
    if (bubble.tokens.isEmpty) {
      return Text(bubble.text);
    }
    final spans = <Widget>[];
    var cursor = 0;
    for (final token in bubble.tokens) {
      final start = bubble.text.indexOf(token.surface, cursor);
      if (start >= 0) {
        if (start > cursor) {
          spans.add(Text(bubble.text.substring(cursor, start)));
        }
        cursor = start + token.surface.length;
      }
      spans.add(_tokenWidget(context, token));
    }
    if (cursor < bubble.text.length) {
      spans.add(Text(bubble.text.substring(cursor)));
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: spans,
    );
  }

  Widget _tokenWidget(BuildContext context, StoryToken token) {
    final content = token.reading == null
        ? Text(token.surface)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                token.reading!,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(token.surface),
            ],
          );

    if (!token.lookupable) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => speak(token.surface),
      child: content,
    );
  }
}
