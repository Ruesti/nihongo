import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_turn.dart';
import 'package:nihongo_app/features/cafe/cafe_guest_script.dart';

void main() {
  test('each guest has ≥3 distinct lines for every outcome it reacts to', () {
    for (final guest in CafeGuest.values) {
      final script = scriptFor(guest);
      for (final outcome in script.lines.keys) {
        final lines = {
          script.followUp(outcome, 0),
          script.followUp(outcome, 1),
          script.followUp(outcome, 2),
        };
        expect(lines.length, greaterThanOrEqualTo(3),
            reason: '$guest/$outcome has fewer than 3 lines');
      }
    }
  });

  test('followUp ist total: jeder Gast liefert für JEDES CafeOutcome eine '
      'nicht-leere Zeile, auch für Ergebnisse, auf die er laut Steckbrief '
      'gar nicht reagiert (Final-Review F1)', () {
    for (final guest in CafeGuest.values) {
      final script = scriptFor(guest);
      for (final outcome in CafeOutcome.values) {
        final line = script.followUp(outcome, 0);
        expect(line, isNotEmpty, reason: '$guest/$outcome liefert leer');
      }
    }
  });

  test('the Gleichaltrige reacts to free production; the Vielredner to '
      'correct/wrong/hinted', () {
    expect(scriptFor(CafeGuest.gleichaltrige).lines.keys,
        contains(CafeOutcome.freeProduced));
    expect(scriptFor(CafeGuest.vielredner).lines.keys,
        containsAll([CafeOutcome.correct, CafeOutcome.wrong, CafeOutcome.hinted]));
  });

  test('followUp rotates deterministically by turn index', () {
    final script = scriptFor(CafeGuest.schulkind);
    final a = script.followUp(CafeOutcome.correct, 0);
    final b = script.followUp(CafeOutcome.correct, 1);
    expect(a, isNot(b));
    // Wraps around: with 3 lines, index 3 must return the same line as index 0.
    expect(script.followUp(CafeOutcome.correct, 3),
        script.followUp(CafeOutcome.correct, 0));
    // And an out-of-order pair still differs (index 4 wraps to 1, not 0).
    expect(script.followUp(CafeOutcome.correct, 4),
        isNot(script.followUp(CafeOutcome.correct, 0)));
  });

  test('the Schulkind sounds nothing like the Wirtin (distinct content)', () {
    final wirtin = scriptFor(CafeGuest.wirtin).followUp(CafeOutcome.wrong, 0);
    final kind = scriptFor(CafeGuest.schulkind).followUp(CafeOutcome.wrong, 0);
    expect(wirtin, isNot(kind));
  });

  test('jede Stimme hat ≥3 verschiedene Zeilen für Erkennen und Lesen; das '
      'Schulkind auch für Schreiben', () {
    for (final guest in CafeGuest.values) {
      final s = scriptFor(guest);
      for (final kind in [
        CafeExerciseKind.recognition,
        CafeExerciseKind.readingInput,
      ]) {
        final lines = {for (var i = 0; i < 3; i++) s.voiceLine(kind, i)};
        expect(lines, isNot(contains(null)), reason: '$guest/$kind fehlt');
        expect(lines.length, 3, reason: '$guest/$kind hat < 3 Zeilen');
      }
    }
    final prod = {
      for (var i = 0; i < 3; i++)
        scriptFor(CafeGuest.schulkind)
            .voiceLine(CafeExerciseKind.productionInput, i)
    };
    expect(prod, isNot(contains(null)));
    expect(prod.length, 3);
  });

  test('ohne Zeile für eine Übungsform sagt der Gast nichts (null, kein '
      'Absturz); Rotation läuft rund', () {
    expect(
        scriptFor(CafeGuest.wirtin)
            .voiceLine(CafeExerciseKind.freeProduction, 0),
        isNull);
    final s = scriptFor(CafeGuest.vielredner);
    expect(s.voiceLine(CafeExerciseKind.recognition, 3),
        s.voiceLine(CafeExerciseKind.recognition, 0));
  });

  test('jeder Gast hat ≥2 verschiedene Einstiegszeilen, rotierend', () {
    for (final guest in CafeGuest.values) {
      final s = scriptFor(guest);
      expect(s.entry(0), isNotNull, reason: '$guest ohne Einstieg');
      expect(s.entry(0), isNot(s.entry(1)), reason: '$guest: nur 1 Einstieg');
      expect(s.entry(s.entries.length), s.entry(0));
    }
  });

  test('alle vier Gäste reagieren auf richtig, falsch und Hinweis', () {
    for (final guest in CafeGuest.values) {
      expect(scriptFor(guest).lines.keys,
          containsAll([CafeOutcome.correct, CafeOutcome.wrong, CafeOutcome.hinted]),
          reason: '$guest');
    }
  });

  test('Stimm-Zeilen tragen weder Wort noch Bedeutung: keine Kana/Kanji, '
      'keine Platzhalter (INV-9 strukturell)', () {
    final japanese = RegExp(r'[぀-ヿ一-鿿]');
    for (final guest in CafeGuest.values) {
      final s = scriptFor(guest);
      for (final kind in [
        CafeExerciseKind.recognition,
        CafeExerciseKind.readingInput,
        CafeExerciseKind.productionInput,
      ]) {
        for (var i = 0; i < 3; i++) {
          final line = s.voiceLine(kind, i);
          if (line == null) continue;
          expect(line, isNot(matches(japanese)), reason: '$guest/$kind: $line');
          expect(line, isNot(contains('{')), reason: '$guest/$kind: $line');
          expect(line.trim(), isNotEmpty);
        }
      }
    }
  });

  test('das Schulkind klingt beim Fragen nicht wie die Wirtin', () {
    final w = scriptFor(CafeGuest.wirtin).voiceLine(CafeExerciseKind.recognition, 0);
    final k = scriptFor(CafeGuest.schulkind).voiceLine(CafeExerciseKind.recognition, 0);
    expect(w, isNot(k));
  });
}
