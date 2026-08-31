# Visueller Stil — Arbeitsdokument

**Serie:** *Shotengai*, 1996
**Zweck:** Stilrichtung festnageln, bevor Assets produziert werden.
**Status:** Vorschlag. Die mit ⬦ markierten Punkte sind offene Entscheidungen.

---

## Das Kernproblem

Du hast dich gegen sprachneutrale Panels entschieden. Damit ist die Wiederverwendung
nicht mehr sprachübergreifend, sondern **innerhalb der Serie**. Der visuelle Stil muss
also nicht Kosten sparen, indem er beliebig ist — er muss Kosten sparen, indem
**derselbe Ort immer wieder derselbe ist**.

Das dreht die übliche Priorität um. Nicht: schöne Einzelbilder. Sondern: ein Ort,
den man wiedererkennt, aus Winkeln, die man kennt.

---

## Richtung

### Was der Stil leisten muss

1. **Ortsgefühl durch Wiederholung.** Vertrautheit entsteht nicht aus Abwechslung.
   Der Leser muss dieselbe Ecke zum zehnten Mal sehen und beim zehnten Mal etwas
   Neues bemerken.
2. **Lesbarkeit unter Text.** In jedem Panel sitzen Sprechblasen, oft Kana über
   Bildinhalt. Der Stil braucht ruhige Flächen, in die Text fallen kann.
3. **Alltag statt Postkarte.** Ein Tempel im Bild sagt Reiseprospekt. Ein
   Getränkeautomat um drei Uhr nachts sagt: ich bin da.
4. **Warm trotz Melancholie.** Die Serie handelt von einem Ort, der leiser wird.
   Der Strich darf das nicht zusätzlich betonen — sonst kippt der Ton.

### Vorschlag: „ruhige Linie, schmutzige Farbe"

- **Linie:** klar, gleichmäßig, wenig Schraffur. Kein expressiver, gebrochener Strich.
  Ruhige Konturen halten Panels lesbar, wenn Text darüberliegt, und sind über
  hunderte Panels konsistent reproduzierbar — was bei generierten Assets der
  entscheidende Punkt ist.
- **Farbe:** gedämpft, leicht vergilbt, wie Offsetdruck auf billigem Papier.
  Nie gesättigt außer bei Lichtquellen.
- **Der Kontrast dazwischen** ist der Stil: saubere Zeichnung, unsaubere Oberfläche.
  Das trägt die Zeit — 1996 sieht nicht aus wie ein Filter, sondern wie Material.

⬦ **Offen:** Vollfarbe durchgehend, oder Graustufen mit selektiver Farbe? Graustufen
wären billiger, seriennäher und würden die Neonlichter zu echten Ereignissen machen.
Aber Vollfarbe trägt „ich bin dort" stärker.

---

## Palette

| Rolle | Charakter |
|---|---|
| Basis | entsättigtes Grüngrau, Beton und Regen |
| Wärme | Bernstein aus Ladenfenstern, Glühbirnenlicht |
| Akzent | Neon: Rot und Cyan, nur als Lichtquelle, nie als Fläche |
| Papier | leichter Warmstich über allem, Druckraster-Textur |

**Regel:** Wärme kommt ausschließlich aus Licht, nie aus Oberflächen. Der Ort selbst
ist kühl; was ihn wärmt, ist eingeschaltet. Das ist die ganze Serie in einem
Palettenprinzip.

---

## Wiederkehrende Kamerastandpunkte (Ankerachsen)

Der wichtigste Produktionsbeschluss. Es gibt eine feste, kleine Menge Blickachsen,
die jede Folge wiederverwendet. Sie werden **einmal richtig gebaut** und danach
nur noch variiert.

| ID | Achse |
|---|---|
| `A1` | Eingang der Shotengai von außen, Regen aufs Dach |
| `A2` | Straße längs, Fluchtpunkt am anderen Ende |
| `A3` | Ladenfront von gegenüber |
| `A4` | Innen, aus der Tür Richtung Werkbank |
| `A5` | Werkbank frontal, Hände im Vordergrund |
| `A6` | Telefonzelle, halbtotal |
| `A7` | Café innen, Tresen und zwei Tische im Blick |

Jede Achse existiert in vier **Zeitvarianten**: Tag, Regen, Abend, Nacht.
Plus Jahreszeit als Overlay-Ebene.

**7 Achsen × 4 Zeiten = 28 Basis-Renders.** Das ist die eigentliche Investition der
Serie. Alles andere ist Variation und Vordergrund.

`A6` ist die wichtigste Achse trotz geringster Bildfläche: Die Telefonzelle ist ihre
einzige Verbindung nach Hause. Immer derselbe Winkel, dutzendfach — und jedes Mal
bedeutet er etwas anderes. Diese Achse **darf nie variiert werden.**

`A7` ist die einzige Achse mit variabler Belegung: Der Raum ist fix, die anwesenden
Gäste wechseln je nach Fälligkeitsstand (siehe Brief, §4.3). Figuren müssen deshalb
als freistellbare Ebenen über dem Hintergrund liegen, nicht in ihn eingerendert sein.
Das ist eine Anforderung an die Asset-Produktion, keine Laufzeitfrage.

---

## LoRA-Strategie

Drei getrennte Trainings. Nicht eins, das alles kann.

1. **Style-LoRA** — der Hausstil der Serie. Zuerst, weil alles andere darauf sitzt.
   Trainingsset aus eigenem, kuratiertem Material; keine Nachbildung eines
   identifizierbaren fremden Zeichenstils.
2. **Character-LoRA je Hauptfigur** — sie und der Ladenbesitzer. Getrennt, weil
   gemeinsame Trainings Identitäten vermischen.
3. **Location-Embedding** — die Straße als Ort. Schwächer als LoRA, eher über
   feste Kompositionsvorlagen plus Inpainting auf den 24 Basis-Renders.

**Reihenfolge:** Stil → Ort → Figuren. Nicht umgekehrt. Eine Figur in einem noch
nicht festgelegten Stil zu trainieren, verbrennt das Training.

### Abgrenzung zur Hardware-Marke

Der Sorayama-nahe, hyperreale Look der Hardware-Seite ist hier ausdrücklich falsch.
Diese Serie ist handgezeichnet, weich, gebraucht. Dieselbe Marke, zwei getrennte
visuelle Welten — das ist Absicht und muss in den Prompt-Anti-Patterns stehen.

### Tamago-chan

Sie ist **nicht** die Hauptfigur dieser Serie. Ein Ei trägt kein 1996er Nachbarschafts-
Drama. Sie bleibt Fortschrittsanzeige, Markengesicht und Übungsbegleiterin — also
außerhalb der Story-Schicht, im SRS-Feed und in der Navigation.

⬦ **Offen:** Läuft sie stilistisch mit der Serie mit, oder bleibt sie bewusst im
kawaii-Register als sichtbare Grenze zwischen Story und App-Schale? Ich würde die
Grenze sichtbar lassen — sie markiert dem Leser, wo die Fiktion aufhört.

---

## Anti-Patterns

- Keine Kirschblüten, keine Torii, keine Fuji-Silhouette. Kein Postkarten-Japan.
- Kein Filter-1996. Die Zeit kommt aus Gegenständen — Faxgerät, CRT, Kassettendeck,
  Papierfahrplan, Münztelefon — nicht aus Chromatischer Aberration.
- Kein Handy, kein Bildschirm mit Touch, keine gesenkten Köpfe.
- Keine leeren, perfekten Räume. Shotengai heißt: Kabel, Schilder, Kisten, Kram.
- Keine dramatischen Perspektiven. Diese Serie steht auf Augenhöhe.
- Keine Speedlines, keine Manga-Effektblitze. Der Stil ist ruhig.

---

## Nächste Schritte

1. ⬦ Vollfarbe oder Graustufe entscheiden — blockiert alles Weitere.
2. Stil-Moodboard aus eigenem Material, 20–30 Referenzen, kuratiert nach den vier
   Anforderungen oben.
3. Style-LoRA trainieren, gegen A2 (Straße längs) testen — die anspruchsvollste Achse.
4. Erst danach: die 24 Basis-Renders.
5. Erst danach: Figuren.
