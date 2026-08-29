import 'package:flutter/material.dart';

import 'episode.dart';
import 'story_progress_store.dart';

/// Default panel aspect ratio (width / height) — matches the default used
/// for the earlier comic-page model (`comic_pack.dart`). Real per-panel
/// dimensions don't exist yet; every panel currently renders the shared
/// placeholder image.
const double _panelAspectRatio = 0.7;

/// Reads an [Episode] panel by panel, tap to advance. No bubble or thought
/// is interactive yet (INV-1: the whole episode must be readable without
/// solving anything) — that begins in a later phase. Resumes from the last
/// panel the reader reached, persisted via [progressStore].
class StoryReaderScreen extends StatefulWidget {
  final Episode episode;
  final StoryProgressStore progressStore;

  const StoryReaderScreen({
    super.key,
    required this.episode,
    required this.progressStore,
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
                        child: Text(bubble.text),
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
