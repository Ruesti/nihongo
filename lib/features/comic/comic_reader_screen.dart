import 'package:flutter/material.dart';

import '../../core/language_pack/language_pack.dart';
import '../../core/text_track/word_tap.dart';
import '../../l10n/app_localizations.dart';
import 'comic_pack.dart';
import 'comic_repository.dart';
import 'spatial_reader.dart';

/// Reads a comic: the current i+1 page rendered spatially, a gloss sheet on
/// L2 tap, and a "next" action that snapshots progress and advances.
class ComicReaderScreen extends StatefulWidget {
  final ComicRepository repo;
  final TextDirection direction;

  const ComicReaderScreen({
    super.key,
    required this.repo,
    required this.direction,
  });

  @override
  State<ComicReaderScreen> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends State<ComicReaderScreen> {
  late Future<ComicPage?> _page = widget.repo.nextPage();
  int _lookups = 0;

  void _onWordTap(Token token) {
    setState(() => _lookups++);
    final result = widget.repo.tap(token);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _GlossSheet(token: token, result: result),
    );
  }

  Future<void> _finish(ComicPage page) async {
    await widget.repo.finishPage(page, lookups: _lookups);
    if (!mounted) return;
    setState(() {
      _lookups = 0;
      _page = widget.repo.nextPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.repo.pack.title)),
      body: FutureBuilder<ComicPage?>(
        future: _page,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final page = snapshot.data;
          if (page == null) {
            return const Center(child: Text('—'));
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SpatialReader(
                    page: page,
                    direction: widget.direction,
                    onWordTap: _onWordTap,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      persistentFooterButtons: [
        FutureBuilder<ComicPage?>(
          future: _page,
          builder: (context, snapshot) {
            final page = snapshot.data;
            return FilledButton.icon(
              key: const ValueKey('finish-comic-page'),
              onPressed: page == null ? null : () => _finish(page),
              icon: const Icon(Icons.arrow_forward),
              label: Text(AppLocalizations.of(context)!.continueLabel),
            );
          },
        ),
      ],
    );
  }
}

class _GlossSheet extends StatelessWidget {
  final Token token;
  final WordTapResult result;
  const _GlossSheet({required this.token, required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(token.lemma, style: Theme.of(context).textTheme.headlineSmall),
          if (token.reading != null) Text(token.reading!),
          const SizedBox(height: 12),
          if (!result.isKnownWord)
            const Text('—')
          else
            for (final s in result.senses) Text(s.glosses.join(', ')),
        ],
      ),
    );
  }
}
