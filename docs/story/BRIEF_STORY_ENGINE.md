# Brief — Story-Engine & Wörterbuch

**Adressat:** Claude Code
**Kontext:** Sprachlern-App. Bestehende Architektur: Five-Rung Retrieval Ladder,
SM-2 SRS, `ScriptProfile`-Abstraktion, concept-keyed Asset-Library.
**Scope dieses Briefs:** die Story-Schicht darüber — Panel-Rendering,
Interaktionsspur, diegetisches Wörterbuch, Café-Modus.
**Referenz-Content:** `PILOT_01_REGEN.md` (Folge 01, 24 Panels, 8 Items, 3 Kana)

**Drei Modi, eine Welt.** Die Story zieht vorwärts und ist linear. Das Café wiederholt
und ist nichtlinear. Das Wörterbuch trägt beides. Alles spielt in derselben Straße —
das Café ist ein Laden in der Shotengai, kein zweites Setting.

---

## §0 — Interview-Gate

Vor jeder Zeile Code sind folgende Punkte zu klären und schriftlich zu beantworten.
Kein Implementierungsschritt vor Freigabe.

1. Panel-Assets: einzelne Bilddateien pro Panel, oder Seiten-Sheet mit
   Panel-Koordinaten? (Beeinflusst Zoom, Ken-Burns und Speicherbedarf.)
2. Hit-Areas für Sprechblasen: im Manifest hinterlegt oder zur Laufzeit erkannt?
3. Audio: pro Wort oder pro Sprechblase geschnitten? Bei Blase — wie wird ein
   Einzelwort daraus isoliert abgespielt?
4. Wörterbuch-Suche: reines Kana-Blättern (§3.2) oder Fallback-Suche für
   Absolut-Einsteiger? Falls Fallback — wie wird er verdient statt geschenkt?
5. Vertikal scrollende Seite oder Panel-für-Panel-Tap? (Bestimmt, ob P24 als
   Schlussbild wirkt oder als Zeile im Scroll untergeht.)
6. Wird Fortschritt pro Panel persistiert oder nur pro Folge?
7. Café: Ist der Gast-Bestand pro Sitzung fix, oder kann er sich während einer
   Sitzung ändern, wenn Items fällig werden? (Empfehlung: fix — sonst poppen
   Figuren auf und der Ort wirkt wie ein Spielautomat.)
8. Wie werden Café-Dialoge autorisiert? Handgeschriebene Varianten pro Item,
   oder Template-Slots, in die SM-2 Items einsetzt? (Handgeschrieben ist besser
   und skaliert nicht. Hybrid vermutlich nötig — Grenze festlegen.)

---

## §1 — Invarianten

Diese Regeln sind erzwingbar zu implementieren, nicht als Konvention zu
dokumentieren. Ein Verstoß ist ein Testfehler, keine Ermessensfrage.

| ID | Invariante |
|---|---|
| **INV-1** | Eine Folge ist von erstem bis letztem Panel durchlesbar, ohne dass eine Übung gelöst werden muss. Es gibt kein Gate im Story-Modus. |
| **INV-2** | **Im Story-Modus** liefert das Antippen einer Sprechblase Audio und Kana — **niemals** Bedeutung. Bedeutung entsteht dort ausschließlich über das Wörterbuch. Im Café-Modus gilt INV-9. |
| **INV-3** | Kein Panel führt mehr Items ein, als im Folgen-Manifest budgetiert. Überschreitung schlägt beim Content-Build fehl, nicht zur Laufzeit. |
| **INV-4** | Jedes Item einer Folge erscheint ≥ 2× in unterschiedlichem Panel-Kontext. Ausnahmen müssen im Manifest explizit als `singleton: true` markiert sein. |
| **INV-5** | Kein Item erreicht im SRS-Feed eine Rung > 2, bevor die einführende Folge vollständig gelesen wurde. |
| **INV-6** | Produktive Rungs (3–5), Nachzeichnen und Sprechübungen laufen **nicht** im Story-Modus. Ausnahme: explizit als `diegetic: true` markierte Panels (Folge 01: P07, P22, P24). |
| **INV-7** | Kanji ohne freigeschaltete Bedeutung sind nicht antippbar. Sie sind Bildtextur. Ein Tap darauf tut nichts — er zeigt keinen Hinweis und keine Sperre. |
| **INV-8** | Das Café führt **keine neuen Items ein**. Jedes dort auftretende Item stammt aus einer bereits gelesenen Folge. Content-Build schlägt fehl, wenn ein Café-Dialog ein Item referenziert, das keine einführende Folge hat. |
| **INV-9** | Freies Antippen von Bedeutung gilt **ausschließlich** im Café und **ausschließlich** für bereits eingeführte Items. Kein Weg führt von dort zu einem noch ungelesenen Item. |
| **INV-10** | Das Café hat keinen eigenen Fortschritt. Kein Level, kein Ausbau, keine Währung, keine Freischaltung durch Café-Aktivität. Alles, was dort wächst, wächst über den SM-2-Bestand. |

**INV-7 ist wichtiger, als sie aussieht.** Ein Tooltip „noch nicht gelernt" zerstört
die Fiktion, dass der Leser in derselben Lage ist wie die Figur.

**INV-8 und INV-9 zusammen** verhindern den einen Fehler, der das ganze Konzept
kippen würde: Wenn Bedeutung im Café gratis ist und dort auch neue Wörter auftauchen,
wird das Café der Hauptpfad und die Story optional. Dann hast du eine Vokabelapp mit
Comic-Beilage gebaut — also genau das, was du nicht wolltest.

---

## §2 — Datenmodell

Sprachneutral im Kern, aber Panel-Assets sind ab hier **länderspezifisch** —
die Serie ist ein Format-Franchise, keine übersetzte Serie. Wiederverwendet werden
Struktur, Motor und Rasterschema; nicht die Pixel.

```
Episode
  id, seasonId, orderIndex
  title, locale, era
  budget: { items: ItemRef[], glyphs: GlyphRef[] }
  pages: Page[]

Page
  index
  panels: Panel[]

Panel
  index
  asset: AssetRef              // concept-keyed
  bubbles: Bubble[]
  thoughts: Thought[]          // Muttersprache des Lerners
  interactions: Interaction[]
  anchorShot?: AnchorShotId    // wiederkehrender Kamerastandpunkt
  notes: string                // Autorenkommentar, nicht gerendert

Bubble
  speakerId
  glyphs: string               // Zielsprache, Kana/Kanji gemischt
  audioRef
  hitArea: Polygon
  tokens: Token[]

Token
  surface, reading
  itemId?                      // null = Klang ohne Item (siehe P08)
  lookupable: bool             // false ⇒ INV-7

Interaction
  type: reveal | listen | speak | trace | dictionary
  diegetic: bool
  optional: bool               // im Story-Modus immer true
```

**Hinweis zu `itemId: null`:** In P08 sagt die Nebenfigur `はい`, bevor das Wort im
Budget aufgenommen ist. Das ist Absicht — Klang darf dem Item vorausgehen. Das Modell
muss diesen Fall tragen, ohne das Budget zu verletzen.

---

## §3 — Das Wörterbuch

Kern der Lernerfahrung, nicht Nebenfunktion. Es ist ein **Gegenstand in der Welt**:
ein Papierwörterbuch von 1996, das der Figur nicht gehört.

### 3.1 Zustand

- Es startet **nicht leer und nicht vollständig**. Es enthält bereits Anstreichungen
  und Randnotizen des Vorbesitzers — an Wörtern, die die Figur noch nicht kennt.
- Gelernte Items erscheinen darin **in ihrer Handschrift**, nicht gedruckt.
- Der Bestand des Buchs *ist* der SRS-Bestand. Keine zweite Vokabelliste. Keine
  Statistikansicht mit Balken. Wer wissen will, wie weit er ist, blättert.

### 3.2 Suche

**Kein Suchfeld.** Nachgeschlagen wird über die Kana-Ordnung — also gojūon-Reihenfolge,
Blättern zur Zeilengruppe, dann zum Zeichen.

Das ist bewusst Reibung, und die Reibung ist der didaktische Ertrag:

- Nachschlagen erzwingt Kenntnis der **Lesung**. Man kann nicht suchen, was man nicht
  aussprechen kann. Das ist auf Japanisch keine Härte, sondern die Wahrheit.
- Wiederholtes Blättern lehrt die Silbenordnung nebenbei und ohne eigene Übung.
- Für Kanji: Radikal-Suche. Das ist dieselbe Zerlegung, die die
  Component-Building-Spiele trainieren — eine Mechanik, zwei Orte.

### 3.3 Ableitung aus `ScriptProfile`

Die Suchmechanik ist **nicht** japanisch hartzucodieren. Sie leitet sich ab aus:

- `collationOrder` — Kana-Reihenfolge, Alphabet, Abjad-Ordnung
- `hasComponentDecomposition` — schaltet Radikal-Suche frei
- `lookupRequiresReading` — bool; bei Alphabetsprachen false

Ein neues Language Pack erbt damit automatisch das Wörterbuch, das zu seiner
Schrift passt.

### 3.4 Kosten

Nachschlagen ist nie kostenlos:

- Es **dauert** — Blättern ist echte Interaktion, nicht ein Tap.
- Wird es mitten in einem Gespräch geöffnet, läuft im Panel sichtbar Zeit weiter.
  In Folge 01/P09 geht die Gesprächspartnerin weg, während der Leser noch blättert.
  Das ist kein Fail-State und wird nicht als Scheitern gemeldet — es passiert einfach.
- Es übersetzt **Wörter**. Nie Höflichkeitsebene, nie Andeutung, nie das Ungesagte.
  Diese Grenze ist Produktversprechen, nicht Sparmaßnahme.

### 3.5 Randnotizen

Der Serienbogen wird über das Werkzeug ausgeliefert, nicht über eigene Szenen.

- Notizen des Vorbesitzers sind an Items gebunden und erscheinen beim Nachschlagen.
- Sie sind **nie auflösbar** — kein Tap, keine Übersetzung, auch nicht nach
  Freischaltung des Items.
- Dosierung: höchstens eine Notiz pro drei Folgen. Der Alltag trägt die Serie,
  der Faden ist Grundrauschen. Diese Rate gehört ins Season-Manifest, nicht in
  den Code.

---

## §4 — Das Café

Der Wiederholungs-Modus. Ersetzt den nackten SRS-Feed vollständig — es gibt keine
zweite, „normale" Kartenansicht daneben.

Das Café liegt in der Shotengai. Ein Laden in derselben Straße, dieselbe Welt,
dieselben Nachbarn. Kein zweites Setting, kein zweiter Erzählstrang, kein eigener
Bogen. Wer es betritt, wechselt nicht die Geschichte, sondern die Tätigkeit.

### 4.1 Warum es existiert

Zwei Probleme auf einmal:

- **Der SRS-Feed war die langweiligste Stelle des Entwurfs.** Karteikarten mit
  Panel-Miniatur daneben funktionieren, aber niemand freut sich darauf.
- **In der Werkstatt spricht niemand.** Der Ladenbesitzer ist als Figur stark, weil
  er schweigt — aber irgendwo braucht die Serie Menschen, die reden. Werkstatt und
  Café sind komplementär: dort Handwerk und Schweigen, hier Sprache und Geplauder.

### 4.2 Gäste sind Rungs

Die zentrale Mechanik. **SM-2 wählt die Items, die Figur wählt die Sprosse.**
Das nutzt die bestehende Entkopplung von Timing und Mastery-Rung als sichtbare
Oberfläche: Der Lerner sucht sich einen Gesprächspartner aus, und diese Wahl *ist*
die Schwierigkeitswahl.

| Gast | Rolle | Rung | Charakter |
|---|---|---|---|
| Die Wirtin | zeigt und benennt Dinge | 1–2 | geduldig, langsam, wiederholt gern |
| Das Schulkind | fragt gnadenlos ab | 3 | direkt, kein Keigo, korrigiert schonungslos |
| Der Vielredner | erzählt, fragt nach dem Kern | 4 | Monologe, Comprehensible Input |
| Die Gleichaltrige | offenes Gespräch | 5 | freie Produktion, kein richtig/falsch |

Das Schulkind ist die wichtigste Figur des Sets. Ein Kind, das eine Erwachsene
abfragt, dreht die Machtverhältnisse um und ist automatisch komisch — und Kinder
sprechen einfach und ohne Höflichkeitsebenen, was für frühe Rungs genau richtig ist.

### 4.3 Belegung ist die Fälligkeitsanzeige

Es gibt **keine** Zahl fälliger Karten, keinen Balken, keine „0 Karten fällig"-Meldung.

Stattdessen: Wer da ist, hängt davon ab, was fällig ist.

- Viel fällig → das Café ist voll, mehrere Gäste an mehreren Tischen.
- Wenig fällig → ein oder zwei Leute.
- Nichts fällig → **das Café ist leer.** Die Wirtin wischt den Tresen, nickt, sagt
  nichts weiter. Man kann sich hinsetzen. Es passiert nichts.

Das ist die diegetische Fassung von „nichts zu tun", und sie ist besser als jede
Leerzustands-Grafik: Sie enttäuscht nicht, sie beruhigt.

Nur Gäste erscheinen, für deren Rung tatsächlich Items fällig sind. Ein Gast ohne
Material ist nicht anwesend.

### 4.4 Antippen

Im Café ist Bedeutung frei antippbar. Begründung ist diegetisch: **hier hilft dir
jemand.** Draußen auf der Straße bist du allein mit dem Buch.

Grenzen, hart:

- Nur bereits eingeführte Items (INV-9).
- Das Café führt nichts Neues ein (INV-8).
- Antippen wird als Hinweis gewertet und geht in die SM-2-Bewertung ein — nicht als
  Fehler, aber auch nicht folgenlos. Wer sich durchtippt, verlängert seine Intervalle
  nicht.

### 4.5 Dialogaufbau

Ein Café-Turn ist keine Karte mit anderem Anstrich. Mindeststruktur:

```
CafeTurn
  guestId
  rung: 1..5
  itemIds: ItemRef[]        // von SM-2 geliefert
  prompt: LocalizedLine     // was der Gast sagt
  expected: ResponseSpec    // je nach Rung: Tap | Tippen | Sprechen | frei
  followUp: LocalizedLine[] // Reaktion auf richtig / falsch / Ausweichen
```

`followUp` ist der Teil, der über Erfolg entscheidet. Ein Gast, der auf jede Antwort
gleich reagiert, ist eine Karteikarte mit Gesicht. Mindestens drei Reaktionen pro
Gast und Ergebnis, rotierend.

### 4.6 Assets

Eine zusätzliche Ankerachse (`A7`, Café innen) plus vier Gästefiguren. Das ist die
gesamte Zusatzinvestition — der Grund, warum das Café als Ort in derselben Straße
liegt und nicht als eigenes Setting.

---

## §5 — Phasen

Phasengesteuert. Keine Phase beginnt vor abgenommenem BERICHT der vorigen.

| Phase | Inhalt | Abnahme |
|---|---|---|
| **P0** | §0 beantwortet, Datenmodell bestätigt | schriftlich |
| **P1** | Content-Schema + Validator. Folge 01 als Fixture, Platzhaltergrafik. Validator erzwingt INV-3, INV-4. | `validate` schlägt bei manipuliertem Budget fehl |
| **P2** | Panel-Reader. Durchlesen ohne jede Interaktion. | Folge 01 von P01–P24 lesbar |
| **P3** | Bubble-Tap: Audio + Kana. INV-2, INV-7. | Tap auf Kanji tut nachweislich nichts |
| **P4** | Wörterbuch: Kana-Blättern, Kosten, Handschrift-Bestand. | P09 fühlt sich richtig an (Prüffrage 2) |
| **P5** | Auslauf + SRS-Übergabe. INV-5, INV-6. | Kein produktiver Rung vor Lesende |
| **P6** | Diegetische Ausnahmen: P07, P22 Sprechen; P24 Nachzeichnen. | überspringbar, ohne dass Fortschritt verloren geht |
| **P7** | Café-Gerüst: Belegung aus SM-2-Fälligkeit, Gast↔Rung-Mapping. INV-8, INV-10. | Leeres Café bei leerem Fälligkeitsstand, ohne Meldung |
| **P8** | Café-Turns für Rung 1–3 (Wirtin, Schulkind), inkl. `followUp`-Rotation. | Zehn Turns hintereinander ohne wörtliche Wiederholung |
| **P9** | Rung 4–5 (Vielredner, Gleichaltrige), freies Antippen. INV-9. | Kein Pfad zu ungelesenen Items nachweisbar |

---

## §6 — Ausdrücklich nicht bauen

- Keine Streak-Mechanik, keine Tageskette, keine Herzen, kein Verlieren.
- Keine Prozentanzeige im Story-Modus.
- Keine „Lektion abgeschlossen"-Zwischenscreens.
- Keine Tile-Arrangement-Übungen. Wiedererkennen ist nicht Abrufen.
- Kein automatisches Aufdecken von Bedeutung bei langem Drücken. Kein Hintertürchen
  zu INV-2.

Speziell fürs Café — das sind die Fallen, in die solche Hubs regelmäßig laufen:

- Kein Ausbau des Cafés, keine Möbel, keine Dekoration, keine Freundschaftslevel.
- Keine Energie, keine Tickets, keine Begrenzung von Besuchen pro Tag.
- Keine Geschenke, keine Sammelobjekte, keine Gästegunst.
- Kein eigener Erzählbogen für das Café. Es ist ein Ort, keine Nebenhandlung.
  Serienbogen läuft über Story und Wörterbuch, nirgends sonst.

---

## §7 — BERICHT

Pro Phase: welche Invarianten getestet, mit welchem Testfall, welches Ergebnis.
Bei INV-1, INV-2, INV-7, INV-8 und INV-9 zusätzlich ein Negativtest — Nachweis, dass
der verbotene Pfad tatsächlich verschlossen ist. Für INV-9 genügt kein Unit-Test:
verlangt ist die vollständige Aufzählung aller Wege, auf denen ein Item im Café
sichtbar werden kann.
