# Design: Mira schweigt, das Café fragt „Was hättest du sagen können?“, und das Café sieht aus wie die Folge

**Datum:** 2026-10-02
**Status:** Entwurf nach Ulis Abnahme des Chat-Designs (2.10., „passt“). Wartet auf Ulis
Review dieser Spec, dann vier Umsetzungspläne (§12).
**Anlass:** Uli, 2.10.: *„Mira hat Sprechblasen mit Kanji/Japanisch, obwohl sie ja noch
nicht Japanisch spricht. Das ist ein Fehler. Wenn sie die Wörter irgendwann kennt, dann
ja. Das wäre etwas, was man im Café nachbereiten könnte, à la ‚Was hättest du da sagen
können?‘. Dabei möchte ich das Café auch noch auf das erarbeitete Muster umstellen.“*

**Ulis Entscheidungen (2.10.):**
1. „Erarbeitetes Muster“ fürs Café = **Weg A**: Die Café-Bilder gehen denselben Weg wie
   die Folge (Foto, Manga-Durchgang, Vollbild in beiden Handylagen mit Kern-Hochbild).
   Erklärungskarte und Fragen liegen als Flächen über dem Bild. Der Ablauf des Cafés
   bleibt.
2. Die **Sprechmomente** (すみません in P5, ありがとう in P8) bleiben: Dort spricht der
   Lerner für Mira, und das Wort wurde kurz vorher gehört.
3. Das Chat-Design in fünf Abschnitten (Mira-Regel + Drehbuch V3, stumme Momente,
   „Erzähl mal“, Café im Manga-Muster, Reihenfolge) ist abgenommen; diese Spec führt es
   aus.

**Baut auf:** Drehbuch V2 (`docs/story/DREHBUCH_FOLGE_01_V2.md`), der
Café-Nachbesprechungs-Spec (`2026-09-15-cafe-nachbesprechung-design.md`), der
Café-Szenen-und-Stimmen-Spec (`2026-09-18-cafe-szenen-und-stimmen-design.md`), der
Manga-Vollbild-Spec mit §12 Hochbild aus dem Querbild
(`2026-09-23-manga-vollbild-titelbild-design.md`) und dem Reader-Erleben
(`2026-09-13-reader-erleben-design.md`).

---

## 1. Befund

### 1.1 Mira spricht Japanisch, das sie nicht kann

Drehbuch V2 hat Mira bewusst „Echo-Zeilen“ gegeben (*„Mira benutzt Gelerntes selbst“*).
Im Code (`folge_01_regen.dart`, `speakerId: 'protagonist'`) sind das sieben Blasen:

| Panel | Miras Blase heute | Tokens |
|---|---|---|
| P4 | 「…あめ」 | あめ |
| P5 | 「…はい。ひとり」 | はい, ひとり |
| P6 | 「…こわれた…？」 | こわれた |
| P7 | 「え？いくら？いくら？」 und 「…ほんとう？」 | いくら ×2, ほんとう |
| P8 | 「ありがとう… すみません… あめ… かさ… いいえ… だいじょうぶ… えき… みせ…」 | 8 Wörter |
| P9 | 「ここ…？あめ…やどり？」 | ここ, あめ |
| P10 | 「ここ…」 | ここ |

Uli hat recht: Dreimal hören macht kein Sprechen. Die Figur, die der Lerner ist, darf
nicht weiter sein als der Lerner. Diese Blasen tragen aber **18 der 55 gehörten
Wort-Vorkommen** der Folge. Ohne sie fallen いくら und ここ auf 0, acht weitere Wörter
auf 1 (Regel INV-4: jedes Wort mindestens zweimal). Die Blasen sind außerdem in die
Manga-Bilder gelettert; sieben der zehn Panels müssen neu gelettert werden (beide
Formate). Die ungeletterten Master liegen unter `build/f01_raw/`, das geht ohne GPU.

### 1.2 Zwei getrennte Stapel

Café-Stapel (PR #48 → #50 → #53 → #54) und Manga-Stapel (#48 → #51 → #55 → #56 → #57)
trennten sich bei #48 und wurden nie zusammengeführt. Das Café kannte weder Manga-Look
noch Vollbild. Am 2.10. wurden beide Stapel zusammengeführt (§11); diese Spec setzt den
zusammengeführten Stand voraus.

## 2. Zielbild

**Mira schweigt, bis sie etwas kann. Wo sie etwas hätte sagen können, fragt die Wirtin
danach. Und das Café sieht aus wie die Folge.**

Drei Dinge, die zusammengehören:

1. **Mira-Regel:** Mira spricht in Folge N nur Wörter, die eine Folge vor N eingeführt
   hat. In Folge 01 spricht sie kein Wort Japanisch. Was sie sagen will und nicht kann,
   zeigt die Folge als **stummen Moment**: eine „…“-Blase.
2. **„Erzähl mal“:** In der Nachbesprechung geht die Wirtin die stummen Momente durch.
   Das Panel steht bildschirmfüllend, die Wirtin fragt *„Was hättest du da sagen
   können?“*, der Lerner wählt das Wort, und es erscheint in Miras leerer Blase. So
   gehört ihr das Wort danach wirklich.
3. **Café im Manga-Muster:** Die Café-Bilder gehen den Weg der Folge (Foto → Manga →
   Kern-Hochbild), das Café ist Vollbild in beiden Lagen, Karten und Fragen liegen als
   Flächen über dem Bild.

## 3. Die Mira-Regel

### 3.1 Regel

**INV-18 Mira spricht nur, was sie schon kann.** Eine Blase mit `speakerId:
'protagonist'` darf nur Tokens tragen, deren `itemId` im Budget einer Folge mit
kleinerem Index liegt (Reihenfolge aus `EpisodeRegistry`). Außerhalb ihrer Tokens
enthält der Blasentext keine Kana und keine Kanji; erlaubt sind „…“, Satzzeichen und
Leerraum. Die „…“-Blase ist damit die einzige Mira-Blase der Folge 01.
*(Seit 5.10. überholt, siehe die Änderung am Anfang von §4: Folge 01 hat gar keine
Mira-Blase mehr, eine tokenlose Mira-Blase ist ein Verstoß.)*

**INV-19 Mira spricht nur nach, was sie gehört hat.** Das Ziel eines Sprechmoments
(`InteractionType.speak`) muss vorher in derselben Folge (frühere Panel-Nummer oder
frühere Blase im selben Panel) oder in einer früheren Folge als Token einer anderen
Figur vorgekommen sein. Folge 01: すみません in P5 wurde in P3 gehört, ありがとう in P8
in P3.

Beide Regeln prüft `EpisodeValidator` beim Content-Build; Verstöße brechen den Build,
nie die Laufzeit. Gedankenkästen (`StoryThought`) sind deutsch und bleiben außerhalb
der Regel; ein Lautecho wie *„Kowareta. Kaputt.“* im Gedanken ist kein Sprechen.

### 3.2 Was die Regel für spätere Folgen heißt

Folge 02 darf Mira die Wörter der Folge 01 sagen lassen, aber kein Wort der Folge 02.
Das ist gewollt: Miras Japanisch wächst genau so langsam wie das des Lerners, und die
Dichte der Folgen steigt über die Staffel von allein, weil Mira immer mehr beitragen
darf. Der Serienplan (`docs/story/STAFFEL_1_DIE_ADRESSE.md`) bekommt diese Regel als
Format-Regel neben die Budgets.

## 4. Stumme Momente in der Folge

> **Änderung 5.10. nach Ulis Gerätesicht: keine „…“-Blase; Schweigen im Erzähltext;
> Schilder als Kasten; keine Off-Zeiger.**
>
> - **Keine „…“-Blase.** Miras Schweigen steht im deutschen Erzähltext, gerade wenn sie
>   nicht im Bild ist. Die vier „…“-Blasen (P4, P6, P7, P10) sind aus Daten, Layout-Datei
>   und Lettering entfernt. Jeder stumme Moment bekommt stattdessen einen kurzen Satz im
>   Gedankenkasten: P4 *„Das Wort von der Straße liegt ihr auf der Zunge. Es bleibt
>   dort.“*, P6 *„Mira will etwas sagen. Sie bringt es nicht heraus.“*, P7 *„Sie bleibt
>   stumm.“*, P10 *„Sie bleibt stumm vor der Tür.“*
> - **Daten bleiben:** die Interaktion `silent` (Ziel, `targetItemIds`, Wirtin-Frage)
>   bleibt unverändert, das Café braucht sie.
> - **Validator neu:** Ein Panel mit `silent` hat **keine** Mira-Blase und mindestens
>   einen Gedankenkasten; eine Mira-Blase ohne Wörter (auch „…“) ist überall ein Verstoß
>   („Miras Schweigen steht im Erzähltext“). Ziel im Budget/früher, irgendwo gehört,
>   genau ein Ziel, höchstens ein stummer Moment je Panel sowie INV-18/19 gelten weiter.
>   `StoryBubble.isSilence` und der Reader-Filter bleiben als harmloser Schutz.
> - **Schilder als Kasten:** Schild-Texte (P1 みなみまち駅, P4 傘, P9 あめやどり) werden als
>   rechteckiges Schild-Etikett gelettert (`"form": "schild"` in der Layout-Datei),
>   nicht als Sprechblase.
> - **Keine Off-Zeiger:** Das Feld `"off"` und die Zeiger sind entfernt. Blasen von
>   Sprechern außerhalb des Bildes stehen am Bildrand auf ihrer Seite, weg von Miras
>   Gesicht; der Erzähltext nennt sie (P3 *„Passanten drängeln sich unters Vordach.“*,
>   P8 *„Hinter ihr ruft der Ladenbesitzer.“*).
> - **„Acht Wörter“:** P10 und Endkarte sagen jetzt *„ein Zeichen und acht Wörter“*,
>   passend zu P8 *„Acht Wörter heute.“*
> - **Folge für Plan 2 „Erzähl mal“ (§5):** Das Café kann das Wort nicht mehr in Miras
>   „…“-Blase schreiben, die gibt es nicht mehr. Die Auflösung im Szenen-Turn braucht
>   eine neue Idee (z. B. eine Blase, die das Café selbst über das Panel legt, oder die
>   Auflösung nur im Café-Text) — vor Plan 2 mit Uli klären.
>
> Der Text unten ist der ursprüngliche Stand vom 2.10.

### 4.1 Erlebnis im Reader

An vier Stellen wollte Mira etwas sagen und konnte nicht. Dort zeigt das Panel eine
Blase mit **„…“** an Miras Position, so wie Manga Sprachlosigkeit zeichnet. Der
deutsche Gedankenkasten trägt den Moment (*„Sag irgendwas.“*), wie heute schon in P5.
Es gibt **keine Aufgabe im Reader** (INV-6: Produktion nicht im Story-Modus); die
Aufgabe kommt im Café. Die „…“-Blase ist **inert**: kein Tipp, kein Vorlesen, kein
Wörterbuch. Sie hat aber eine Tippfläche in der Layout-Datei, denn das Café zeichnet
später das Wort hinein (§5.3).

| Panel | Moment | Zielwort | Wirtin-Frage im Café (Entwurf) |
|---|---|---|---|
| P4 | Unterm Dach, das Schild 傘, das Wort vom Bahnsteig im Kopf | あめ | *„Unter dem Dach, als du das Schild gesehen hast und das Wort von der Straße noch im Ohr hattest. Was hättest du leise sagen können?“* |
| P6 | Er zeigt auf die gebrochenen Streben | こわれた | *„Er hat dir den Schirm gezeigt und es dreimal gesagt. Was hättest du nachsprechen können?“* |
| P7 | Sie greift zum Geldbeutel | いくら | *„Als du zum Geldbeutel gegriffen hast. Was hättest du fragen können?“* |
| P10 | Die Hand am Türgriff meines Cafés | すみません | *„Und dann standest du vor meiner Tür, die Hand am Griff. Was sagt man, wenn man irgendwo hereinkommt?“* |

Vier Momente, nicht sieben: P5 behält den Sprechmoment und braucht daneben keine
zweite Mira-Stelle (sie nickt nur); P8 und P9 werden Gedanken (§4.3). Je Panel
höchstens ein stummer Moment, damit nie zwei „…“-Blasen im selben Bild stehen (P7
verliert Miras zweite Blase 「…ほんとう？」 ersatzlos; der Ladenbesitzer sagt ほんとう
zweimal).

### 4.2 Datenmodell

```
InteractionType.silent                        neu
StoryInteraction(
  type: silent, diegetic: true,
  targetItemIds: ['lex_ja_ikura'], target: 'いくら',
  promptText: '<Wirtin-Frage, deutsch>')
StoryBubble(speakerId: 'protagonist', text: '…', tokens: [],
  hitArea / hitAreaPortrait aus folge_01_layout.g.dart)   // die „…“-Blase
```

- Ein stummer Moment ist eine Interaktion des Panels (die Liste `interactions` trägt
  heute schon mehrere). Sein Zielwort zählt für INV-4 wie ein Sprechziel (Tokens plus
  Interaktionsziele).
- **Validator:** Ein Panel mit `silent` hat genau eine Protagonist-Blase mit Text „…“
  und ohne Tokens; `targetItemIds` hat genau einen Eintrag, und der liegt im Budget
  dieser oder einer früheren Folge; der Zieltext steht als Token irgendwo in der
  Folge (das Wort wurde gehört, auch wenn erst nach dem Moment, wie いくら in P7).
- **Reader:** Blasen ohne Tokens und ohne `audioRef` werden nicht tippbar gemacht
  (heute landen tokenlose Blasen im Fallback-Fuß; die „…“-Blase mit Tippfläche wird
  schlicht übersprungen).
- **Layout-Datei** (`tool/comic/folge01_layout.json`): Die stumme Blase ist eine
  gewöhnliche Blase mit dem Text „…“; das ist zugleich ihre Markierung (wie
  `StoryBubble.isSilence` in der App). `letter_folge01.py` lettert sie wie jede
  andere, `gen_layout_dart.py` exportiert ihre Tippfläche. INV-14 (eine Quelle)
  gilt unverändert.
- **INV-3 für wiederverwendete Wörter:** Tokens mit Ids früherer Folgen
  (`priorItemIds`) sind erlaubt, ohne im Budget zu stehen; sie zählen nicht für
  INV-4.

### 4.3 Drehbuch V3 — die Nebenfiguren tragen die Dichte

Alle Mira-Zeilen fallen; damit jedes Wort mindestens zweimal gehört wird, reden die
Nebenfiguren mehr, im Haus-Stil der Cluster-Wiederholung (「どうぞ、どうぞ！」). Claude
entwirft, Uli liest gegen:

| Panel | Vorher | Nachher |
|---|---|---|
| P3 | Passant A: 「あめ！あめ！」 Passantin B: 「あめ、あめ… さむい、さむい」 | Passant A drängelt vorbei: 「すみません！あめ！あめ！」 Passantin B, unterm Vordach, lachend: 「ありがとう！あめ、あめ… さむい、さむい」 |
| P4 | Mira: 「…あめ」 | Mira: „…“ (stummer Moment, Ziel あめ) |
| P5 | Ladenbesitzer: 「あめ、あめ！」「これ？かさ？みせ！」「ひとり？」 Mira: 「…はい。ひとり」 | Ladenbesitzer winkt sie unters Vordach: 「ここ、ここ！」, dann 「あめ、あめ！」「これ？かさ？みせ！みせ！」, sie musternd: 「えき？ひとり？ひとり…」 Mira nickt (keine Blase). Sprechmoment すみません bleibt. |
| P6 | Mira: 「…こわれた…？」 | Mira: „…“ (stummer Moment, Ziel こわれた) |
| P7 | Mira: 「え？いくら？いくら？」 Er: 「いいえ、いいえ。どうぞ、どうぞ。かさ！」 Mira: 「…ほんとう？」 Er: 「ほんとう。だいじょうぶ、だいじょうぶ」 | Mira greift zum Geldbeutel: „…“ (stummer Moment, Ziel いくら). Er sieht es: 「いくら？いいえ、いいえ。どうぞ、どうぞ。かさ！」 Dann: 「ほんとう、ほんとう。だいじょうぶ、だいじょうぶ」 |
| P8 | Mira murmelt acht Wörter | Deutscher Gedanke: *„Acht Wörter heute. Sie zählt sie an den Fingern ab, auf dem Weg die Straße hinunter.“* Sprechmoment ありがとう bleibt, 「はいはい」 bleibt. |
| P9 | Mira: 「ここ…？あめ…やどり？」 | Deutscher Gedanke: *„Sie liest, Zeichen für Zeichen. Das zweite kennt sie.“* Schild bleibt. |
| P10 | Mira: 「ここ…」 | Mira: „…“ (stummer Moment, Ziel すみません) |

**Dichte-Bilanz V3** (gehört = Tokens anderer Figuren und Schilder; Ziele = 2
Sprechmomente + 4 stumme Momente):

| Wort | gehört | Ziele | gesamt |
|---|---|---|---|
| あめ | 7 | 1 | 8 |
| かさ, はい | 4 | | 4 |
| こわれた | 3 | 1 | 4 |
| どうぞ | 3 | | 3 |
| すみません | 1 | 2 | 3 |
| えき, ここ, これ, さむい, だめ, ひとり, ほんとう, いいえ, だいじょうぶ, みせ | 2 | | 2 |
| いくら, ありがとう | 1 | 1 | 2 |
| **Summe** | **44** | **6** | **50** |

**Nachtrag 6.10.:** Wörter über Szenen gestreut statt in der Blase verdoppelt (Uli:
„warum werden so viele Wörter doppelt gesprochen?"). Jedes Wort steht höchstens einmal
je Blase; Ausnahme nur 「どうぞ、どうぞ」 und 「はいはい」. Neue Zeilen: P3 「すみません！あめ！
さむい！」 / 「ありがとう！あめ… ほんとう、さむい」; P5 「ここ！だいじょうぶ？」「あめ、さむい」
「これ、かさ？みせ！」「えき？ひとり？ほんとう？」; P6 「これ… ここ、こわれた」「いいえ、だめ。
はい、こわれた」; P7 「いくら？いいえ、だめ！どうぞ、どうぞ。かさ！」「ほんとう。だいじょうぶ」;
P8 neu zweite Blase 「ひとり、だいじょうぶ？みせ、ここ！」. Summe unverändert 44 + 6 = 50;
neue Bilanz: あめ 5 · かさ, はい 4 · さむい, ほんとう, ここ, だいじょうぶ, どうぞ, こわれた,
すみません 3 · alle übrigen 2. Maßgeblich: `docs/story/DREHBUCH_FOLGE_01_V3.md`, geprüft
von `folge_01_dichte_test.dart` (auch die Floskel-Liste).

Vorher: 55 gehört + 2 Ziele = 57. Der Rückgang ist der Preis der Regel; er wird in
späteren Folgen aufgeholt, weil Mira dann Gelerntes sagen darf. Die Dichte-Prüfung
(`folge_01_dichte_test.dart`) bekommt die neuen Schwellen: gehörte Tokens ≥ 44,
gesamt ≥ 50, jedes Wort ≥ 2. Die Format-Regel „Sprachdichte“ im Drehbuch wird
entsprechend neu gefasst: *gezählt werden gehörte Vorkommen plus Sprech- und
Stumm-Ziele; Mira zählt erst, wenn sie sprechen darf.*

Das Drehbuch V3 wird als `docs/story/DREHBUCH_FOLGE_01_V3.md` geführt (V2 bleibt als
Protokoll). Die Bilder werden **nicht** neu gerendert; nur das Lettering ändert sich:
P3, P4, P5, P6, P7, P8, P10 beide Formate (P5 bekommt eine Blase mehr, P7 und P8 je
eine weniger; Gesichts- und Nogo-Prüfung des Lettering-Skripts gelten).

## 5. Café: „Erzähl mal“

### 5.1 Ablauf

Akt 1 (die Wirtin erklärt) bleibt unverändert. **Akt 2 beginnt neu mit den stummen
Momenten**, immer bei der Wirtin, denn Mira erzählt ihr den Tag:

1. Eröffnung der Wirtin (rotierend, mindestens drei): *„Erzähl mal. Wie war dein
   Tag?“* / *„Setz dich. Und dann erzähl von draußen.“* / *„Ich hab dich vor der Tür
   stehen sehen. Erzähl von vorher.“*
2. Je stummer Moment in Panel-Reihenfolge ein **Szenen-Turn** (§5.2).
3. Übergabe an die übrigen Wörter (*„Und jetzt der Rest.“*, rotierend), dann die
   bestehenden Blöcke mit rotierenden Stimmen (Café-Szenen-Spec §3.1).

**Jedes Wort wird pro Nachbesprechung einmal gefragt.** Die vier Stumm-Wörter kommen
in ihrer Szene und fehlen in den normalen Blöcken. Folge 01: 4 Szenen-Turns + 14
normale Turns (statt 18 normale). Hat eine Folge keine stummen Momente, entfällt der
Block samt Eröffnung.

### 5.2 Der Szenen-Turn

- **Bild:** das Folgen-Panel bildschirmfüllend, im Format der Handylage (wie der
  Reader: `assetFor(format)`, `coverRect`, `mapToScreen` aus `panel_geometry.dart`),
  mit der „…“-Blase.
- **Fläche** (§6.3): die Wirtin-Frage (`promptText` des Moments), darunter **vier
  Wörter** der Folge in Kana zur Wahl: das Ziel und drei andere Budget-Wörter derselben
  Folge, deterministisch nach Turn-Index gewählt (kein Zufall, testbar), nie zweimal
  dieselbe Vierergruppe in einer Nachbesprechung.
- **Richtig:** das Wort erscheint in der „…“-Blase (die App zeichnet den Text in das
  Rechteck der Blase, Schrift wie das Lettering, Furigana nicht nötig, es sind Kana),
  das Wort wird vorgelesen (TTS wie beim Blasen-Tipp), die Wirtin reagiert (rotierend,
  mindestens drei: *„Genau. Das hätte gereicht.“*, *„Siehst du. Du hattest es schon.“*,
  *„Ja. Beim nächsten Mal sagst du es.“*). Bewertung wie ein normaler Akt-2-Turn
  (`LadderReview.submit`, `CafeOutcome.correct`).
- **Falsch:** die Wirtin nennt das richtige Wort (*„Nicht ganz. いくら. Das hätte
  gepasst.“*), es erscheint trotzdem in der Blase und wird vorgelesen; Bewertung
  `incorrect` → `hard`, wie heute.
- **„Erklär's mir nochmal“** steht wie in jedem Turn bereit und zählt als Hinweis
  (`hinted` → `hard`).
- **Übungsform und Sprosse:** Der Szenen-Turn ist eine Auswahl-Form und damit nur auf
  Sprosse 0–2 erlaubt (I1: keine Auswahl auf Produktions-Sprossen). Nach Akt 1 stehen
  alle Items auf Sprosse 1; sollte ein Stumm-Wort ausnahmsweise höher stehen (das Wort
  war schon aus einer Lektion bekannt), wird es normal gefragt, nicht in der Szene.
- **Kein Sprechen:** Der Szenen-Turn ist eine Wahl, kein Sprechmoment. Sprechen bleibt
  der Folge vorbehalten (Sprechmomente) und der Gleichaltrigen (Sprosse 5).

### 5.3 Datenmodell und Nahtstellen (`lib/features/cafe/`)

| Stelle | Änderung |
|---|---|
| `cafe_debrief.dart` | `silentMomentsFor(episode)` → Liste aus (Panel, Interaktion, „…“-Blase), nur für Items, die im Karteikasten liegen (INV-8/INV-11 wie `debriefItemsFor`). |
| `CafeDebriefScreen._finishExplain` | Turn-Liste = Szenen-Turns (Sprecher Wirtin) + `initialQueue(rest)`; `rest` = Manifest ohne die Stumm-Wörter. Der Sprecherplan (`speakerPlan`) gilt für `rest`. |
| `cafe_turn.dart` | `CafeExerciseKind.sceneChoice` (neu); `CafeTurnContent.forSilentMoment(...)` mit Ziel, drei Ablenkern, Frage, Panel, Blasenrechteck je Format. |
| `cafe_turn_screen.dart` | Für `sceneChoice`: Panel statt Café-Szene, Fläche mit Frage und vier Chips, Blasen-Füllung nach Antwort. Reaktionen aus dem Wirtin-Skript (`CafeGuestScript`, neue Zeilen für richtig/falsch im Szenen-Turn). |
| `cafe_guest_script.dart` / `cafe_prompts.dart` | Eröffnungen (3), Übergabe „Rest“ (3), Szenen-Reaktionen richtig/falsch (je 3). Steckbrief der Wirtin gilt (warm, kurz, wiederholt das Wort einmal). |
| Episode | keine neuen Felder: die Momente kommen aus `panel.interactions` (§4.2). |

Der normale Besuch bleibt unverändert. (Später denkbar: Szenen-Turns auch im normalen
Besuch für Sprosse-1/2-Wörter mit Szene. Nicht Teil dieser Spec.)

## 6. Café im Manga-Muster (Weg A)

### 6.1 Bilder: derselbe Weg wie die Folge

Die Bibliothek aus der Café-Szenen-Spec §3.2 bleibt in Struktur und Umfang (6 Motive
× 4 Lichter + 7 Momente × 2 Lichter = **38 Motive**), aber jedes Motiv geht den Weg der
Panels:

1. **Foto** (Look A, feste Figurenbeschreibungen, LoRA 0,3, Anti-Anime-Negativ) in
   **1664 × 928**, zwei Seeds, Uli pickt. Die fünf alten Café-Bilder (1216 × 832) und
   die Umleuchten-Ergebnisse aus PR #54 werden nicht weiterverwendet; sie haben das
   falsche Format und den falschen Look.
2. **Manga-Durchgang** mit Tiefe (`manga_graph`, Rezept Manga-Vollbild §2.2, Standard
   D70 wie bei den Panels).
3. **Hochbild aus dem Kern** (Manga-Vollbild §12): je Motiv ein `kern` in einer
   Layout-Datei `tool/comic/cafe_layout.json`. Kern = die Figur mit ihrem Tisch oder
   Tresen; der leere Raum bekommt den Tresen als Kern. Bei einer Figur im Raum reicht
   fast immer der Beschnitt; Verlängern bleibt der Ausweich. `check_kern.py` prüft.
4. **Auslieferung** quer 1920 × 1072 und hoch 1080 × 1936, JPEG q88, unter
   `assets/comic/cafe/{motiv}_{licht}.jpg` und `{motiv}_{licht}_hoch.jpg`. 76 Dateien,
   grob 28 MB. Für die Serie wird das später Teil des Download-Pakets (nicht hier).

**Licht:** Die Café-Szenen-Spec wollte Umleuchten des fertigen Tag-Bildes. Im neuen Weg
gibt es zwei Wege: (R) Umleuchten des **Fotos**, danach der Manga-Durchgang je Licht,
der den Look vereinheitlicht; (T) Text-zu-Bild je Licht mit Lichtwörtern. **Gate:** zwei
Motive (`leer`, `wirtin_tresen`) in vier Lichtern auf beiden Wegen, ein Bogen, Uli
wählt. Dann **Runde 1 = alle 13 Motive in Tag** (das reicht für Plan 4 und den
Gerätetest), **Runde 2 = die 25 übrigen Lichter**.

**Mira bleibt hinter der Kamera** (unverändert). Keine Nahaufnahmen, keine
Mehr-Figuren-Szenen (Café-Szenen-Spec §7).

**Skripte** (`tool/comic/`): `cafe_motifs.py` bekommt Prompts im Panel-Format und die
Hoch-Umgebungssätze; `cafe_library.py` wird auf Foto → `manga_graph` → Hochbild
umgestellt und nutzt dafür die aus `folge01_hoch.py`/`kern_geometry.py`
verallgemeinerte Hoch-Ableitung (eine Funktion, zwei Aufrufer, keine Kopie);
`cafe_assemble.py` liefert beide Formate; Bögen wie gehabt. README-Abschnitt „Café“.

### 6.2 Szenen-Bibliothek in der App (`cafe_scenes.dart`)

- `sceneAsset(motif, light, format)` liefert den Pfad des gewünschten Formats; die
  Tabelle im Code (`cafeSceneLibrary`) führt je Motiv und Licht, **welche Formate**
  vorliegen. Rückfallkette wie heute (Licht → Stammplatz → Tag → neutrale Fläche),
  davor: fehlt das Hochbild, wird das Querbild **eingepasst** (Letterbox), nie
  verzerrt (dieselbe Regel wie im Reader, Manga-Vollbild §7.1).
- Struktureller Test: jede Tabellenzeile hat ihre Dateien, jede Datei ihre Zeile,
  beide Formate.
- Während des Übergangs (Runde 1 noch nicht da) zeigt das Café die alten 16:10-Bilder
  eingepasst; nichts stürzt ab.

### 6.3 Bildschirme: Vollbild, zwei Lagen, Flächen über dem Bild

Das Café übernimmt das Reader-Muster (Manga-Vollbild §7.1/§7.2). Die alte Festlegung
„keine Vollbild-Änderung an Café“ (Manga-Vollbild §9) ist damit aufgehoben.

- **Vollbild:** `ReaderSystemUi.enterImmersive()` beim Betreten des Cafés,
  `exitImmersive()` beim Verlassen (derselbe injizierbare Adapter wie im Reader; der
  Übergang Endkarte → Café bleibt im Vollbild, keine Statusleiste blitzt auf). Beide
  Handylagen erlaubt, `OrientationBuilder` wählt das Format.
- **Fläche** (ein Widget `CafeOverlay` für alle Café-Bildschirme): halbdurchsichtige
  dunkle Fläche mit weißer Schrift wie der Gedankenkasten des Readers. **Hochformat:**
  unten, höchstens die untere Hälfte des Schirms. **Querformat:** rechts, ein Drittel
  der Breite, volle Höhe. Die Kerne der Café-Motive werden so gesetzt, dass die Figur
  links bzw. in der oberen Bildhälfte steht und unter der Fläche sichtbar bleibt.
- **Tastatur** (Lesen- und Schreiben-Turns): `resizeToAvoidBottomInset: false`, die
  Fläche bekommt `viewInsets.bottom` als Abstand und scrollt innen; das Bild dahinter
  bleibt stehen.
- **Zurück:** halbtransparenter Chip oben links wie im Reader; keine AppBar mehr. Der
  Name des Sprechers steht in der Fläche, nicht in einer Leiste.

| Bildschirm | Hinter der Fläche | In der Fläche |
|---|---|---|
| **Café-Raum** (`CafeScreen`) | `leer` im Licht der Stunde, Vollbild | Wer da ist: eine Reihe Stammplatz-Miniaturen (quer, 16:9, mit Namen), Tipp öffnet den Turn; Einladung der Wirtin bei offener Nachbesprechung; Leerzustand wie heute (Wirtin wischt den Tresen: dann `wirtin_tresen` als Bild, Fläche nur mit dem Satz) |
| **Erklärungskarte** (Akt 1, `CafeDebriefScreen`) | `wirtin_tisch` im Licht der Stunde, Vollbild | die Karte (`DebriefCardView`) scrollbar, mit Panel-Miniatur, Gebrauch, Varianten, „Weiter“; das Band entfällt, das Bild ist jetzt der Hintergrund |
| **Frage-Bildschirm** (Akt 2 und normaler Besuch, `CafeTurnScreen`) | Szene des Sprechers (`turnScene`), ein Bild pro Block wie heute | Sprecher-Name, Stimm-Zeile, das Wort groß, Antwortfeld oder Auswahl, Hinweis-Knöpfe, Reaktion |
| **Szenen-Turn** (§5.2) | das Folgen-Panel | Wirtin-Frage, vier Chips, Reaktion |

Dictionary-Sheet und Erklärungskarte als Sheet (aus „Erklär's mir nochmal“) bleiben
Sheets über dem Vollbild, wie das Wörterbuch im Reader.

## 7. Content Folge 01 (Ulis Anteil, Claude entwirft)

- Drehbuch V3 (§4.3) als Datei und als Daten in `folge_01_regen.dart`.
- Vier Wirtin-Fragen (§4.1), drei Eröffnungen, drei Übergaben, je drei Reaktionen
  richtig/falsch im Szenen-Turn (§5.1/§5.2) — gegenlesen am Steckbrief der Wirtin.
- Layout-Datei: sieben Panels neu gesetzt (Blasentexte, „…“-Blasen, P5 eine Blase mehr),
  Lettering-Bogen zur Sicht.
- Café-Bilder: Gate-Bogen (2 Motive × 4 Lichter × 2 Wege), Picks Runde 1 (13 Motive ×
  2 Seeds), Picks Runde 2.

## 8. Regeln

| Regel | Stand |
|---|---|
| **INV-18** Mira spricht nur, was sie schon kann | neu, §3.1, Validator |
| **INV-19** Mira spricht nur nach, was sie gehört hat | neu, §3.1, Validator |
| **INV-4** jedes Wort ≥ 2 | unverändert; stumme Ziele zählen wie Sprechziele |
| **INV-6** Produktion nicht im Story-Modus | gewahrt: der stumme Moment hat im Reader keine Aufgabe |
| **INV-8 / INV-11** Café führt nichts ein, Quelle = Manifest ∩ Karteikasten | gewahrt: Szenen-Turns nur für Items im Karteikasten; Ablenker ebenfalls nur Budget-Wörter der Folge |
| **INV-9** Bedeutung nur für Eingeführtes | gewahrt |
| **INV-10** kein Café-Fortschritt | gewahrt: die Blasen-Füllung ist Anzeige im Turn, wird nicht gespeichert, nichts wird freigeschaltet |
| **I1** keine Auswahl auf Produktions-Sprossen | gewahrt: Szenen-Turn nur Sprosse ≤ 2 |
| **„Eine Stimme ändert nie die Übungsform“** | gewahrt: Szenen-Turns sind immer die Wirtin, die Form hängt am Moment, nicht an der Stimme |
| **INV-14 / INV-15 / INV-16** (eine Quelle, kein Beschnitt von Text, kein Meta-Text im Bild) | gelten für die „…“-Blase und für die Café-Bilder (dort gibt es keinen eingebrannten Text) |
| **INV-17** hoch und quer zeigen dieselbe Szene | gilt auch für Café-Bilder (`check_kern.py`) |
| Manga-Vollbild §9 „kein Umbau der Café-Bilder, keine Vollbild-Änderung an Café“ | **aufgehoben** durch Ulis Entscheidung vom 2.10. |

## 9. Bewusst NICHT

- **Kein neues Wort für Folge 01.** Budget bleibt 18 Wörter + 5 Zeichen.
- **Kein Neu-Rendern der Panels.** Nur Lettering.
- **Kein Sprechen im Szenen-Turn.** Wahl, keine Spracherkennung.
- **Keine Änderung an Akt 1** außer dem Bild dahinter.
- **Keine Änderung am normalen Besuch** außer Vollbild und Flächen.
- **Keine Mira in Café-Bildern,** keine Nahaufnahmen, keine Gruppenbilder.
- **Keine gespeicherte Blasen-Füllung.** Beim nächsten Lesen ist die Blase wieder „…“;
  Mira spricht das Wort erst in einer späteren Folge (INV-18).
- **Keine Zähler, Häkchen, Prozente.**
- **Kein Download-Paket;** Folge 01 und das Café werden gebündelt.

## 10. Risiken

| Risiko | Umgang |
|---|---|
| „…“-Blasen wirken wie fehlender Inhalt | Der deutsche Gedanke trägt den Moment; die Blase ist klein und sitzt an Miras Position; im Café wird sie gefüllt — der Lerner erlebt die Auflösung. |
| Dichte sinkt von 57 auf 50 | Nebenfiguren wiederholen im Haus-Stil; Schwellen angepasst; ab Folge 02 steigt die Dichte mit Miras Wortschatz. |
| Vier Chips verraten die Antwort zu leicht | Ablenker aus derselben Folge, deterministisch; es ist Sprosse 1, Erkennen ist die richtige Stufe direkt nach der Erklärung. |
| Manga-Durchgang verändert Gesichter der Café-Figuren (Identitätsdrift, schon in #54 ein Risiko) | Gate mit zwei Motiven, feste Figurenbeschreibungen, Tiefe als Zügel, Seeds; Weitszene bleibt die Disziplin. |
| Fläche verdeckt die Figur | Kern je Motiv so gesetzt, dass die Figur frei bleibt; quer rechts, hoch unten; Gerätetest. |
| Übergang: alte 16:10-Bilder im Vollbild | Letterbox statt Beschnitt, kein Absturz; Runde 1 (Tag) kommt vor dem Gerätetest. |
| Zusammengeführte Stapel sind auf dem S23 ungetestet (Plan H, #57) | Vollsuite auf der GPU-Box vor dem Merge; S23-Test ist Teil der Abnahme von Plan 1. |

## 11. Stapel und Voraussetzungen

Am 2.10. wurden die Stapel zusammengeführt: `impl/manga-vollbild-app` (PR #56) enthält
jetzt `impl/cafe-bilder` (PR #54) mit drei gelösten Konflikten (`episode.dart`: beide
Feldsätze; `pubspec.yaml`: beide Asset-Ordner; `tool/comic/comfy_client.py`:
Manga-Fassung als Obermenge); `fix/blase-woerterbuch` (PR #57) enthält alles.
Merge-Reihenfolge nach main: Doku #27, #43, #47, #49, #52; Reader #44, #45, #48; Café
#50, #53, #54; Manga #51, #55, #56, #57. Geschlossen als überholt: #1, #42, #46. Offen
bleibt #26 (Geführter Weg), das braucht eine eigene Entscheidung.

Diese Spec und ihre Pläne setzen auf dem zusammengeführten `main` auf.

## 12. Reihenfolge: vier Pläne

| Plan | Inhalt | Voraussetzung |
|---|---|---|
| **1 „Mira schweigt“** | INV-18/19 im Validator, `InteractionType.silent`, Drehbuch V3 (Datei + Daten), Layout-Datei und Lettering der sieben Panels, Reader (inerte „…“-Blase), Dichte-Schwellen, Layout-Konsistenztest. Abnahme: Vollsuite, Emulator-Sicht, S23. | zusammengeführtes main |
| **2 „Erzähl mal“** | Szenen-Turn, Eröffnung und Übergabe, Wirtin-Zeilen, Turn-Liste in `CafeDebriefScreen`, Blasen-Füllung, Tests. Abnahme: S23 — Folge lesen, ins Café, vier Szenen, Wort in der Blase. | Plan 1 |
| **3 „Café-Bilder im Manga-Weg“** | Skripte, Gate R/T, Runde 1 Tag (13), Runde 2 Lichter (25), beide Formate, Bibliothekstabelle, struktureller Test. Abnahme: Ulis Picks, `check_kern.py` grün. | zusammengeführtes main; GPU-Box |
| **4 „Café im Vollbild“** | `CafeOverlay`, Vollbild-Adapter im Café, drei Bildschirme umgebaut, Format-Wahl, Letterbox-Rückfall, Tastatur, Tests. Abnahme: S23 in beiden Lagen. | Plan 3 Runde 1 (Tag) für die Sicht; der Code kann vorher mit Letterbox laufen |

Plan 1 und Plan 3 können sofort und parallel starten. Plan 2 folgt auf Plan 1, Plan 4
kann parallel zu Plan 3 beginnen und wird mit dessen Runde 1 abgenommen. Jeder Plan
lässt die App lauffähig.

## 13. Tests und Abnahme

Strukturell und deterministisch, im Stil der bestehenden Tests:

- **Validator:** Protagonist-Blase mit Token einer Folge ≥ eigenem Index → Verstoß;
  Kana außerhalb der Tokens → Verstoß; Sprechziel ohne vorheriges Hören → Verstoß;
  `silent` ohne „…“-Blase, mit zwei „…“-Blasen, mit Ziel außerhalb des Budgets, mit
  Ziel, das nirgends gehört wird → je ein Verstoß. Folge 01 V3 besteht alles.
- **Dichte:** neue Schwellen (44 / 50 / je ≥ 2) grün; die Bilanz aus §4.3 stimmt Wort
  für Wort.
- **Layout:** Konsistenztest Layout-Datei ↔ `folge_01_layout.g.dart` deckt die
  „…“-Blasen ab; Lettering-Prüfungen (Gesichter, Nogo, sichere Zone) grün für sieben
  neu gesetzte Panels in beiden Formaten.
- **Reader:** „…“-Blase ist nicht tippbar, nicht im Fallback-Fuß, löst nichts aus.
- **Café „Erzähl mal“:** Turn-Liste beginnt mit den Szenen-Turns in Panel-Reihenfolge,
  Stumm-Wörter fehlen im Rest; vier Chips, Ziel enthalten, Ablenker aus dem Budget,
  deterministisch, keine Wiederholung der Vierergruppe; richtig → Wort in der Blase +
  `correct`; falsch → Wort in der Blase + `hard`; Hinweis → `hard`; ohne stumme Momente
  kein Block; Stumm-Wort auf Sprosse ≥ 3 → normaler Turn.
- **Szenen-Bibliothek:** Tabelle ↔ Dateien in beiden Formaten; `sceneAsset` je Format;
  fehlendes Hochbild → Querbild eingepasst.
- **Vollbild:** Adapter beim Betreten/Verlassen des Cafés, Übergang Reader → Café ohne
  `exit`/`enter`-Paar dazwischen; Fläche unten im Hochformat, rechts im Querformat;
  Tastatur verschiebt nur die Fläche.
- **Unverändert grün:** alle Café-Tests (INV-9, Belegung, Sprecherplan, Stimmen), alle
  Reader-Tests, die Comic-Werkzeugtests (`tool/comic/test_*.py`).

**Abnahme:** Ulis Gerätetest auf dem S23, pro Plan wie in §12. Messlatte am Ende:
Er liest Folge 01, Mira sagt kein Wort Japanisch, an vier Stellen steht „…“; im Café
fragt die Wirtin nach genau diesen vier Stellen, und das gewählte Wort steht in Miras
Blase; das Café ist Vollbild in beiden Lagen, die Bilder sehen aus wie die Folge, und
keine Fläche verdeckt eine Figur.
