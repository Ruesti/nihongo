# Design: Nachbereitung der Folge — alles kommt dran, Zeichen erklärt, Zeichen nachgezeichnet

Stand 16.10.2026. Zweiter Nachtrag zur Spec „Das Café als Übungsraum“ (8.10.), gestapelt
auf „Das Café spricht dich an“ (15.10., `2026-10-15-cafe-ansprache-design.md`). Was hier
steht, geht vor; was hier nicht steht, bleibt wie dort.

## 0. Auslöser und Entscheidungen

Uli 15.10., nach dem Gerätetest von Plan A: „Es müsste alles, was in der Folge vorkam,
wiederholt werden. Grammatik, was warum gesagt, Schriftzeichen-Erklärung (mit einem
Strich, mit zwei Strichen, mit Punkt), Schriftzeichen nachzeichnen, erst einfach, dann
schwer.“

Befund in Spec und Code: Wörter (Wirtin, Schulmädchen) sind gebaut. „Was warum gesagt“
(Wirtin §3.1 Punkt 5, Gleichaltrige §3.4) und Grammatik (Wirtin §3.1 Punkt 6, Gleichaltrige
§3.4 Punkt 4, `grammarNotes` in `CafeContent`) stehen in der Übungsraum-Spec und sind
Plan B. Nacherzählen der Folge: alter Mann §3.3, Plan B. **Nicht vorgesehen** waren bisher
die Erklärung der Zeichenmarken (゛ ゜ ー, kleine Zeichen) und das Nachzeichnen. Die App
hat dafür Bausteine aus den alten Kanji-Spielen (`lib/features/kanji_games/trace/`:
`StrokePainter`, `StrokeValidator`, `KanjiSvgLoader`), aber nur fünf gebündelte
Kana-Vorlagen (あいうえお). Die Zeichen sind Lernposten vom Typ `RefType.character` mit
Sprossen.

Lesart der Marken: „ein Strich“ = Dehnungsstrich ー (Katakana) bzw. Dehnung mit う/い in
Hiragana, „zwei Striche“ = Trübung ゛, „Punkt“ = Halbtrübung ゜. Dazu die kleinen Zeichen
ゃゅょ und っ.

Zahlen Folge 01: 48 verschiedene Kana in der ganzen Folge, 32 davon in den 18 Wörtern;
neun Zeichen mit zwei Strichen (がござじぞだでどぶ), keins mit Punkt, ein kleines ょ, kein
Dehnungsstrich, mehrere Dehnungen mit う.

Entscheidungen (Uli, 16.10.):

1. **Nachzeichnen in fester Portion** je Besuch (etwa sechs Zeichen); nie geschriebene
   Zeichen zuerst, dann nach Fälligkeit; einfach beim ersten Mal, schwer ab dem zweiten.
2. **Das Schulmädchen** übt das Schreiben („Schreib mit“); **die Wirtin** erklärt die Marken
   beim Auflösen.

## 1. Ziel und Nicht-Ziele

**Ziel:** Nach einer Folge geht im Café nichts verloren: jedes Wort, jede Situation, jede
Grammatikform, jede Zeichenmarke und, über mehrere Besuche, jedes Zeichen kommt dran.
„Erst einfach, dann schwer“ ergibt sich aus dem Stand je Zeichen.

**Nicht-Ziele:**

- Kanji nachzeichnen (駅, 傘 auf Schildern in Folge 01): kommt mit dem Kanji-Vorrat der
  Staffel, nicht hier.
- Katakana nachzeichnen: folgt mit der Katakana-Tastatur.
- Neue Inhalte für alter Mann und Gleichaltrige: bleiben Plan B der Übungsraum-Spec.
- Ein Fortschrittszähler je Folge: nein (INV-10 bleibt; der Abschluss spricht in Worten).

## 2. Abdeckung: alles aus der Folge

### 2.1 Regel (INV-28)

Nach dem Besuch „nach der Folge“ (Weg 1) gilt:

| Was | Wo | Stand |
|---|---|---|
| jedes Wort aufgelöst | Wirtin §3.1 | gebaut (Plan A) |
| jedes Wort abgefragt, das nicht Ziel bei alter Mann oder Gleichaltriger ist | Schulmädchen §3.2 | gebaut (Plan A) |
| jede Situation (stumm/sprechen) mit „Warum sagt man das“ | Gleichaltrige §3.4 | Plan B |
| die Folge nacherzählt und gefragt | alter Mann §3.3 | Plan B |
| jede Grammatikform der Folge einmal erklärt (Folge 01: こわれた, だいじょうぶ, いいえ, ひとり) | Wirtin §3.1 Punkt 6 am Wort; Gleichaltrige §3.4 Punkt 4 an der Situation | Plan B |
| jede Zeichenmarke erklärt, die in einem Wort der Folge steckt | Wirtin, §3 dieser Spec | **Plan C** |
| jedes Zeichen der Folge nachgezeichnet, verteilt über Besuche | Schulmädchen, §4 dieser Spec | **Plan C** |

Test `cafe_visit_planner_test`: aus den Folgendaten (Wörter, Interaktionen,
`CafeContent`) folgt die Abdeckung je Zeile; eine Simulation mehrerer Besuche zeigt, dass
jedes Zeichen der Folge drankommt.

### 2.2 Zeichen-Liste je Besuch

- `planAfterEpisode` / `planFreeVisit` (reine Funktionen in `cafe_visit.dart`) leiten die Zeichen aus den
  Lesungen der Folgenwörter ab (`readings` → Runen; kleine Zeichen und Marken sind eigene
  Zeichen, z. B. ょ, が). Nichts wird von Hand gepflegt.
- **Nach der Folge (Weg 1):** Zeichen der Folgenwörter, zuerst die mit Sprosse 0 (nie
  geschrieben), dann die fälligen, dann die übrigen in Lesereihenfolge; **höchstens
  sechs** je Besuch (`kTracePortion = 6`). Was nicht passt, bleibt für die nächsten
  Besuche; Sprosse 0 bleibt vorne, bis alles einmal geschrieben ist.
- **Frei (Weg 2):** nur fällige Zeichen, höchstens sechs; keine Zeichen, wenn nichts
  fällig ist.
- `CafeVisitPlan.characters: List<String>` (Posten-Ids); `CafeStationPlan` des
  Schulmädchens führt sie als dritten Abschnitt. Die gespeicherte Besuchsposition (Plan A, `clearCafeVisitPosition`) kennt Abschnitt
  (`abfrage` | `schreiben`) und Index, damit „Später weiter“ mitten im Schreiben richtig
  aufsetzt.

### 2.3 Abschluss der Wirtin

Bleibt in Worten, ohne Zähler (INV-10). Zusätzlich, wenn aus der Zeichen-Liste der Folge
etwas übrig ist: „Ein paar Zeichen aus der Folge fehlen dir noch, die nehmen wir beim
nächsten Mal.“ Ist alles einmal geschrieben: „Die Zeichen aus der Folge hast du jetzt alle
einmal geschrieben.“ Beides über die Gästestimme.

## 3. Zeichen-Erklärung bei der Wirtin

### 3.1 Regeltabelle (`lib/features/cafe/kana_marks.dart`)

```
enum KanaMark { dakuten, handakuten, dehnung, klein }
class KanaMarkRule { KanaMark mark; String base; String kana; String lautwandel;
                     String satz; String kurz; }
KanaMarkRule? markOf(String kana);      // が → dakuten, base か, k→g
```

| Art | Zeichen | Lautwandel | voller Satz der Wirtin | kurz |
|---|---|---|---|---|
| zwei Striche ゛ | が ぎ ぐ げ ご ざ じ ず ぜ ぞ だ ぢ づ で ど ば び ぶ べ ぼ | k→g, s→z, t→d, h→b | „Siehst du die zwei Striche an が? Aus か wird が, aus k wird g.“ | „zwei Striche“ |
| Punkt ゜ | ぱ ぴ ぷ ぺ ぽ | h→p | „Der kleine Kreis an ぱ: aus は wird ぱ, aus h wird p.“ | „Punkt“ |
| Dehnung | う nach o/u, い nach e/i, ー | Vokal wird lang | „Das う hier macht das o lang: どうぞ, nicht do-zo.“ | „lang“ |
| klein | ゃ ゅ ょ っ (ぁ ぃ ぅ ぇ ぉ) | verschmilzt / kurzer Stopp | „Das kleine ょ hängt sich an じ: jo, ein Laut.“ / „Das kleine っ ist ein kurzer Stopp.“ | „klein“ |

Die Sätze sind Vorlagen mit Platzhaltern (Zeichen, Grundzeichen, Laute); je Art gibt es
den vollen Satz und den Kurzhinweis. Alle Hiragana-Marken sind in der Tabelle; Katakana
wird dieselbe Tabelle später nur erweitern.

### 3.2 In der Zerlegung (`word_decomposition.dart`)

`SoundUnit` bekommt `mark: KanaMark?` und `base: String?`. Dehnung und Kleinzeichen
erkennt die Zerlegung heute schon (Kachel きょ, Kachel って, Dehnung an der Kachel davor);
neu ist nur, dass die Kachel weiß, welche Marke sie trägt und welches Grundzeichen gilt.

### 3.3 Beim Auflösen (Wirtin §3.1, zwischen Punkt 3 und 4)

1. Nach dem langsamen Vorsprechen leuchtet die erste Kachel mit einer Marke, und die
   Wirtin sagt in ihrer Blase (Gästestimme) den **vollen Satz**.
2. Weitere Kacheln mit Marken tragen nur den **Kurzhinweis** als kleine Beschriftung
   unter der Kachel.
3. **Dosierung (INV-29):** je Art und Besuch kommt der volle Satz genau einmal, beim
   ersten Wort, in dem die Art vorkommt; danach nur noch Kurzhinweise. Der Besuch merkt
   sich die schon erklärten Arten (`CafeVisit.explainedMarks`).
4. **Tipp auf eine Kachel mit Marke:** zeigt Grundzeichen und Zeichen nebeneinander
   (か → が) und spricht beide (`TtsService.speak`, japanisch). Tipp auf eine Kachel ohne
   Marke bleibt wie heute (spricht den Laut).

Keine Antwort wird dadurch verraten (INV-9): die Erklärung kommt, nachdem das Wort
ohnehin groß gezeigt wurde.

## 4. Nachzeichnen beim Schulmädchen („Schreib mit“)

### 4.1 Ablauf

Nach ihrer Abfrage (alle Wörter des Abschnitts) kommt, wenn die Zeichen-Liste nicht leer
ist, der dritte Abschnitt. Blase: „Schreib mit. Hefte raus.“ Dann je Zeichen ein Bildschirm:

- **Einfach** (Sprosse 0, nie geschrieben): Blase „Zeichne か nach.“ Das Zeichen groß als
  Vorlage blass im Feld, der nächste Strich etwas kräftiger. Du ziehst Strich für Strich
  mit dem Finger. Ein Strich, der nicht passt, bleibt kurz rot, dazu der Richtungshinweis
  des Prüfers („von oben nach unten“), und du ziehst ihn neu. Sind alle Striche gezogen:
  Bild zufrieden, Blase „Geht doch.“ Ergebnis: **gesehen**, Sprosse 0 → 1 wie bei einer
  Begegnung (`markEncountered`), keine Bewertung.
- **Schwer** (Sprosse ≥ 1): leeres Feld. Blase „Schreib ka. Los.“, dazu die Lautschrift
  `ka` groß in der Fläche; das Zeichen selbst wird **nicht** gezeigt. Du zeichnest aus dem
  Gedächtnis. Jeder Strich wird gegen die Vorlage geprüft:
  - alle Striche ohne Hilfe richtig → Bild zufrieden, „Ha, gewusst!“, Ergebnis **good**;
  - erster Strich daneben → die Vorlage erscheint blass, Bild abwinkend, Blase „Nee. Guck
    hin.“, du machst mit Hilfe fertig → Ergebnis **hard**;
  - „Zeig's mir“ vor dem ersten Strich → Vorlage blass, einmal nachziehen, Blase „Das
    nehmen wir nochmal.“ → Ergebnis **again**.
- Weiter, Später weiter wie in jeder Station.

### 4.2 Bewertung und Planung

Ergebnis je Zeichen über `LadderReview.submit` auf den Posten `lang_ja:character:<id>`
(INV-30: good/hard/again genau wie oben; „gesehen“ bewertet nicht). Fehlt der Posten, legt
der Planer ihn an (wie die Seeds). Dadurch kommt „erst einfach, dann schwer“ aus dem
Stand je Zeichen, nicht aus einem Schalter.

### 4.3 Das Feld (`lib/features/cafe/trace_field.dart`)

- Neues Widget `TraceField(assetPath, mode: easy|hard, onResult)`, gebaut aus
  `KanjiSvgLoader.loadStrokes`, `StrokePainter`, `StrokeValidator.isAcceptable` und
  `directionHint` (bestehend, unverändert). Der alte `TracePractice`/`trace_screen` der
  Kanji-Spiele bleibt unberührt.
- Quadratisch, Kantenlänge mindestens 240 dp; hochkant passt das in die halbe Höhe der
  Fläche, quer ins Drittel rechts nur knapp (§8). Finger zeichnet; „nochmal“ löscht den
  aktuellen Strich; Strichfolge nach Vorlage.
- Bild und Blase wie in der Ansprache-Spec: fragend beim Zeichnen, zufrieden/abwinkend
  mit dem Ergebnis.

### 4.4 Vorlagen (`lib/data/kana_strokes.dart`, `assets/kanji_svg/`)

- Gebündelt werden alle Hiragana: 46 Grundzeichen, 20 mit zwei Strichen, 5 mit Punkt,
  8 kleine (ぁぃぅぇぉゃゅょっ), zusammen 79 Dateien aus KanjiVG (Codepunkt als Dateiname,
  wie die fünf vorhandenen), grob 160 KB.
- Die Tabelle in `kana_strokes.dart` führt die Codepunkte; Strukturtest: jedes Zeichen
  der Kana-Daten hat seine Datei, jede Datei ihr Zeichen.
- Lizenz KanjiVG (CC BY-SA 3.0): Nennung in den Einstellungen unter „Über“ (Name, Link),
  wie es die Dateiköpfe verlangen.

## 5. Daten und Komponenten

| Datei | Neu/Änderung | Aufgabe |
|---|---|---|
| `lib/features/cafe/kana_marks.dart` | neu | Regeltabelle, `markOf` (§3.1) |
| `lib/features/cafe/word_decomposition.dart` | Änderung | `mark`, `base` an `SoundUnit` (§3.2) |
| `lib/features/cafe/stations/wirtin_station.dart` | Änderung | Erklärung, Kurzhinweis, Kachel-Tipp, Dosierung (§3.3) |
| `lib/features/cafe/cafe_visit.dart` | Änderung | Zeichen-Liste, Portion, Position mit Abschnitt, `explainedMarks` (§2.2, §3.3) |
| `lib/features/cafe/stations/schulmaedchen_station.dart` | Änderung | Abschnitt „Schreib mit“ (§4.1) |
| `lib/features/cafe/trace_field.dart` | neu | Zeichenfeld einfach/schwer (§4.3) |
| `lib/data/kana_strokes.dart`, `assets/kanji_svg/*.svg` | Erweiterung | 79 Hiragana-Vorlagen (§4.4) |
| `lib/features/cafe/cafe_visit_screen.dart` | Änderung | Abschluss-Sätze zu den Zeichen (§2.3) |
| `lib/features/settings/settings_screen.dart` | Änderung | Nennung KanjiVG (§4.4) |
| `pubspec.yaml` | Änderung | Asset-Ordner bleibt, Dateien kommen dazu |

Keine Änderung an der Datenbank; `CafeContent` (Übungsraum §5.2) bleibt unverändert.

## 6. Invarianten (Fortsetzung)

- **INV-28** Abdeckung nach der Folge gemäß Tabelle §2.1; jedes Zeichen der Folge kommt
  über Besuche hinweg dran, Sprosse 0 zuerst.
- **INV-29** Je Art einer Zeichenmarke und Besuch genau ein voller Satz der Wirtin; sonst
  Kurzhinweise.
- **INV-30** Nachzeichnen bewertet nur im schweren Modus (good/hard/again); der einfache
  Modus hebt nur auf Sprosse 1. Das Zeichen wird im schweren Modus nie vor dem ersten
  Strich gezeigt.
- INV-10 (Abschluss ohne Zähler), INV-9 (Stimm-Zeile verrät keine Antwort), INV-24 bis 27
  (Ansprache) bleiben.

## 7. Tests

- `kana_marks_test`: jede Art erkannt, Grundzeichen richtig (が→か, ぱ→は, ょ klein, っ
  klein, う-Dehnung nur nach o/u), Sätze und Kurzhinweise vollständig, Platzhalter gefüllt.
- `word_decomposition_test`: Kacheln tragen `mark`/`base`; Kachel きょ meldet `klein`.
- `wirtin_station_test`: voller Satz beim ersten Wort je Art, danach Kurzhinweis; zweites
  Wort derselben Art ohne vollen Satz; Kachel-Tipp zeigt beide Zeichen und spricht beide;
  Satz läuft über die Gästestimme (`FakeVoiceSource`).
- `cafe_visit_planner_test`: Zeichen aus Lesungen; Reihenfolge Sprosse 0 → fällig →
  Rest; Portion sechs; frei nur fällige; Simulation von Besuchen → jedes Zeichen der
  Folge einmal; Abdeckungstabelle §2.1 aus den Folgendaten.
- `trace_field_test`: einfach → gesehen; schwer ohne Fehler → good; erster Fehler blendet
  Vorlage ein → hard; „Zeig's mir“ → again; Strichfolge; Richtungshinweis; Zeichen im
  schweren Modus nicht sichtbar vor dem ersten Strich.
- `schulmaedchen_station_test`: Abschnitt „Schreib mit“ nach der Abfrage; leer, wenn die
  Liste leer ist; „Später weiter“ im Abschnitt setzt am Zeichen wieder auf; Bild- und
  Blasenwechsel.
- `cafe_visit_screen_test`: Abschluss-Satz bei Rest und bei vollständiger Liste.
- `kana_strokes_test`: Strukturtest der 79 Vorlagen gegen die Kana-Daten.
- Vollsuite grün (bis auf die bekannten Tokenizer-Tests), Emulator-Bogen Wirtin
  (Kachel mit Marke, Kachel-Tipp) und Schulmädchen (einfach, schwer, Fehler), S23: das
  Zeichnen mit dem Finger beurteilt nur Uli am Gerät.

## 8. Risiken und offene Punkte

- **Zeichenfeld quer:** 240 dp im Drittel rechts (mindestens 360 dp breit laut
  Ansprache-Spec) passt, aber Blase, Lautschrift und Knöpfe darüber und darunter werden
  eng. Entscheidet der Emulator-Bogen; sonst wird die Fläche beim Schreiben bis zur
  Hälfte breit.
- **Strich-Prüfer:** Er stammt aus den Kanji-Spielen und wurde nie am Gerät mit Kana
  geprüft. Ist er zu streng oder zu lasch, werden die Schwellen in `StrokeValidator`
  nachgezogen (nur Werte, kein Umbau).
- **Lesart „ein Strich“:** als Dehnung gelesen; meint Uli etwas anderes, ändert sich nur
  die Tabellenzeile.
- **Besuchsdauer:** Wirtin (18 Wörter) plus Abfrage plus sechs Zeichen plus Plan B
  (alter Mann, Gleichaltrige) wird nach der Folge lang. „Später weiter“ fängt das auf;
  wird es Uli zu lang, sinkt die Portion auf vier.

## 9. Pläne und Reihenfolge

- **Plan A2 / A3** (Ansprache-Spec): Bilder auf der GPU-Box parallel zum App-Rahmen.
- **Plan C — Zeichen:** Regeltabelle und Zerlegung; Erklärung bei der Wirtin; Vorlagen
  und Tabelle; Zeichenfeld; Zeichen-Liste im Planer und Position; „Schreib mit“ beim
  Schulmädchen; Abschluss-Sätze; Nennung; Tests; Vollsuite; Emulator-Bogen; S23.
  Hängt an Wirtin und Schulmädchen (vorhanden) und am neuen Rahmen aus A3.
- **Plan B** (Übungsraum-Spec): alter Mann, Gleichaltrige, Inhalte Folge 01; bekommt die
  Abdeckungstabelle §2.1 als Test. Kann auf eigenem Branch neben C laufen.
- Reihenfolge: A2 ∥ A3 → C → B. Diese Spec ist gestapelt auf #63.

## 10. Abnahme

1. Emulator-Bogen: Wirtin mit どうぞ (Dehnung) und だいじょうぶ (zwei Striche, kleines ょ),
   voller Satz einmal, dann Kurzhinweise, Kachel-Tipp; Schulmädchen „Schreib mit“ einfach
   und schwer, Fehlerfall, „Zeig's mir“; Abschluss mit Rest.
2. S23: ein Besuch nach Folge 01 bis zum Schreiben, dann ein freier Besuch am nächsten
   Tag mit schwerem Modus.
3. Uli: „Nichts aus der Folge geht verloren, und ich weiß, was die Striche bedeuten.“
