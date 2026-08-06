import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/content_selector.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';

Token _t(String lemma) =>
    Token(surface: lemma, lemma: lemma, pos: 'n', charStart: 0, charEnd: lemma.length);

/// A passage of [known] known 'k' tokens + [unknown] distinct unknown ones.
List<Token> _passage(int known, int unknown) => [
      for (var i = 0; i < known; i++) _t('k'),
      for (var i = 0; i < unknown; i++) _t('u$i'),
    ];

Knowledge _knows(String lemma) =>
    lemma == 'k' ? Knowledge.known : Knowledge.unknown;

void main() {
  test('the i+1 window partitions by unknown ratio', () {
    const w = IPlusOneWindow(); // 0.02–0.15
    expect(w.classify(0.0), Fit.tooEasy);
    expect(w.classify(0.10), Fit.ideal);
    expect(w.classify(0.5), Fit.tooHard);
  });

  test('ideal first (easiest), then least-hard, then too-easy', () {
    final passages = <String, List<Token>>{
      'idealHard': _passage(9, 1), // 0.10 ideal
      'idealEasy': _passage(19, 1), // 0.05 ideal
      'wall': _passage(0, 10), // 1.00 too hard
      'hard': _passage(8, 2), // 0.20 too hard
      'easy': _passage(10, 0), // 0.00 too easy
    };

    final ranked =
        rankByIPlusOne<String>(passages.keys, (id) => passages[id]!, _knows);

    expect(ranked.map((r) => r.passage).toList(),
        ['idealEasy', 'idealHard', 'hard', 'wall', 'easy']);
    expect(ranked.first.fit, Fit.ideal);
  });

  test('a beginner with nothing known gets all-too-hard, least-hard first', () {
    final passages = <String, List<Token>>{
      'less': [_t('k'), _t('u1'), _t('u2'), _t('u3')], // 0.75
      'more': [_t('u1'), _t('u2'), _t('u3'), _t('u4')], // 1.00
    };

    final ranked =
        rankByIPlusOne<String>(passages.keys, (id) => passages[id]!, _knows);

    expect(ranked.map((r) => r.passage).toList(), ['less', 'more']);
    expect(ranked.every((r) => r.fit == Fit.tooHard), isTrue);
  });
}
