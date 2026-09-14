import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episode_validator.dart';

import '../../fixtures/story/pilot_01_regen_fixture.dart';

Map<String, dynamic> _mutableCopy(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  test('the pilot episode fixture is valid as written', () {
    final episode = Episode.fromJson(pilot01RegenJson);
    expect(() => validateEpisode(episode), returnsNormally);
  });

  test('does not flag the singleton item (douzo) despite a single occurrence', () {
    final episode = Episode.fromJson(pilot01RegenJson);
    final douzo =
        episode.budget.items.firstWhere((i) => i.id == 'lex_ja_douzo');
    expect(douzo.singleton, isTrue);
    validateEpisode(episode); // must not throw
  });

  test('INV-3: rejects a token that references an item outside the budget', () {
    final tampered = _mutableCopy(pilot01RegenJson);
    final page3 = (tampered['pages'] as List)[2] as Map<String, dynamic>;
    final panel7 = (page3['panels'] as List)[0] as Map<String, dynamic>;
    final token =
        ((panel7['bubbles'] as List)[0] as Map)['tokens'] as List;
    (token[0] as Map<String, dynamic>)['itemId'] = 'lex_ja_ghost';

    final episode = Episode.fromJson(tampered);

    expect(
      () => validateEpisode(episode),
      throwsA(
        isA<StoryValidationException>().having(
          (e) => e.violations.join(),
          'violations',
          contains('lex_ja_ghost'),
        ),
      ),
    );
  });

  test('INV-4: rejects a non-singleton item whose occurrences drop below two',
      () {
    // これ occurs exactly twice in the real fixture: once in Panel 5
    // (これ？かさ？) and once in Panel 6 (これ、こわれた). Dropping the
    // Panel-5 bubble
    // leaves a single occurrence — below the ≥2 floor for a non-singleton
    // item (INV-4 counts total occurrences, not distinct panels, since V2's
    // dense panels legitimately repeat a word several times within one
    // scene — see episode_validator.dart's doc comment).
    final tampered = _mutableCopy(pilot01RegenJson);
    final page1 = (tampered['pages'] as List)[1] as Map<String, dynamic>;
    final panel5 = (page1['panels'] as List)[0] as Map<String, dynamic>;
    (panel5['bubbles'] as List)
        .removeWhere((b) => (b as Map)['text'] == 'これ？かさ？');

    final episode = Episode.fromJson(tampered);

    expect(
      () => validateEpisode(episode),
      throwsA(
        isA<StoryValidationException>().having(
          (e) => e.violations.join(),
          'violations',
          contains('lex_ja_kore'),
        ),
      ),
    );
  });

  test('structural: rejects an episode with duplicate panel indices across pages', () {
    final episode = Episode.fromJson({
      'id': 'ep_dup',
      'seasonId': 'season_dup',
      'orderIndex': 1,
      'title': 'Dup',
      'locale': 'ja',
      'era': '1996',
      'budget': {'items': [], 'glyphs': []},
      'pages': [
        {
          'index': 1,
          'panels': [
            {
              'index': 1,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
        {
          'index': 2,
          'panels': [
            {
              'index': 1,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    });

    expect(
      () => validateEpisode(episode),
      throwsA(
        isA<StoryValidationException>().having(
          (e) => e.violations.join(),
          'violations',
          contains('Duplicate panel index'),
        ),
      ),
    );
  });
}
