# Design: Der Empfang & die erste Begegnung

*Status: Entscheidungsvorlage, fertig entworfen. Datum: 2026-08-17.*
*Nächster Schritt nach Freigabe: Implementierungsplan (writing-plans).*

## Problem

Ein neuer Nutzer wird heute nicht abgeholt. Die App startet direkt auf dem
Home-Raster mit „Lektionen" — keine Begrüßung, keine Erklärung der Methode,
keine Kontaktaufnahme. Es gibt keinen Weg, den Einstieg zu wählen (bei null
anfangen vs. mit Vorwissen einsteigen). Und die allererste Handlung an einem
neuen Zeichen ist eine **Prüfung** (Lektion 1 „Erste Zeichen": das Zeichen
wird gezeigt und sofort *„Wie lautet dieses Zeichen auf Romaji?"* gefragt) —
obwohl ein neuer Nutzer nichts kennt. Es fehlt das *Erleben und Erfahren*
eines Zeichens, bevor es abgefragt wird.

Dieses Dokument entwirft zwei zusammengehörige Dinge als **einen** Spec:

1. **Der Empfang** — ein einmaliger Onboarding-Fluss (Begrüßung, Methode,
   Platzierung).
2. **Die erste Begegnung** — ein „erst erleben, dann prüfen"-Moment vor der
   ersten Prüfung jedes neuen Lern-Items, für **alle** trainierbaren Typen.

**Nicht** in diesem Spec: Manga/gestuftes Lesen (eigener Spec), Ausbau der
Konversation, volle Grammatik-Inhalte, Merkbild-Generierung (ComfyUI),
WaniKani/Anki-Import.

## Randbedingungen (nicht verhandelbar)

Aus `CLAUDE.md` und der bestehenden Architektur:

- **I1 — Recall, kein Recognition** auf Produktions-Sprossen. Die Begegnung
  ist *keine* Prüfung und verletzt das nicht; sie sitzt vor Sprosse 1.
- **I2 — Timing ≠ Schwierigkeit.** `srsState` (wann) und `masteryRung` (wie
  schwer) bleiben getrennt. Sprosse 0 ist reine Schwierigkeits-/Reifestufe.
- **I3 — Keine Gamification.** Kein Streak, keine Punkte im Empfang.
- **Nie falsch „gewusst" behaupten.** Die Platzierung markiert nur
  *bestätigtes* Wissen als bekannt (Wissens-Brücke-Prinzip: lieber
  over-mining als falsches „known").
- **Offline-first, Asset-Doktrin §6.** Fehlende Assets → Platzhalter/Weglassen,
  nie Absturz.
- **`learn_items` ist die einzige SRS-Einheit** (§3). Alle drei `refType`
  (`lexeme|character|grammar`) laufen dieselbe Leiter.

## Stimme: „Datum, wärmer"

Der Empfang wird von der bestehenden App-Stimme **Datum** gesprochen —
derselben, die im Alltag mit gemessenen Fakten begleitet („Kapitel 2. Vor 6
Wochen: 55 Prozent unbekannt. Heute: 9."). Für den Erstkontakt ist ihr
Register **wärmer/persönlicher** (zweite Person, ruhig, zugewandt), aber die
Grundregel bleibt: **nie etwas erfinden**. Kein Maskottchen wird wiederbelebt.

---

## Teil A — Die Erfahrung

### A1. Die Nutzerreise (Ende zu Ende)

Erststart erkennt einen neuen Nutzer über ein `shared_preferences`-Flag
`onboardingComplete=false` und schaltet **vor** die Home-Shell einen einmaligen
Empfang. Danach nie wieder automatisch, aber aus den Einstellungen erneut
aufrufbar (additiv — macht nichts „ungewusst").

```
Erststart
  └─ Willkommen (Datum, warm)
       └─ Wie die App tickt (3 ehrliche Beats)
            └─ Wo stehst du?  ──┬─ "Bei null"  ─────────────► direkt zur 1. Begegnung
                                └─ "Kann schon etwas"
                                     └─ Kana Ja/Nein
                                          └─ (nur bei Wortschatz) 60-Sek-Mini-Check
                                               └─ Dein Startpunkt (Datum spiegelt echten Stand)
                                                    └─ 1. Begegnung (das Ritual)
```

Ab dann: normale Shell (Home / Lesen / Review / …). Aber **jedes** neue Item —
egal ob in einer Lektion oder später im Review-Tab — bekommt erst die
Begegnung, dann die Prüfung.

### A2. Der Empfang (Onboarding-Fluss)

Kein 8-seitiges Tutorial-Karussell (widerspräche der Minimalismus-Haltung).
**Drei ruhige Screens**, jeder eine Sache, Datum spricht:

- **Willkommen** — eine Zeile, die die Methode ehrlich setzt:
  > „Willkommen. Hier lernst du Japanisch, indem du es *liest* — in deinem
  > Tempo, Zeichen für Zeichen."

- **Wie die App tickt** — drei kurze, ehrliche Beats, die den *ganzen Bogen*
  zeigen (nicht nur Zeichen):
  > „Du lernst Zeichen, Wörter und Grammatik — jedem *begegnest* du zuerst
  > (sehen, hören, nachfahren), bevor du geprüft wirst."
  > „Du liest sie dann in echten Texten und wendest sie im Gespräch an."
  > „Kein Punktesammeln, keine Serien. Dein Fortschritt ist, was du wirklich
  > lesen kannst. Alles läuft offline."

- **Wo stehst du?** — die Platzierungs-Gabelung (A3).

### A3. Die Platzierung (Hybrid)

- **„Ich fange bei null an"** → ein Tipp, Schluss. Direkt zur ersten Begegnung.
  Null Reibung.
- **„Ich kann schon etwas"** → gestaffelt, nur so tief wie nötig:
  1. **Kana, Ja/Nein** (sicher, weil binär): „Hiragana kannst du?" / „Katakana
     auch?" Bekanntes Kana → als *gemeistert* gesetzt (Begegnung + Prüfung
     entfallen; zählt beim Lesen als bekannt).
  2. **Nur wer Wortschatz behauptet:** ein **60-Sekunden-Mini-Check** — eine
     Handvoll häufiger Wörter, „Kennst du das?", selbst benotet (aufdecken →
     „ja/nein"). Nur *bestätigte* Wörter werden als bekannt markiert.
  3. **Grobe optionale Grammatik-Stufe** („Warst du schon mal bei ~JLPT N5?")
     — setzt nur die *Reihenfolge* des Grammatik-Einstiegs, markiert **nichts**
     als gewusst.
- **„Dein Startpunkt"** — Datum spiegelt den *echten* gesetzten Stand zurück,
  gemessen, warm:
  > *(Anfänger)* „Wir fangen ganz vorn an. Los geht's mit あ."
  > *(Vorwissen)* „Gut — Hiragana überspringen wir. Wir starten bei Katakana;
  > 12 Wörter kennst du schon."

### A4. Die erste Begegnung — das Ritual (Sprosse 0), polymorph über `refType`

Ein neues Item wird **nie kalt geprüft**. Sein erster Auftritt ist ein ruhiger,
mehrsinniger Moment. Weil die App drei Typen trainiert, ist das Ritual
**typgerecht** (siehe Datenmodell B2), teilt aber das Prinzip „erst mehrsinnig
erleben, dann prüfen":

- **Zeichen (character)** — groß sehen · hören (TTS) · **Strichfolge animiert**
  (aus KanjiVG-Pfaden), wiederholbar · **nachfahren** mit dem Finger (nutzt die
  vorhandene Trace-Fläche des Kanji-Spiels) · **Merkbild/Eselsbrücke**, falls
  vorhanden. Kein Bestehen/Durchfallen, nur „Weiter".

- **Wort (lexeme)** — *Bedeutung erleben*: das Wort mit Furigana sehen · hören ·
  das **Konzept-Bild** dazu (Asset an `conceptId`, I4 — 猫 zeigt eine Katze) ·
  ein natürlicher Beispielsatz aus schon *bekannten* Wörtern, der es in Gebrauch
  zeigt.

- **Grammatik (grammar)** — *das Muster begreifen*: eine kurze, schlichte
  Erklärung was es tut · ein minimales Beispiel nur aus Bekanntem, das die Form
  zeigt · hören · optional ein Kontrastpaar. Gerahmt durch das **Kann-Ziel**
  (`can_do_goals`): „Damit kannst du jetzt sagen, dass dir etwas gefällt."

Nach der Begegnung steht das Item auf **Sprosse 1** und ist für seine erste
echte Erkennungs-Prüfung *später* fällig.

**Innerhalb einer Lektion:** erst die Begegnungen der ganzen Gruppe
(z. B. あ, い, う, え, お), *dann* die Erkennungs-Übungen dazu — unmittelbares
Abrufen, aber nie kalt. **Im Review-Tab** greift dieselbe Regel automatisch:
trifft die Warteschlange auf ein Sprosse-0-Item, kommt zuerst die Begegnung.

**Sätze und Konversation** sind *keine* Erstkontakt-Oberflächen und bekommen
kein rung-0-Ritual: Sätze sind der Ort, wo Wörter/Grammatik im Kontext wieder
auftauchen (Brücke zum Manga-/Lesen-Spec); Konversation ist Produktion am
anderen Ende der Leiter (jeder Fehler erzeugt via I7 ein `learn_item`, das dann
normal Begegnung/Prüfung durchläuft). Im Empfang werden beide nur *angekündigt*.

---

## Teil B — Datenmodell & Architektur

Verankert im bestehenden Code (Explore-Kartierung Stand `main`).

### B1. Sprosse 0 im `LearnItem`

`LearnItem.masteryRung` (`lib/core/db/learning_db.dart`) wird von `1..5` auf
**`0..5`** erweitert; **0 = „noch nicht begegnet"**. Zusätzlich
`encounteredAt: datetime?` (nur zur Nachvollziehbarkeit). Kein Konflikt mit I2:
Rung ist Schwierigkeit/Reife, 0 = Meisterung hat nicht begonnen.

### B2. `resolveEncounter` als Geschwister des Übungs-Resolvers

`lib/core/ladder/rung_defs.dart:resolveExercise(rung, refType, profile)` bekommt
einen Fall `rung == 0` → liefert einen **`Encounter`** statt einer Übung. Ein
`Encounter` ist ein versiegelter Typ mit Varianten pro `refType`, gebaut von
einem kleinen `EncounterFactory` aus den Pack-Daten:

```
Encounter (sealed)
 ├─ CharacterEncounter  { glyph, reading, audio, strokeOrder?, mnemonic? }
 ├─ LexemeEncounter     { writtenForm, furigana, reading, audio, conceptAsset?, exampleSentence? }
 └─ GrammarEncounter    { pattern, plainExplanation, example, audio, canDoGoal, contrast? }
```

Der Session-Runner behandelt einen `Encounter` als **ungenotet**: keine
`GradeButtons`, nur „Weiter".

### B3. `introduce()` startet auf Sprosse 0

`lib/core/ladder/ladder_review.dart:introduce()` legt neue Items auf **Rung 0**
an (heute Rung 1). Neu: `markEncountered(item)` — setzt Rung 0→1, plant die
erste Fälligkeit über `srs.schedule`, projiziert „learning" in die Substanz
(`KnowledgeBridge`), **ohne** den Noten-Pfad (`submit`) zu durchlaufen (es gibt
keine Note).

### B4. Der Seam-Fix — Lektionen speisen die Leiter

Heute schreiben Lektionen `SrsCard` in die *alte* `AppDatabase`
(`lib/core/database.dart`), der Review-Tab liest `LearnItem` aus `LearningDb` —
**unverbunden**; Lektion-Abschluss erzeugt aktuell keine Wiederholungen. Ansatz
1 heilt das:

- `features/lesson/exercise_factory.dart` + `features/lesson/lesson_screen.dart`
  schreiben nicht mehr `SrsCard`, sondern arbeiten über `LadderReview` gegen
  `LearningDb` (die einzige SRS-Einheit, §3).
- Lektionsstart: für jede Karte `introduce()` (Rung 0), außer die Platzierung
  hat sie als bekannt/gemeistert markiert.
- Lektionslauf: erst alle `Encounter` (Rung 0) der Gruppe, dann die ersten
  Erkennungs-Übungen (Rung 1) — alles über `LadderReview` in `LearningDb`.
- Die alte `AppDatabase` behält nur noch **Lektions-Status** fürs Home-Raster
  („Lektion 1 erledigt"), nicht mehr SRS-Wahrheit.

### B5. Platzierung schreibt den Bekannt-Stand

- **Kana bekannt** → dessen `LearnItem`s auf gemeisterte Rung (≥3), aus dem
  On-Ramp ausgenommen, per `KnowledgeBridge` als *known* in `MiningDb`
  projiziert.
- **Bestätigte Wörter (Mini-Check)** → nur diese über den vorhandenen
  `importFrequencyBootstrap`/`simulateWellKnownCard`-Pfad
  (`lib/core/pipeline/fsrs_bootstrap_import.dart`) als *known* + zugehörige
  `LearnItem`s auf gemeisterte Rung. Nichts Unbestätigtes.
- **Grobe Grammatik-Stufe** → setzt nur den Start-`sequenceIndex`
  (`grammar_points.sequenceIndex`), markiert nichts als gewusst.
- Onboarding schreibt `onboardingComplete=true` + ein `placementProfile` (was
  erklärt wurde) für spätere Wiederholung/Transparenz.

### B6. Routing

Neues `features/onboarding/` mit den Screens. Ein `GoRouter`-Redirect
(`lib/app.dart`): solange `!onboardingComplete`, leitet `/` → `/onboarding`.
Nach Abschluss → erste Begegnung bzw. Home. Aus **Einstellungen** erneut
aufrufbar.

### B7. KanjiVG-Import (Content-Daten)

Bring die KanjiVG-Strichfolge-Pfade für **Kana + die Kanji der ersten
Lektionen** ins Repo (als Asset-Daten, Namenskonvention analog
`assets/kanji_svg/{codepoint}.svg`). KanjiVG steht unter **CC-BY-SA** —
Attribution im Repo/Impressum erforderlich. Das trägt die animierte Strichfolge
des Zeichen-Rituals, ohne handgezeichnete SVGs. Strichfolgen für *alle* Kanji
sind ausdrücklich außerhalb dieses Specs (Content-Aufgabe).

---

## Grenzfälle & Fehlerfälle

- **Fehlende Assets:** keine Strichfolge → Strich-/Nachfahr-Schritt weglassen;
  kein Konzept-Bild → Bedeutung als Text; kein Merkbild → weglassen.
  **Sehen + Hören funktioniert immer** (Glyph/Form + TTS stets da). Nie Absturz.
- **Kein all-bekannter Beispielsatz** für Wort/Grammatik → Begegnung ohne
  Beispiel. Abhängigkeit von `sentences`-Daten notiert.
- **TTS stumm/aus** → Begegnung bleibt visuell vollständig; Audio ist Zugabe.
- **Onboarding abgebrochen** (App gekillt) → Flag nur bei Abschluss gesetzt →
  nächster Start beginnt neu (idempotent, kurz).
- **Ritual überspringen:** kein Pro-Item-Skip (wäre wieder Kalt-Prüfen); wer's
  kann, überspringt über die Platzierung.
- **Review trifft Rung-0-Item** → Resolver liefert Begegnung statt Erkennung
  (der zu fixende Bug; als Regressionstest verankert).
- **Platzierung „lügt"** → System erfindet nie „gewusst"; Unbestätigtes bleibt
  unbekannt und taucht beim Lesen/Mining wieder auf. Selbstheilend.
- **Bestehender Fortschritt (Altdaten):** einmaliger **idempotenter Backfill**
  beim ersten Start nach dem Update (alte `SrsCard`-Meisterung → `LearnItem`),
  im Muster des vorhandenen `KnowledgeBoot`. Ohne nennenswerte Altdaten reicht
  ein sauberer Seed. **Default: Backfill, falls Altdaten vorhanden.**

## Teststrategie (in der Beweis-Report-Disziplin des Projekts)

- **Unit:** `resolveExercise(0, refType)` → korrekter `Encounter` je Typ;
  `introduce()` startet Rung 0; `markEncountered` promotet 0→1 + plant
  Fälligkeit **ohne** SM-2-Grading; Platzierungs-Mapping (Kana→gemeistert,
  bestätigtes Wort→known via Bootstrap, Grammatik-Stufe→`sequenceIndex`).
- **Widget:** Onboarding rendert 3 Screens; „bei null" → direkt erste Begegnung;
  „kann etwas" → Kana-J/N → (Wortschatz) Mini-Check → Startpunkt.
  Begegnungs-Widget je `refType`; **graceful degradation** (Pack ohne Strich-SVG
  → kein Absturz, Schritt fehlt). **Keine `GradeButtons` auf einer Begegnung**
  (assert). Lektion: **alle Begegnungen vor allen Prüfungen** (Reihenfolge).
  Review: Rung-0-Item zeigt Begegnung, nicht Erkennung (Regressionstest).
- **Beweis (`tool/`):** Neu-Nutzer-Lauf: leer → Onboarding(null) → Lektion 1 →
  danach Items Rung 1 in `LearningDb`, fällig geplant, **und der Review-Tab
  serviert sie** (Seam geschlossen). Vorwissen-Lauf: Hiragana erklärt →
  Hiragana-Items gemeistert, aus Lektion ausgenommen, `MiningDb`-`unknownRatio`
  einer Hiragana-Passage sinkt.
- **Invarianten-Wächter:** kein Streak/Score (I3); Platzierung markiert nie
  Unbestätigtes als gewusst.

## Offene Entscheidung (zum Gegenlesen)

Altdaten-Migration (`SrsCard` → `LearnItem`): Default **Backfill, falls
vorhanden** (siehe Grenzfälle). Wenn du das anders willst, hier ändern.

## Abhängigkeit zum nächsten Spec

Dieser Empfang baut den **Bekannt-Stand** (Platzierung + Begegnungen →
geteilte Wissens-Substanz `MiningDb`) auf. Der **Manga-/Lesen-Spec** liest genau
diesen Stand, um „i+1"-Inhalte für dein Niveau zu wählen. Der Empfang ist damit
Voraussetzung dafür, dass der Manga-Leser dein Level überhaupt kennt.
