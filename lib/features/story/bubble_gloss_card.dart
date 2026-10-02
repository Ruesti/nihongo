import 'package:flutter/material.dart';

import 'dictionary.dart';
import 'episode.dart';
import 'notebook_style.dart';

/// Die Wörterkarte zu einer Sprechblase (Uli, 2.10.): nach dem Tipp auf die
/// Blase liest die App vor und schiebt diese Karte hoch — der Blasentext groß
/// mit „anhören", darunter je nachschlagbarem Wort eine Zeile: Japanisch,
/// deutsche Bedeutung, Lautsprecher. Ersetzt das Kana-Blätter-Wörterbuch,
/// dessen Reihen-Index nach einem Blasen-Tipp wie zufällige Zeichen ohne Bezug
/// zum Gesprochenen wirkte. Wörter ohne Eintrag fallen weg, Dubletten zählen
/// einmal, in der Reihenfolge der Blase.
class BubbleGlossCard extends StatelessWidget {
  final StoryBubble bubble;
  final List<DictionaryEntry> entries;
  final Set<String> knownIds;
  final Future<void> Function(String text) speak;

  /// „alle Wörter der Folge" — null blendet den Sprung aus.
  final VoidCallback? onShowAll;

  const BubbleGlossCard({
    super.key,
    required this.bubble,
    required this.entries,
    required this.knownIds,
    required this.speak,
    this.onShowAll,
  });

  List<({StoryToken token, DictionaryEntry entry})> get _rows {
    final byId = {for (final e in entries) e.id: e};
    final seen = <String>{};
    final rows = <({StoryToken token, DictionaryEntry entry})>[];
    for (final t in bubble.tokens) {
      final id = t.itemId;
      if (id == null || !seen.add(id)) continue;
      final entry = byId[id];
      if (entry == null) continue;
      rows.add((token: t, entry: entry));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return NotebookPaper(
      key: const ValueKey('bubble-gloss-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SPRECHBLASE', style: Notebook.label),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x596B5F52),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: Notebook.lineHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(bubble.text,
                        style: Notebook.ja.copyWith(fontSize: 26),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: OutlinedButton.icon(
                    key: const ValueKey('bubble-gloss-listen'),
                    onPressed: () => speak(bubble.text),
                    icon: const Icon(Icons.volume_up, size: 16),
                    label: const Text('anhören'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Notebook.red,
                      backgroundColor: const Color(0xFFFAF6EE),
                      side: const BorderSide(color: Notebook.line),
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (rows.isEmpty)
            NotebookLine(
              'Hier gibt es nichts nachzuschlagen.',
              textKey: const ValueKey('bubble-gloss-empty'),
              style: Notebook.hand.copyWith(
                  fontSize: 19, color: Notebook.ink2),
            ),
          for (final r in rows)
            NotebookWordRow(
              surface: r.token.surface,
              reading: r.token.reading,
              meaning: r.entry.meaning,
              known: knownIds.contains(r.entry.id),
              onSpeak: () => speak(r.token.surface),
              rowKey: ValueKey('bubble-gloss-row-${r.entry.id}'),
              speakKey: ValueKey('bubble-gloss-speak-${r.entry.id}'),
              knownKey: ValueKey('bubble-gloss-known-${r.entry.id}'),
            ),
          if (onShowAll != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('bubble-gloss-all-words'),
                onPressed: onShowAll,
                style: TextButton.styleFrom(
                  foregroundColor: Notebook.red,
                  minimumSize: const Size(0, 44),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text('alle Wörter der Folge',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: Notebook.handFont,
                              fontSize: 19,
                              fontVariations: [FontVariation('wght', 500)])),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
