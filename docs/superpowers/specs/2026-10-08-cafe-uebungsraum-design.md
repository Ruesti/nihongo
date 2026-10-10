# Das Café als Übungsraum — Design

Stand 8.10.2026 · Status: Entwurf nach Ulis Abnahme im Gespräch (6.–8.10.) · Basis: Branch `impl/mira-schweigt` (PR #60, Folge 01 V3 ohne Mira-Blasen)

## 0. Auslöser und Entscheidungen

Uli am 6.10. nach dem Gerätetest von Folge 01: „Das Café ist noch nicht wirklich gebaut. Bis jetzt gibt es nur die Wirtin. Der Screen ist fehlerhaft. Schulmädchen, Gleichaltrige, alter Mann, Vielredner kommen überhaupt nicht vor. Die Lernmechanik gefällt mir auch noch nicht.“

Befund im Code (6.10.): Die vier Gäste existieren (`cafe_occupancy.dart`), sitzen aber nur im freien Raum und nur bei fälligen Wörtern. Nach einer Folge kommt ausschließlich die Nachbesprechung der Wirtin: eine Kartenreihe pro Wort mit „Got it“, abgeschnittene Panel-Ausschnitte, danach ein Abfrage-Bildschirm aus losen Texten („Erklär's mir nochmal“, „zeigen“, „gewusst“, „nicht“) ohne Eingabe. Einen „alten Mann“ gibt es nicht als Gast.

Entscheidungen im Gespräch:

| Frage | Ulis Antwort |
|---|---|
| Wofür ist das Café? | **B — Übungsraum.** Erst umsetzen, nach Begutachtung nachschärfen. |
| Was stört an der Lernmechanik? | **A** zu viel Karteikarte · **B** Abfrage unklar/kaputt · **C** zu wenig Hören und Sprechen · **D** zu wenig Bezug zur Folge. |
| Alter Mann? | = der Vielredner, keine eigene Figur. |
| Was fehlt inhaltlich? | Im Manga fehlt der Bezug zwischen Schriftzeichen und Aussprache. Das Wort soll **aufgelöst** werden: Zeichen für Zeichen mit dem Laut. Dazu Vokabeln, Aussprache, „warum sagt man was“, Grammatik. |
| Welcher Ansatz? | **Ansatz 1: vier feste Stationen**, jeder Gast macht genau eine Sache. |

Die Spec vom 2.10. (`2026-10-02-mira-schweigt-erzaehl-mal-cafe-manga-design.md`) bleibt für Plan 1 (gebaut), Plan 3 (Café-Bilder) und Plan 4 (Café im Vollbild) gültig. **Plan 2 „Erzähl mal“ geht in dieser Spec auf** (§3.4): die stummen Momente werden die Situationen der Gleichaltrigen.

## 1. Ziel und Nicht-Ziele

**Ziel:** Nach jeder Folge — und bei jedem freien Besuch — führt das Café durch vier Stationen, in denen die Wörter der Folge verstanden (aufgelöst), geschrieben, gehört und gesprochen werden. Jede Station hat eine Figur mit genau einer Aufgabe. Jede Übung zeigt das Panel, aus dem das Wort stammt.

**Nicht-Ziele (in diesem Schritt):**
- Café-Bilder im Manga-Weg und Café im Vollbild (Pläne 3 und 4 der Spec vom 2.10.). Die Stationen nutzen die vorhandenen Gäste-Bilder (`cafe_scenes.dart`) als Kopf.
- Grammatik als eigener Lernstrang. Grammatik erscheint nur als Notiz am Wort bzw. an der Situation.
- Katakana-Tastatur. Folge 01 braucht nur Hiragana; die Tastatur ist so gebaut, dass Katakana später dazukommen kann.
- Freie Konversation mit KI. Die Gleichaltrige arbeitet mit vorbereiteten Situationen.

## 2. Zwei Wege ins Café, ein Raum

| | Weg 1: nach der Folge | Weg 2: frei angeklickt (Café-Tab) |
|---|---|---|
| Einstieg | „Ins Café“ auf der Endkarte der Folge | Café-Tab in der Leiste |
| Zweck | Wörter der Folge verstehen und festigen | Wiederholen, was fällig ist |
| Wortauswahl | nur die Wörter dieser Folge (`episode.budget.items`, `refType: lexeme`) | fällige `learn_items` aller gelesenen Folgen (`getDueItems`) |
| Stationen | alle vier, in fester Reihenfolge: Wirtin → Schulmädchen → alter Mann → Gleichaltrige | nur Stationen, bei denen etwas liegt (§2.2) |
| Dauer | 8–12 Minuten; nach jeder Station „Später weiter“ | höchstens 12 Wörter pro Besuch |
| Nichts da | – | Wirtin wischt den Tresen; freiwillige Runde beim Schulmädchen über zufällige bekannte Wörter |

**Der Raum:** Ein Bildschirm zeigt die vier Gäste am Tisch (vorhandene Bilder). Der aktive Gast ist hell, die anderen gedimmt aber sichtbar; darüber eine Leiste mit vier Punkten (Stationen), ohne Zähler und Häkchen (INV-10/I3). Tippen auf einen gedimmten Gast tut nichts — die Reihenfolge ist fest. „Später weiter“ speichert Station und Position (`StoryProgressStore`, Schlüssel `cafe_visit_<episodeId>` bzw. `cafe_visit_free`); der nächste Einstieg fragt „Weitermachen bei …?“.

### 2.1 Wortzuteilung nach der Folge

Folge 01 hat 18 Wörter. Zuteilung durch `CafeVisitPlanner` (reine Funktion, testbar):

1. **Wirtin:** alle Wörter der Folge, in `debriefOrder` (Reihenfolge des ersten Auftretens).
2. **Gleichaltrige:** alle Situationen der Folge (§3.4) — bei Folge 01 sechs: vier stumme Momente + zwei Sprechmomente. Zielwörter: あめ, こわれた, いくら, すみません, ありがとう (すみません kommt zweimal vor, zählt einmal).
3. **Alter Mann:** die Fragen der Folge (§3.3), bei Folge 01 vier. Zielwörter z. B. かさ, みせ, さむい, どうぞ.
4. **Schulmädchen:** alle Wörter, die weder bei 2 noch bei 3 Ziel sind, zuerst die, bei denen das Nachsprechen bei der Wirtin nicht klappte (§3.1 Schritt 7). Nach der Folge gibt es keine Obergrenze (Folge 01: etwa 9 Wörter); die Grenze von 12 gilt nur für den freien Besuch.

Regel: Jedes Wort der Folge ist Ziel in mindestens einer der drei aktiven Stationen (Test `cafe_visit_planner_test`).

### 2.2 Zuteilung beim freien Besuch

Fällige Items nach Sprosse (`guestForRung` in `cafe_occupancy.dart` bleibt die Grundlage):

| Sprosse | Station | Bedingung |
|---|---|---|
| 1–2 | Wirtin | nur wenn das letzte Ergebnis `again` oder `hard` war — sonst direkt Schulmädchen |
| 3 | Schulmädchen | |
| 4 | Alter Mann | |
| 5 | Gleichaltrige | Situation aus der Folge, in der das Wort vorkam |

Höchstens 12 Items pro Besuch, zuerst die am längsten fälligen. Stationen ohne Items werden übersprungen.

## 3. Die vier Stationen

Gemeinsam für alle: Kopf = Gäste-Bild der Station (`CafeMotif`), eine Zeile Text der Figur in ihrer Stimme (`cafe_guest_script.dart`, Steckbriefe bleiben), darunter die Übung. Alle Texte deutsch; kein „Got it“. Keine Antwort steht je zur Auswahl (I1). Keine Selbsteinschätzung.

### 3.1 Wirtin — „Auflösen“

Pro Wort ein Bildschirm, von oben nach unten:

1. **Szene:** Panel-Ausschnitt mit der **ganzen** Sprechblase, in der das Wort fiel (`firstAppearancePanel`); das Wort in der Blase hervorgehoben (§6.3 Blasen-Überlagerung).
2. **Das Wort groß** in Kana. Steht es im Manga als Kanji (駅, 傘 — Schilder), erscheint das Kanji groß, darunter die Kana.
3. **Zerlegung:** eine Kachel pro Laut-Einheit, darunter der Laut in Lautschrift: **あ** a · **め** me. Beim Öffnen spricht die Wirtin das Wort einmal ganz (`TtsService.speak`), dann langsam (`speakSlow`), die Kacheln leuchten der Reihe nach mit. Tipp auf eine Kachel spricht nur diesen Laut, Tipp auf das Wort spricht es ganz. Laut-Einheiten (§6.2): Grundzeichen; Zeichen + kleines ゃゅょ als eine Kachel (きょ kyo); kleines っ als Kachel mit dem verdoppelten Folgekonsonanten (っ + て → „tt“); ん n; Dehnung ー bzw. folgendes う/い nach o/e als Teil der Kachel davor (と+う → tō).
4. **Bedeutung** deutsch, eine Zeile (`meaningForConcept`, kein englischer glossKey).
5. **„Warum sagt man das hier“:** der vorhandene `usage`-Text (`folge_01_regen.dart`, Abschnitt `debrief`).
6. **Grammatik:** ein bis zwei Sätze, nur wenn das Wort eine Form zeigt (Daten §5.3). Folge 01: こわれた (Vergangenheit, „ist kaputtgegangen“), だいじょうぶ (Aussage und Frage, nur der Tonfall unterscheidet), いいえ (höfliches Nein), ひとり (Zählwort für eine Person).
7. **Nachsprechen:** Mikro-Knopf; Spracherkennung wie bei den Sprechmomenten (`SttSpeakEvaluator.evaluate`, gleiche Schwelle wie `diegetic_speak_sheet.dart`). Nicht erkannt → die Wirtin spricht noch einmal langsam vor, ein zweiter Versuch. Danach geht es immer weiter. Ein gescheitertes Nachsprechen markiert das Wort als „wackelig“ für diesen Besuch (Schulmädchen zuerst, §2.1 Punkt 4); es geht **nicht** in die Wiederholungsplanung.
8. **Weiter.**

Nach der Folge: alle Wörter (Folge 01: 18, ca. 4 Minuten). Frei: nur Wörter mit letztem Ergebnis `again`/`hard`.

### 3.2 Schulmädchen — „Abfrage“

Frech, direkt, kein Keigo („はい、つぎ！“). Nur sie prüft wirklich. Zwei Übungsarten im Wechsel (gerade/ungerade Position in der Liste, deterministisch):

- **Hören → Schreiben:** Sie spricht das Wort (TTS), es wird nicht gezeigt. Eingabe über die **eingebaute Kana-Tastatur** (§6.1). Richtig → kurze Bestätigung in ihrer Stimme. Falsch → sie spricht es noch einmal, blendet die Zerlegung der Wirtin (§3.1 Punkt 3) kurz ein, zweiter Versuch, dann weiter. Vergleich auf Kana-Ebene nach Normalisierung (kein Leerzeichen, kein Satzzeichen).
- **Sehen → Sprechen:** Panel mit der Sprechblase, in der das Zielwort durch „___“ ersetzt ist (§6.3). Du sprichst das Wort; `SttSpeakEvaluator`. Falsch → sie sagt es einmal vor, zweiter Versuch, dann weiter.

Ergebnis in die Wiederholungsplanung (`LadderReview.submit`): erster Versuch richtig → `good`; zweiter Versuch richtig → `hard`; beide falsch → `again`. Es gibt keine Wahl zwischen Antworten und kein „gewusst/nicht“.

### 3.3 Alter Mann (Vielredner) — „Zuhören“

Er erzählt die Folge nach: drei bis vier kurze japanische Sätze, nur mit Wörtern aus dem Budget dieser Folge und früherer Folgen (INV-20), im knappen Stil der Folge. Entwurf Folge 01 (Uli liest gegen):

| # | Japanisch | Deutsch |
|---|---|---|
| 1 | あめ。さむい、さむい。 | Regen. Kalt, kalt. |
| 2 | えき、ひとり。みせ、ここ。 | Bahnhof, allein. Der Laden, hier. |
| 3 | かさ、こわれた。だめ。 | Der Schirm, kaputt. Geht nicht. |
| 4 | いくら？いいえ。かさ、どうぞ！ | Wie viel? Nein. Der Schirm, bitte! |

Ablauf:

1. **Erst hören, ohne Text.** Er spricht Satz für Satz (TTS). Ein Tipp wiederholt den Satz, ein zweiter blendet den japanischen Text ein, ein dritter die deutsche Übersetzung.
2. **Dann vier Fragen**, zwei Arten im Wechsel:
   - **„Welche Szene?“** Er sagt einen seiner Sätze; du tippst auf das passende Panel. Gezeigt werden alle Panels der Folge als kleine Kacheln in Lesereihenfolge. Das ist Verstehen, nicht Produktion — Auswahl erlaubt.
   - **„Welches Wort?“** Er fragt auf Deutsch („Was hat ihr der Ladenbesitzer gegeben?“), du sprichst oder schreibst das japanische Wort (Mikro oder Kana-Tastatur, frei wählbar). Keine Auswahl.
3. Fehler → er wiederholt den Satz langsam und zeigt den Text; ein zweiter Versuch, dann weiter.

Daten Folge 01 (§5.2), Entwurf: Szene-Fragen zu Satz 1 → P3, Satz 3 → P6; Wort-Fragen: „Was hat er ihr gegeben?“ → かさ; „Wo ist Mira angekommen?“ → えき.

Ergebnis: richtig → `good`; falsch → `hard` (er bewertet nicht streng; kein Rückstufen auf `again`).

### 3.4 Gleichaltrige — „Warum sagt man das“ (ersetzt Plan 2 „Erzähl mal“)

Sie stellt die Stellen nach, an denen Mira stumm blieb oder sprechen musste: alle Interaktionen vom Typ `silent` und `speak` der Folge, in Lesereihenfolge. Folge 01: P4 あめ, P5 すみません, P6 こわれた, P7 いくら, P8 ありがとう, P10 すみません.

1. **Situation:** das Panel in voller Blase; ihre Frage auf Deutsch aus den Daten (§5.2), z. B. „Er zeigt dir den kaputten Schirm. Was hättest du gesagt?“
2. **Freie Antwort, gesprochen.** `SttService.listen` schreibt mit; der erkannte Text erscheint unter dem Panel. Enthält er ein erwartetes Wort (`expected`, z. B. こわれた oder だめ), freut sie sich; wenn nicht, sagt sie, was sie gesagt hätte (`sample`). Kein Richtig/Falsch, keine Wiederholung erzwungen.
3. **Warum sagt man das:** ihr Erklärsatz aus den Daten (`why`).
4. **Grammatik:** ein bis zwei Sätze, nur wenn die Situation eine Form zeigt (`grammar`, optional).
5. **„Man kann auch sagen“:** die vorhandenen `variants` des Zielworts, jede mit Vorlesen und ihrer `note`.
6. **Weiter.**

Ergebnis: `freeProduced` (bestehendes `CafeOutcome`) — ändert die Fälligkeit nicht.

## 4. Abschluss durch die Wirtin

Ein Bildschirm, zwei bis drei Sätze in Worten, ohne Zahlen, ohne Häkchen (I3): „かさ und どうぞ sitzen. こわれた und いくら kommen morgen wieder.“ Quelle: die Ergebnisse von Schulmädchen und altem Mann dieses Besuchs (`CafeSummary`, reine Funktion über die Liste der `CafeOutcome` je Item + neue `dueAt`). „Sitzen“ = `good` beim ersten Versuch; „kommen wieder“ = alles andere, mit „morgen“/„in ein paar Tagen“ aus `dueAt`. Danach „Zurück zur Folge“ (Weg 1) bzw. „Café verlassen“.

## 5. Daten

### 5.1 Bestehend und weiterverwendet

- `episode.budget.items`, `pages[].panels[].bubbles[].tokens` (Wort ↔ Blase ↔ Panel), `interactions` (`silent`, `speak`, `trace`).
- `debrief` je Wort: `usage`, `variants[{form, reading, meaning, note}]` (in `folge_01_regen.dart`).
- `kana_data.dart`: `KanaEntry(kana, romaji)` für 141 Zeichen (Hiragana/Katakana).
- `learn_items` + `LadderReview` (SM-2 + Sprossen), `getDueItems`.
- `cafe_guest_script.dart` (Stimmen), `cafe_scenes.dart` (Motive), `cafe_occupancy.dart` (`guestForRung`).

### 5.2 Neu je Folge: `CafeContent`

Eine Dart-Map neben den Folgendaten (`lib/features/story/episodes/folge_01_cafe.dart`), Schema:

```
CafeContent {
  episodeId,
  monologue: [ {ja, de, panelIndex} ],              // Sätze des alten Mannes, panelIndex = Szene
  questions: [ {kind: scene|word, sentenceIndex?,   // scene: welcher Satz; Antwort = panelIndex des Satzes
                prompt?, targetItemId?} ],           // word: deutsche Frage, Zielwort
  situations: [ {panelIndex, interactionIndex,       // zeigt auf silent/speak-Interaktion
                 question, expected: [itemId…], sample, why, grammar?} ],
  grammarNotes: { itemId: text }                     // §3.1 Punkt 6
}
```

### 5.3 Prüfregeln (Erweiterung `episode_validator.dart`, Funktion `validateCafeContent(episode, content, {priorItemIds})`)

| Regel | Inhalt |
|---|---|
| **INV-20** | Jedes Kana-/Kanji-Wort in `monologue[].ja` und `situations[].sample` ist ein Token eines Budget-Items dieser Folge oder in `priorItemIds` (gleiche Zeichen-Erkennung wie INV-18). |
| **INV-21** | Jede `word`-Frage zielt auf ein Budget-Item, das im Monolog oder in einer Blase der Folge vorkommt; jede `scene`-Frage zeigt auf einen vorhandenen Satz, dessen `panelIndex` existiert. |
| **INV-22** | Jede Situation zeigt auf eine vorhandene `silent`- oder `speak`-Interaktion; `expected` enthält deren Zielwort; alle `expected` sind Budget-Items oder prior. |
| **INV-23** | Jedes Budget-Item ist Ziel in mindestens einer der drei aktiven Stationen (Planer-Regel §2.1; geprüft als Test über `CafeVisitPlanner`). |

Verstöße brechen den Content-Build (`StoryValidationException`), wie bisher.

## 6. Komponenten

### 6.1 Kana-Tastatur (`lib/features/cafe/kana_keyboard.dart`)

Eingebautes Widget, 50-Laute-Raster (Hiragana, 5 Spalten, scrollbar), dazu drei Funktionstasten: **゛゜** (macht das zuletzt getippte Zeichen stimmhaft/halbstimmhaft, zweimal = zurück), **小** (macht das zuletzt getippte Zeichen klein: ゃゅょっ, auch ぁぃぅぇぉ), **⌫**. Ausgabe als `String`. Keine System-Tastatur nötig. Tests: だいじょうぶ und ちょっと lassen sich tippen.

### 6.2 Zerlegung (`lib/features/cafe/word_decomposition.dart`)

Reine Funktion `decompose(String kana) → List<SoundUnit(text, romaji)>` nach den Regeln in §3.1 Punkt 3; Lautschrift aus `kana_data.dart`. Tests: あめ → [あ a, め me]; きょう → [きょ kyō]; ちょっと → [ちょ cho, っ t, と to]; ありがとう → [あ a, り ri, が ga, と tō]; さんぽ → [さ sa, ん n, ぽ po].

### 6.3 Blasen-Überlagerung (`lib/features/cafe/bubble_overlay.dart`)

Zeichnet über das Panel-Bild an der Stelle der Blase (Rechteck aus `folge_01_layout.g.dart`, Format hoch) eine weiße Blase mit dem Blasentext aus den Daten — die gelesene Blase bleibt darunter verdeckt. Zwei Modi: **hervorheben** (Zielwort farbig) und **ausblenden** (Zielwort → „___“). Kein neues Rendern, keine zusätzlichen Bilddateien. Widget-Test: Rechteck und Text stimmen mit `StoryBubble` überein.

### 6.4 Ablauf

- `CafeVisitPlanner` (rein): aus Folge + `CafeContent` (+ fälligen Items) die Stationsliste mit Items (§2.1/§2.2).
- `CafeVisitScreen`: Raum, Leiste, Fortsetzen, Übergabe an die Station.
- Stationen: `WirtinStation`, `SchulmaedchenStation`, `VielrednerStation`, `GleichaltrigeStation` (je eine Datei unter `lib/features/cafe/stations/`), jede bekommt ihre Items und meldet je Item ein `CafeOutcome` zurück.
- `CafeSummary` (rein) + `CafeSummaryScreen`.
- Einstiege: Endkarte (`story_reader_screen.dart`, „Ins Café“) → `CafeVisitScreen(episode)`; Café-Tab (`cafe_route.dart`) → `CafeVisitScreen.free()`.

### 6.5 Entfällt

`cafe_debrief_screen.dart`, `cafe_debrief_card.dart`, `cafe_turn_screen.dart`, der Gäste-Tipp in `cafe_screen.dart`, `cafe_speaker_plan.dart`. `cafe_debrief.dart` bleibt (Reihenfolge, erstes Panel, `debrief`-Zugriff), `cafe_turn.dart` bleibt für `CafeOutcome` und `resultForOutcome`; `kindForRung` wird durch die Stationen ersetzt. Die dazugehörigen Tests werden ersetzt, nicht gelöscht ohne Ersatz.

## 7. Wiederholungsplanung — was zählt

| Station | Ergebnis → `ReviewResult` |
|---|---|
| Wirtin | nichts (nur „wackelig“ für diesen Besuch) |
| Schulmädchen | 1. Versuch richtig `good` · 2. Versuch richtig `hard` · sonst `again` |
| Alter Mann | richtig `good` · falsch `hard` |
| Gleichaltrige | `freeProduced` (keine Änderung) |

Die Zuordnung Sprosse ↔ Gast (`guestForRung`) bleibt; nach einer Folge laufen die Stationen unabhängig von der Sprosse, beim freien Besuch nach Sprosse (§2.2).

## 8. Invarianten

- **I1** Keine Antwort zur Auswahl in Schulmädchen, Wort-Fragen und Situationen. Die Szene-Frage des alten Mannes wählt ein Panel, kein Wort.
- **I3/INV-10** Keine Zähler, Punkte, Häkchen; Fortschritt nur in Worten.
- **INV-18/19** gelten weiter; INV-20–23 neu (§5.3).
- Offline: alle Stationen laufen ohne Netz; Spracherkennung und Vorlesen nutzen die Geräte-Dienste; fehlt eines, bietet die Station die Tastatur bzw. zeigt den Text (kein Crash, Hinweis in der Stimme der Figur).

## 9. Tests

- Reine Funktionen: `CafeVisitPlanner` (Zuteilung, Abdeckung INV-23, Höchstzahl frei), `decompose`, `CafeSummary`, Kana-Normalisierung.
- Validator: INV-20–23 mit Negativ- und Positivfällen; Folge 01 besteht.
- Widgets: Kana-Tastatur (゛゜, 小, ⌫), Blasen-Überlagerung, jede Station mit Fake-TTS/-STT (Muster aus `story_reader_silence_test.dart`), Fortsetzen nach „Später weiter“, Abschluss-Text.
- Ablauf-Test: Folge 01 Weg 1 durch alle Stationen, Ergebnisse landen in `learn_items`.
- Emulator (NUC) Durchlauf beider Wege; S23.

## 10. Pläne

- **Plan A — Gerüst, Wirtin, Schulmädchen:** Planer, Raum, Fortsetzen, Zerlegung, Kana-Tastatur, Blasen-Überlagerung, Stationen 1–2, Abschluss, Einstiege, Abriss der alten Nachbesprechung. Danach ist das Café benutzbar und Uli kann begutachten.
- **Plan B — Alter Mann, Gleichaltrige, Folge-01-Inhalte:** `CafeContent` Folge 01 (Monolog, Fragen, Situationen, Grammatiknotizen), Validator INV-20–23, Stationen 3–4, freier Besuch nach Sprosse.

## 11. Offene Punkte

- Entwurfstexte (Monolog, Fragen, Situationen, Grammatiknotizen, Abschluss-Sätze) schreibt Claude in Plan B, Uli liest gegen.
- Später: Katakana auf der Tastatur; Café-Bilder und Vollbild (Pläne 3/4); ab Folge 02 wachsen die Sätze des alten Mannes mit Miras Wortschatz.
