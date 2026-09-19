import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

Map<String, dynamic> _minimal({String? weather}) => {
      'id': 'ep_w',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'weather': ?weather,
      'budget': {'items': [], 'glyphs': []},
      'pages': [],
    };

void main() {
  test('weather ist optional und wird aus JSON gelesen', () {
    expect(Episode.fromJson(_minimal()).weather, isNull);
    expect(Episode.fromJson(_minimal(weather: 'rain')).weather, 'rain');
  });

  test('Folge 01 „Regen" regnet', () {
    expect(loadFolge01().weather, 'rain');
  });
}
