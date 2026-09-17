import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_prompts.dart';

void main() {
  test('Wirtin-Zeilen der Nachbesprechung rotieren über mindestens drei '
      'Varianten — ohne Zahlen (INV-10)', () {
    final lines = {for (var i = 0; i < 3; i++) wirtinDebriefLine(i)};
    final closings = {for (var i = 0; i < 3; i++) wirtinDebriefClosing(i)};
    expect(lines, hasLength(3));
    expect(closings, hasLength(3));
    expect(wirtinDebriefLine(3), wirtinDebriefLine(0));
    expect(wirtinDebriefClosing(4), wirtinDebriefClosing(1));
    for (final s in [...lines, ...closings, wirtinDebriefInvite]) {
      expect(RegExp(r'\d').hasMatch(s), isFalse, reason: s);
    }
  });
}
