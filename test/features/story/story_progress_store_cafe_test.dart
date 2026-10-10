import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StoryProgressStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = StoryProgressStore(await SharedPreferences.getInstance());
  });

  test('Position speichern, lesen, löschen', () async {
    expect(await store.cafeVisitPosition('ep_1'), isNull);
    await store.saveCafeVisitPosition('ep_1', 1, 3);
    expect(await store.cafeVisitPosition('ep_1'), (station: 1, item: 3));
    await store.clearCafeVisitPosition('ep_1');
    expect(await store.cafeVisitPosition('ep_1'), isNull);
  });

  test('wackelige Wörter: speichern, lesen; Position löschen räumt sie mit ab',
      () async {
    expect(await store.cafeVisitWobbly('ep_1'), isEmpty);
    await store.saveCafeVisitWobbly('ep_1', {'lex_a', 'lex_b'});
    expect(await store.cafeVisitWobbly('ep_1'), {'lex_a', 'lex_b'});
    expect(await store.cafeVisitWobbly('ep_2'), isEmpty);
    await store.saveCafeVisitWobbly('ep_1', const {});
    expect(await store.cafeVisitWobbly('ep_1'), isEmpty);
    await store.saveCafeVisitWobbly('ep_1', {'lex_a'});
    await store.clearCafeVisitPosition('ep_1');
    expect(await store.cafeVisitWobbly('ep_1'), isEmpty);
  });

  test('Besuch offen =Folge beendet und Besuch nicht erledigt', () async {
    expect(await store.isCafeVisitPending('ep_1'), isFalse);
    await store.markCompleted('ep_1');
    expect(await store.isCafeVisitPending('ep_1'), isTrue);
    await store.markCafeVisitDone('ep_1');
    expect(await store.isCafeVisitPending('ep_1'), isFalse);
  });
}
