# Café-Stimmen — Umsetzungsplan (Plan 1 von 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** In Akt 2 der Nachbesprechung fragen alle vier Café-Gäste blockweise mit, jeder in seinem Ton — die Wirtin rahmt, die Übungsform folgt weiter der Sprosse. Ohne neue Bilder sofort auf dem Gerät erlebbar.

**Architecture:** Drei kleine Bausteine auf dem bestehenden Café: (1) `CafeGuestScript` wird zur vollständigen *Stimme* (Reaktionen + Stimm-Zeilen je Übungsform + Einstiegszeilen), (2) ein reiner **Sprecherplan** (`speakerPlan`) verteilt die Turns einer Warteschlange auf Blöcke von drei, (3) `CafeTurnScreen` nimmt optional einen Plan entgegen und zieht Titel, Stimm-Zeile, Übergabe und Reaktion vom jeweiligen Sprecher. Der normale Besuch (ein Gast = eine Sprosse) bleibt exakt wie heute; nur die Nachbesprechung übergibt einen Plan.

**Tech Stack:** Flutter 3.44, Dart 3 (Records, Switch-Ausdrücke, Enhanced Enums), Drift (`LearningDb.forTesting()`), `flutter_test` Widget-Tests. Keine neuen Abhängigkeiten.

**Spec:** `docs/superpowers/specs/2026-09-18-cafe-szenen-und-stimmen-design.md` — §3.1 (Wer fragt), §4 (Stimmen), §5.1–5.2 (Sprecherplan, Turn-Bildschirm), §6 (Regeln), §9 (Tests). Die Spec reist mit diesem Plan; Ausführende lesen beide.

## Global Constraints

- **Stimme ≠ Sprosse:** Eine Stimme ändert nie die Übungsform. `kindForRung` (`lib/features/cafe/cafe_turn.dart`) bleibt unverändert; Sprecher steuert nur Titel, Text und Reaktion (Spec §6, I1).
- **Keine Bedeutung in der Stimm-Zeile:** Stimm-Zeilen für Erkennen, Lesen, Schreiben enthalten weder Kana/Kanji noch Platzhalter; sie stehen *über* dem Wort (Spec §4, Präzisierung 19.9.). INV-9 bleibt strukturell gewahrt.
- **Deterministisch, kein Zufall:** Alle Rotationen nach Index (`% length`), wie heute in `followUp` (Brief §4.5). Der einzige sitzungsabhängige Wert ist `sessionOffset = DateTime.now().millisecondsSinceEpoch ~/ 60000`, und der wird nur an der Nahtstelle im `CafeDebriefScreen` gebildet, nie in einer reinen Funktion.
- **Mindestmengen (Spec §4):** je Gast ≥ 3 Stimm-Zeilen für Erkennen und Lesen, das Schulkind zusätzlich ≥ 3 für Schreiben, je Gast ≥ 2 Einstiegszeilen, jeder Gast Reaktionen für `correct`, `wrong`, `hinted`.
- **Blöcke von drei** (`cafeBlockSize = 3`): erster Block Wirtin, ab drei Blöcken auch der letzte, dazwischen Schulkind → Vielredner → Gleichaltrige im Kreis (Spec §3.1/§5.1).
- **Kein Zwischenscreen** beim Blockwechsel: Übergabe und Einstieg sind Zeilen im selben Bildschirm, kein eigener Screen, kein Knopf (Brief §6).
- **Normaler Besuch unverändert:** Ohne `speakers` verhält sich `CafeTurnScreen` wie heute (Titel = Gast, Reaktionen = Gast); alle bestehenden Café-Tests bleiben grün.
- **Sprache der Texte:** Deutsch, Du-Form, Stil laut Steckbrief (Spec §4). Bestehende Reaktionszeilen werden nicht umformuliert.
- **Branch:** Umsetzung auf `impl/cafe-stimmen`, abgezweigt von `design/cafe-szenen-stimmen` (enthält Spec + Pläne, gestapelt auf `impl/cafe-nachbesprechung`, PR #48). Draft-PR mit Basis `design/cafe-szenen-stimmen`.
- **Tests laufen mit `flutter test`** im Worktree. Baseline vor Beginn festhalten (Task 0). Die 8 roten `test/mining_packs/ja`-Tests (nativer Tokenizer, fehlende FFI-Lib auf dem NUC) sind vorbestehend und zählen nicht.

---

## Dateistruktur

| Datei | Verantwortung | Änderung |
|---|---|---|
| `lib/features/cafe/cafe_guest_script.dart` | **Die Stimme eines Gastes:** Reaktionen, Stimm-Zeilen je Übungsform, Einstiegszeilen, Steckbriefe als Doku | erweitern (Task 1) |
| `lib/features/cafe/cafe_prompts.dart` | Wirtin-Zeilen der Nachbesprechung (Einladung, Karten-Zeile, Schluss) — neu: Übergabe-Zeile | erweitern (Task 2) |
| `lib/features/cafe/cafe_speaker_plan.dart` | **Sprecherplan:** reine Funktionen `speakerPlan`, `speakerBlockOrdinal`, `isSpeakerChange` | neu (Task 3) |
| `lib/features/cafe/cafe_turn_screen.dart` | Turn-Bildschirm: optionaler `speakers`-Plan, Stimm-Zeile, Sprecherwechsel, Reaktion vom Sprecher | ändern (Task 4) |
| `lib/features/cafe/cafe_debrief_screen.dart` | Akt 2 übergibt den Plan | ändern (Task 5) |
| `test/features/cafe/cafe_guest_script_test.dart` | Stimmen-Invarianten | erweitern (Task 1) |
| `test/features/cafe/cafe_prompts_test.dart` | Übergabe-Zeile | erweitern (Task 2) |
| `test/features/cafe/cafe_speaker_plan_test.dart` | Plan-Invarianten | neu (Task 3) |
| `test/features/cafe/cafe_turn_screen_voices_test.dart` | Sprecherwechsel im Bildschirm | neu (Task 4) |
| `test/features/cafe/cafe_debrief_screen_voices_test.dart` | Nachbesprechung mit mehreren Stimmen | neu (Task 5) |

Schnittstellen zwischen den Tasks (jede Task sieht nur sich selbst — hier stehen die Namen, die Nachbarn benutzen):

```dart
// Task 1 (cafe_guest_script.dart)
class CafeGuestScript {
  final Map<CafeOutcome, List<String>> lines;
  final Map<CafeExerciseKind, List<String>> voice;
  final List<String> entries;
  const CafeGuestScript(this.lines, {this.voice = const {}, this.entries = const []});
  String followUp(CafeOutcome outcome, int turnIndex);
  String? voiceLine(CafeExerciseKind kind, int turnIndex);
  String? entry(int ordinal);
}
CafeGuestScript scriptFor(CafeGuest guest);

// Task 2 (cafe_prompts.dart)
String wirtinHandoverLine(int index);

// Task 3 (cafe_speaker_plan.dart)
const int cafeBlockSize = 3;
List<CafeGuest> speakerPlan(int itemCount, {int blockSize = cafeBlockSize, int sessionOffset = 0});
int speakerBlockOrdinal(List<CafeGuest> plan, int turnIndex, {int blockSize = cafeBlockSize});
bool isSpeakerChange(List<CafeGuest> plan, int turnIndex);

// Task 4 (cafe_turn_screen.dart)
CafeTurnScreen({..., List<CafeGuest>? speakers});   // Länge == initialQueue.length, sonst ignoriert
// Widget-Keys: 'cafe-turn-voice', 'cafe-turn-handover', 'cafe-turn-entry' (neu);
//              'cafe-turn-prompt', 'cafe-turn-followup', 'cafe-turn-next', 'cafe-turn-done' (bestehend)
```

---

### Task 0: Branch und Baseline

**Files:** keine Code-Änderung.

- [ ] **Step 1: Branch anlegen** (im Worktree `design-cafe-szenen-stimmen` oder einem frischen Worktree davon)

```bash
cd /home/uli/projects/nihongo/.claude/worktrees/design-cafe-szenen-stimmen
git fetch origin --quiet
git checkout -b impl/cafe-stimmen design/cafe-szenen-stimmen
```

- [ ] **Step 2: Baseline der Tests festhalten**

Run: `flutter test 2>&1 | tail -3`
Expected: eine Zeile wie `+704 -8: Some tests failed.` — die 8 roten sind `test/mining_packs/ja` (vorbestehend). Zahl notieren; am Ende (Task 6) muss `+` um die neuen Tests gewachsen und `-8` gleich geblieben sein.

Run: `flutter test test/features/cafe 2>&1 | tail -1`
Expected: `All tests passed!`

---

### Task 1: Die Stimme — `CafeGuestScript` mit Stimm-Zeilen, Einstiegen und Steckbriefen

**Files:**
- Modify: `lib/features/cafe/cafe_guest_script.dart` (ganze Datei ersetzen, Inhalt unten)
- Test: `test/features/cafe/cafe_guest_script_test.dart` (erweitern)

**Interfaces:**
- Consumes: `CafeGuest` (`cafe_occupancy.dart`), `CafeOutcome`, `CafeExerciseKind` (`cafe_turn.dart`).
- Produces: `CafeGuestScript.voice`, `.entries`, `voiceLine(kind, turnIndex) → String?`, `entry(ordinal) → String?`; `scriptFor(guest)` unverändert.

- [ ] **Step 1: Fehlschlagende Tests schreiben** — ans Ende von `test/features/cafe/cafe_guest_script_test.dart` (vor der schließenden `}` von `main`) einfügen:

```dart
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
```

- [ ] **Step 2: Tests laufen lassen — müssen fehlschlagen**

Run: `flutter test test/features/cafe/cafe_guest_script_test.dart 2>&1 | tail -5`
Expected: Kompilierfehler `The method 'voiceLine' isn't defined for the type 'CafeGuestScript'`.

- [ ] **Step 3: `cafe_guest_script.dart` vollständig ersetzen**

```dart
import 'cafe_occupancy.dart';
import 'cafe_turn.dart';

/// Die Stimme eines Gastes (Spec Café-Szenen-und-Stimmen §4): Reaktionen je
/// Ergebnis (Brief §4.5: mindestens drei, rotierend), Stimm-Zeilen je
/// Übungsform und Einstiegszeilen beim Blockwechsel. Alles rotiert
/// deterministisch nach Index — nie zufällig, damit Tests es festnageln.
///
/// Die Stimm-Zeile steht ÜBER dem groß gezeigten Wort (bzw. der Bedeutung
/// beim Schreiben) und setzt nichts ein: Sie kann strukturell nie die
/// Antwort verraten (INV-9). Eine Stimme ändert nie die Übungsform — die
/// kommt aus der Sprosse (`kindForRung`), egal wer fragt (Spec §6).
class CafeGuestScript {
  final Map<CafeOutcome, List<String>> lines;

  /// Stimm-Zeilen je Übungsform. Fehlt eine Form, sagt der Gast dazu
  /// nichts — der Turn zeigt dann nur das Wort, wie vor dieser Spec.
  final Map<CafeExerciseKind, List<String>> voice;

  /// Einstiegszeilen, wenn dieser Gast einen Block übernimmt.
  final List<String> entries;

  const CafeGuestScript(this.lines,
      {this.voice = const {}, this.entries = const []});

  String followUp(CafeOutcome outcome, int turnIndex) {
    final options = lines[outcome]!;
    return options[turnIndex % options.length];
  }

  String? voiceLine(CafeExerciseKind kind, int turnIndex) {
    final options = voice[kind];
    if (options == null || options.isEmpty) return null;
    return options[turnIndex % options.length];
  }

  String? entry(int ordinal) {
    if (entries.isEmpty) return null;
    return entries[ordinal % entries.length];
  }
}

/// Die Wirtin (Sprosse 1–2). Steckbrief: geduldig, langsam, wiederholt
/// gern; „du", warm, nie belehrend; kurze Sätze mit Pausen; Tic: sie sagt
/// das Wort einmal vor. Sie eröffnet und schließt die Nachbesprechung.
const _wirtin = CafeGuestScript(
  {
    CafeOutcome.correct: [
      'Genau so.',
      'Ja, richtig — du hörst gut zu.',
      'Schön. Das sitzt jetzt.',
    ],
    CafeOutcome.wrong: [
      'Nicht ganz. Wir sehen es uns zusammen an.',
      'Kein Problem, das wiederholen wir einfach.',
      'Fast. Ich zeige es dir gleich noch einmal.',
    ],
    CafeOutcome.hinted: [
      'Nachsehen ist erlaubt. Beim nächsten Mal von allein.',
      'Gut, dass du nachschaust — es prägt sich trotzdem ein.',
      'Schau ruhig nach. Langsam wird es deins.',
    ],
  },
  voice: {
    CafeExerciseKind.recognition: [
      'Das hier. Was heißt das?',
      'Hör noch einmal hin. Und was bedeutet es?',
      'Das kennst du. Sag mir, was es heißt.',
    ],
    CafeExerciseKind.readingInput: [
      'Wie liest man das? Lass dir Zeit.',
      'Lies es mir vor. Langsam ist gut.',
      'Und wie spricht man das aus? Keine Eile.',
    ],
  },
  entries: [
    'So. Jetzt wieder ich.',
    'Danke. Den Rest nehme ich.',
    'Gut. Weiter bei mir.',
  ],
);

/// Das Schulkind (Sprosse 3). Steckbrief: direkt, kein Keigo, korrigiert
/// schonungslos; „du", frech, von unten nach oben; sehr kurze Sätze, oft
/// ein Wort; Tic: „Schnell!", „Easy.", „Nee." Im normalen Besuch fragt es
/// nur Schreiben (Sprosse 3); in der Nachbesprechung fragt es „mit" —
/// Erkennen und Lesen in seinem Ton, die Übungsform bleibt die der Sprosse.
const _schulkind = CafeGuestScript(
  {
    CafeOutcome.correct: [
      'Ha, gewusst!',
      'Klar, easy.',
      'Siehst du, geht doch.',
    ],
    CafeOutcome.wrong: [
      'Nee. Falsch.',
      'Das heißt das gar nicht!',
      'Nochmal — aber richtig diesmal.',
    ],
    CafeOutcome.hinted: [
      'Spicken gilt nicht!',
      'Nachgucken? Schwach.',
      'Nächstes Mal ohne Buch, ja?',
    ],
  },
  voice: {
    CafeExerciseKind.recognition: [
      'Was heißt das? Schnell!',
      'Das da. Weißt du das? Los.',
      'Easy. Was heißt es?',
    ],
    CafeExerciseKind.readingInput: [
      'Lies mal vor. Ohne Stottern.',
      'Wie liest man das? Zack.',
      'Vorlesen! Ich hör zu.',
    ],
    CafeExerciseKind.productionInput: [
      'Wie sagt man das? Schreib es hin.',
      'Auf Japanisch, bitte. Schnell.',
      'Das Wort dazu — du kannst das. Los.',
    ],
  },
  entries: [
    'Darf ich auch mal? Die leichten nehm ich.',
    'Jetzt ich! Pass auf.',
  ],
);

/// Der Vielredner (Sprosse 4). Steckbrief: Monologe, Comprehensible Input;
/// „du", als säße man schon Stunden zusammen; lange, abschweifende Sätze,
/// die IMMER in der Frage enden; Tic: „Ach, weißt du …", „wo wir gerade
/// dabei sind". Sein Monolog auf Sprosse 4 bleibt in `cafe_prompts.dart`.
const _vielredner = CafeGuestScript(
  {
    CafeOutcome.correct: [
      'Ha, genau! Wusste ich, dass du es hast.',
      'Siehst du — du verstehst mehr, als du denkst.',
      'Genau das, ja. Bei so viel Gerede muss man ja was mitnehmen.',
    ],
    CafeOutcome.wrong: [
      'Kein Ding, das war auch viel Gerede. Nächstes.',
      'Ich rede halt zu viel — das hört sich noch ein.',
      'Macht nichts, das kriegst du beim nächsten Mal.',
    ],
    CafeOutcome.hinted: [
      'Nachgeschaut, auch gut — Hauptsache, es bleibt hängen.',
      'Klar, schau nach. Bei mir verliert man schon mal den Faden.',
      'Passt, so lernt man es auch.',
    ],
  },
  voice: {
    CafeExerciseKind.recognition: [
      'Ach, weißt du, neulich am Tresen fiel genau das hier. '
          'Und was heißt es noch gleich?',
      'Ich sag dir, den ganzen Tag ging es um so was. '
          'Das da — was war das noch?',
      'Wo wir gerade dabei sind: Das hier hab ich gestern dreimal gehört. '
          'Was bedeutet es?',
    ],
    CafeExerciseKind.readingInput: [
      'Stand groß an der Tür, so wie das hier. Wie spricht man das aus?',
      'Ach, weißt du, ich les das immer falsch. Wie liest man das richtig?',
      'Das da hat der Alte von nebenan ständig gesagt. '
          'Wie klingt das, wenn man es liest?',
    ],
  },
  entries: [
    'Ach, wo wir gerade dabei sind — ich hätte da auch was.',
    'Moment, das erinnert mich an etwas. Darf ich?',
  ],
);

/// Die Gleichaltrige (Sprosse 5). Steckbrief: offenes Gespräch, kein
/// richtig/falsch auf Sprosse 5; „du", auf Augenhöhe; mittellange,
/// beiläufige Sätze; Tic: „Sag mal …", „Ich glaub …". Fragt sie in der
/// Nachbesprechung Erkennen oder Lesen, reagiert sie weich auf richtig,
/// falsch und Hinweis (neu). Ihre Eröffnung auf Sprosse 5 bleibt in
/// `cafe_prompts.dart`.
const _gleichaltrige = CafeGuestScript(
  {
    CafeOutcome.freeProduced: [
      'Schön gesagt. Weiter geht es.',
      'Ja, so ungefähr würde ich es auch sagen.',
      'Gefällt mir. Nächstes?',
      'Cool, du traust dich was.',
    ],
    CafeOutcome.correct: [
      'Ja, genau das.',
      'Stimmt. Hätte ich auch gesagt.',
      'Genau. Siehst du, das sitzt.',
    ],
    CafeOutcome.wrong: [
      'Hm, nee — ich glaub, das war was anderes.',
      'Ich glaub nicht. Schau nochmal hin.',
      'Fast, aber nicht ganz. Kommt schon noch.',
    ],
    CafeOutcome.hinted: [
      'Klar, schau nach. Mach ich auch.',
      'Nachgucken ist okay. Nächstes Mal ohne.',
      'Ich glaub, das merkst du dir jetzt.',
    ],
  },
  voice: {
    CafeExerciseKind.recognition: [
      'Sag mal, das hier — was hieß das gleich?',
      'Ich glaub, das hatten wir. Was heißt es?',
      'Kennst du das noch? Was bedeutet es?',
    ],
    CafeExerciseKind.readingInput: [
      'Wie sagt man das? Ich hab es neulich falsch gelesen.',
      'Sag mal, wie liest man das eigentlich?',
      'Ich glaub, ich spreche das immer falsch aus. Wie geht es richtig?',
    ],
  },
  entries: [
    'Ich hab da auch noch was.',
    'Sag mal, darf ich kurz?',
  ],
);

/// The script for a guest.
CafeGuestScript scriptFor(CafeGuest guest) => switch (guest) {
      CafeGuest.wirtin => _wirtin,
      CafeGuest.schulkind => _schulkind,
      CafeGuest.vielredner => _vielredner,
      CafeGuest.gleichaltrige => _gleichaltrige,
    };
```

- [ ] **Step 4: Tests laufen lassen — grün**

Run: `flutter test test/features/cafe/cafe_guest_script_test.dart 2>&1 | tail -1`
Expected: `All tests passed!` (die 4 alten + 6 neuen).

- [ ] **Step 5: Zählen, dass die Spec-Menge stimmt** (45 neue Zeilen: 27 Stimm-Zeilen + 9 Einstiege + 9 Reaktionen der Gleichaltrigen)

Run: `grep -c "^      '" lib/features/cafe/cafe_guest_script.dart`
Expected: `67` — Reaktionen und Stimm-Zeilen stehen mit sechs Leerzeichen Einzug: 31 alte Reaktionen + 27 Stimm-Zeilen + 9 Reaktionen der Gleichaltrigen (die drei mehrzeiligen Vielredner-Zeilen zählen je einmal, ihre Fortsetzungen beginnen mit zehn Leerzeichen).

Run: `grep -c "^    '" lib/features/cafe/cafe_guest_script.dart`
Expected: `9` — die Einstiegszeilen stehen mit vier Leerzeichen Einzug (3 + 2 + 2 + 2). Zusammen 27 + 9 + 9 = 45 neue Zeilen (Spec §4).

- [ ] **Step 6: Commit**

```bash
git add lib/features/cafe/cafe_guest_script.dart test/features/cafe/cafe_guest_script_test.dart
git commit -m "feat(cafe): Stimmen — Stimm-Zeilen, Einstiege und Steckbriefe je Gast; Gleichaltrige reagiert auf richtig/falsch/Hinweis"
```

---

### Task 2: Die Übergabe-Zeile der Wirtin

**Files:**
- Modify: `lib/features/cafe/cafe_prompts.dart` (ans Dateiende)
- Test: `test/features/cafe/cafe_prompts_test.dart` (erweitern)

**Interfaces:**
- Produces: `String wirtinHandoverLine(int index)`.

- [ ] **Step 1: Fehlschlagenden Test schreiben** — in `test/features/cafe/cafe_prompts_test.dart` vor der schließenden `}` von `main`:

```dart
  test('die Wirtin gibt mit drei verschiedenen Zeilen ab, rotierend', () {
    final lines = {for (var i = 0; i < 3; i++) wirtinHandoverLine(i)};
    expect(lines.length, 3);
    expect(wirtinHandoverLine(3), wirtinHandoverLine(0));
    for (final line in lines) {
      expect(line.trim(), isNotEmpty);
    }
  });
```

- [ ] **Step 2: Test laufen lassen — muss fehlschlagen**

Run: `flutter test test/features/cafe/cafe_prompts_test.dart 2>&1 | tail -3`
Expected: `The function 'wirtinHandoverLine' isn't defined`.

- [ ] **Step 3: Funktion anhängen** — ans Ende von `lib/features/cafe/cafe_prompts.dart`:

```dart

/// Die Wirtin gibt in der Nachbesprechung einen Block an einen Gast ab
/// (Spec Café-Szenen-und-Stimmen §3.1) — eine Zeile im selben Bildschirm,
/// kein Zwischenscreen (Brief §6). Rotiert nach Blocknummer.
String wirtinHandoverLine(int index) {
  const lines = [
    'Frag du mal.',
    'Nimm du die nächsten.',
    'Mach du weiter, ich hol Tee.',
  ];
  return lines[index % lines.length];
}
```

- [ ] **Step 4: Test grün**

Run: `flutter test test/features/cafe/cafe_prompts_test.dart 2>&1 | tail -1`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_prompts.dart test/features/cafe/cafe_prompts_test.dart
git commit -m "feat(cafe): Übergabe-Zeile der Wirtin beim Blockwechsel"
```

---

### Task 3: Der Sprecherplan (reine Funktionen)

**Files:**
- Create: `lib/features/cafe/cafe_speaker_plan.dart`
- Test: `test/features/cafe/cafe_speaker_plan_test.dart`

**Interfaces:**
- Consumes: `CafeGuest` (`cafe_occupancy.dart`).
- Produces: `cafeBlockSize`, `speakerPlan(itemCount, {blockSize, sessionOffset}) → List<CafeGuest>`, `speakerBlockOrdinal(plan, turnIndex, {blockSize}) → int`, `isSpeakerChange(plan, turnIndex) → bool`.

- [ ] **Step 1: Fehlschlagende Tests schreiben** — `test/features/cafe/cafe_speaker_plan_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_speaker_plan.dart';

void main() {
  const w = CafeGuest.wirtin;
  const s = CafeGuest.schulkind;
  const v = CafeGuest.vielredner;
  const g = CafeGuest.gleichaltrige;

  /// Ein Sprecher je Block (jeder dritte Eintrag).
  List<CafeGuest> blocksOf(List<CafeGuest> plan) =>
      [for (var i = 0; i < plan.length; i += cafeBlockSize) plan[i]];

  test('18 Items, Offset 0 → Wirtin, Schulkind, Vielredner, Gleichaltrige, '
      'Schulkind, Wirtin (Spec §3.1)', () {
    final plan = speakerPlan(18);
    expect(plan.length, 18);
    expect(blocksOf(plan), [w, s, v, g, s, w]);
    // Innerhalb eines Blocks bleibt der Sprecher gleich.
    for (var i = 0; i < 18; i++) {
      expect(plan[i], plan[i - i % cafeBlockSize]);
    }
  });

  test('der Sitzungs-Offset dreht den Kreis der drei anderen', () {
    expect(blocksOf(speakerPlan(18, sessionOffset: 1)), [w, v, g, s, v, w]);
    expect(blocksOf(speakerPlan(18, sessionOffset: 2)), [w, g, s, v, g, w]);
    expect(blocksOf(speakerPlan(18, sessionOffset: 3)),
        blocksOf(speakerPlan(18, sessionOffset: 0)));
  });

  test('drei Blöcke: die Wirtin rahmt (erster und letzter Block)', () {
    expect(blocksOf(speakerPlan(9)), [w, s, w]);
  });

  test('zwei Blöcke: Wirtin und eine zweite Stimme, keine Rahmung', () {
    expect(blocksOf(speakerPlan(6)), [w, s]);
    // Angebrochener zweiter Block (4 Items): W W W S.
    expect(speakerPlan(4), [w, w, w, s]);
  });

  test('ein Block oder nichts: nur die Wirtin', () {
    expect(speakerPlan(3), [w, w, w]);
    expect(speakerPlan(1), [w]);
    expect(speakerPlan(0), isEmpty);
    expect(speakerPlan(-2), isEmpty);
  });

  test('ab fünf Blöcken kommen alle drei anderen vor', () {
    final blocks = blocksOf(speakerPlan(15)).toSet();
    expect(blocks, containsAll([w, s, v, g]));
  });

  test('speakerBlockOrdinal zählt die Blöcke desselben Sprechers', () {
    final plan = speakerPlan(18); // W S V G S W
    expect(speakerBlockOrdinal(plan, 0), 0); // Wirtin, 1. Block
    expect(speakerBlockOrdinal(plan, 4), 0); // Schulkind, 1. Block
    expect(speakerBlockOrdinal(plan, 13), 1); // Schulkind, 2. Block
    expect(speakerBlockOrdinal(plan, 16), 1); // Wirtin, 2. Block
    expect(speakerBlockOrdinal(plan, 99), 0); // außerhalb: harmlos
  });

  test('isSpeakerChange nur am ersten Turn eines Blocks mit neuem Sprecher',
      () {
    final plan = speakerPlan(18);
    expect(isSpeakerChange(plan, 0), isFalse);
    expect(isSpeakerChange(plan, 2), isFalse);
    expect(isSpeakerChange(plan, 3), isTrue);
    expect(isSpeakerChange(plan, 4), isFalse);
    expect(isSpeakerChange(plan, 15), isTrue);
    expect(isSpeakerChange(plan, 18), isFalse);
    expect(isSpeakerChange(const [w, w, w], 1), isFalse);
  });
}
```

- [ ] **Step 2: Tests laufen lassen — müssen fehlschlagen**

Run: `flutter test test/features/cafe/cafe_speaker_plan_test.dart 2>&1 | tail -3`
Expected: `Error: Couldn't resolve the package 'nihongo_app' … cafe_speaker_plan.dart` bzw. `Target of URI doesn't exist`.

- [ ] **Step 3: `lib/features/cafe/cafe_speaker_plan.dart` anlegen**

```dart
import 'cafe_occupancy.dart';

/// Wer in Akt 2 der Nachbesprechung welchen Turn fragt (Spec
/// Café-Szenen-und-Stimmen §3.1/§5.1): Blöcke von [cafeBlockSize] Turns.
/// Den ersten Block hat die Wirtin, ab drei Blöcken auch den letzten;
/// dazwischen kreisen Schulkind → Vielredner → Gleichaltrige, Startpunkt
/// aus dem Sitzungs-Offset. Reine Funktionen, kein Zufall: gleicher Input,
/// gleicher Plan. Die Stimme ändert nie die Übungsform — die kommt weiter
/// aus der Sprosse (`kindForRung`, Spec §6).
const int cafeBlockSize = 3;

const List<CafeGuest> _others = [
  CafeGuest.schulkind,
  CafeGuest.vielredner,
  CafeGuest.gleichaltrige,
];

List<CafeGuest> speakerPlan(int itemCount,
    {int blockSize = cafeBlockSize, int sessionOffset = 0}) {
  if (itemCount <= 0) return const [];
  final blocks = (itemCount + blockSize - 1) ~/ blockSize;
  final start = sessionOffset % _others.length;
  final plan = <CafeGuest>[];
  for (var b = 0; b < blocks; b++) {
    final frames = b == 0 || (blocks >= 3 && b == blocks - 1);
    final speaker =
        frames ? CafeGuest.wirtin : _others[(start + b - 1) % _others.length];
    final remaining = itemCount - plan.length;
    plan.addAll(
        List.filled(remaining < blockSize ? remaining : blockSize, speaker));
  }
  return plan;
}

/// Ordnungszahl des bei [turnIndex] laufenden Blocks unter den Blöcken
/// desselben Sprechers (0 = sein erster Block). Damit rotieren Einstiegs-
/// zeile und Szene je Sprecher, nicht global. Außerhalb des Plans: 0.
int speakerBlockOrdinal(List<CafeGuest> plan, int turnIndex,
    {int blockSize = cafeBlockSize}) {
  if (turnIndex < 0 || turnIndex >= plan.length) return 0;
  final speaker = plan[turnIndex];
  final block = turnIndex ~/ blockSize;
  var ordinal = 0;
  for (var b = 0; b < block; b++) {
    if (plan[b * blockSize] == speaker) ordinal++;
  }
  return ordinal;
}

/// True, wenn bei [turnIndex] ein anderer Sprecher übernimmt als beim Turn
/// davor. Am ersten Turn und außerhalb des Plans: false.
bool isSpeakerChange(List<CafeGuest> plan, int turnIndex) =>
    turnIndex > 0 &&
    turnIndex < plan.length &&
    plan[turnIndex] != plan[turnIndex - 1];
```

- [ ] **Step 4: Tests grün**

Run: `flutter test test/features/cafe/cafe_speaker_plan_test.dart 2>&1 | tail -1`
Expected: `All tests passed!` (8 Tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_speaker_plan.dart test/features/cafe/cafe_speaker_plan_test.dart
git commit -m "feat(cafe): Sprecherplan — Blöcke von drei, Wirtin rahmt, drei Stimmen im Kreis"
```

---

### Task 4: Der Turn-Bildschirm spricht mit mehreren Stimmen

**Files:**
- Modify: `lib/features/cafe/cafe_turn_screen.dart`
- Test: `test/features/cafe/cafe_turn_screen_voices_test.dart` (neu)

**Interfaces:**
- Consumes: Task 1 (`voiceLine`, `entry`, `scriptFor`), Task 2 (`wirtinHandoverLine`), Task 3 (`speakerPlan`-Ergebnis als `speakers`, `speakerBlockOrdinal`, `isSpeakerChange`, `cafeBlockSize`).
- Produces: Konstruktor-Parameter `List<CafeGuest>? speakers`; Widget-Keys `cafe-turn-voice`, `cafe-turn-handover`, `cafe-turn-entry`. Titel der Leiste = Name des aktuellen Sprechers; nach der Warteschlange wieder der Gast (`widget.guest`).

Verhalten im Detail:
- `speakers == null` **oder** Länge ≠ Länge der Warteschlange → `List.filled(queue.length, widget.guest)` (wie heute). So bleibt der normale Besuch unberührt, auch wenn ein Aufrufer einen falschen Plan mitgibt.
- Sprecher des Turns: `_speakers[_index]` (außerhalb: `widget.guest`).
- Stimm-Zeile: `scriptFor(speaker).voiceLine(kind, _index)` für Erkennen, Lesen, Schreiben; für Monolog (Sprosse 4) und freie Produktion (Sprosse 5) bleibt es beim heutigen Kopftext ohne zusätzliche Zeile.
- Blockwechsel (`isSpeakerChange`): Vorheriger Sprecher Wirtin → zuerst `wirtinHandoverLine(_index ~/ cafeBlockSize)`; dann `entry(speakerBlockOrdinal(...))` des neuen Sprechers. Beide als kursive Zeilen über der Stimm-Zeile, im selben Bildschirm.
- Reaktion: `scriptFor(speaker).followUp(outcome, _index)`.

- [ ] **Step 1: Fehlschlagende Tests schreiben** — `test/features/cafe/cafe_turn_screen_voices_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_guest_script.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_prompts.dart';
import 'package:nihongo_app/features/cafe/cafe_turn.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';

void main() {
  late LearningDb db;
  late List<LearnItem> items;

  const words = ['あめ', 'かさ', 'えき', 'みせ'];

  setUp(() async {
    db = LearningDb.forTesting();
    items = [];
    for (var i = 0; i < words.length; i++) {
      final concept = 'concept_$i';
      final lexeme = 'lex_ja_$i';
      await db.into(db.concepts).insert(ConceptsCompanion.insert(
          id: concept,
          glossKey: 'gloss_$i',
          partOfSpeech: 'noun',
          defaultAssetType: const Value('image')));
      await db.into(db.lexemes).insert(LexemesCompanion.insert(
          id: lexeme,
          languageId: 'lang_ja',
          conceptId: concept,
          writtenForm: words[i],
          reading: words[i]));
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, lexeme, rung: 1);
      items.add((await db.getLearnItem('lang_ja:lexeme:$lexeme'))!);
    }
  });
  tearDown(() async => db.close());

  Widget screen({List<CafeGuest>? speakers}) => MaterialApp(
        home: CafeTurnScreen(
          db: db,
          guest: CafeGuest.wirtin,
          initialQueue: items,
          speakers: speakers,
          doneLine: 'Ende.',
        ),
      );

  Future<void> answerKnown(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(ValueKey(key))).data!;

  testWidgets('ohne speakers: die Wirtin durchgehend — Stimm-Zeile über dem '
      'Wort, kein Sprecherwechsel, Reaktion von ihr', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsOneWidget);
    expect(textOf(tester, 'cafe-turn-voice'),
        scriptFor(CafeGuest.wirtin).voiceLine(CafeExerciseKind.recognition, 0));
    expect(find.byKey(const ValueKey('cafe-turn-handover')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-turn-entry')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    expect(textOf(tester, 'cafe-turn-followup'),
        scriptFor(CafeGuest.wirtin).followUp(CafeOutcome.correct, 0));

    // Auch der vierte Turn bleibt bei der Wirtin.
    await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await answerKnown(tester);
    }
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-handover')), findsNothing);
  });

  testWidgets('mit speakers [W,W,W,S]: ab Turn 4 fragt das Schulkind — '
      'Titel, Übergabe, Einstieg, eigene Stimme und Reaktion; am Ende wieder '
      'die Wirtin', (tester) async {
    await tester.pumpWidget(screen(speakers: const [
      CafeGuest.wirtin,
      CafeGuest.wirtin,
      CafeGuest.wirtin,
      CafeGuest.schulkind,
    ]));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(const ValueKey('cafe-turn-handover')), findsNothing);
      await answerKnown(tester);
    }

    expect(find.widgetWithText(AppBar, 'Das Schulkind'), findsOneWidget);
    expect(textOf(tester, 'cafe-turn-handover'), wirtinHandoverLine(1));
    expect(textOf(tester, 'cafe-turn-entry'),
        scriptFor(CafeGuest.schulkind).entry(0));
    expect(textOf(tester, 'cafe-turn-voice'),
        scriptFor(CafeGuest.schulkind)
            .voiceLine(CafeExerciseKind.recognition, 3));
    // Die Übungsform ist die der Sprosse (Erkennen), nicht die des
    // Schulkinds (Schreiben): Erkennen-Knöpfe, kein Eingabefeld.
    expect(find.byKey(const ValueKey('cafe-turn-known')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-input')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    expect(textOf(tester, 'cafe-turn-followup'),
        scriptFor(CafeGuest.schulkind).followUp(CafeOutcome.correct, 3));

    await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-turn-done-line')), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    expect(await db.select(db.reviewLog).get(), hasLength(4));
  });

  testWidgets('ein Plan falscher Länge wird ignoriert — Wirtin überall',
      (tester) async {
    await tester.pumpWidget(screen(speakers: const [CafeGuest.schulkind]));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    await answerKnown(tester);
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-handover')), findsNothing);
  });

  testWidgets('Wechsel zwischen zwei Gästen ohne Wirtin: Einstieg, aber keine '
      'Übergabe-Zeile', (tester) async {
    await tester.pumpWidget(screen(speakers: const [
      CafeGuest.vielredner,
      CafeGuest.vielredner,
      CafeGuest.vielredner,
      CafeGuest.gleichaltrige,
    ]));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Der Vielredner'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await answerKnown(tester);
    }
    expect(find.widgetWithText(AppBar, 'Die Gleichaltrige'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-handover')), findsNothing);
    expect(textOf(tester, 'cafe-turn-entry'),
        scriptFor(CafeGuest.gleichaltrige).entry(0));
  });

  testWidgets('Sprosse 2 (Lesen): die Stimm-Zeile der Lese-Form steht über '
      'dem Wort, das Eingabefeld bleibt', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_0', rung: 2);
    final item = (await db.getLearnItem('lang_ja:lexeme:lex_ja_0'))!;
    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(
          db: db, guest: CafeGuest.wirtin, initialQueue: [item]),
    ));
    await tester.pumpAndSettle();
    expect(textOf(tester, 'cafe-turn-voice'),
        scriptFor(CafeGuest.wirtin).voiceLine(CafeExerciseKind.readingInput, 0));
    expect(find.byKey(const ValueKey('cafe-turn-input')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Tests laufen lassen — müssen fehlschlagen**

Run: `flutter test test/features/cafe/cafe_turn_screen_voices_test.dart 2>&1 | tail -3`
Expected: `No named parameter with the name 'speakers'`.

- [ ] **Step 3: `cafe_turn_screen.dart` ändern** — fünf Stellen:

(a) Imports: nach `import 'cafe_prompts.dart';` einfügen:

```dart
import 'cafe_speaker_plan.dart';
```

(b) Widget-Felder: nach dem Feld `final List<Episode> episodes;` einfügen und den Konstruktor ergänzen:

```dart
  /// Sprecher je Turn der Warteschlange (Spec Café-Szenen-und-Stimmen
  /// §3.1): die Nachbesprechung übergibt `speakerPlan(...)`, der normale
  /// Besuch nichts. Null oder falsche Länge = überall [guest] wie bisher.
  /// Die Stimme ändert nie die Übungsform (§6) — die kommt aus der Sprosse.
  final List<CafeGuest>? speakers;

  const CafeTurnScreen({
    super.key,
    required this.db,
    required this.guest,
    this.languageId = 'lang_ja',
    this.bridge,
    this.initialQueue,
    this.doneLine,
    this.episodes = const [],
    this.speakers,
  });
```

(c) State: die Zeile `late final CafeGuestScript _script = scriptFor(widget.guest);` **löschen** und stattdessen nach `bool _loading = true;` einfügen:

```dart
  /// Ein Sprecher je Turn — aus [CafeTurnScreen.speakers] oder überall der
  /// Gast. Wird in [_load] gesetzt, sobald die Warteschlange steht.
  List<CafeGuest> _speakers = const [];

  /// Zeilen beim Blockwechsel (Übergabe der Wirtin, Einstieg des neuen
  /// Sprechers), als (Key, Text). Leer, wenn kein Wechsel ansteht.
  List<(String, String)> _blockIntro = const [];

  CafeGuest get _speaker =>
      _index < _speakers.length ? _speakers[_index] : widget.guest;

  CafeGuestScript get _script => scriptFor(_speaker);
```

In `_load` den `setState` ersetzen durch:

```dart
    setState(() {
      _queue = List.of(queue);
      final plan = widget.speakers;
      _speakers = plan != null && plan.length == queue.length
          ? List.of(plan)
          : List.filled(queue.length, widget.guest);
      _loading = false;
    });
```

(d) In `_prepareTurn` vor dem abschließenden `setState` die Intro-Zeilen berechnen und im `setState` setzen:

```dart
    final intro = <(String, String)>[];
    if (isSpeakerChange(_speakers, _index)) {
      if (_speakers[_index - 1] == CafeGuest.wirtin) {
        intro.add(('cafe-turn-handover',
            wirtinHandoverLine(_index ~/ cafeBlockSize)));
      }
      final entry = scriptFor(_speakers[_index])
          .entry(speakerBlockOrdinal(_speakers, _index));
      if (entry != null) intro.add(('cafe-turn-entry', entry));
    }
    setState(() {
      _content = content;
      _encounterCard = encounterCard;
      _blockIntro = intro;
      _hintUsed = false;
      _revealed = false;
      _followUp = null;
      _input.clear();
    });
```

(e) `build`: Titel auf den Sprecher umstellen — die Zeile `appBar: AppBar(title: Text(_guestName(widget.guest))),` ersetzen durch:

```dart
      appBar: AppBar(
        title: Text(_guestName(_content == null ? widget.guest : _speaker)),
      ),
```

(f) `_buildTurn`: nach `final headerText = switch (...) {...};` die Stimm-Zeile bestimmen und die Kinder der `Column` am Anfang ergänzen. Der Anfang der Methode lautet danach:

```dart
  Widget _buildTurn(CafeTurnContent content) {
    final followUp = _followUp;
    final isMonologue = content.kind == CafeExerciseKind.comprehension ||
        content.kind == CafeExerciseKind.freeProduction;
    final headerText = switch (content.kind) {
      CafeExerciseKind.comprehension =>
        vielrednerMonologue(content.writtenForm, _index),
      CafeExerciseKind.freeProduction =>
        gleichaltrigeOpener(content.writtenForm, _index),
      _ => content.promptText,
    };
    // Die Stimm-Zeile steht ÜBER dem Wort und setzt nichts ein (Spec §4);
    // Monolog und Eröffnung tragen ihre Stimme schon im Kopftext.
    final voiceLine = isMonologue ? null : _script.voiceLine(content.kind, _index);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (key, line) in _blockIntro)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line,
                  key: ValueKey(key),
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
          if (voiceLine != null) ...[
            Text(voiceLine,
                key: const ValueKey('cafe-turn-voice'),
                style:
                    const TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
            const SizedBox(height: 8),
          ],
          Text(headerText,
              key: ValueKey(
                  isMonologue ? 'cafe-turn-monologue' : 'cafe-turn-prompt'),
              style: TextStyle(fontSize: isMonologue ? 18 : 28)),
```

Der Rest der Methode (ab `const SizedBox(height: 16),` nach dem Kopftext) bleibt unverändert.

(g) Kommentar in `_gradeFree` aktualisieren (Verhalten unverändert):

```dart
  Future<void> _gradeFree() async {
    if (_content == null) return;
    // Freie Produktion (Sprosse 5) wird gehalten, nicht benotet: bewusst
    // kein [CafeOutcome.hinted], auch wenn ein Hinweis lief — beide Ausgänge
    // terminieren ohnehin als `hard` (Brief §4.4). Die Gleichaltrige hat
    // seit der Stimmen-Spec auch correct/wrong/hinted-Zeilen, aber die
    // gelten für Erkennen/Lesen in der Nachbesprechung, nicht hier.
    await _submitOutcome(CafeOutcome.freeProduced);
  }
```

- [ ] **Step 4: Tests grün — neue und alte**

Run: `flutter test test/features/cafe/cafe_turn_screen_voices_test.dart 2>&1 | tail -1`
Expected: `All tests passed!` (5 Tests).

Run: `flutter test test/features/cafe 2>&1 | tail -1`
Expected: `All tests passed!` — insbesondere `cafe_turn_screen_test.dart`, `cafe_turn_screen_queue_test.dart`, `cafe_turn_screen_explain_test.dart`, `cafe_debrief_screen_test.dart` unverändert grün (normaler Besuch unberührt).

- [ ] **Step 5: Analyse sauber**

Run: `flutter analyze lib/features/cafe test/features/cafe 2>&1 | tail -2`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/cafe/cafe_turn_screen.dart test/features/cafe/cafe_turn_screen_voices_test.dart
git commit -m "feat(cafe): Turn-Bildschirm mit Sprecherplan — Stimm-Zeile über dem Wort, Übergabe und Einstieg beim Blockwechsel, Reaktion vom Sprecher"
```

---

### Task 5: Die Nachbesprechung übergibt den Sprecherplan

**Files:**
- Modify: `lib/features/cafe/cafe_debrief_screen.dart` (`_finishExplain`)
- Test: `test/features/cafe/cafe_debrief_screen_voices_test.dart` (neu)

**Interfaces:**
- Consumes: Task 3 `speakerPlan`, Task 4 `CafeTurnScreen(speakers: …)`.
- Produces: nichts Neues nach außen. Sitzungs-Offset = `DateTime.now().millisecondsSinceEpoch ~/ 60000` (dieselbe Größe wie für die Schlusszeile).

- [ ] **Step 1: Fehlschlagenden Test schreiben** — `test/features/cafe/cafe_debrief_screen_voices_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_debrief_screen.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

const _words = ['あめ', 'かさ', 'えき', 'みせ', 'ここ', 'はい'];

/// Sechs Wörter in einer Blase → sechs Items, zwei Blöcke → die Wirtin und
/// eine zweite Stimme (Spec §3.1: zwei Blöcke rahmen nicht).
Map<String, dynamic> _episodeJson() => {
      'id': 'ep_test_voices',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          for (var i = 0; i < _words.length; i++)
            {'id': 'lex_ja_$i', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'assets/story/p01.jpg',
              'bubbles': [
                {
                  'speakerId': 'x',
                  'text': _words.join('、'),
                  'tokens': [
                    for (var i = 0; i < _words.length; i++)
                      {'surface': _words[i], 'itemId': 'lex_ja_$i'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    };

void main() {
  late LearningDb db;
  late StoryProgressStore store;
  late Episode episode;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = StoryProgressStore(await SharedPreferences.getInstance());
    db = LearningDb.forTesting();
    episode = Episode.fromJson(_episodeJson());
    for (var i = 0; i < _words.length; i++) {
      await db.into(db.concepts).insert(ConceptsCompanion.insert(
          id: 'concept_$i',
          glossKey: 'gloss_$i',
          partOfSpeech: 'noun',
          defaultAssetType: const Value('image')));
      await db.into(db.lexemes).insert(LexemesCompanion.insert(
          id: 'lex_ja_$i',
          languageId: 'lang_ja',
          conceptId: 'concept_$i',
          writtenForm: _words[i],
          reading: _words[i]));
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_$i',
          rung: 0);
    }
  });
  tearDown(() async => db.close());

  Future<void> tapVerstanden(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pumpAndSettle();
  }

  Future<void> answerKnown(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
    await tester.pumpAndSettle();
  }

  testWidgets('Akt 2: Block 1 fragt die Wirtin, Block 2 eine andere Stimme '
      '(Übergabe + Einstieg), am Ende die Schlusszeile', (tester) async {
    await tester.pumpWidget(_wrap(CafeDebriefScreen(
        db: db, episode: episode, progressStore: store)));
    await tester.pumpAndSettle();
    for (var i = 0; i < _words.length; i++) {
      await tapVerstanden(tester);
    }
    expect(find.byKey(const ValueKey('cafe-turn-screen')), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-voice')), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await answerKnown(tester);
    }
    // Welche der drei Stimmen, hängt vom Sitzungs-Offset ab — aber nie die
    // Wirtin, und immer mit Übergabe und Einstieg.
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsNothing);
    expect(find.byKey(const ValueKey('cafe-turn-handover')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-entry')), findsOneWidget);
    // Sprosse 1 → Erkennen, egal wer fragt (Stimme ≠ Sprosse).
    expect(find.byKey(const ValueKey('cafe-turn-known')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-input')), findsNothing);

    for (var i = 0; i < 3; i++) {
      await answerKnown(tester);
    }
    expect(find.byKey(const ValueKey('cafe-turn-done-line')), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsOneWidget);
    expect(await db.select(db.reviewLog).get(), hasLength(6));
  });
}
```

- [ ] **Step 2: Test laufen lassen — muss fehlschlagen**

Run: `flutter test test/features/cafe/cafe_debrief_screen_voices_test.dart 2>&1 | tail -5`
Expected: FAIL bei `expect(find.widgetWithText(AppBar, 'Die Wirtin'), findsNothing)` — heute fragt die Wirtin alle sechs.

- [ ] **Step 3: `_finishExplain` in `cafe_debrief_screen.dart` ändern**

Import ergänzen (nach `import 'cafe_prompts.dart';`):

```dart
import 'cafe_speaker_plan.dart';
```

Den Block von der bestehenden Zeile `if (!mounted) return;` bis zum schließenden `));` des `pushReplacement` **vollständig** ersetzen durch (der alte Kommentar „Nach Sitzung rotieren …" und die alte `doneLine`-Zeile gehen darin auf — nichts doppelt lassen):

```dart
    if (!mounted) return;
    // Nach Sitzung rotieren, nicht nach Item-Anzahl: an der Anzahl hängend
    // hörte man bei gleich langen Folgen immer denselben Satz — und immer
    // dieselbe Stimmen-Reihenfolge (Spec Café-Szenen-und-Stimmen §3.1).
    final sessionOffset = DateTime.now().millisecondsSinceEpoch ~/ 60000;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => CafeTurnScreen(
        db: widget.db,
        guest: CafeGuest.wirtin,
        languageId: widget.languageId,
        bridge: widget.bridge,
        initialQueue: refreshed,
        speakers: speakerPlan(refreshed.length, sessionOffset: sessionOffset),
        doneLine: wirtinDebriefClosing(sessionOffset),
        episodes: [widget.episode],
      ),
    ));
```

Die Klassendoku oben in der Datei (Zeile „Akt 2: dieselben Items als gewohnte Café-Turns …") um einen Satz ergänzen:

```dart
/// … vorgegebener Warteschlange). Akt 2 spricht mit mehreren Stimmen:
/// [speakerPlan] verteilt die Turns blockweise auf die vier Gäste, die
/// Wirtin rahmt (Spec Café-Szenen-und-Stimmen §3.1). Item-Quelle ist …
```

- [ ] **Step 4: Tests grün**

Run: `flutter test test/features/cafe/cafe_debrief_screen_voices_test.dart test/features/cafe/cafe_debrief_screen_test.dart 2>&1 | tail -1`
Expected: `All tests passed!` — der bestehende Test „Akt 2 endet mit der Schlusszeile" hat 2 Items (ein Block → nur Wirtin) und bleibt grün.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_debrief_screen.dart test/features/cafe/cafe_debrief_screen_voices_test.dart
git commit -m "feat(cafe): Nachbesprechung Akt 2 mit vier Stimmen — Sprecherplan nach Sitzung rotierend"
```

---

### Task 6: Gesamtlauf, Spec-Abgleich, Draft-PR

**Files:** keine Code-Änderung (außer ggf. Fixes aus dem Gesamtlauf).

- [ ] **Step 1: Alle Tests**

Run: `flutter test 2>&1 | tail -3`
Expected: `+<Baseline+26> -8` — 26 neue Tests (Task 1: 6, Task 2: 1, Task 3: 8, Task 4: 5, Task 5: 1 … plus die 5 Widget-Tests zählen einzeln; die genaue Zahl steht in der Ausgabe, entscheidend: `-8` unverändert, keine neuen roten).

Run: `flutter analyze 2>&1 | tail -2`
Expected: `No issues found!`

- [ ] **Step 2: Spec-Abgleich (Checkliste, jeden Punkt im Code zeigen)**

| Spec | Wo |
|---|---|
| §3.1 Blöcke von drei, Wirtin rahmt, Kreis der drei anderen, Offset pro Sitzung | `cafe_speaker_plan.dart`, `cafe_debrief_screen.dart` |
| §3.1 Übergabe-Zeile + Einstiegszeile, kein Zwischenscreen | `cafe_turn_screen.dart` `_blockIntro` (Zeilen im selben Screen) |
| §3.1 Übungsform folgt der Sprosse | `kindForRung` unverändert, Test „Erkennen-Knöpfe, kein Eingabefeld" |
| §3.1 unter zwei Blöcken nur Wirtin | `speakerPlan(3)` Test |
| §4 Steckbriefe, ≥3 Zeilen je Form, ≥2 Einstiege, Gleichaltrige-Reaktionen, 45 Zeilen | `cafe_guest_script.dart` + Tests, `grep -c` = 76 |
| §4 Stimm-Zeile über dem Wort, nie die Bedeutung | Test „keine Kana/Kanji, keine Platzhalter" |
| §5.2 Titel = Sprecher, Reaktion vom Sprecher, Warteschlangen-Logik unverändert | `_speaker`, `_script`-Getter; `_dueForGuest` unberührt |
| §6 normaler Besuch unverändert | alle alten Café-Tests grün, Test „ohne speakers" |
| §9 Sprecherplan-Tests (erster/letzter Block, alle drei ab fünf Blöcken, zwei Offsets, ein Block, Länge) | `cafe_speaker_plan_test.dart` |

- [ ] **Step 3: Push und Draft-PR** (Basis: `design/cafe-szenen-stimmen`)

```bash
git push -u origin impl/cafe-stimmen
gh pr create --draft --base design/cafe-szenen-stimmen --head impl/cafe-stimmen \
  --title "feat(cafe): Stimmen — in der Nachbesprechung fragen alle vier, die Wirtin rahmt" \
  --body-file - <<'EOF'
Plan 1 von 2 zur Spec „Café-Szenen und Stimmen" (PR #50): die Stimmen, ohne neue Bilder.

- `CafeGuestScript` = Stimme: Reaktionen + Stimm-Zeilen je Übungsform + Einstiege, Steckbriefe als Doku; 45 neue Zeilen; die Gleichaltrige reagiert jetzt auf richtig/falsch/Hinweis.
- `speakerPlan`: Blöcke von drei, Wirtin rahmt, Schulkind → Vielredner → Gleichaltrige im Kreis, Offset pro Sitzung.
- `CafeTurnScreen(speakers:)`: Titel, Stimm-Zeile (über dem Wort, nie die Bedeutung), Übergabe + Einstieg beim Blockwechsel, Reaktion vom Sprecher. Ohne `speakers` exakt wie bisher.
- Nachbesprechung Akt 2 übergibt den Plan.

Stimme ≠ Sprosse: `kindForRung` unverändert, I1/INV-8/INV-9/INV-10 unberührt. Gerätetest S23 folgt mit Plan 2 (Bilder).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
```

- [ ] **Step 4: Gedächtnis-Notiz** (Memory-Datei `nihongo-lernmechanik-design.md`): PR-Nummer, „Stimmen gebaut, Gerätetest offen".

---

## Self-Review (durchgeführt beim Schreiben)

- **Spec-Abdeckung:** §3.1 (Task 3, 4, 5), §4 (Task 1, 2), §5.1 (Task 3), §5.2 (Task 4), §6 (Constraints + alte Tests), §9 Sprecherplan/Vorlagen/Bildschirme (Task 3, 1, 4/5). §3.2/§3.3/§5.3/§5.4/§5.6 (Bilder) sind bewusst Plan 2.
- **Platzhalter:** keine.
- **Typen/Namen:** `voiceLine(kind, turnIndex)`, `entry(ordinal)`, `speakerPlan`, `speakerBlockOrdinal`, `isSpeakerChange`, `cafeBlockSize`, `wirtinHandoverLine`, Keys `cafe-turn-voice`/`cafe-turn-handover`/`cafe-turn-entry` — in allen Tasks gleich benannt.
- **Abweichung von der Spec, in der Spec nachgetragen (19.9.):** Stimm-Zeile über dem Wort statt Wort-Einsetzung (§4 Präzisierung).
