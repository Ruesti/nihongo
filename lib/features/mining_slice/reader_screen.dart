import 'package:flutter/material.dart';

import '../../core/language_pack/language_pack.dart';
import '../../core/pipeline/due_in_reading.dart';
import '../../core/text_track/word_tap.dart';
import '../reader/reading_view.dart';
import 'slice_pack.dart';
import 'slice_repository.dart';

/// The reader, one passage at a time. This is a *composition* screen: it
/// owns no vocabulary, scheduling, or Datum logic — it wires the real
/// [ReadingView] (SpanReader + inline review, §7) to the real
/// [SliceRepository] operations. A word tap opens a dictionary sheet; a
/// due item surfaces inline and is graded in place; finishing a passage
/// records an immutable snapshot (§7) and moves on. No route change on
/// grading — the reader is the review surface.
class ReaderScreen extends StatefulWidget {
  final SliceRepository repo;
  final int passageIndex;

  const ReaderScreen({super.key, required this.repo, this.passageIndex = 0});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Future<List<DueCardInView>> _due;
  int _lookups = 0;
  bool _advancing = false;

  SlicePassage get _passage => widget.repo.pack.passages[widget.passageIndex];
  int get _count => widget.repo.pack.passages.length;
  bool get _isLast => widget.passageIndex >= _count - 1;

  @override
  void initState() {
    super.initState();
    _due = widget.repo.dueInView(_passage);
  }

  void _onWordTap(Token token) {
    setState(() => _lookups++);
    final result = widget.repo.tap(token);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _GlossSheet(token: token, result: result),
    );
  }

  Future<void> _finishPassage() async {
    if (_advancing) return;
    setState(() => _advancing = true);
    await widget.repo.finishReading(_passage, lookupCount: _lookups);
    if (!mounted) return;
    if (_isLast) {
      Navigator.of(context).pop(true); // back to the opening, which refreshes
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ReaderScreen(
            repo: widget.repo, passageIndex: widget.passageIndex + 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.repo.pack.workTitle} · ${widget.passageIndex + 1}/$_count'),
      ),
      body: FutureBuilder<List<DueCardInView>>(
        future: _due,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ReadingView(
            tokens: _passage.tokens,
            dueItems: snapshot.data!,
            furiganaByCharStart: _passage.furiganaByCharStart,
            onWordTap: _onWordTap,
            onGrade: (cardId, rating) => widget.repo.grade(cardId, rating),
          );
        },
      ),
      persistentFooterButtons: [
        FilledButton.icon(
          key: const ValueKey('finish-passage'),
          onPressed: _advancing ? null : _finishPassage,
          icon: Icon(_isLast ? Icons.check : Icons.arrow_forward),
          label: Text(_isLast ? 'Fertig gelesen' : 'Nächster Absatz'),
        ),
      ],
    );
  }
}

/// The dictionary sheet behind a word tap (§5). Shows the tapped word,
/// its reading, and its senses — or an honest "no entry" when the word
/// isn't in the (prebaked) dictionary. Never invents a gloss.
class _GlossSheet extends StatelessWidget {
  final Token token;
  final WordTapResult result;

  const _GlossSheet({required this.token, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(token.lemma, style: theme.textTheme.headlineMedium),
            if (token.reading != null && token.reading != token.lemma)
              Text(token.reading!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (!result.isKnownWord)
              Text('Kein Wörterbucheintrag.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
            else
              ...result.senses.take(6).map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• ${s.glosses.take(4).join('; ')}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
