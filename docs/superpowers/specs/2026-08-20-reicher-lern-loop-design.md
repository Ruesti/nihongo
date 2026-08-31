# Design: Reicher Lern-Loop — die pädagogische Tiefe des geführten Wegs

*Status: Entscheidungsvorlage. Datum: 2026-08-20.*
*Baut auf dem geführten Weg auf (`spec/gefuehrter-weg`, PR #26).*
*Nächster Schritt nach Freigabe: Implementierungsplan (writing-plans).*

## Problem

Der geführte Weg funktioniert *strukturell*, aber jeder Lern-Moment ist **flach**:
Zeichen sehen → „Verstanden" → ein Platzhalter-Comic. Gerätetest-Feedback des
Nutzers: *„mir wurden nur 2 Zeichen gezeigt, ich musste auf Verstanden klicken —
das ist noch nicht wirklich Sprache erfahren."* Das Vehikel steht, das *Erlebnis*
fehlt. Der Nutzer will **ausgewogen alles**: Kana lernen, **nachzeichnen**,
**wiederholen**, **Wörter**, **Grammatik**, und **„warum steht was wo"**
(Struktur *verstehen*, nicht auswendig).

## Vision

Jedes Kapitel wird eine **volle Runde**:

> **Neu lernen** (mehrsinnig: Zeichen sehen/hören/**nachzeichnen**; Wort mit
> Bedeutung + Bild + echtem Beispielsatz; Grammatik als **„warum"-Karte**) →
> **Kurz üben** (erster Abruf) → **Auffrischen** (gespaced wiederholen über die
> 5-Sprossen-Leiter) → **Lesen** (echte kleine Szene, *„das kann ich lesen!"*).

## Nicht verhandelbare Invarianten

- **I1 — Recall, kein Recognition** auf Produktions-Sprossen.
- **I2 — Timing ≠ Schwierigkeit.** **I3 — Keine Gamification.**
- **„Erst erleben, dann prüfen":** das Erstmeeting (Sprosse 0) bleibt *ungenotet*;
  der erste Abruf kommt *danach*.
- **Kein Anki-Drill vorn:** Wiederholung ist warm und gespaced (der
  „Auffrischen"-Beat), kein Karteikarten-Grind.
- **Ehrlichkeit, Offline-first, System-Sprache (l10n), I8 sprach-blind.**

## Wiederverwendung vs. Neu (aus der Code-Kartierung)

**Existiert, muss nur verdrahtet/herausgelöst werden:**
- **Übungs-Widgets der 5 Sprossen** (`_RecognitionExercise`/`_ReadingInputExercise`/
  `_ProductionExercise`/`_WriteTraceExercise`) sind sauber gebaut, aber **privat in
  `review_screen.dart`** → in eine wiederverwendbare Datei herauslösen.
  `GradeButtons` ist bereits öffentlich. `ExerciseLoader.load` baut alle 5
  Sprossen-Inhalte.
- **Leiter + Scheduler + `getDueItems(langId)`** — das komplette Spaced-Repetition-
  Fundament (Promotion = 3× hintereinander good/easy). Der Weg ruft `getDueItems`
  heute nie.
- **Trace-Primitive** (`KanjiSvgLoader`, `StrokeValidator`, `StrokePainter`) — pur,
  wiederverwendbar. (Die alte `TraceScreen` hängt an der Legacy-SRS-DB und wird
  **nicht** wiederverwendet.)
- **`StrokeOrderView`** (passive Strichfolge-Animation) im Encounter.
- **Kana-Strichdaten** (`strokeAssetForKana` + gebündelte SVGs あいうえお).

**Fehlt (Modell/Inhalt):**
- `GrammarPoints` hat **keine Lehr-Textfelder** (nur `sequenceIndex` + `canDoId`);
  graded Grammatik wirft `UnimplementedError`; **null Grammatik-Inhalt** geseedet.
- `Assets`- und `Sentences`-Tabellen existieren, sind aber **leer**; `Sentences`
  hat **keine Wort-Verknüpfung**; `_loadLexeme` setzt `exampleSentence` hart auf
  `null`.
- `ja_seed` setzt `strokeOrderAssetId` der Kana **nicht** (darum keine Strichfolge).
- rung-4 „writeTrace" rendert **keinen** Zeichen-Canvas (nur Glyph + Aufdecken).
- In-Reading-Review (`InReadingReviewPanel`/`DueInReading`) läuft auf der
  **`MiningDb`** (getrennte SRS!) und ist nur an den alten Slice-Reader verdrahtet,
  **nicht** an den Comic/Journey-Reader.

## Komponenten

### A. Reicher Lektions-Schritt (Neu lernen)
Der `LessonStepScreen` wird von „nur Encounter" zu einer Folge von **Lern-Beats**
pro Baustein:
- **Zeichen:** `EncounterView` (sehen/hören + `StrokeOrderView`-Animation) →
  **`TracePractice`** (nachzeichnen).
- **Wort:** `EncounterView` (Schriftform + Lesung + Audio + **Konzeptbild** +
  **echter Beispielsatz**).
- **Grammatik:** **`GrammarCard`** (Muster + „warum"-Erklärung + Beispiel +
  Kontrast).
Danach `markEncountered` (Sprosse 0→1). Reuse `EncounterView`; **neu:**
`TracePractice`, `GrammarCard`.

### B. `TracePractice` (Nachzeichnen)
Neues Widget aus den Primitiven: Ziel-Glyph blass als Führung, Nutzer zeichnet
**Strich für Strich**, validiert gegen KanjiVG (`StrokeValidator`), Richtungs-
Hinweise, fertig wenn alle Striche akzeptiert. Genutzt (1) im Zeichen-Lern-Beat
und (2) als **rung-4-Übung** (ersetzt das heutige No-op). Degradiert sauber, wenn
kein Strich-Asset da ist (Schritt entfällt).

### C. Strichfolge-Seed-Fix
`ja_seed`: `strokeOrderAssetId: Value(strokeAssetForKana(glyph))` für die Kana.
Einzeiler; Assets liegen schon → speist Encounter-Animation *und* Trace.

### D. `GradedExerciseRunner` (Leiter-Übung wiederverwendbar)
Die privaten Übungs-Widgets nach `lib/features/practice/graded_exercise.dart`
herauslösen (mechanisch, keine State-Kopplung). Ein `GradedExerciseRunner`:
gegeben eine Liste fälliger `LearnItem`s → `ExerciseLoader.load` → rendern (mit
Aufdecken + `GradeButtons`) → `LadderReview.submit` → nächstes. Genutzt vom
**Kurz-üben**- *und* **Auffrischen**-Beat; `ReviewScreen` wird optional darauf
umgestellt (DRY).

### E. „Kurz üben" + „Auffrischen"-Beats
- **Kurz üben:** direkt nach dem Kennenlernen der Kapitel-Bausteine ein leichter
  Erkennungs-Durchgang (rung 1) *nur* der neuen Items — sofortiger, niedrig-
  schwelliger Abruf. Ehrlich: Erstmeeting ungenotet, erster Abruf gleich danach.
- **Auffrischen:** ein Weg-Beat, der **`getDueItems(langId)`** holt und über den
  `GradedExerciseRunner` benotet — gespaced, Items klettern die Sprossen
  (Erkennen → Lesen → Produzieren → Nachzeichnen). **Autoriert** (nicht
  automatisch): ein neuer Curriculum-Schritt-Typ **`RefreshStep`**, den der Autor
  im Kapitel-Faden platziert (z. B. am Anfang eines Kapitels). Der Schritt holt
  die fälligen Items und läuft den Runner; sind keine fällig, entfällt er still.
  Kein Punkte-Zähler. **Das holt die aus der Nav-Leiste genommene Wiederholung
  zurück in den Fluss.**
  → *Modell:* `CurriculumStep` bekommt eine dritte Variante `RefreshStep`
  (neben `LessonStep`/`MangaStep`); `resolveStepIndex` überspringt einen
  `RefreshStep` nur, wenn nichts fällig ist.

### F. Grammatik mit „warum"
- **Schema:** `GrammarPoints` += `pattern`, `explanation`, `example`,
  `contrast?` (nullable). schemaVersion-Bump + Migration + `build_runner`-Regen.
- **Loader:** `_loadGrammar` baut aus den echten Spalten sowohl den
  `GrammarEncounter` (Sprosse 0) **als auch die graded Sprossen** (heute wirft es
  dort `UnimplementedError`).
- **Inhalt:** echte Grammatikpunkte mit deutschen „warum"-Erklärungen (Satzbau
  Verb-am-Ende, は als Thema, です höflich). Lektions-Schritte referenzieren
  `grammarIds`.
- **Rendering:** `GrammarCard` (reiche Lehr-Karte) für die Begegnung.
- **Grammatik wird geübt** (nicht nur erklärt): die Leiter gilt auch für
  Grammatik — **recall-basiert, kein Multiple-Choice (I1)**, unter
  Wiederverwendung der vorhandenen Inhalts-Varianten:
  - *Erkennen* (Sprosse 1): das Muster zeigen → aufdecken → seine Funktion/
    Bedeutung (`RecognitionContent{displayForm: pattern, answer: explanation}`).
  - *Produzieren* (Sprosse 3+): Aufforderung (die Kann-Ziel-Funktion) → der
    Lernende **baut/tippt** einen Satz mit dem Muster
    (`ProductionInputContent{prompt: canDo/Funktion, expectedForm: example}`).
  So läuft Grammatik durch **denselben** `GradedExerciseRunner` wie Wörter/Zeichen
  — der Auffrischen-Beat übt sie mit.

### G. Konzeptbilder + Beispielsätze
- **Konzeptbilder:** `Assets`-Zeilen seeden (type `image`, path) + einfache
  Platzhalter-Bilder bündeln; `_loadLexeme` zieht sie schon. Echte Kunst später.
- **Beispielsätze:** eine **Wort-Verknüpfung** ergänzen (`Sentences` += `lexemeId`
  bzw. kleine Join-Struktur), `_loadLexeme` um die Abfrage erweitern
  (`exampleSentence`), echte all-bekannte Beispielsätze der Kapitel-Wörter seeden.

### H. Echtes erstes Kapitel (Inhalt)
Ein substanzielles Kapitel 1 (ggf. + 2) autorieren: eine Handvoll Kana (mit
Trace) + mehrere Wörter (mit Bild + Beispiel) + 1–2 Grammatikpunkte (mit „warum")
+ eine **echte lesbare Comic-Szene** (mehrere Blasen, Deutsch + gerade Gelerntes,
gestuft). `assets/curriculum/ja.json` + `ja_seed` erweitern.

### I. Lesen mit echtem Inhalt + Gloss
Die Comic-Szene bekommt echte Mehr-Blasen-Inhalte (der `ComicPack` trägt L1/L2
schon). **Gloss verdrahten:** heute `_EmptyComicDictionary` (Tipp → „—"). Ein
kleines gebündeltes Wörterbuch der Kapitel-Wörter → Antippen zeigt echte
Bedeutung.

## Bewusst später (eigener Follow-up)

- **Fällige Leiter-Wiederholung *direkt im Comic* einblenden** — verlangt eine
  Brücke zwischen Leiter (`LearningDb`) und Lese-Wiederholung (`MiningDb`, zwei
  getrennte SRS). Fürs MVP trägt der **Auffrischen-Beat** das Wiederholen; das
  Lesen bringt Kontext + Antippen.
- **Echte ComfyUI-Manga-Zeichnungen.**
- **Graded Grammatik-Produktion.**

## Datenmodell-Änderungen

- `GrammarPoints` += `pattern, explanation, example, contrast?` (schema-Bump v3,
  Migration, `build_runner`).
- `Sentences` += `lexemeId` (nullable FK) — Wort↔Satz-Verknüpfung (schema-Bump).
- `Assets`: nur Zeilen seeden (keine Schema-Änderung).
- `Characters`: `strokeOrderAssetId` seeden (keine Schema-Änderung).

## Grenzfälle

- Kein Strich-Asset → Trace-Beat entfällt (degrade). Kein Konzeptbild → Text.
- Kein Beispielsatz → weggelassen. Kein Grammatik-Textfeld → degrade.
- Keine fälligen Items → Auffrischen-Beat entfällt. Nie Absturz.

## Teststrategie

- **Unit:** `StrokeValidator` accept/reject; `GradedExerciseRunner`
  (load→grade→submit rückt vor, Promotion nach 3×); `_loadGrammar` aus echten
  Spalten; Auffrischen-Einfügung wenn fällig; Beispielsatz-Loader.
- **Widget:** Lektions-Schritt fährt die Multi-Beat-Folge; Trace-Canvas nimmt
  Striche an; `GrammarCard` zeigt „warum"; Auffrischen benotet ein fälliges Item.
- **Beweis (`tool/`):** ein Lernender macht ein volles Kapitel (lernen+trace+
  grammatik → üben → auffrischen → lesen) Ende-zu-Ende.

## Scope / Nicht-Ziele

**Drin:** reicher Lektions-Schritt (Trace + GrammarCard + Wort-mit-Bild/Beispiel),
Strichfolge-Seed-Fix, `GradedExerciseRunner` (Herauslösen + Runner), Kurz-üben +
**autorierter `RefreshStep`**-Auffrischen-Beat, Grammatik (Schema + Inhalt +
Karte + **graded Üben über die Leiter, recall-basiert**), Konzeptbilder +
Beispielsätze (Schema-Link), echtes erstes Kapitel, Comic-Wörterbuch fürs Gloss.

**Draußen (später):** In-Reading-Leiter-Wiederholung, echte ComfyUI-Art, volles
Curriculum.

## Getroffene Detail-Entscheidungen (Defaults)

- Übung **gespaced** statt alles sofort. **Grammatik = Verstehen *und* Üben**
  (recall-basiert über die Leiter, kein MC). **Auffrischen autoriert**
  (`RefreshStep` im Curriculum, nicht automatisch). Trace im Lern-Beat **und**
  rung-4.

## Umsetzungs-Hinweis

Der Spec ist groß; der Implementierungsplan gliedert sich natürlich in Phasen:
(1) kleine Verdrahtungen (Strichfolge-Seed, Trace-Widget, Übungs-Herauslösung),
(2) die Beats (Kurz-üben, Auffrischen), (3) Grammatik (Schema + Inhalt + Karte),
(4) Wort-Reichtum (Bilder + Beispielsätze), (5) echtes Kapitel + Gloss. Jede Phase
ist für sich lauffähig und gerätetestbar.
