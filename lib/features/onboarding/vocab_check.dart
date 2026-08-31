import 'package:flutter/material.dart';

import '../../core/db/learning_db.dart';
import '../../l10n/app_localizations.dart';

/// One word offered in the micro-check.
class VocabCheckItem {
  final String lexemeId;
  final String writtenForm;
  final String reading;
  final String meaning;
  const VocabCheckItem({
    required this.lexemeId,
    required this.writtenForm,
    required this.reading,
    required this.meaning,
  });
}

/// The seeded lexemes of a language, as check items (word + reading + meaning).
/// Small today (the JA seed has 5), grows with the pack — language-agnostic.
Future<List<VocabCheckItem>> loadVocabCheckItems(
  LearningDb db,
  String languageId, {
  int limit = 12,
}) async {
  final lexemes = await (db.select(db.lexemes)
        ..where((t) => t.languageId.equals(languageId))
        ..limit(limit))
      .get();
  final items = <VocabCheckItem>[];
  for (final lex in lexemes) {
    final concept = await (db.select(db.concepts)
          ..where((t) => t.id.equals(lex.conceptId)))
        .getSingleOrNull();
    items.add(VocabCheckItem(
      lexemeId: lex.id,
      writtenForm: lex.writtenForm,
      reading: lex.reading,
      meaning: concept?.glossKey ?? '',
    ));
  }
  return items;
}

/// Presents each word once; the learner marks "Kenne ich" / "Neu für mich".
/// Only confirmed words are returned — the honesty invariant (never mark
/// unconfirmed knowledge known).
class VocabCheckStep extends StatefulWidget {
  final List<VocabCheckItem> items;
  final void Function(List<String> knownLexemeIds) onDone;
  const VocabCheckStep({super.key, required this.items, required this.onDone});

  @override
  State<VocabCheckStep> createState() => _VocabCheckStepState();
}

class _VocabCheckStepState extends State<VocabCheckStep> {
  final List<String> _known = [];
  int _index = 0;

  void _answer(bool knows) {
    if (knows) _known.add(widget.items[_index].lexemeId);
    if (_index + 1 >= widget.items.length) {
      widget.onDone(List.of(_known));
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (widget.items.isEmpty) {
      // Nothing to check — resolve immediately on first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone(const []));
      return const SizedBox.shrink();
    }
    final item = widget.items[_index];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.vocabCheckIntro,
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(item.writtenForm,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(item.reading, textAlign: TextAlign.center),
              const Spacer(),
              FilledButton(
                onPressed: () => _answer(true),
                child: Text(l.vocabCheckKnow),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _answer(false),
                child: Text(l.vocabCheckDont),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
