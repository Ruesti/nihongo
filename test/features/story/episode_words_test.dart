import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/dictionary.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episode_words.dart';

const _entries = [
  DictionaryEntry(id: 'lex_ja_hai', headword: 'はい', meaning: 'ja'),
  DictionaryEntry(
      id: 'lex_ja_ame',
      headword: 'あめ',
      meaning: 'Regen',
      marginNote: 'unleserliche Notiz'),
  DictionaryEntry(id: 'lex_ja_eki', headword: 'えき', meaning: 'Bahnhof'),
  DictionaryEntry(id: 'lex_ja_kore', headword: 'これ', meaning: 'das hier'),
  DictionaryEntry(id: 'lex_ja_kasa', headword: 'かさ', meaning: 'Schirm'),
  DictionaryEntry(
      id: 'lex_ja_mise', headword: 'みせ', meaning: 'Laden, Geschäft'),
];

/// Zwei Panels: Schild mit 駅, dann zwei Blasen (これ？かさ？みせ！ und
/// あめ、あめ！). はい kommt in keiner Blase vor.
Episode _episode() => Episode.fromJson({
      'id': 'ep_words',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Regen',
      'titleJa': '雨',
      'locale': 'ja',
      'era': '1996',
      'budget': {'items': [], 'glyphs': []},
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'assets/story/p01.jpg',
              'bubbles': [
                {
                  'speakerId': 'signage',
                  'text': 'みなみまち駅',
                  'tokens': [
                    {'surface': '駅', 'reading': 'えき', 'itemId': 'lex_ja_eki'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 1,
              'asset': 'assets/story/p02.jpg',
              'bubbles': [
                {
                  'speakerId': 'mira',
                  'text': 'これ？かさ？みせ！',
                  'tokens': [
                    {'surface': 'これ', 'itemId': 'lex_ja_kore'},
                    {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                    {'surface': 'みせ', 'itemId': 'lex_ja_mise'},
                  ],
                },
                {
                  'speakerId': 'mira',
                  'text': 'あめ、あめ！',
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    });

void main() {
  group('episodeWordsInStoryOrder', () {
    test('ordnet die Einträge nach erstem Vorkommen in der Geschichte, '
        'Rest hinten dran', () {
      final words = episodeWordsInStoryOrder(_episode(), _entries);
      expect(
        words.map((w) => w.entry.id).toList(),
        ['lex_ja_eki', 'lex_ja_kore', 'lex_ja_kasa', 'lex_ja_mise', 'lex_ja_ame', 'lex_ja_hai'],
      );
    });

    test('merkt sich die Kanji-Schreibung, wenn die Blase eine hat', () {
      final words = episodeWordsInStoryOrder(_episode(), _entries);
      final eki = words.firstWhere((w) => w.entry.id == 'lex_ja_eki');
      final kore = words.firstWhere((w) => w.entry.id == 'lex_ja_kore');
      expect(eki.kanji, '駅');
      expect(kore.kanji, isNull);
    });
  });

  group('EpisodeWordList', () {
    Future<List<String>> pump(WidgetTester tester,
        {Set<String> known = const {}, VoidCallback? onClose}) async {
      final spoken = <String>[];
      await tester.pumpWidget(MaterialApp(
        home: EpisodeWordList(
          episode: _episode(),
          entries: _entries,
          knownIds: known,
          speak: (t) async => spoken.add(t),
          onClose: onClose ?? () {},
        ),
      ));
      await tester.pump();
      return spoken;
    }

    testWidgets('Kopf: Folge, Titel, japanischer Titel, Wortzahl',
        (tester) async {
      await pump(tester);
      expect(find.byKey(const ValueKey('episode-word-list')), findsOneWidget);
      expect(find.text('Folge 1 · Regen'), findsOneWidget);
      expect(find.text('雨'), findsOneWidget);
      expect(find.textContaining('6 Wörter'), findsOneWidget);
    });

    testWidgets('Zeilen in Geschichtsreihenfolge, Kanji mit Lesung, Haken, '
        'Randnotiz', (tester) async {
      await pump(tester, known: {'lex_ja_kasa'});

      final eki = tester.getTopLeft(find.byKey(const ValueKey('episode-word-lex_ja_eki')));
      final hai = tester.getTopLeft(find.byKey(const ValueKey('episode-word-lex_ja_hai')));
      expect(eki.dy, lessThan(hai.dy));

      expect(find.text('駅'), findsOneWidget);
      expect(find.text('えき'), findsOneWidget);
      expect(find.byKey(const ValueKey('episode-word-known-lex_ja_kasa')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('episode-word-known-lex_ja_kore')),
          findsNothing);
      expect(find.byKey(const ValueKey('episode-word-note-lex_ja_ame')),
          findsOneWidget);
      expect(find.text('unleserliche Notiz'), findsOneWidget);
    });

    testWidgets('Lautsprecher spricht das Wort, Zurück ruft onClose',
        (tester) async {
      var closed = 0;
      final spoken = await pump(tester, onClose: () => closed++);

      await tester.tap(find.byKey(const ValueKey('episode-word-speak-lex_ja_kore')));
      expect(spoken, ['これ']);

      await tester.tap(find.byKey(const ValueKey('episode-word-list-back')));
      expect(closed, 1);
    });
  });
}
