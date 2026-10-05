import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episode_validator.dart';

/// Minimale Folge: zwei Wörter im Budget, jedes zweimal von anderen gehört.
Map<String, dynamic> _episode({
  List<Map<String, dynamic>> extraBubbles = const [],
  List<Map<String, dynamic>> interactions = const [],
  List<Map<String, dynamic>> thoughts = const [],
}) =>
    {
      'id': 'ep_test',
      'seasonId': 's_test',
      'orderIndex': 1,
      'era': 'test',
      'locale': 'ja',
      'title': 'Test',
      'budget': {
        'items': [
          {'id': 'lex_a', 'refType': 'lexeme'},
          {'id': 'lex_b', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'x.jpg',
              'bubbles': [
                {
                  'speakerId': 'passant',
                  'text': 'あ、あ。い、い',
                  'hitArea': [],
                  'tokens': [
                    {'surface': 'あ', 'itemId': 'lex_a'},
                    {'surface': 'あ', 'itemId': 'lex_a'},
                    {'surface': 'い', 'itemId': 'lex_b'},
                    {'surface': 'い', 'itemId': 'lex_b'},
                  ],
                },
                ...extraBubbles,
              ],
              'thoughts': thoughts,
              'interactions': interactions,
              'notes': '',
            },
          ],
        },
      ],
    };

Matcher _violation(String fragment) => throwsA(isA<StoryValidationException>()
    .having((e) => e.violations.join('\n'), 'violations', contains(fragment)));

void main() {
  test('Grundfolge ist gültig', () {
    expect(() => validateEpisode(Episode.fromJson(_episode())), returnsNormally);
  });

  group('INV-18 Mira spricht nur, was sie schon kann', () {
    test('Mira-Token aus dem eigenen Budget ist ein Verstoß', () {
      final ep = Episode.fromJson(_episode(extraBubbles: [
        {
          'speakerId': 'protagonist',
          'text': '…あ',
          'hitArea': [],
          'tokens': [
            {'surface': 'あ', 'itemId': 'lex_a'},
          ],
        },
      ]));
      expect(() => validateEpisode(ep), _violation('INV-18'));
    });

    test('Mira-Token aus einer früheren Folge ist erlaubt (auch für INV-3)',
        () {
      // Ein wiederverwendetes Wort steht nicht im Budget der neuen Folge
      // (Café-Spec §5.1); INV-3 und INV-18 akzeptieren es über priorItemIds.
      final ep = Episode.fromJson(_episode(extraBubbles: [
        {
          'speakerId': 'protagonist',
          'text': 'う',
          'hitArea': [],
          'tokens': [
            {'surface': 'う', 'itemId': 'lex_alt'},
          ],
        },
      ]));
      expect(() => validateEpisode(ep, priorItemIds: {'lex_alt'}),
          returnsNormally);
      expect(() => validateEpisode(ep), _violation('INV-3'));
    });

    test('Kana außerhalb der Tokens ist ein Verstoß', () {
      final ep = Episode.fromJson(_episode(extraBubbles: [
        {
          'speakerId': 'protagonist',
          'text': 'え？',
          'hitArea': [],
          'tokens': [],
        },
      ]));
      expect(() => validateEpisode(ep), _violation('INV-18'));
    });

    test('Token ohne itemId bei Mira ist ein Verstoß', () {
      final ep = Episode.fromJson(_episode(extraBubbles: [
        {
          'speakerId': 'protagonist',
          'text': 'え',
          'hitArea': [],
          'tokens': [
            {'surface': 'え', 'itemId': null},
          ],
        },
      ]));
      expect(() => validateEpisode(ep), _violation('INV-18'));
    });
  });

  group('INV-19 Mira spricht nur nach, was sie gehört hat', () {
    test('Sprechziel, das niemand vorher sagt, ist ein Verstoß', () {
      final json = _episode(interactions: [
        {
          'type': 'speak',
          'diegetic': true,
          'target': 'う',
          'targetItemIds': ['lex_c'],
        },
      ]);
      (json['budget'] as Map)['items'] = [
        ...((json['budget'] as Map)['items'] as List),
        {'id': 'lex_c', 'refType': 'lexeme', 'singleton': true},
      ];
      expect(() => validateEpisode(Episode.fromJson(json)), _violation('INV-19'));
    });

    test('Sprechziel, das vorher eine andere Figur sagt, ist erlaubt', () {
      final ep = Episode.fromJson(_episode(interactions: [
        {
          'type': 'speak',
          'diegetic': true,
          'target': 'あ',
          'targetItemIds': ['lex_a'],
        },
      ]));
      expect(() => validateEpisode(ep), returnsNormally);
    });
  });

  test('InteractionType.silent wird aus JSON gelesen', () {
    final it = StoryInteraction.fromJson(
        {'type': 'silent', 'diegetic': true, 'target': 'あ'});
    expect(it.type, InteractionType.silent);
  });

  test('isSilence erkennt nur die tokenlose „…“-Blase', () {
    StoryBubble b(String text, List<Map<String, dynamic>> tokens) =>
        StoryBubble.fromJson(
            {'speakerId': 'protagonist', 'text': text, 'hitArea': [], 'tokens': tokens});
    expect(b('…', []).isSilence, isTrue);
    expect(b(' … ', []).isSilence, isTrue);
    expect(b('…あ', [{'surface': 'あ', 'itemId': 'lex_a'}]).isSilence, isFalse);
    expect(b('みなみまち駅', []).isSilence, isFalse);
  });

  group('stumme Momente (Spec §4.2, Änderung 5.10.: Schweigen im Erzähltext)',
      () {
    const narration = [
      {'text': 'Mira möchte etwas sagen. Ihr fehlt das Wort.'},
    ];
    Map<String, dynamic> silence() => {
          'speakerId': 'protagonist',
          'text': '…',
          'hitArea': [],
          'tokens': [],
        };
    Map<String, dynamic> silent(String target, String id) => {
          'type': 'silent',
          'diegetic': true,
          'target': target,
          'targetItemIds': [id],
          'promptText': 'Was hättest du sagen können?',
        };

    test('gültig: keine Mira-Blase, Erzähltext, ein Ziel aus dem Budget', () {
      final ep = Episode.fromJson(_episode(
          thoughts: narration, interactions: [silent('あ', 'lex_a')]));
      expect(() => validateEpisode(ep), returnsNormally);
    });

    test('silent ohne Erzähltext ist ein Verstoß', () {
      final ep =
          Episode.fromJson(_episode(interactions: [silent('あ', 'lex_a')]));
      expect(() => validateEpisode(ep), _violation('ohne Erzähltext'));
    });

    test('„…“-Blase von Mira im stummen Moment ist ein Verstoß', () {
      final ep = Episode.fromJson(_episode(
          extraBubbles: [silence()],
          thoughts: narration,
          interactions: [silent('あ', 'lex_a')]));
      expect(() => validateEpisode(ep),
          _violation('Miras Schweigen steht im Erzähltext'));
      expect(() => validateEpisode(ep), _violation('sie schweigt hier'));
    });

    test('Mira-Blase mit Wort im stummen Moment ist ein Verstoß', () {
      final ep = Episode.fromJson(_episode(extraBubbles: [
        {
          'speakerId': 'protagonist',
          'text': 'う',
          'hitArea': [],
          'tokens': [
            {'surface': 'う', 'itemId': 'lex_alt'},
          ],
        },
      ], thoughts: narration, interactions: [
        silent('あ', 'lex_a')
      ]));
      expect(() => validateEpisode(ep, priorItemIds: {'lex_alt'}),
          _violation('sie schweigt hier'));
    });

    for (final text in ['…', '...', '……', '…?', ' ']) {
      test('tokenlose Mira-Blase „$text" ist überall ein Verstoß', () {
        final ep = Episode.fromJson(
            _episode(extraBubbles: [{...silence(), 'text': text}]));
        expect(() => validateEpisode(ep),
            _violation('Miras Schweigen steht im Erzähltext'));
      });
    }

    test('zwei silent in einem Panel sind ein Verstoß', () {
      final ep = Episode.fromJson(_episode(
          thoughts: narration,
          interactions: [silent('あ', 'lex_a'), silent('い', 'lex_b')]));
      expect(() => validateEpisode(ep), _violation('stummer Moment'));
    });

    test('Ziel außerhalb des Budgets ist ein Verstoß', () {
      final ep = Episode.fromJson(_episode(
          thoughts: narration, interactions: [silent('う', 'lex_x')]));
      expect(() => validateEpisode(ep), _violation('weder im Budget'));
    });

    test('Ziel, das niemand in der Folge sagt, ist ein Verstoß', () {
      final json = _episode(
          thoughts: narration, interactions: [silent('う', 'lex_c')]);
      (json['budget'] as Map)['items'] = [
        ...((json['budget'] as Map)['items'] as List),
        {'id': 'lex_c', 'refType': 'lexeme', 'singleton': true},
      ];
      expect(() => validateEpisode(Episode.fromJson(json)),
          _violation('sagt in dieser Folge niemand'));
    });

    test('mehr als ein Ziel ist ein Verstoß', () {
      final ep = Episode.fromJson(_episode(thoughts: narration, interactions: [
        {
          'type': 'silent',
          'diegetic': true,
          'target': 'あ',
          'targetItemIds': ['lex_a', 'lex_b'],
        },
      ]));
      expect(() => validateEpisode(ep), _violation('genau ein Ziel'));
    });

    test('gültig: Ziel aus einer früheren Folge (priorItemIds)', () {
      final ep = Episode.fromJson(_episode(extraBubbles: [
        {
          'speakerId': 'passant',
          'text': 'う',
          'hitArea': [],
          'tokens': [
            {'surface': 'う', 'itemId': 'lex_alt'},
          ],
        },
      ], thoughts: narration, interactions: [
        silent('う', 'lex_alt')
      ]));
      expect(() => validateEpisode(ep, priorItemIds: {'lex_alt'}),
          returnsNormally);
    });

    test('„…“ einer anderen Figur ist kein Mira-Verstoß', () {
      final ep = Episode.fromJson(_episode(extraBubbles: [
        {...silence(), 'speakerId': 'passant'},
      ], thoughts: narration, interactions: [
        silent('あ', 'lex_a')
      ]));
      expect(() => validateEpisode(ep), returnsNormally);
    });
  });
}
