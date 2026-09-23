import 'package:flutter/material.dart';

import 'dictionary.dart';
import 'dictionary_sheet.dart';
import 'diegetic_speak_sheet.dart';
import 'diegetic_trace_sheet.dart';
import 'episode.dart';
import 'panel_geometry.dart';
import 'reader_system_ui.dart';
import 'speak_evaluator.dart';
import 'story_progress_store.dart';
import 'trace_evaluator.dart';

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
/// carrying a `dictionary` interaction automatically
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

  /// Weg von der Endkarte ins Café (Spec Café-Nachbesprechung §3.2). Gesetzt
  /// → die Endkarte zeigt „Ins Café" (primär) und „Später" (zurück); null →
  /// „Zurück zum Lesen" wie bisher. Kein Gate: die Folge gilt in jedem Fall
  /// als gelesen (INV-1).
  final Future<void> Function()? onEnterCafe;

  /// Vollbild beim Lesen (Spec Manga-Vollbild §7.1). Tests injizieren eine
  /// aufzeichnende Attrappe; die App nimmt den `SystemChrome`-Default.
  final ReaderSystemUi systemUi;

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
    this.onEnterCafe,
    this.systemUi = const SystemChromeReaderUi(),
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

  /// Positions whose diegetic speak/trace interaction has succeeded — the
  /// story "reacts" there (P?: reaction image + narration line), swapping
  /// in `reactionAsset`/`reactionCaption` from the panel's interaction.
  /// Without a success (or on skip), the panel stays exactly as authored
  /// (INV-1: no story-critical gate).
  final Set<int> _reactedPositions = {};

  @override
  void initState() {
    super.initState();
    _restorePosition();
  }

  @override
  void dispose() {
    // Zurück-Geste, Café-Wechsel, App-Navigation: Leisten immer wieder her.
    // Doppelt aufgerufen (Endkarte + dispose) ist unschädlich.
    widget.systemUi.exitImmersive();
    super.dispose();
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
      widget.systemUi.enterImmersive();
      _maybeShowDictionary(clamped);
      _maybeFireCompletion(clamped);
    }
  }

  void _beginReading() {
    widget.systemUi.enterImmersive();
    setState(() => _phase = _ReaderPhase.reading);
    _maybeShowDictionary(_position ?? 0);
    _maybeFireCompletion(_position ?? 0);
  }

  void _advance() {
    final current = _position;
    if (current == null) return;
    if (current >= _panels.length - 1) {
      widget.systemUi.exitImmersive();
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

  /// Die diegetische Interaktion des Panels, solange sie noch aussteht (nicht
  /// reagiert) und ihr Bewerter verdrahtet ist. Sie wird als Hinweis-Kasten auf
  /// dem Bild gezeigt; erst ein Tap darauf öffnet das Sprech-/Nachzeichen-Blatt.
  StoryInteraction? _pendingDiegeticOf(StoryPanel panel, int position) {
    if (_reactedPositions.contains(position)) return null;
    final it = _diegeticInteractionOf(panel);
    if (it == null) return null;
    if (it.type == InteractionType.speak && widget.speakEvaluator == null) {
      return null;
    }
    if (it.type == InteractionType.trace && widget.traceEvaluator == null) {
      return null;
    }
    return it;
  }

  StoryInteraction? _diegeticInteractionOf(StoryPanel panel) {
    for (final it in panel.interactions) {
      if (it.diegetic &&
          (it.type == InteractionType.speak ||
              it.type == InteractionType.trace)) {
        return it;
      }
    }
    return null;
  }

  void _markReacted(int position) {
    if (!mounted) return;
    setState(() => _reactedPositions.add(position));
  }

  String _effectiveAssetFor(StoryPanel panel, PanelFormat format) {
    final reacted = _reactedPositions.contains(_position);
    final reaction = _diegeticInteractionOf(panel)?.reactionAssetFor(format);
    return (reacted && reaction != null) ? reaction : panel.assetFor(format);
  }

  /// Format, in dem das von [_effectiveAssetFor] tatsächlich gezeigte Bild
  /// geschnitten ist. Weicht von [format] ab, wenn das angeforderte Hochbild
  /// fehlt — Panel oder Reaktion —: dann liefert `assetFor`/`reactionAssetFor`
  /// das Querbild als Rückfall, und Cover-Rechteck wie Tippflächen müssen
  /// dessen Seitenverhältnis folgen statt des Hochformats (Spec §5.1/§7.4).
  PanelFormat _shownFormatFor(StoryPanel panel, PanelFormat format) {
    if (format != PanelFormat.portrait) return format;
    final reacted = _reactedPositions.contains(_position);
    final interaction = _diegeticInteractionOf(panel);
    final reacting = reacted && interaction?.reactionAssetFor(format) != null;
    final hasPortraitVariant = reacting
        ? interaction!.reactionAssetPortrait != null
        : panel.assetPortrait != null;
    return hasPortraitVariant ? PanelFormat.portrait : PanelFormat.landscape;
  }

  /// Öffnet das Sprech-Blatt — nur auf Tap auf den Hinweis-Kasten, nie automatisch.
  void _openSpeak(int position) {
    final evaluator = widget.speakEvaluator;
    if (evaluator == null) return;
    final panel = _panels[position];
    StoryInteraction? interaction;
    for (final i in panel.interactions) {
      if (i.type == InteractionType.speak && i.diegetic) {
        interaction = i;
        break;
      }
    }
    if (interaction == null) return;

    final derivedItemIds = <String>[
      for (final b in panel.bubbles)
        for (final t in b.tokens)
          if (t.itemId != null) t.itemId!,
    ];
    final targetText = interaction.target ??
        panel.bubbles.map((b) => b.text).join(' ');
    final itemIds = interaction.targetItemIds ?? derivedItemIds;
    final taskText = interaction.promptText;

    if (!mounted) return;
    showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => DiegeticSpeakSheet(
          targetText: targetText,
          evaluator: evaluator,
          speak: widget.speak,
          taskText: taskText,
          onSuccess: () {
            _markReacted(position);
            widget.onDiegeticSpeakSuccess?.call(itemIds);
          },
          onSkip: () => Navigator.of(sheetContext).pop(),
        ),
      );
  }

  /// Öffnet das Nachzeichen-Blatt — nur auf Tap auf den Hinweis-Kasten, nie automatisch.
  void _openTrace(int position) {
    final evaluator = widget.traceEvaluator;
    if (evaluator == null) return;
    final panel = _panels[position];
    StoryInteraction? interaction;
    for (final i in panel.interactions) {
      if (i.type == InteractionType.trace && i.diegetic) {
        interaction = i;
        break;
      }
    }
    if (interaction == null) return;

    // Derive the trace target from tokens (surface + itemId), NOT bubble
    // text — P24 carries an inert margin-note bubble with no tokens that
    // must be excluded. Only used as a fallback when the interaction
    // carries no explicit target/targetItemIds (bisheriges Verhalten).
    final derivedTokens = [
      for (final b in panel.bubbles)
        for (final t in b.tokens)
          if (t.itemId != null) t,
    ];
    if (interaction.target == null && derivedTokens.isEmpty) return;
    final targetText =
        interaction.target ?? derivedTokens.map((t) => t.surface).join();
    final itemIds = interaction.targetItemIds ??
        derivedTokens.map((t) => t.itemId!).toList();
    final taskText = interaction.promptText;

    if (!mounted) return;
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => DiegeticTraceSheet(
          targetText: targetText,
          evaluator: evaluator,
          taskText: taskText,
          onSuccess: () {
            _markReacted(position);
            widget.onDiegeticTraceSuccess?.call(itemIds);
          },
          onSkip: () => Navigator.of(sheetContext).pop(),
        ),
      );
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
      final episode = widget.episode;
      final textTheme = Theme.of(context).textTheme;
      final hasCover = episode.cover != null;
      final onCover = hasCover ? Colors.white : null;

      final texts = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            hasCover ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text('Folge ${episode.orderIndex}',
              style: textTheme.labelLarge?.copyWith(color: onCover)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (episode.titleJa != null) ...[
                Text(episode.titleJa!,
                    key: const ValueKey('story-title-ja'),
                    style: textTheme.displaySmall?.copyWith(color: onCover)),
                const SizedBox(width: 12),
              ],
              Text(episode.title,
                  style: textTheme.headlineMedium?.copyWith(color: onCover)),
            ],
          ),
          if (episode.intro != null) ...[
            const SizedBox(height: 16),
            Text(episode.intro!,
                textAlign: hasCover ? TextAlign.start : TextAlign.center,
                style: TextStyle(color: onCover)),
          ],
          const SizedBox(height: 32),
          Text('Tippe, um zu beginnen',
              style: textTheme.bodySmall?.copyWith(color: onCover)),
        ],
      );

      return Scaffold(
        backgroundColor: hasCover ? Colors.black : null,
        body: GestureDetector(
          key: const ValueKey('story-title-card'),
          behavior: HitTestBehavior.opaque,
          onTap: _beginReading,
          child: hasCover
              ? LayoutBuilder(builder: (context, constraints) {
                  final format = formatForSize(
                      Size(constraints.maxWidth, constraints.maxHeight));
                  return Stack(fit: StackFit.expand, children: [
                    Image.asset(
                      episode.coverFor(format)!,
                      key: const ValueKey('story-title-cover'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: const Color(0xFF1B2220)),
                    ),
                    // Dunkler Verlauf unten, damit der Text auf jedem Motiv
                    // lesbar bleibt (Spec §7.3).
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0xD9000000)],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: texts,
                        ),
                      ),
                    ),
                  ]);
                })
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: texts,
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
                if (widget.onEnterCafe != null) ...[
                  FilledButton(
                    key: const ValueKey('story-end-cafe'),
                    onPressed: () => widget.onEnterCafe!(),
                    child: const Text('Ins Café'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const ValueKey('story-end-done'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Später'),
                  ),
                ] else
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
    final pending = _pendingDiegeticOf(panel, position);
    final reactionCaption = _reactedPositions.contains(_position)
        ? _diegeticInteractionOf(panel)?.reactionCaption
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        key: const ValueKey('story-reader-panel'),
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: LayoutBuilder(builder: (context, constraints) {
          final screen = Size(constraints.maxWidth, constraints.maxHeight);
          final format = formatForSize(screen);
          final shown = _shownFormatFor(panel, format);
          final imageRect = coverRect(screen, aspectOf(shown));
          final asset = _effectiveAssetFor(panel, format);
          final footerBubbles = [
            for (final b in panel.bubbles)
              if (b.hitAreaFor(shown).points.isEmpty) b,
          ];
          return Stack(
            clipBehavior: Clip.hardEdge,
            fit: StackFit.expand,
            children: [
              // Bild im Cover-Rechteck: eine Achse füllt den Schirm, die
              // andere steht symmetrisch über (Spec §3.1/§7.1).
              Positioned.fromRect(
                rect: imageRect,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  // KeyedSubtree mit dem Asset als Key: AnimatedSwitcher
                  // erkennt einen Wechsel nur an einem neuen Key — die
                  // konstante ValueKey('story-panel-image') am Image selbst
                  // (für Tests) hätte den Übergang sonst unterdrückt.
                  child: KeyedSubtree(
                    key: ValueKey(asset),
                    child: Image.asset(
                      asset,
                      key: const ValueKey('story-panel-image'),
                      // AnimatedSwitcher layoutet intern mit einem losen
                      // Stack (StackFit.loose) — ohne explizite Größe würde
                      // sich das Bild an seiner natürlichen Größe statt am
                      // Cover-Rechteck ausrichten, BoxFit.fill liefe leer.
                      width: imageRect.width,
                      height: imageRect.height,
                      fit: BoxFit.fill,
                      errorBuilder: (_, _, _) =>
                          Container(color: const Color(0xFF2A2A2A)),
                    ),
                  ),
                ),
              ),
              // Tippflächen der gelettertern Blasen, relativ zum Bildrechteck.
              for (var i = 0; i < panel.bubbles.length; i++)
                if (panel.bubbles[i].hitAreaFor(shown).points.isNotEmpty)
                  Positioned.fromRect(
                    rect: mapToScreen(
                        _bboxOf(panel.bubbles[i].hitAreaFor(shown)),
                        imageRect),
                    child: GestureDetector(
                      key: ValueKey('story-bubble-hit-$i'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        widget.speak(panel.bubbles[i].text);
                        _openDictionary();
                      },
                    ),
                  ),
              // Bedienung und Erzählstimme über dem Bild, innerhalb der
              // Systemränder (Spec §7.2).
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BackChip(
                            enabled: position > 0,
                            onPressed: _goBack,
                          ),
                          const SizedBox(width: 8),
                          if (panel.thoughts.isNotEmpty)
                            Expanded(
                              // IgnorePointer: reines Fließtext-Feld ohne
                              // eigene Interaktion; Flutters RenderParagraph
                              // beansprucht Taps sonst für sich selbst (auch
                              // ohne Recognizer) und blockt so darunter
                              // liegende Tippflächen der Blasen (Bug,
                              // Folge-01-Panel-1-Fixture: Gedanken-Kasten
                              // überlappt die Tippfläche des Schild-Texts).
                              child: IgnorePointer(
                                child: Container(
                                  key: const ValueKey('story-thought-box'),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xF2FFF8E7),
                                    border: Border.all(
                                        color: const Color(0xFF444444)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (final thought in panel.thoughts)
                                        Text(thought.text,
                                            style: const TextStyle(
                                                fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      if (footerBubbles.isNotEmpty)
                        Container(
                          key: const ValueKey('story-bubble-footer'),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xF2FFFFFF),
                            border: Border.all(color: const Color(0xFF444444)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final bubble in footerBubbles)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: _BubbleContent(
                                      bubble: bubble, speak: widget.speak),
                                ),
                            ],
                          ),
                        ),
                      if (pending != null)
                        GestureDetector(
                          key: const ValueKey('story-diegetic-prompt'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (pending.type == InteractionType.trace) {
                              _openTrace(position);
                            } else {
                              _openSpeak(position);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xF2FFF8E7),
                              border:
                                  Border.all(color: const Color(0xFF444444)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  pending.type == InteractionType.trace
                                      ? Icons.edit
                                      : Icons.mic,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    pending.promptText ??
                                        'Tippen, um mitzumachen',
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                                const Icon(Icons.touch_app, size: 18),
                              ],
                            ),
                          ),
                        ),
                      if (reactionCaption != null)
                        // IgnorePointer: reine Erzählzeile ohne eigene
                        // Interaktion, siehe Gedanken-Kasten oben.
                        IgnorePointer(
                          child: Container(
                            key: const ValueKey('story-reaction-caption'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xF2FFF8E7),
                              border:
                                  Border.all(color: const Color(0xFF444444)),
                            ),
                            child: Text(
                              reactionCaption,
                              style:
                                  const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Zurück als kleiner halbtransparenter Chip oben links (die AppBar entfällt
/// im Vollbild, Spec §7.2). Behält den Key `story-reader-back`, damit der
/// Sperrzustand auf Panel 1 weiter testbar ist.
class _BackChip extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _BackChip({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final chip = DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0x99000000),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        key: const ValueKey('story-reader-back'),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: enabled ? onPressed : null,
      ),
    );
    if (enabled) return chip;
    // Panel 1: gesperrt (onPressed null) — ein deaktivierter IconButton
    // registriert aber gar keinen Recognizer, der Tap fiele sonst durch zum
    // GestureDetector des Panels und würde weiterblättern. Hier schlucken.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: chip,
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
