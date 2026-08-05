# Verbindungs-Entwurf: On-Ramp → Mining (die Wissens-Brücke)

*Status: Entscheidungsvorlage. Kein Code, keine Migration — erst die eine
Architektur-Entscheidung unten (A/B/C), dann Bau.*

## Was die Brücke schließt

Mining ist **i+1**: es erntet die unbekannten Wörter aus Stoff knapp über
deinem Stand — das setzt ein vorhandenes „i" voraus. Der On-Ramp (die alte
Lektions-App: `LearningDb`, 5-Sprossen-Recall-Leiter, Kana, Kernvokabular,
Grammatik) baut dieses „i" von null auf. **Verbinden** heißt zweierlei:

1. **Wissens-Brücke** — was der On-Ramp lehrt, muss in Mining als *bekannt*
   zählen, sonst erntet Mining bereits Gelerntes erneut.
2. **Schwierigkeits-Anschluss** — ein Absolvent darf nicht auf Rashōmon
   geworfen werden; Mining wählt Inhalte im i+1-Fenster.

Dieser Entwurf klärt **Stück 1** (das tragende) vollständig und skizziert
Stück 2.

## Was tatsächlich abbildbar ist — und was nicht

Der On-Ramp trainiert drei `refType`s (`LearnItems.refType`). Mining kennt
als Wissenseinheit nur das **Lemma** (Wort). Also:

| On-Ramp `refType` | Trägt | Mapping nach Mining |
|---|---|---|
| `lexeme` (→ `Lexemes.writtenForm` = das Wort) | Wortwissen | **→ bekanntes Lemma** ✓ *(die ganze Brücke)* |
| `character` (Kanji-Glyph) | Lesefähigkeit einzelner Zeichen | **kein** Lemma — bildet nicht ab |
| `grammar` (Grammatikpunkt) | Strukturwissen | Mining modelliert Grammatik im i+1 nicht — bildet nicht ab |

**Kernaussage: Die Brücke ist `lexeme`-Meisterung → bekanntes Lemma.**
Zeichen- und Grammatik-Meisterung sind für die *Wortwissens*-Frage
bedeutungslos (später denkbar: Zeichenwissen speist ein Lese-Konfidenz-
Signal, Grammatikwissen steuert die Inhaltsauswahl — beides außerhalb
dieses Entwurfs).

## Meisterung → Wissensstufe

Die Leiter hat 5 Sprossen (`rung_defs.dart`); Rungs **3–5 sind Produktion**
(Recall: Bedeutung → Schriftform tippen). Wer produzieren kann, erkennt
das Wort beim Lesen erst recht. Mapping:

| On-Ramp-Zustand | Mining-`Knowledge` |
|---|---|
| `masteryRung ≥ 3` (Produktion erreicht) | **known** |
| `masteryRung` 1–2 (eingeführt, im Lernen) | **learning** |
| gar nicht im On-Ramp | **unknown** |

**SM-2-Zahlen werden *nicht* in FSRS umgerechnet.** `ease`/`intervalDays`
(SM-2) und `stability`/`difficulty` (FSRS) sind verschiedene Algorithmen
ohne ehrliche Zahlen-Abbildung. Stattdessen der bereits etablierte,
ehrliche Pfad aus `fsrs_bootstrap_import.dart`: **`simulateWellKnownCard`**
— FSRS *vorwärts* laufen lassen (mehrere `easy`), bis eine echte
„known"-Trajektorie entsteht. Für `known` die volle Simulation, für
`learning` eine leichte (1 Review). Genau die Disziplin, die
`importFrequencyBootstrap` heute schon nutzt — die Brücke speist sie nur
aus On-Ramp-Meisterung statt aus einem Frequenz-Rang.

## Das eine echte Risiko: Formabgleich

`Lexemes.writtenForm` muss dem Lindera-**Lemma** entsprechen. Für
kuratiertes A1/A2-Vokabular tut es das (Zitierform: 猫, 食べる). Abweichungen
(Okurigana-Varianten, Kana- statt Kanji-Schreibung) **scheitern sicher**:
das Wort wird schlicht nicht als bekannt markiert → Mining erntet es
(over-mining), behauptet aber **nie** fälschlich „bekannt". Optionale
Härtung: nur `writtenForm`s brücken, die als JMdict-Lemma existieren.

## Die Architektur-Entscheidung (deine Wahl)

Trenne zwei Dinge, die heute vermischt gedacht werden:

- **Scheduling-Zustand** (*wann* wiederholen) — darf pro Domäne getrennt
  bleiben: SM-2-Recall-Leiter (On-Ramp) vs. FSRS-im-Lesen (Mining). Zwei
  verschiedene Übungsarten, zwei legitime Zeitpläne.
- **Wissens-Zustand** (*ist dieses Lemma bekannt*) — **muss geteilt sein**,
  eine einzige Wahrheit, sonst driften die Welten.

Drei Wege für den Wissens-Zustand:

- **(A) Einmal-Brücke bei Übergabe** — On-Ramp-Meisterung wird einmal nach
  `MiningDb` kopiert. Am einfachsten. **Driftet**, sobald beide weiterlaufen
  (ein im On-Ramp zurückgestuftes Wort bleibt in Mining „bekannt").
- **(B) Laufende Zwei-DB-Synchronisation** — bei jeder Änderung
  neu projizieren. Zwei Quellen der Wahrheit + Konfliktregeln = genau der
  Drift-Einlader.
- **(C) Geteiltes Wissens-Substrat — *empfohlen*.** `MiningDb`
  `VocabItems`+`Cards` ist **die** einzige Wahrheit für „bekannt". Der
  On-Ramp behält seine eigene *Zeitplanung* (`LearnItems`), projiziert
  aber bei jeder Promotion/Demotion das Lemma über die Brückenfunktion in
  die geteilte `Card`. Mining liest/schreibt dieselbe. **Zwei Scheduler,
  eine Wissenswahrheit.** Das Überlappungsfenster (ein Wort zugleich in der
  On-Ramp-Leiter *und* im Lesetext) ist klein; Regel: „jeder Scheduler
  besitzt seine eigene Zeitplanung; das geteilte Bekannt-Flag ist
  last-write-wins."

**Empfehlung: (C).** Nur hier hat der Lernende *ein* nicht-driftendes
Wissensmodell — der eigentliche Sinn von „verbunden". (A) ist ok, falls der
On-Ramp→Mining-Übergang wirklich ein Einmal-Ereignis bleibt; die frühere
Formulierung „verbunden/kontinuierlich" spricht dagegen.

## Schwierigkeits-Anschluss (Stück 2 — nach der Brücke)

Sobald der Bekannt-Zustand einfließt, wählt Mining Inhalte, deren
`unknownRatio` im i+1-Fenster liegt (~5–15 %) — sanfter Start mit
Anfänger-Graded-Readern statt Rashōmon. Die Pipeline misst `unknownRatio`
schon pro Passage (`passage_snapshot.dart`); es fehlen (a) eine
abgestufte Inhaltsbibliothek und (b) ein Selektor. Eigenes Arbeitspaket —
die Brücke schaltet es frei.

## Erste Implementierungs-Scheibe (Vorschlag, nach deiner A/B/C-Wahl)

Ein `KnowledgeBridge` (`core/pipeline`): liest gemeisterte Lexeme aus
`LearningDb` (Join `LearnItems refType=lexeme` × `Lexemes` für
`writtenForm`), bildet `rung → Knowledge` ab, upsertet `MiningDb`
`VocabItems`+`Cards` über das vorhandene Bootstrap-Muster. Idempotent.
Dazu ein Test: ein Rung-4-Lexem wird zu einem `known`-Lemma in einer
`FsrsKnowledgeSource`, und Minings `unknownRatio` für eine Passage mit
diesem Wort sinkt entsprechend. Klein, wie die Lese-Scheibe.

## Was ich von dir brauche

Die **Architektur (A/B/C)** — ich empfehle **C**. Danach baue ich die
Brücken-Scheibe.
