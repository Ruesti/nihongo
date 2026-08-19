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
    // ja_l1 page: 2 L2 + 1 L1 = 2/3
    expect(measuredL2Ratio(l1.pages.first), closeTo(2 / 3, 0.001));
  });
}
