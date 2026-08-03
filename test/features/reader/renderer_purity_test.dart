import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The Phase 6 kill-gate says the renderer must contain "zero vocabulary
// logic — verified by inspection." This test makes that inspection
// mechanical and regression-proof rather than a one-time human read: it
// asserts the renderer's own imports never reach into vocabulary,
// scheduling, scoring, FSRS, card assembly, the database, or Datum. If
// someone later wires the renderer to any of those, this fails.

void main() {
  test('span_reader.dart imports nothing vocabulary/scheduling/db/Datum-related',
      () {
    final source = File('lib/features/reader/span_reader.dart').readAsStringSync();
    final imports = source
        .split('\n')
        .where((l) => l.trimLeft().startsWith('import '))
        .toList();

    // Whatever else it imports, none may touch these concerns.
    const forbidden = [
      'db/',            // no database
      'pipeline/',      // no scoring / FSRS / card assembly / knowledge
      'mining_packs/',  // no dictionary/frequency data packs
      'datum',          // no Datum
      'srs',
      'scheduler',
    ];

    for (final imp in imports) {
      for (final needle in forbidden) {
        expect(imp.contains(needle), isFalse,
            reason: 'renderer must not import "$needle": $imp');
      }
    }

    // Positively: it should only depend on Flutter + the Token type.
    expect(imports.any((i) => i.contains('package:flutter/')), isTrue,
        reason: 'a renderer is a Flutter widget');
    expect(imports.any((i) => i.contains('language_pack/language_pack.dart')),
        isTrue,
        reason: 'it renders Token, which lives in the language_pack seam types');
  });
}
