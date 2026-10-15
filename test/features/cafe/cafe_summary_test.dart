import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_summary.dart';
import 'package:nihongo_app/features/cafe/cafe_turn.dart';

void main() {
  final now = DateTime(2026, 10, 10, 20);
  VisitRecord r(String form, CafeOutcome o, {bool first = true, int dueInDays = 1}) =>
      VisitRecord(itemId: form, writtenForm: form, outcome: o, firstTry: first,
          dueAt: now.add(Duration(days: dueInDays)));

  test('sitzt = beim ersten Versuch richtig; Rest kommt wieder, mit Zeitwort', () {
    final lines = summaryLines([
      r('かさ', CafeOutcome.correct),
      r('どうぞ', CafeOutcome.correct),
      r('こわれた', CafeOutcome.correct, first: false, dueInDays: 1),
      r('いくら', CafeOutcome.wrong, dueInDays: 0),
    ], now: now);
    expect(lines, [
      'かさ und どうぞ sitzen.',
      'こわれた und いくら kommen morgen wieder.',
    ]);
  });

  test('in ein paar Tagen ab 3 Tagen; nur ein Wort ohne „und"', () {
    final lines = summaryLines([
      r('あめ', CafeOutcome.correct, first: false, dueInDays: 4),
    ], now: now);
    expect(lines, ['あめ kommt in ein paar Tagen wieder.']);
  });

  test('ohne Bewertungen: nur die Wirtin', () {
    expect(summaryLines(const [], now: now), ['Das war es für heute.']);
  });

  test('keine Zahlen im Text (INV-10) — auch bei vielen Wörtern', () {
    final lines = summaryLines([
      for (var i = 0; i < 12; i++) r('w$i', CafeOutcome.correct),
    ], now: now);
    // Die Testwörter heißen w0…w11; nur der Text drumherum zählt.
    expect(lines.join().replaceAll(RegExp(r'w\d+'), ''),
        isNot(matches(RegExp(r'\d'))));
  });
}
