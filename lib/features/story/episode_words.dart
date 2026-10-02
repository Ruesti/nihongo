import 'package:flutter/material.dart';

import 'dictionary.dart';
import 'episode.dart';
import 'notebook_style.dart';

/// Ein Wort der Folge für die Wortliste: der Wörterbuch-Eintrag plus die
/// Kanji-Schreibung, falls eine Blase das Wort als Kanji mit Lesung trägt
/// (駅 zu えき). Der Eintrag selbst führt nur die Kana-Schreibung.
class EpisodeWord {
  final DictionaryEntry entry;
  final String? kanji;
  const EpisodeWord({required this.entry, this.kanji});
}

/// Die Einträge in der Reihenfolge ihres ersten Vorkommens in der Geschichte
/// (Seiten → Panels → Blasen → Wörter); Einträge, die in keiner Blase stehen,
/// folgen hinten in Eintragsreihenfolge.
List<EpisodeWord> episodeWordsInStoryOrder(
    Episode episode, List<DictionaryEntry> entries) {
  final byId = {for (final e in entries) e.id: e};
  final seen = <String>{};
  final words = <EpisodeWord>[];
  for (final page in episode.pages) {
    for (final panel in page.panels) {
      for (final bubble in panel.bubbles) {
        for (final token in bubble.tokens) {
          final id = token.itemId;
          if (id == null) continue;
          final entry = byId[id];
          if (entry == null || !seen.add(id)) continue;
          final isKanji =
              token.reading != null && token.surface != entry.headword;
          words.add(EpisodeWord(
              entry: entry, kanji: isKanji ? token.surface : null));
        }
      }
    }
  }
  for (final e in entries) {
    if (seen.add(e.id)) words.add(EpisodeWord(entry: e));
  }
  return words;
}

/// Die Wortliste der Folge hinter dem Buch-Symbol (Uli, 2.10.): eine
/// Notizbuchseite mit allen Wörtern der Folge in Geschichtsreihenfolge, je
/// Zeile Wort, Bedeutung, Lautsprecher, roter Haken bei Gelerntem. Die
/// Randnotiz des Vorbesitzers (Brief §3.5) bleibt als Bleistift-Kritzelei
/// unter dem Wort. Kein Kana-Blättern, keine versteckten Bedeutungen mehr.
class EpisodeWordList extends StatelessWidget {
  final Episode episode;
  final List<DictionaryEntry> entries;
  final Set<String> knownIds;
  final Future<void> Function(String text) speak;
  final VoidCallback onClose;

  const EpisodeWordList({
    super.key,
    required this.episode,
    required this.entries,
    required this.knownIds,
    required this.speak,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final words = episodeWordsInStoryOrder(episode, entries);
    final titleJa = episode.titleJa;
    return ColoredBox(
      key: const ValueKey('episode-word-list'),
      color: Notebook.paperDark,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('episode-word-list-back'),
                    icon: const Icon(Icons.arrow_back),
                    color: Notebook.ink,
                    tooltip: 'Zurück zur Geschichte',
                    onPressed: onClose,
                  ),
                  const Text('WÖRTER DER FOLGE',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: Notebook.ink2)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x2E1A1410),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: NotebookPaper(
                        topPadding: 18,
                        bottomPadding: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: Notebook.lineHeight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                          'Folge ${episode.orderIndex} · ${episode.title}',
                                          style: Notebook.handBold,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                  if (titleJa != null) ...[
                                    const SizedBox(width: 12),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 5),
                                      child: Text(titleJa,
                                          style: Notebook.ja.copyWith(
                                              fontSize: 26,
                                              color: Notebook.red)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            NotebookLine(
                              '${words.length} Wörter, so wie sie in der Geschichte vorkommen',
                              style: Notebook.hand
                                  .copyWith(fontSize: 19, color: Notebook.ink2),
                            ),
                            for (final w in words) ...[
                              NotebookWordRow(
                                surface: w.kanji ?? w.entry.headword,
                                reading: w.kanji == null ? null : w.entry.headword,
                                meaning: w.entry.meaning,
                                known: knownIds.contains(w.entry.id),
                                onSpeak: () => speak(w.entry.headword),
                                rowKey: ValueKey('episode-word-${w.entry.id}'),
                                speakKey:
                                    ValueKey('episode-word-speak-${w.entry.id}'),
                                knownKey:
                                    ValueKey('episode-word-known-${w.entry.id}'),
                              ),
                              if (w.entry.marginNote != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 24),
                                  child: NotebookLine(
                                    w.entry.marginNote!,
                                    textKey: ValueKey(
                                        'episode-word-note-${w.entry.id}'),
                                    tilt: -0.02,
                                    style: Notebook.hand.copyWith(
                                        fontSize: 15,
                                        color: Notebook.pencil,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
