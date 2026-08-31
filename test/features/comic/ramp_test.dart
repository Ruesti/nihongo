import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/comic_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ComicPack> load(String path) async =>
      ComicPack.fromJson(jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>);

  test('higher level has more L2 than level 0 (the ramp)', () async {
    final l0 = await load('assets/comic/ja_l0.json');
    final l1 = await load('assets/comic/ja_l1.json');
    expect(l1.level, greaterThan(l0.level));
    expect(measuredL2Ratio(l1.pages.first),
        greaterThan(measuredL2Ratio(l0.pages.first)));
  });

  test('measuredL2Ratio counts L2 bubbles over all bubbles', () async {
    final l1 = await load('assets/comic/ja_l1.json');
    // ja_l1 page: 3 L2 (猫/犬/水) + 2 L1 = 3/5
    expect(measuredL2Ratio(l1.pages.first), closeTo(3 / 5, 0.001));
  });
}
