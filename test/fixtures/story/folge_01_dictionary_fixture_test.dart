import 'package:flutter_test/flutter_test.dart';

import 'folge_01_dictionary_fixture.dart';

void main() {
  test('has exactly the 8 budgeted words from Folge 01, each with a German meaning',
      () {
    expect(folge01DictionaryEntries, hasLength(8));
    for (final entry in folge01DictionaryEntries) {
      expect(entry.meaning, isNotEmpty);
    }
  });

  test("only あめ carries the previous owner's margin note", () {
    final withNotes =
        folge01DictionaryEntries.where((e) => e.marginNote != null).toList();
    expect(withNotes, hasLength(1));
    expect(withNotes.single.headword, 'あめ');
  });
}
