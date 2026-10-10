import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/word_decomposition.dart';

List<String> _texts(String w) => decompose(w).map((u) => u.text).toList();
List<String> _romaji(String w) => decompose(w).map((u) => u.romaji).toList();

void main() {
  test('einfache Kana: eine Kachel je Zeichen', () {
    expect(_texts('あめ'), ['あ', 'め']);
    expect(_romaji('あめ'), ['a', 'me']);
  });

  test('Yōon (きょ) ist eine Kachel', () {
    expect(_texts('きょう'), ['きょう']);
    expect(_romaji('きょう'), ['kyō']);
  });

  test('kleines っ verdoppelt den Folgekonsonanten', () {
    expect(_texts('ちょっと'), ['ちょ', 'っ', 'と']);
    expect(_romaji('ちょっと'), ['cho', 't', 'to']);
  });

  test('Dehnung とう wird zu tō, ん ist eine Kachel', () {
    expect(_texts('ありがとう'), ['あ', 'り', 'が', 'とう']);
    expect(_romaji('ありがとう'), ['a', 'ri', 'ga', 'tō']);
    expect(_romaji('さんぽ'), ['sa', 'n', 'po']);
  });

  test('Dehnung ei und Katakana-Strich', () {
    expect(_romaji('えいが'), ['ē', 'ga']);
    expect(_texts('コーヒー'), ['コー', 'ヒー']);
    expect(_romaji('コーヒー'), ['kō', 'hī']);
  });

  test('じゃ/じゅ/じょ und ぢ/づ', () {
    expect(_romaji('じょうぶ'), ['jō', 'bu']);
    expect(_romaji('だいじょうぶ'), ['da', 'i', 'jō', 'bu']);
  });

  test('unbekanntes Zeichen bleibt als Kachel ohne Laut', () {
    expect(_texts('駅'), ['駅']);
    expect(_romaji('駅'), ['']);
  });
}
