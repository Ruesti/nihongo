import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_prompts.dart';

void main() {
  test('the Vielredner monologue slots the word and rotates', () {
    final a = vielrednerMonologue('あめ', 0);
    final b = vielrednerMonologue('あめ', 1);
    expect(a, contains('あめ'));
    expect(b, contains('あめ'));
    expect(a, isNot(b)); // ≥2 distinct templates
    // Multi-line "rich" monologue: more than a one-liner.
    expect(a.trim().length, greaterThan(40));
    // Wraps around.
    expect(vielrednerMonologue('あめ', 3), isNotEmpty);
  });

  test('the Gleichaltrige opener slots the word and rotates', () {
    final a = gleichaltrigeOpener('あめ', 0);
    final b = gleichaltrigeOpener('あめ', 1);
    expect(a, contains('あめ'));
    expect(b, contains('あめ'));
    expect(a, isNot(b));
  });
}
