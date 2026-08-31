import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/comic/bundled_dictionary.dart';

void main() {
  test('looks up a known lemma, returns senses; unknown → empty', () {
    final senses = jaBundledDictionary.lookup('猫', '');
    expect(senses, isNotEmpty);
    expect(senses.first.glosses, contains('Katze'));

    expect(jaBundledDictionary.lookup('不明', ''), isEmpty);
  });
}
