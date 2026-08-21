import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/bundled_dictionary.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<String> load(String p) => rootBundle.loadString(p);

  test('chapter 1 teaches a few kana + a word before reading', () async {
    final c = Curriculum.fromJson(
        jsonDecode(await load('assets/curriculum/ja.json')) as Map<String, dynamic>);
    final first = c.steps[0] as LessonStep;
    expect(first.characterIds.length, greaterThanOrEqualTo(2));
    expect(first.lexemeIds, isNotEmpty);
    expect(c.steps[1], isA<MangaStep>());
  });

  test('every L2 word in the scene has a gloss in the bundled dictionary', () async {
    final pack = ComicPack.fromJson(
        jsonDecode(await load('assets/comic/ja_l0.json')) as Map<String, dynamic>);
    for (final page in pack.pages) {
      for (final b in page.bubbles.where((b) => b.lang == BubbleLang.l2)) {
        for (final t in b.tokens) {
          expect(jaBundledDictionary.lookup(t.lemma, ''), isNotEmpty,
              reason: 'no gloss for ${t.lemma}');
        }
      }
    }
  });
}
