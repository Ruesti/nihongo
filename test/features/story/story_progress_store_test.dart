import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('returns null when no position has been saved for an episode', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = StoryProgressStore(prefs);

    expect(await store.lastPosition('ep_ja_shotengai_01'), isNull);
  });

  test('saves and retrieves a position for an episode', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = StoryProgressStore(prefs);

    await store.savePosition('ep_ja_shotengai_01', 7);

    expect(await store.lastPosition('ep_ja_shotengai_01'), 7);
  });

  test('tracks positions independently per episode', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = StoryProgressStore(prefs);

    await store.savePosition('ep_a', 3);
    await store.savePosition('ep_b', 9);

    expect(await store.lastPosition('ep_a'), 3);
    expect(await store.lastPosition('ep_b'), 9);
  });

  test('overwrites a previously saved position for the same episode', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = StoryProgressStore(prefs);

    await store.savePosition('ep_ja_shotengai_01', 2);
    await store.savePosition('ep_ja_shotengai_01', 5);

    expect(await store.lastPosition('ep_ja_shotengai_01'), 5);
  });
}
