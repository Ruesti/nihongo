import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';

Map<String, dynamic> _base() => {
      'id': 'ep_x',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [],
    };

void main() {
  test('Episode.debrief parst Gebrauch und Varianten je Item', () {
    final episode = Episode.fromJson({
      ..._base(),
      'debrief': {
        'lex_ja_ame': {
          'usage': 'Regen. Das Wort vom Zettel.',
          'variants': [
            {
              'form': 'おおあめ',
              'reading': 'おおあめ',
              'meaning': 'starker Regen',
              'note': 'wenn es schüttet',
            },
          ],
        },
      },
    });
    final note = episode.debrief['lex_ja_ame']!;
    expect(note.usage, 'Regen. Das Wort vom Zettel.');
    expect(note.variants, hasLength(1));
    expect(note.variants.single.form, 'おおあめ');
    expect(note.variants.single.meaning, 'starker Regen');
    expect(note.variants.single.note, 'wenn es schüttet');
  });

  test('fehlender debrief-Block → leere Map; fehlende Varianten → leere '
      'Liste; fehlende Lesung → Form', () {
    expect(Episode.fromJson(_base()).debrief, isEmpty);
    final note = DebriefNote.fromJson({'usage': 'x'});
    expect(note.variants, isEmpty);
    final v = DebriefVariant.fromJson({'form': 'どうも', 'meaning': 'danke, kurz'});
    expect(v.reading, 'どうも');
    expect(v.note, isNull);
  });
}
