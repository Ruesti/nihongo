# Design: Café-Szenen und Stimmen — das Café sieht aus wie ein Ort und klingt wie mehrere Menschen

**Datum:** 2026-09-18
**Status:** Entwurf — wartet auf Ulis Review. Drei Entscheidungen sind offen (§3); die
Spec ist mit Claudes Empfehlung als Annahme geschrieben und ändert sich an genau
diesen drei Stellen, falls Uli anders entscheidet.
**Anlass:** Ulis Gerätetest der Nachbesprechung (PR #48) auf dem S23, 18.9.: *„Im
groben Prinzip ist es gut. Was fehlt, sind die Café-Szenen und Bilder. Beim Fragen ein
bisschen mehr Abwechslung zwischen Wirtin, Gleichaltrige, Schulmädchen, Vielredner.
Wäre schön, wenn es auch eine reichhaltige Bibliothek an Bildern gäbe, damit
Abwechslung optisch."*

**Baut auf:** der Café-Nachbesprechungs-Spec (`2026-09-15-cafe-nachbesprechung-design.md`,
PR #47, umgesetzt in PR #48), dem Story-Brief (§4 Café, §6 Nicht-bauen — liegt auf
dem Branch `docs/story-engine-phase0`, PR #27), dem Stil-Arbeitsdokument
(`comic/docs/VISUAL_STYLE.md`, unversioniert) und den fünf fertigen Café-Bildern aus
PR #46.

---

## 1. Befund: was auf dem S23 fehlte, und warum

Drei getrennte Ursachen, die im Test wie ein Mangel wirkten:

1. **Die Bilder gibt es, aber nicht auf diesem Branch.** Die fünf Café-Bilder (leeres
   Café, Wirtin am Tresen, Schulkind in der Nische, Vielredner mit Zeitung,
   Gleichaltrige mit Kaffee) liegen mit ihrer Verdrahtung auf PR #46
   (`comic/folge01-panels`, gestapelt auf #44). PR #48 ist auf #45 gestapelt und
   enthält #46 nicht. Der Café-Raum in #48 ist darum eine nackte Textliste, und die
   Nachbesprechung (beide Akte) hat bis auf die Panel-Miniatur der Erklärungskarte kein
   einziges Bild. Das ist ein Stapel-Artefakt, kein Design-Fehler — und es wird in
   jedem Fall behoben, egal wie Uli in §3 entscheidet.
2. **Nur die Wirtin fragt, und das ist heute Regel, nicht Zufall.** Der Story-Brief
   legt fest: *Gäste sind Sprossen.* Die Sprosse ist die Schwierigkeitsstufe eines
   Wortes (1 bis 5). Die Wirtin bedient Sprosse 1–2, das Schulkind 3, der Vielredner 4,
   die Gleichaltrige 5. Nach einer Folge stehen alle Wörter auf Sprosse 1 — also fragt
   in der Nachbesprechung ausschließlich die Wirtin, und im normalen Besuch wochenlang
   ebenso, bis die ersten Wörter auf Sprosse 3 geklettert sind. Im Code:
   `guestForRung` in `cafe_occupancy.dart`, ohne jeden Zufall.
3. **Die Texte sind dünn.** Insgesamt 13 Textvorlagen (Fragen, Einladung, Zwischen-
   und Schlusszeilen) und 31 Reaktionszeilen. Wirtin und Schulkind haben gar keine
   Frage-Vorlage: Über einer Erkennen-Frage steht nur das nackte Wort
   (`cafe_turn_screen.dart`, `headerText`). Selbst mit vier Stimmen wäre die
   Abwechslung schnell erschöpft.

Was es an Bildmaterial schon gibt (im Render-Ordner `comic/assets/style/`,
unversioniert, nicht in der App): den Café-Anker A7 in vier Lichtstimmungen (Tag,
Regen, Abend, Nacht — aus der Manga-Phase, nicht im aktuellen Look), freigestellte
Gästefiguren, integrierte Einzelgast-Szenen. Der **aktuelle Look ist „Look A,
fotorealistisch"** (Ulis Entscheidung 12.9.): Text-zu-Bild mit dem Qwen-Image-Modell,
Stil-LoRA `shotengai_style` auf 0,3, Foto-Zusatz im Prompt und Anti-Anime-Negativ,
Figuren ohne Referenzbild über **feste Beschreibungen** im Prompt konsistent gehalten.
Die fünf Café-Bilder aus #46 sind in diesem Look gerendert und abgenommen — sie sind der
Grundstock der Bibliothek.

## 2. Zielbild

**Das Café sieht aus wie ein Ort und klingt wie mehrere Menschen.**

- **Ein Ort:** derselbe Raum, aus Blickwinkeln, die man kennt, im Licht der Stunde.
  Das Stil-Dokument sagt es so: *„Vertrautheit entsteht nicht aus Abwechslung. Der
  Leser muss dieselbe Ecke zum zehnten Mal sehen und beim zehnten Mal etwas Neues
  bemerken."* Abwechslung kommt also nicht aus neuen Räumen, sondern aus Licht (Tag,
  Regen, Abend, Nacht), Belegung (wer da ist) und kleinen Momenten (die Wirtin schenkt
  Tee ein, das Schulkind macht Hausaufgaben, der Vielredner hat die Zeitung
  zusammengefaltet).
- **Mehrere Menschen:** Wer fragt, hat eine Stimme, ein Bild und ein Repertoire. Die
  Wirtin bleibt die Gastgeberin der Nachbesprechung; die drei anderen reden mit.

Was sich **nicht** ändert: Das Café führt nichts ein, zählt nichts, schaltet nichts
frei (INV-8, INV-10). Die Stimmen sind Ton, keine Mechanik. Die Bilder sind Stimmung,
kein Fortschritt.

## 3. Drei Entscheidungen (Ulis) — mit Claudes Annahme

### 3.1 Wer fragt? — Annahme: **Stimme rotiert, Schwierigkeit bleibt** (A)

Das Problem: Die Regel „Gäste sind Sprossen" hat einen Sinn — *„SM-2 wählt die Items,
die Figur wählt die Sprosse. Der Lerner sucht sich einen Gesprächspartner aus, und
diese Wahl ist die Schwierigkeitswahl."* Diese Wahl gibt es aber nur im normalen
Besuch. In der Nachbesprechung wählt niemand: Die Wirtin lädt ein, die Wörter stehen
fest. Dort kann die Regel also gelockert werden, ohne dass der Lerner etwas verliert.

| | A — Stimme rotiert, Schwierigkeit bleibt *(empfohlen)* | B — Stimme rotiert überall | C — Nur die Wirtin fragt, andere sind Kulisse |
|---|---|---|---|
| **Nachbesprechung** | Die Wirtin eröffnet und schließt. Dazwischen fragen Schulkind, Vielredner und Gleichaltrige blockweise mit, jeder in seinem Ton. Die **Übungsform** bleibt die der Sprosse (Erkennen, Lesen) — nur die Stimme wechselt. | wie A | Die Wirtin fragt alles. Die anderen sitzen im Bild und werfen zwischen den Fragen Kommentare ein. |
| **Normaler Besuch** | **unverändert:** Gast = Sprosse, der Lerner wählt den Gast und damit die Schwierigkeit. | Es fragt, wer da ist. Die Schwierigkeit kommt still aus der Sprosse; die Wahl des Gastes bedeutet nichts mehr. | unverändert |
| **Was es kostet** | Die Brief-Regel bekommt eine Ausnahme (die Nachbesprechung), sauber benannt. Die Anwesenheit der drei anderen in der Nachbesprechung ist keine Fälligkeitsanzeige mehr (Brief §4.3) — dort sind sie Stammgäste am Abend nach der Folge. | Brief §4.2 wird gestrichen. Wenn Wörter später auf Sprosse 3–5 klettern, ist nicht mehr sichtbar, *warum* das Schulkind plötzlich schwerer fragt. | Kaum Abwechslung beim Fragen; Ulis Wunsch nur halb erfüllt. Die Einwürfe brauchen trotzdem das ganze Text-Repertoire. |

**Warum A:** Es erfüllt Ulis Wunsch dort, wo er ihn gespürt hat (die Nachbesprechung),
hält die Mechanik dort, wo sie etwas bedeutet (der Besuch mit Wahl), und ist
rückbaubar: Wer später doch B will, streicht den Filter im normalen Besuch — die
Stimmen und Bilder sind dieselben.

**So läuft es unter A (Akt 2 der Nachbesprechung):**
- Die Wörter der Folge werden in **Blöcke von drei** geteilt. Den ersten Block hat die
  Wirtin, ab drei Blöcken auch den letzten; dazwischen wechselt die Stimme im Kreis
  Schulkind → Vielredner → Gleichaltrige → Schulkind → … Danach kommt die Schlusszeile
  der Wirtin wie heute. Folge 01 (18 Wörter) ergibt sechs Blöcke: Wirtin, Schulkind,
  Vielredner, Gleichaltrige, Schulkind, Wirtin.
- Die **Reihenfolge der drei anderen rotiert pro Sitzung** (wie heute die Schlusszeile:
  nach Minute, nicht nach Anzahl), damit zwei Nachbesprechungen nicht gleich klingen.
- Jeder Blockwechsel hat eine **Übergabe-Zeile**: Die Wirtin gibt ab (*„Frag du
  mal."*), der neue Sprecher steigt ein (Schulkind: *„Darf ich auch mal? Also —"*,
  Vielredner: *„Ach, wo wir gerade dabei sind …"*, Gleichaltrige: *„Ich hab da auch
  noch was."*). Mindestens zwei Einstiegszeilen pro Gast, rotierend.
- **Die Übungsform folgt weiter der Sprosse.** Ein Sprosse-1-Wort ist Erkennen (Wort
  sehen, Bedeutung antippen), egal wer fragt. Das Schulkind fragt auf Sprosse 1 also
  *„Was heißt das? Schnell!"* — nicht *„Schreib das!"*. Das ist der Unterschied zwischen
  Stimme und Sprosse, und er hält I1 (kein Auswahl-Abfragen auf Produktions-Sprossen)
  automatisch ein, weil `kindForRung` unverändert bleibt.
- Die **Reaktionen** (richtig, falsch, Hinweis) kommen vom Sprecher des Blocks, aus dem
  vorhandenen `CafeGuestScript`. Die Gleichaltrige braucht dafür neue Zeilen — sie hat
  heute nur Reaktionen für freies Sprechen (Sprosse 5).
- **Bei weniger als sechs Wörtern** (nur ein Block) fragt nur die Wirtin. Zwei Blöcke
  ergeben Wirtin und eine zweite Stimme; erst ab drei Blöcken rahmt die Wirtin.

**Trifft der Lerner die Wirtin im normalen Besuch** (Sprosse 1–2 fällig), bleibt alles
wie heute — nur mit Bild und mit Frage-Vorlagen statt nacktem Wort (§4).

### 3.2 Wie groß wird die Bildbibliothek? — Annahme: **Mittel, 38 Bilder**

| | Klein — die fünf vorhandenen | Mittel — 38 Bilder *(empfohlen)* | Groß — rund 70 Bilder |
|---|---|---|---|
| **Inhalt** | leer + je Gast ein Bild, nur Tag | Raum und Stammplätze in **vier Lichtern**, dazu **zwei Momente je Gast** in zwei Lichtern, dazu die Wirtin am Tisch für Akt 1 | wie Mittel, zusätzlich **Reaktionsbilder** je Gast und Ergebnis (richtig, falsch, Hinweis) |
| **Was der Lerner erlebt** | immer dasselbe Bild pro Gast | das Café im Licht der Stunde; pro Nachbesprechung mindestens sechs verschiedene Bilder; derselbe Gast in verschiedenen Momenten | nach jeder Antwort ein passendes Gesicht |
| **Kosten** | keine neuen Renders, nur Verdrahtung | ~33 neue Renders, mit Seed-Auswahl ~80 Roh-Bilder, ~2 h GPU + Kuratieren; ~4 MB im Bundle | ~65 neue Renders; Gesichter in Nahaufnahme sind die härteste Disziplin für Identität ohne Referenzbild — hohes Drift-Risiko, doppelte Kuratierung |

**Warum Mittel:** Es liefert genau die Abwechslung, die das Stil-Dokument meint (Licht,
Belegung, Momente im selben Raum), bleibt in der bewiesenen Disziplin (Weitszene,
Figur klein im Raum) und ist eine Sitzung Rendern. Groß bringt Nahaufnahmen, die im
Look A ohne Referenzbild am ehesten aus der Rolle fallen (§8) — das lohnt erst, wenn
Mittel steht und Uli die Reaktionen vermisst.

**Die Bibliothek unter Mittel** (Motiv × Licht; ✓ = existiert schon aus PR #46):

| Motiv | Beschreibung | Tag | Regen | Abend | Nacht |
|---|---|---|---|---|---|
| `leer` | Raum ohne Gäste, Tresen und Nischen im Blick | ✓ | ○ | ○ | ○ |
| `wirtin_tresen` | Wirtin wischt den Tresen (Stammplatz) | ✓ | ○ | ○ | ○ |
| `wirtin_tisch` | Wirtin sitzt dem Betrachter gegenüber am Tisch, Teekanne — **das Bild der Erklärungskarte**, in Akt 2 zugleich ihr zweiter Moment | ○ | ○ | ○ | ○ |
| `wirtin_tee` | Wirtin schenkt am Tresen Tee ein | ○ | | ○ | |
| `schulkind_nische` | Schulkind in der Nische rechts (Stammplatz) | ✓ | ○ | ○ | ○ |
| `schulkind_hausaufgaben` | Schulkind über einem Heft, Stift in der Hand | ○ | | ○ | |
| `schulkind_kakao` | Schulkind mit Kakaotasse, Blick zum Betrachter | ○ | | ○ | |
| `vielredner_zeitung` | Vielredner liest die Zeitung (Stammplatz) | ✓ | ○ | ○ | ○ |
| `vielredner_gefaltet` | Zeitung zusammengefaltet, redet mit den Händen | ○ | | ○ | |
| `vielredner_fenster` | Vielredner mit Tasse, Blick aus dem Fenster | ○ | | ○ | |
| `gleichaltrige_kaffee` | Gleichaltrige mit Kaffee am Tisch (Stammplatz) | ✓ | ○ | ○ | ○ |
| `gleichaltrige_haende` | Tasse in beiden Händen, leichtes Lächeln | ○ | | ○ | |
| `gleichaltrige_fenster` | Gleichaltrige schaut aus dem Fenster | ○ | | ○ | |

Sechs Motive in vier Lichtern (24) plus sieben Momente in zwei Lichtern (14) = **38**,
davon 5 vorhanden, **33 neu**. Momente in Regen und Nacht gibt es bewusst nicht — die
Auswahl fällt dann auf den Stammplatz zurück (§5.3).

**Mira ist nicht im Bild.** Die Kamera ist ihr Blick: Der Lerner sitzt am Tisch, die
anderen schauen ihn an oder sind bei sich. So sind es auch die fünf vorhandenen Bilder.

### 3.3 Wo erscheinen die Szenen? — Annahme: **an allen drei Orten**

| Ort | Was zu sehen ist | Größe |
|---|---|---|
| **Café-Raum** (Belegungsansicht) | Kopfbild: `leer` im Licht der Stunde. Darunter je anwesendem Gast der Stammplatz als Miniatur (wie in PR #46, nur im passenden Licht). | Kopfbild 16:10, Miniaturen 96×64 |
| **Frage-Bildschirm** (Akt 2 und normaler Turn) | Über der Frage die Szene des Sprechers: Stammplatz oder Moment, **ein Bild pro Block** (nicht pro Frage — sonst wird es unruhig). Der Titel der Leiste trägt den Namen des Sprechers. | 16:10; klappt beim Tippen (Tastatur offen) auf ein schmales Band zusammen |
| **Erklärungskarte** (Akt 1) | Über der Wirtin-Zeile (*„Setz dich …"*) ein schmales Band `wirtin_tisch` im Licht der Stunde. Die Panel-Miniatur („Hier hast du es zum ersten Mal gehört") bleibt das Hauptbild der Karte — deshalb nur ein Band, nicht zwei Bilder gleicher Größe. | Band 16:6 (Beschnitt, `BoxFit.cover`) |

Kein Bild ist je Voraussetzung: Fehlt eine Datei, zeigt die App das Rückfall-Bild oder
eine neutrale Fläche, nie einen Absturz (CLAUDE.md §6, wie schon in PR #46 mit
`errorBuilder`).

## 4. Die Stimmen: Steckbriefe und Repertoire

Die vier Figuren sind im Brief mit je einer Zeile beschrieben. Für ein Repertoire
braucht jede einen Steckbrief, an dem sich jede neue Zeile messen lässt (Claude
entwirft, Uli liest gegen — wie beim Erklärungsblock der Nachbesprechungs-Spec):

| | Wirtin | Schulkind | Vielredner | Gleichaltrige |
|---|---|---|---|---|
| **Aus dem Brief** | geduldig, langsam, wiederholt gern | direkt, kein Keigo, korrigiert schonungslos | Monologe, Comprehensible Input | freie Produktion, kein richtig/falsch |
| **Anrede** | du, warm, nie belehrend | du, frech, von unten nach oben | du, als säße man schon Stunden zusammen | du, auf Augenhöhe |
| **Satzlänge** | kurz, mit Pausen | sehr kurz, oft ein Wort | lang, abschweifend, endet **immer** in der Frage | mittel, beiläufig |
| **Tic** | wiederholt das Wort einmal vor | „Schnell!", „Easy.", „Nee." | „Ach, weißt du …", „wo wir gerade dabei sind" | „Sag mal …", „Ich glaub …" |
| **Auf Sprosse 1 (Erkennen)** | *„Das hier. Was heißt das?"* | *„Was heißt das? Schnell!"* | *„… und da fällt mir ein: [Wort]. Was war das noch?"* | *„Sag mal, [Wort] — was hieß das gleich?"* |
| **Auf Sprosse 2 (Lesen)** | *„Wie liest man das? Lass dir Zeit."* | *„Lies mal vor. Ohne Stottern."* | *„… stand groß da: [Wort]. Wie spricht man das?"* | *„Wie sagt man das? Ich hab's neulich falsch gelesen."* |
| **Auf falsch** | *„Nicht ganz. Wir sehen es uns zusammen an."* (heute) | *„Nee. Falsch."* (heute) | *„Kein Ding, das war auch viel Gerede."* (heute) | *„Hm, nee — ich glaub, das war was anderes."* (neu) |

**Was neu geschrieben wird** (Zahlen sind Mindestwerte, wie der Brief sie fordert —
*mindestens drei, rotierend*):

| Textsorte | je Gast | Summe |
|---|---|---|
| Frage-Vorlagen Erkennen (Sprosse 0–1) | 3 | 12 |
| Frage-Vorlagen Lesen (Sprosse 2) | 3 | 12 |
| Frage-Vorlagen Schreiben (Sprosse 3, nur das Schulkind im normalen Besuch — heute steht dort die nackte Bedeutung) | 3 | 3 |
| Einstiegszeilen beim Blockwechsel | 2 (Wirtin: 3 Übergabe-Zeilen) | 9 |
| Reaktionen richtig/falsch/Hinweis für die Gleichaltrige | 3 × 3 | 9 |
| **neu insgesamt** | | **45** |

Die 31 vorhandenen Reaktionszeilen und die 6 Vorlagen für Vielredner-Monolog
(Sprosse 4) und Gleichaltrige-Eröffnung (Sprosse 5) bleiben. Die Vorlagen setzen das
Wort in Kana ein und nennen **nie** die Bedeutung (wie heute: Bedeutung erscheint nur
als Antwort oder Hinweis). Das gilt für alle vier Stimmen — auch der Vielredner
schwadroniert *um* das Wort herum, nicht *über* seine Bedeutung.

**Rotation:** wie heute nach Turn-Index (deterministisch, testbar), nicht zufällig.
Abnahme-Kriterium aus dem Brief: zehn Turns hintereinander ohne wörtliche Wiederholung
— gilt jetzt pro Stimme und Übungsform.

## 5. Datenmodell & Nahtstellen

### 5.1 Sprecherplan (`cafe_speaker_plan.dart`, neu)

Eine reine Funktion, keine Zustände:

```
speakerPlan(itemCount, {blockSize: 3, sessionOffset}) → List<CafeGuest>
```

- Index 0 … blockSize−1 → Wirtin; ab drei Blöcken auch der letzte Block; die Blöcke
  dazwischen im Zyklus Schulkind, Vielredner, Gleichaltrige (Startpunkt des Zyklus aus
  `sessionOffset`); bei genau zwei Blöcken Wirtin und eine zweite Stimme; ein einziger
  Block → nur Wirtin.
- Der normale Besuch benutzt `List.filled(n, guest)` — derselbe Bildschirm, ein
  Sprecher. So bleibt `CafeTurnScreen` **ein** Ablauf für beide Anlässe.

### 5.2 Turn-Bildschirm (`cafe_turn_screen.dart`)

| Heute | Neu |
|---|---|
| `guest` fest, `_script = scriptFor(widget.guest)` | `speakers: List<CafeGuest>` (Plan); `speaker = speakers[_index]`; Skript und Name je Turn vom Sprecher |
| Kopfzeile bei Erkennen/Lesen = nacktes `promptText` | `promptLine(speaker, kind, word, index)` aus `cafe_prompts.dart`; Monolog und Eröffnung (Sprosse 4/5) unverändert |
| kein Bild | Szene über der Kopfzeile: `CafeSceneLibrary.turnScene(speaker, light, blockIndex)` |
| Titel „Die Wirtin" | Titel = Name des aktuellen Sprechers |
| — | Beim Blockwechsel eine Übergabe- und eine Einstiegszeile (`handoverLine`, `entryLine`) vor der ersten Frage des Blocks |

Die Warteschlangen-Logik (Filter auf `guestForRung == guest` im normalen Besuch,
`initialQueue` in der Nachbesprechung, `LadderReview.submit`, `doneLine`) bleibt
unverändert. `CafeDebriefScreen._finishExplain` übergibt statt `guest: wirtin` den
Sprecherplan.

### 5.3 Szenen-Bibliothek (`cafe_scenes.dart`, neu)

```
enum CafeLight { tag, regen, abend, nacht }
CafeLight lightFor(DateTime now, {bool rain = false})
   // 06–17 Uhr Tag, 17–21 Abend, 21–06 Nacht; rain ersetzt nur Tag durch Regen
String  sceneAsset(CafeMotif motif, CafeLight light)   // mit Rückfallkette
String  turnScene(CafeGuest speaker, CafeLight light, int blockIndex)
   // Stammplatz, Moment 1, Moment 2 … rotierend nach Block
```

- **Rückfallkette:** gewünschtes Licht → Stammplatz desselben Gastes im gewünschten
  Licht → Stammplatz in `tag` → neutrale Fläche. Damit ist jede Kombination aus Motiv
  und Licht definiert, auch die bewusst nicht gerenderten (Momente in Regen/Nacht).
- **Was existiert, steht in einer Tabelle im Code** (`const` Liste aus §3.2), nicht im
  Dateisystem-Scan. Ein struktureller Test prüft: jede Tabellenzeile hat eine Datei
  unter `assets/comic/cafe/`, und jede Datei ist in der Tabelle (keine Leichen im
  Bundle).
- **Dateinamen:** `assets/comic/cafe/{motiv}_{licht}.jpg`, JPEG q88, 1216×832, wie die
  Bilder aus PR #46 (die fünf werden entsprechend umbenannt: `cafe_wirtin.jpg` →
  `wirtin_tresen_tag.jpg`).
- **Regen kommt aus der Folge:** `Episode.weather` (neu, optional; Folge 01: `rain`).
  Die Nachbesprechung übergibt `rain: episode.weather == 'rain'`. Der normale Besuch
  kennt nur die Uhr.

Warum keine Zufallsauswahl: Rotation nach Block ist deterministisch (Tests) und wirkt
für den Lerner trotzdem lebendig, weil Licht und Sitzungs-Offset variieren.

### 5.4 Café-Raum und Erklärungskarte

- `CafeScreen`: Kopfbild `sceneAsset(leer, light)`, Miniaturen `sceneAsset(stammplatz(g),
  light)`; Leerzustand `wirtin_tresen` im Licht der Stunde. Die Verdrahtung aus PR #46
  wird übernommen und auf die Bibliothek umgestellt.
- `CafeDebriefScreen` (Akt 1): Band `sceneAsset(wirtin_tisch, light)` über der
  Wirtin-Zeile; `DebriefCardView` unverändert.

### 5.5 Stapel und Herkunft der fünf Bilder

Die Umsetzung stapelt auf `impl/cafe-nachbesprechung` (PR #48). Die fünf Café-Bilder
und die `pubspec`-Zeile werden aus PR #46 übernommen (Dateien, nicht der Branch — #46
trägt daneben die 24-Panel-Verdrahtung des Readers, die durch Folge 01 V3 in #45
ohnehin überholt ist und getrennt bereinigt werden muss). Dieser Hinweis gehört in die
Beschreibung des Umsetzungs-PRs, damit #46 nicht doppelt gemergt wird.

### 5.6 Produktion der Bilder (Ulis Content-Anteil, Claude rendert auf der GPU-Box)

- **Rezept = das der fünf vorhandenen Bilder** (`folge01_fix.py`-Weg): Qwen-Image
  Text-zu-Bild, LoRA `shotengai_style_ckpt6` auf **0,3**, Foto-Zusatz (*photorealistic
  film still, realistic detailed human faces, natural skin texture, 35mm photograph*)
  und Anti-Anime-Negativ, 1216×832, 24 Schritte, cfg 4.
- **Feste Figurenbeschreibungen**, aus den abgenommenen Bildern nachgeschärft, damit
  zehn Bilder derselben Figur dieselbe Person zeigen: Wirtin (Sechzigerin, graues Haar
  im tiefen Knoten, schwarzes kurzärmeliges Kleid, beige Schürze), Schulkind (kurzer
  schwarzer Bob mit Pony, dunkelblaue Matrosenuniform mit weißen Streifen, graues
  Halstuch, weiße Socken), Vielredner (Mitte vierzig, kurzes schwarzes Haar, Stoppeln,
  abgetragene olivbraune Arbeitsjacke über dunklem Pullover), Gleichaltrige (junge
  Frau, kinnlanger schwarzer Bob, weiter cremefarbener Strickpullover). Diese Sätze
  stehen im Render-Skript und werden **nie** zwischen Motiven verändert.
- **Licht:** bevorzugt durch **Umleuchten** des fertigen Tag-Bildes (Qwen-Image-Edit +
  Relight-LoRA, für die Anker-Orte bewährt: derselbe Raum, nur das Licht ändert sich).
  Ob das im fotorealistischen Look ohne Flach-Effekt hält, ist **ungeprüft** — deshalb
  ist Schritt 1 der Umsetzung ein Beweis mit zwei Motiven (§10). Fällt er durch:
  Text-zu-Bild je Licht mit Lichtwörtern im Prompt und Seed-Auswahl (Raum darf dann
  leicht abweichen; die Möbel und Farben halten über die LoRA und das Rezept).
- **Seed-Auswahl:** zwei bis drei Seeds je Motiv, Kontaktbögen zur Sichtung an Uli im
  Chat (wie bisher; keine Pfade auf der Box als Abgabe). Uli wählt, Claude bündelt.

## 6. Regeln, die stehen bleiben

| Regel | Wie sie gewahrt bleibt |
|---|---|
| **INV-8** (Café führt nichts ein) | Stimmen und Bilder berühren die Item-Quelle nicht. Die Vorlagen setzen nur das fällige Wort ein. |
| **INV-9** (Bedeutung nur für Eingeführtes) | unverändert; Vorlagen nennen keine Bedeutung. |
| **INV-10** (kein Café-Fortschritt) | Licht folgt der Uhr, Momente dem Block. Nichts wird freigeschaltet, nichts gesammelt. |
| **I1** (kein Auswahl-Abfragen auf Produktion) | `kindForRung` unverändert; die Stimme ändert nie die Übungsform. |
| **I6** (stabiler Abrufreiz) | betrifft das Konzeptbild eines Wortes; das bleibt fest. Café-Szenen sind Stimmung, kein Abrufreiz, und dürfen wechseln. |
| **Brief §4.2** (Gäste sind Sprossen) | gilt im normalen Besuch unverändert; die Nachbesprechung ist die benannte Ausnahme (Annahme A). |
| **Brief §4.3** (Belegung = Fälligkeit) | gilt im normalen Besuch; in der Nachbesprechung sind die drei anderen Stammgäste, keine Anzeige. |
| **Brief §4.6** (Zusatzinvestition = A7 + vier Gäste) | wird bewusst erweitert: A7 in vier Lichtern, vier Gäste in je drei Momenten. Kein neuer Ort, keine neue Figur. |
| **Brief §6** (kein Ausbau, keine Deko, keine Gunst) | Die Bibliothek zeigt denselben Raum. Nichts daran ist erspielbar. |

**Neue Regel (Vorschlag für den Brief):** *Eine Stimme ändert nie die Übungsform. Wer
fragt, ist Ton; wie schwer, ist Sprosse.*

## 7. Bewusst NICHT

- **Keine Mehr-Gäste-Szenen** in einem Bild. Direktes Generieren mehrerer Figuren war
  unzuverlässig (Figuren fallen weg, Maßstab driftet); der Raum-Bildschirm zeigt die
  Anwesenden als Miniaturen, nicht als Gruppenbild.
- **Keine Reaktionsbilder** (Groß) — erst, wenn Mittel steht und Uli sie vermisst.
- **Keine Nahaufnahmen.** Weitszene mit Figur im Raum ist die bewiesene Disziplin.
- **Keine neue Figur, kein neuer Ort.** Mira bleibt hinter der Kamera.
- **Kein Zufall zur Laufzeit,** keine Animation, kein Parallax-Effekt.
- **Keine Texte aus einem Sprachmodell zur Laufzeit.** Alle Zeilen sind gebündelt; die
  App bleibt offline vollständig.
- **Keine Änderung an Akt 1 außer dem Band.** Die Wirtin erklärt weiterhin allein — die
  Erklärung ist ihre Rolle; nur das Nachfragen wird geteilt.

## 8. Risiken

| Risiko | Umgang |
|---|---|
| **Identitätsdrift:** dieselbe Figur sieht in zehn Bildern nicht gleich aus (kein Referenzbild im Look A) | feste Beschreibungen (§5.6), Weitszene statt Nahaufnahme, zwei bis drei Seeds, Ulis Sichtung vor dem Bündeln. Bleibt es schlecht: Umleuchten statt Neu-Rendern für alle Lichtvarianten, so dass nur die Tag-Bilder Drift tragen können. |
| **Umleuchten flacht den Foto-Look ab** (bei LoRA 1,5 im Edit-Modell gesehen) | Schritt 1 ist der Beweis mit zwei Motiven in vier Lichtern, LoRA 0,3 oder ohne LoRA; Rückfall = Text-zu-Bild je Licht. |
| **Bildschirmplatz:** Szene + Wort + Antwortfeld + Tastatur passen nicht auf ein Handy-Hochformat | Szene klappt bei offener Tastatur auf ein Band (`resizeToAvoidBottomInset`, flexibler Kopf); Gerätetest auf dem S23 ist Teil der Abnahme. |
| **Blockwechsel wirkt wie ein Zwischenscreen** (Brief §6 verbietet „Lektion abgeschlossen"-Screens) | Die Übergabe ist eine Zeile im selben Bildschirm, kein eigener Screen, kein Knopf. |
| **42 neue Zeilen klingen doch wie eine Person** | Steckbriefe (§4) als Messlatte; Test „Schulkind klingt nicht wie die Wirtin" (heute schon für Reaktionen) wird auf Fragen und Einstiege ausgedehnt. |
| **Später (Sprosse 3+) verwirrt es, dass das Schulkind mal leicht, mal schwer fragt** | Im normalen Besuch fragt das Schulkind nur Sprosse 3 (unverändert). In der Nachbesprechung fragt es „mit" — ein Satz im Einstieg trägt das: *„Darf ich auch mal? Die leichten nehm ich."* |

## 9. Teststrategie & Abnahme

Strukturell und deterministisch, im Stil der bestehenden Café-Tests:

- **Sprecherplan:** der erste Block ist die Wirtin, ab drei Blöcken auch der letzte;
  alle drei anderen kommen vor, sobald fünf Blöcke da sind; zwei Sitzungs-Offsets
  ergeben zwei Reihenfolgen; ein Block → nur Wirtin; Länge = Item-Anzahl.
- **Vorlagen:** je Gast und Übungsform mindestens drei Zeilen; zehn aufeinanderfolgende
  Turns einer Stimme ohne wörtliche Wiederholung; jede Vorlage enthält das eingesetzte
  Wort und nie die Bedeutung; jeder Gast hat Reaktionen für richtig, falsch und Hinweis.
- **Szenen-Bibliothek:** jede Tabellenzeile hat eine Datei, jede Datei eine Zeile;
  `sceneAsset` liefert für jede Kombination aus Motiv und Licht einen Pfad; die
  Uhrgrenzen (06, 17, 21) und der Regen-Ersatz nur bei Tag; Rotation der Momente nach
  Block.
- **Bildschirme:** der Turn-Bildschirm zeigt Name und Szenen-Schlüssel des jeweiligen
  Sprechers und wechselt beim Blockwechsel; Übergabe- und Einstiegszeile erscheinen
  genau einmal pro Blockwechsel; Akt 1 zeigt das Wirtin-Band; der Raum zeigt `leer` im
  Licht der Stunde; fehlende Datei → Rückfall, kein Absturz.
- **Unverändert grün:** alle bestehenden Café-Tests (INV-9, Belegung, Nachbesprechung,
  Route) — die Stimmen ändern die Item-Quelle nicht.

**Abnahme:** Ulis Gerätetest auf dem S23. Messlatte: Er liest Folge 01 zu Ende, geht
ins Café, sieht den Raum im Licht der Stunde, wird in einer Nachbesprechung von
mindestens drei verschiedenen Stimmen gefragt, sieht dabei mindestens sechs
verschiedene Bilder — und kein Bild sieht „reingeklebt" oder nach einer anderen Person
aus.

## 10. Grobe Reihenfolge (für den Umsetzungsplan, nicht Teil dieses Designs)

1. **Bild-Beweis (Gate):** `leer` und `wirtin_tresen` in vier Lichtern über Umleuchten
   rendern, Kontaktbogen an Uli. Entscheidet den Produktionsweg für Licht (§5.6).
2. **Stimmen ohne Bilder:** Steckbriefe, 42 Zeilen, Sprecherplan, Turn-Bildschirm mit
   Rotation und Übergaben, Tests. Ab hier ist die Abwechslung beim Fragen auf dem
   Gerät erlebbar, auch ohne neue Renders.
3. **Bibliothek:** restliche Motive rendern, Seeds sichten, bündeln;
   `CafeSceneLibrary`, Raum, Turn-Bildschirm, Akt-1-Band, `Episode.weather`.
4. **Gerätetest S23** und Nachbesserung.

Schritt 2 ist unabhängig von 1 und 3 und kann sofort beginnen. Jeder Schritt lässt die
App lauffähig. Daraus werden **zwei Umsetzungspläne**: „Stimmen" (Schritt 2) und
„Bilder" (Schritte 1 und 3); der Gerätetest schließt beide ab.
