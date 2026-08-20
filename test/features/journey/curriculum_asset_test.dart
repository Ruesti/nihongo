import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled JA curriculum parses and interleaves lesson/manga', () async {
    final raw = await rootBundle.loadString('assets/curriculum/ja.json');
    final c = Curriculum.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    expect(c.languageCode, 'ja');
    expect(c.steps.length, greaterThanOrEqualTo(4));
    // First chapter must teach before it reads: a lesson precedes a manga.
    expect(c.steps[0], isA<LessonStep>());
    expect(c.steps[1], isA<MangaStep>());
    // No "all kana first": the first lesson introduces at most a few characters.
    expect((c.steps[0] as LessonStep).characterIds.length, lessThanOrEqualTo(3));
  });
}
