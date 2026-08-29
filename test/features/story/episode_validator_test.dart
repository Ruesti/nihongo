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

  test('INV-4: rejects a non-singleton item that only appears in one panel', () {
    final tampered = _mutableCopy(pilot01RegenJson);
    final lastPage = (tampered['pages'] as List).last as Map<String, dynamic>;
    final lastPanel = (lastPage['panels'] as List).last as Map<String, dynamic>;
    (lastPanel['bubbles'] as List)
        .removeWhere((b) => (b as Map)['speakerId'] == 'buch');

    final episode = Episode.fromJson(tampered);

    expect(
      () => validateEpisode(episode),
      throwsA(
        isA<StoryValidationException>().having(
          (e) => e.violations.join(),
          'violations',
          contains('lex_ja_ame'),
        ),
      ),
    );
  });
}
