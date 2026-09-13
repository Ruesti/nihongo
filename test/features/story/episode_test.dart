import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart' show RefType;
import 'package:nihongo_app/features/story/episode.dart';

const _json = {
  'id': 'ep_test_01',
  'seasonId': 'season_test',
  'orderIndex': 1,
  'title': 'Test',
  'locale': 'ja',
  'era': '1996',
  'budget': {
    'items': [
      {'id': 'lex_test_hai', 'refType': 'lexeme'},
      {'id': 'lex_test_douzo', 'refType': 'lexeme', 'singleton': true},
    ],
    'glyphs': [
      {'glyph': 'あ'},
    ],
  },
  'pages': [
    {
      'index': 1,
      'panels': [
        {
          'index': 1,
          'asset': 'assets/comic/placeholder_page.png',
          'anchorShot': 'A1',
          'notes': 'author-only commentary',
          'thoughts': [
            {'text': 'Ich hätte anrufen sollen.'},
          ],
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'はい',
              'tokens': [
                {'surface': 'はい', 'itemId': 'lex_test_hai'},
              ],
            },
          ],
          'interactions': [
            {'type': 'speak', 'diegetic': true},
          ],
        },
      ],
    },
  ],
};

void main() {
  test('parses a full episode with budget, thoughts, bubbles, and interactions', () {
    final episode = Episode.fromJson(_json);

    expect(episode.id, 'ep_test_01');
    expect(episode.seasonId, 'season_test');
    expect(episode.orderIndex, 1);
    expect(episode.era, '1996');

    expect(episode.budget.items, hasLength(2));
    expect(episode.budget.items[0].id, 'lex_test_hai');
    expect(episode.budget.items[0].refType, RefType.lexeme);
    expect(episode.budget.items[0].singleton, isFalse);
    expect(episode.budget.items[1].singleton, isTrue);
    expect(episode.budget.glyphs.single.glyph, 'あ');

    expect(episode.pages, hasLength(1));
    final panel = episode.pages.single.panels.single;
    expect(panel.index, 1);
    expect(panel.anchorShot, 'A1');
    expect(panel.notes, 'author-only commentary');
    expect(panel.thoughts.single.text, 'Ich hätte anrufen sollen.');

    final bubble = panel.bubbles.single;
    expect(bubble.speakerId, 'ladenbesitzer');
    expect(bubble.tokens.single.itemId, 'lex_test_hai');
    expect(bubble.tokens.single.lookupable, isTrue);
    expect(bubble.hitArea.points, isEmpty);

    expect(panel.interactions.single.type, InteractionType.speak);
    expect(panel.interactions.single.diegetic, isTrue);
    expect(panel.interactions.single.optional, isTrue);

    expect(episode.allPanels, hasLength(1));
  });

  test('defaults anchorShot to null, notes to empty, and itemId to null when absent', () {
    final episode = Episode.fromJson({
      ..._json,
      'pages': [
        {
          'index': 1,
          'panels': [
            {
              'index': 1,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'passantin',
                  'text': 'はい？',
                  'tokens': [
                    {'surface': 'はい'},
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

    final panel = episode.pages.single.panels.single;
    expect(panel.anchorShot, isNull);
    expect(panel.notes, '');
    expect(panel.bubbles.single.tokens.single.itemId, isNull);
  });

  test('defaults budget to empty items/glyphs when absent', () {
    final episode = Episode.fromJson({
      'id': 'ep_nobudget',
      'seasonId': 'season_nobudget',
      'orderIndex': 1,
      'title': 'NoBudget',
      'locale': 'ja',
      'era': '1996',
      'pages': [],
    });

    expect(episode.budget.items, isEmpty);
    expect(episode.budget.glyphs, isEmpty);
  });

  test('Episode traegt optionale deutsche intro/outro-Texte', () {
    final withTexts = Episode.fromJson({
      'id': 'ep_x', 'seasonId': 's', 'orderIndex': 1, 'title': 'T',
      'locale': 'ja', 'era': 'e',
      'budget': {'items': [], 'maxNew': 0},
      'pages': [],
      'intro': 'Eine junge Frau steigt aus dem Zug.',
      'outro': 'Der Name kommt ihr bekannt vor …',
    });
    expect(withTexts.intro, 'Eine junge Frau steigt aus dem Zug.');
    expect(withTexts.outro, 'Der Name kommt ihr bekannt vor …');

    final without = Episode.fromJson({
      'id': 'ep_y', 'seasonId': 's', 'orderIndex': 1, 'title': 'T',
      'locale': 'ja', 'era': 'e',
      'budget': {'items': [], 'maxNew': 0},
      'pages': [],
    });
    expect(without.intro, isNull);
    expect(without.outro, isNull);
  });

  test('StoryInteraction traegt optionales Reaktions-Bild + Erzaehlzeile', () {
    final withReaction = StoryInteraction.fromJson({
      'type': 'speak', 'diegetic': true,
      'reactionAsset': 'assets/story/p07_reaction.jpg',
      'reactionCaption': 'Sie hat dich gehört.',
    });
    expect(withReaction.reactionAsset, 'assets/story/p07_reaction.jpg');
    expect(withReaction.reactionCaption, 'Sie hat dich gehört.');

    final without = StoryInteraction.fromJson({'type': 'trace'});
    expect(without.reactionAsset, isNull);
    expect(without.reactionCaption, isNull);
  });
}
