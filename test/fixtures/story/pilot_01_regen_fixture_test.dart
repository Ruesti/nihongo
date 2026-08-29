import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';

import 'pilot_01_regen_fixture.dart';

void main() {
  test('the pilot episode fixture parses into 6 pages and 24 panels', () {
    final episode = Episode.fromJson(pilot01RegenJson);

    expect(episode.id, 'ep_ja_shotengai_01');
    expect(episode.pages, hasLength(6));
    expect(episode.allPanels, hasLength(24));
    expect(episode.budget.items, hasLength(8));
    expect(episode.budget.glyphs, hasLength(3));
  });
}
