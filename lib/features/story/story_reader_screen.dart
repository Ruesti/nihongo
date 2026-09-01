import 'package:flutter/material.dart';

import 'dictionary.dart';
import 'dictionary_sheet.dart';
import 'episode.dart';
import 'story_progress_store.dart';

/// Default panel aspect ratio (width / height) — matches the default used
/// for the earlier comic-page model (`comic_pack.dart`). Real per-panel
/// dimensions don't exist yet; every panel currently renders the shared
/// placeholder image.
const double _panelAspectRatio = 0.7;

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

  const StoryReaderScreen({
    super.key,
    required this.episode,
    required this.progressStore,
    required this.speak,
    required this.dictionaryEntries,
    required this.knownIds,
  });

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  late final List<StoryPanel> _panels = widget.episode.allPanels.toList();
  int? _position;

  @override
  void initState() {
    super.initState();
    _restorePosition();
  }

  Future<void> _restorePosition() async {
    final saved = await widget.progressStore.lastPosition(widget.episode.id);
    if (!mounted) return;
    final clamped = saved == null ? 0 : saved.clamp(0, _panels.length - 1);
    setState(() => _position = clamped);
    _maybeShowDictionary(clamped);
  }

  void _advance() {
    final current = _position;
    if (current == null || current >= _panels.length - 1) return;
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
  }

  void _maybeShowDictionary(int position) {
    final panel = _panels[position];
    final hasDictionaryInteraction =
        panel.interactions.any((i) => i.type == InteractionType.dictionary);
    if (!hasDictionaryInteraction) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    if (position == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
                child: Image.asset(
                  panel.asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: const Color(0xFFEDEDED)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final thought in panel.thoughts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          thought.text,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    for (final bubble in panel.bubbles)
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
