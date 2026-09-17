import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_prompts.dart';

void main() {
  test('„Setz dich." eröffnet genau einmal; danach rotieren drei '
      'Anschlusszeilen', () {
    final opener = wirtinDebriefLine(0);
    final followUps = {for (var i = 1; i <= 3; i++) wirtinDebriefLine(i)};
    expect(followUps, hasLength(3));
    expect(followUps, isNot(contains(opener)));
    expect(wirtinDebriefLine(4), wirtinDebriefLine(1));
  });

  test('Schlusszeilen der Wirtin rotieren über mindestens drei Varianten — '
      'und nirgends steht eine Zahl (INV-10)', () {
    final lines = {for (var i = 0; i < 4; i++) wirtinDebriefLine(i)};
    final closings = {for (var i = 0; i < 3; i++) wirtinDebriefClosing(i)};
    expect(lines, hasLength(4));
    expect(closings, hasLength(3));
    expect(wirtinDebriefClosing(4), wirtinDebriefClosing(1));
    for (final s in [...lines, ...closings, wirtinDebriefInvite]) {
      expect(RegExp(r'\d').hasMatch(s), isFalse, reason: s);
    }
  });
}
