import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/cafe/cafe_visit.dart';
import 'package:nihongo_app/features/story/episode.dart';

Episode _episode(List<String> ids) => Episode.fromJson({
      'id': 'ep_t', 'seasonId': 's', 'orderIndex': 1, 'title': 'T',
      'locale': 'ja', 'era': 'e',
      'budget': {
        'items': [for (final id in ids) {'id': id, 'refType': 'lexeme'}],
        'glyphs': [],
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0, 'asset': 'x.jpg',
              'bubbles': [
                {
                  'speakerId': 'x', 'text': 'x', 'hitArea': [],
                  'tokens': [for (final id in ids.reversed) {'surface': 'x', 'itemId': id}],
                },
              ],
              'thoughts': [], 'interactions': [],
            },
          ],
        },
      ],
    });

LearnItem _item(String id, int rung, {int dueDaysAgo = 0}) => LearnItem(
      id: 'lang_ja:lexeme:$id', languageId: 'lang_ja', refType: 'lexeme',
      refId: id, masteryRung: rung, ease: 2.5, intervalDays: 1,
      dueAt: DateTime.now().subtract(Duration(days: dueDaysAgo)),
      reps: 1, lapses: 0, consecutiveCorrect: 0);

void main() {
  group('planAfterEpisode', () {
    test('Wirtin bekommt alle Wörter in Auftrittsreihenfolge, Schulmädchen '
        'alle ohne anderes Ziel, wackelige zuerst', () {
      final ep = _episode(['a', 'b', 'c', 'd']);
      final plan = planAfterEpisode(ep,
          vielrednerTargets: {'c'}, gleichaltrigeTargets: {'d'}, wobbly: {'b'});
      expect(plan.stations.map((s) => s.station),
          [CafeStation.wirtin, CafeStation.schulmaedchen]);
      expect(plan.stations[0].itemIds, ['d', 'c', 'b', 'a']); // Token-Reihenfolge
      expect(plan.stations[1].itemIds, ['b', 'a']);
    });

    test('jedes Wort ist Ziel in mindestens einer aktiven Station (INV-23)', () {
      final ep = _episode(['a', 'b', 'c']);
      final plan = planAfterEpisode(ep, vielrednerTargets: {'a'});
      final covered = {
        for (final s in plan.stations)
          if (s.station != CafeStation.wirtin) ...s.itemIds,
        'a',
      };
      expect(covered, {'a', 'b', 'c'});
    });

    test('Stationen ohne Items fehlen im Plan', () {
      final ep = _episode(['a']);
      final plan = planAfterEpisode(ep, vielrednerTargets: {'a'});
      expect(plan.stations.map((s) => s.station), [CafeStation.wirtin]);
    });
  });

  group('planFreeVisit', () {
    test('Sprosse ≤2 mit letztem again/hard → Wirtin, sonst Schulmädchen; '
        'Sprosse 4/5 in Plan A ebenfalls Schulmädchen', () {
      final plan = planFreeVisit(
        [_item('a', 1), _item('b', 2), _item('c', 3), _item('d', 5)],
        {'lang_ja:lexeme:a': 'again', 'lang_ja:lexeme:b': 'good'},
      );
      expect(plan.stationFor(CafeStation.wirtin)?.itemIds, ['a']);
      expect(plan.stationFor(CafeStation.schulmaedchen)?.itemIds, ['b', 'c', 'd']);
    });

    test('höchstens maxItems, die am längsten fälligen zuerst', () {
      final due = [for (var i = 0; i < 15; i++) _item('w$i', 3, dueDaysAgo: i)];
      final plan = planFreeVisit(due, const {}, maxItems: 12);
      final ids = plan.stations.expand((s) => s.itemIds).toList();
      expect(ids.length, 12);
      expect(ids.first, 'w14');
      expect(ids, isNot(contains('w0')));
    });

    test('nichts fällig → leerer Plan', () {
      expect(planFreeVisit(const [], const {}).stations, isEmpty);
    });
  });

  group('planPracticeAnyway', () {
    test('bis zu max bekannte Wörter (Sprosse ≥ 1) beim Schulmädchen, '
        'gleiche Saat → gleiche Reihenfolge', () {
      final all = [_item('neu', 0), for (var i = 0; i < 8; i++) _item('k$i', 2)];
      final a = planPracticeAnyway(all, seed: 7);
      final b = planPracticeAnyway(all, seed: 7);
      expect(a.stations.single.station, CafeStation.schulmaedchen);
      expect(a.stations.single.itemIds.length, 6);
      expect(a.stations.single.itemIds, isNot(contains('neu')));
      expect(a.stations.single.itemIds, b.stations.single.itemIds);
    });

    test('ohne bekannte Wörter → leerer Plan', () {
      expect(planPracticeAnyway([_item('neu', 0)], seed: 1).stations, isEmpty);
    });
  });
}
