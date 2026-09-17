import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episode_validator.dart';

Map<String, dynamic> _panel(int index, List<Map<String, dynamic>> tokens) => {
      'index': index,
      'asset': 'assets/story/p0$index.jpg',
      'bubbles': [
        {
          'speakerId': 'x',
          'text': tokens.map((t) => t['surface']).join(),
          'tokens': tokens,
        },
      ],
      'thoughts': [],
      'interactions': [],
    };

Map<String, dynamic> _episode({Map<String, dynamic>? debrief}) => {
      'id': 'ep_v',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
          {'id': 'lex_ja_hai', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      if (debrief != null) 'debrief': debrief,
      'pages': [
        {
          'index': 0,
          'panels': [
            _panel(0, [
              {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
              {'surface': 'はい', 'itemId': 'lex_ja_hai'},
            ]),
            _panel(1, [
              {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
              {'surface': 'はい', 'itemId': 'lex_ja_hai'},
            ]),
          ],
        },
      ],
    };

List<String> _violations(Map<String, dynamic> json) {
  try {
    validateEpisode(Episode.fromJson(json));
    return const [];
  } on StoryValidationException catch (e) {
    return e.violations;
  }
}

void main() {
  test('ein gültiger Erklärungsblock (Budget-Item, ≤2 Varianten, fremde '
      'Formen) passiert', () {
    expect(
        _violations(_episode(debrief: {
          'lex_ja_ame': {
            'usage': 'Regen.',
            'variants': [
              {'form': 'おおあめ', 'reading': 'おおあめ', 'meaning': 'starker Regen'},
              {'form': 'あまぐも', 'reading': 'あまぐも', 'meaning': 'Regenwolke'},
            ],
          },
        })),
        isEmpty);
  });

  test('Debrief für ein Item außerhalb des Budgets ist ein Verstoß', () {
    final v = _violations(_episode(debrief: {
      'lex_ja_himitsu': {'usage': 'geheim'},
    }));
    expect(v, hasLength(1));
    expect(v.single, contains('lex_ja_himitsu'));
    expect(v.single, contains('nicht im Budget'));
  });

  test('mehr als zwei Varianten sind ein Verstoß', () {
    final v = _violations(_episode(debrief: {
      'lex_ja_ame': {
        'usage': 'Regen.',
        'variants': [
          {'form': 'a', 'meaning': '1'},
          {'form': 'b', 'meaning': '2'},
          {'form': 'c', 'meaning': '3'},
        ],
      },
    }));
    expect(v, hasLength(1));
    expect(v.single, contains('3 Varianten'));
  });

  test('eine Variante, die selbst Budget-Item dieser Folge ist, ist ein '
      'Verstoß', () {
    final v = _violations(_episode(debrief: {
      'lex_ja_ame': {
        'usage': 'Regen.',
        'variants': [
          {'form': 'はい', 'meaning': 'ja'},
        ],
      },
    }));
    expect(v, hasLength(1));
    expect(v.single, contains('"はい"'));
    expect(v.single, contains('Budget-Item'));
  });
}
