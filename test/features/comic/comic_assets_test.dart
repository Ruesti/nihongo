import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ComicPack> load(String path) async {
    final raw = await rootBundle.loadString(path);
    return ComicPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  test('JA and ES packs both parse (model is language-agnostic)', () async {
    final ja = await load('assets/comic/ja_l0.json');
    final es = await load('assets/comic/es_l0.json');
    expect(ja.languageCode, 'ja');
    expect(es.languageCode, 'es');
    // ES has no reading layer; JA does — both are valid.
    final jaL2 = ja.pages.first.bubbles.firstWhere((b) => b.lang == BubbleLang.l2);
    final esL2 = es.pages.first.bubbles.firstWhere((b) => b.lang == BubbleLang.l2);
    expect(jaL2.tokens.single.reading, isNotNull);
    expect(esL2.tokens.single.reading, isNull);
  });
}
