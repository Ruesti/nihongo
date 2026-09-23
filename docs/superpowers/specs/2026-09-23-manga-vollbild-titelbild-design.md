# Design: Manga-Vollbild — Manga-Look, Hoch- und Querformat, Titelbild je Folge

**Datum:** 2026-09-23
**Status:** Von Uli freigegeben („Ja"; Manga-Methode: „M1 depth"). Abnahme
der Bilder per Bogen-Picks, Abnahme des Readers per Gerätetest am S23.
**Basis:** Branch `fix/reader-ux-feedback` (PR #51, Reader mit Blasen im Bild,
Mitmach-Hinweis, volle Panelbreite). Neuer Zweig `design/manga-vollbild`.
**Anlass:** Uli: *„Ich möchte auf jeden Fall noch auf Manga gehen. So wie ich
es verstanden habe ist es am besten erst fotorealistisch und dann daraus Manga
erzeugen. Bilder hoch und Querformat bildschirmfüllend. Brauche noch
Episodenbilder als Startbild der Episode."*

---

## 1. Was sich ändert, in drei Sätzen

1. Die Panels werden nicht mehr als Foto (Look A) gezeigt, sondern als
   **Manga im Hausstil**. Das Foto bleibt der erste Arbeitsschritt, weil es die
   Figuren stabil hält; der Manga-Look ist ein zweiter Schritt darüber.
2. Jedes Bild gibt es **zweimal**: quer (16:9) und hoch (9:16). Der Reader
   zeigt je nach Handy-Lage das passende Bild **bildschirmfüllend**.
3. Jede Folge beginnt mit einem **Titelbild**: ein eigenes Motiv, über das
   die App Folgennummer, Titel, Anmoderation und „Tippe, um zu beginnen" legt.

Umfang jetzt: Folge 01 (10 Panels, 3 Reaktionsbilder, 1 Titelbild). Die
Pipeline ist so gebaut, dass die 45 geplanten Folgen sie unverändert nutzen.

## 2. Der Manga-Durchgang (Gate-Ergebnis vom 23.9.)

### 2.1 Warum Foto zuerst
Der Foto-Durchgang (Look A, feste Figurenbeschreibungen im Prompt, LoRA 0,3,
Anti-Anime-Negativ) liefert stabile Gesichter, Alter und Kleidung ohne
Referenzbilder. Ein Manga-Bild direkt aus dem Text zu rendern brachte
Stil-Drift; eine Umwandlung ohne Zügel (denoise 0,4/0,6 vom 13.9.) brachte
entweder „halb Foto, halb Zeichnung" oder vertauschte Personen (alte Frau
wurde jung).

### 2.2 Die Methode: img2img mit Struktur-Zügel (Tiefe)
Gate-Test auf den fünf härtesten Panels (P03, P07, P17, P21, P22), Bogen
https://claude.ai/artifact/KLKqaT8XSiaVDZtcMD86nX, Kopien `~/manga-gate/`.
Uli wählt **M1 Depth**; Canny ist der Ausweich, wenn ein Panel mit Tiefe
etwas verliert (z. B. Brille, Schirmspeichen).

Rezept (ComfyUI auf der GPU-Box, alle Modelle liegen dort):

| Baustein | Wert |
|---|---|
| Modell | `qwen-image-Q4_K_M.gguf` + `shotengai_style_ckpt6.safetensors` Stärke **1,5** |
| Latent | VAEEncode des Foto-Finals (img2img) |
| Sampler | euler / simple, 24 Steps, cfg 4,0, **denoise 0,7**, Seed = Seed des Fotos |
| Zügel | `Qwen-Image-InstantX-ControlNet-Union` über `ControlNetLoader` + `ControlNetApplyAdvanced` (mit VAE), Bild aus `DepthAnythingV2Preprocessor` (res = kurze Seite), Stärke **0,7**, start 0, end 0,8 |
| Ausweich | `CannyEdgePreprocessor` 100/200, Stärke 0,6 |
| Positiv | `shotengai_style, muted painterly 1990s manga illustration, hand-drawn linework, deep shadows, melancholic, atmospheric, ` + **Panel-Inhalt mit den festen Figurenbeschreibungen** (P/M/W aus dem Foto-Skript) |
| Negativ | `photo, photorealistic, text, watermark, oversaturated, bright, cute, kawaii, blurry, deformed hands, extra fingers, distorted face` |

Der Panel-Inhalt im Prompt ist Pflicht: er hält die Personen zusätzlich zum
Zügel (der alte Lauf hatte nur den Stil-Prompt).

Bekannter Schönheitsfehler: „grimy weathered" aus dem Stil-Prompt setzt
Flecken auf durchsichtige Schirme (P21). Für Schirm-Panels bekommt der
Positiv-Prompt `clean transparent umbrella`; das ist Teil der
Feinschliff-Runde (§6, Runde 2).

### 2.3 Feinschliff, bevor alles läuft
Vor dem Vollrender werden an zwei Panels (P03 nah, P21 zwei Personen) die
Stellschrauben einmal durchgespielt: denoise 0,6 / 0,7 / 0,8 und
Zügel-Stärke 0,6 / 0,7 / 0,85. Sechs Bilder je Panel, ein Bogen, Uli wählt
den Standard. Erst danach der Vollrender.

## 3. Bildformate und Vollbild

### 3.1 Die Zahlen
- Handy (S23): 2340 × 1080, Seitenverhältnis **2,17 : 1**.
- Bisherige Panels 1216 × 832 = 1,46 : 1. Bildschirmfüllend gezeigt ginge
  ein **Drittel der Höhe** verloren. Deshalb werden sie nicht weiterverwendet.
- Neue Render-Größen = die Qwen-eigenen: **quer 1664 × 928**, **hoch 928 × 1664**.
  Bildschirmfüllend verschwinden dann nur **18 % der Höhe (quer)** bzw.
  **17 % der Breite (hoch)**, gleichmäßig an beiden Rändern.
- **Sichere Zone** = mittlere 80 % in der Richtung, die beschnitten wird.
  Blasen, Gesichter, der Mitmach-Hinweis und die Titel-Texte liegen darin.
  Das Lettering-Skript prüft das (§4.4).
- Auslieferungsgröße in der App (nach 2×-Vergrößerung und Verkleinern):
  **quer 1920 × 1072**, **hoch 1080 × 1936**, JPEG Qualität 88.
  Bündel Folge 01: 11 Motive (10 Panels + Titelbild) × 2 Formate + 3
  Reaktionen × 2 = 28 Dateien ≈ 10 MB. Für die
  Serie (45 Folgen) wird das später ein Download-Paket; nicht Teil dieses
  Designs, aber der Grund, warum kein Bild größer als nötig ausgeliefert wird.

### 3.2 Hochformat = eigener Render, nicht gestreckt (Weg A)
Hoch und quer werden getrennt gerendert: gleiche Beschreibung, gleicher
Seed, andere Leinwand. Uli hat Weg A gewählt: auch die zehn Querbilder
werden neu gerendert (statt die alten per Rand-Ausmalen zu strecken). Die
damals korrigierten Inhaltsfehler (P04 Jacke, P11 draußen, P16 Schirm-Aktion,
P17 Schirm liegt) stehen als Prüfliste auf dem Pick-Bogen.

## 4. Die Pipeline (Skripte unter `tool/comic/`, laufen auf der Box)

Die Skripte werden versioniert und nutzen `tool/comic/comfy_client.py`
(liegt bisher nur auf `impl/cafe-bilder`; wird hierher übernommen).

### 4.1 `folge01_foto.py` — Foto-Durchgang
Look-A-Rezept (LoRA 0,3, Foto-Zusatz, Anti-Anime-Negativ, feste
Figurenbeschreibungen) für die 10 Reader-Panels (Quell-Prompts der
Nummern 1, 2, 4, 5, 7, 17, 21, 22, 11, 3 aus `folge01_A.py`/`folge01_fix.py`
auf der Box) und die Titelbild-Motive, je Format 1664 × 928 und 928 × 1664,
Seeds 701 und 702. Ergebnis: Pick-Bogen, Uli wählt je Panel und Format.

### 4.2 `folge01_manga.py` — Manga-Durchgang
Nimmt die Picks (`picks_foto.txt`), rendert nach §2.2 mit dem Seed des
Fotos. Ergebnis: Bogen Foto | Manga je Format, Uli gibt frei oder nennt
Panels für Canny-Ausweich / anderen Seed.

### 4.3 `upscale_2x.py` → Auslieferungsgröße
2× mit 4x-UltraSharp (vorhanden), dann Verkleinern auf 1920 × 1072 bzw.
1080 × 1936, JPEG q88, Ablage `assets/story/folge01/` (siehe §5.3).

### 4.4 `letter_folge01.py` — Lettering je Format
- Eingabe: **eine Layout-Datei** `tool/comic/folge01_layout.json` mit, je
  Panel und Format: Blasen (Text, Rechteck normiert 0..1, Furigana-Hinweise),
  Gesichtszonen (Ellipsen), sichere Zone.
- Ausgabe: gelettertes JPEG je Panel und Format; getönte Reaktionsvarianten
  (p02/p05/p08) je Format wie bisher.
- Prüfungen (Abbruch bei Verstoß): keine Blase über einer Gesichtszone;
  jede Blase liegt in der sicheren Zone.
- Aus derselben Layout-Datei erzeugt `tool/comic/gen_layout_dart.py` die
  Datei `lib/features/story/episodes/folge_01_layout.g.dart` (Tippflächen je
  Format). Damit gibt es genau eine Quelle für Blasenposition und Tippfläche.

## 5. Datenformat (Episodenschema)

### 5.1 Neue Felder, alle optional, alte Daten laufen unverändert
```
StoryPanel.asset             (bleibt: Querbild)
StoryPanel.assetPortrait     String?   Hochbild; fehlt es, wird asset genommen
StoryBubble.hitArea          (bleibt: Tippfläche im Querbild)
StoryBubble.hitAreaPortrait  StoryPolygon?  Tippfläche im Hochbild; fehlt sie, gilt hitArea
StoryInteraction.reactionAsset          (bleibt: quer)
StoryInteraction.reactionAssetPortrait  String?
Episode.cover                String?   Titelbild quer
Episode.coverPortrait        String?   Titelbild hoch; fehlt es, wird cover genommen
Episode.titleJa              String?   japanische Schreibung des Titels („雨"), nur Anzeige
```
`fromJson` liest die neuen Schlüssel; Tests decken „Schlüssel fehlt" ab.

### 5.2 Folge 01
`folge_01_regen.dart` bekommt je Panel `assetPortrait`, je Blase
`hitAreaPortrait` (aus `folge_01_layout.g.dart`), Reaktions-Hochbilder und
`cover`/`coverPortrait`. Die Tippflächen im Querbild kommen ebenfalls aus
der generierten Datei (keine Handpflege mehr).

### 5.3 Dateien
```
assets/story/folge01/p01.jpg            quer  1920 × 1072
assets/story/folge01/p01_hoch.jpg       hoch  1080 × 1936
assets/story/folge01/p02_reaction.jpg / p02_reaction_hoch.jpg
assets/story/folge01/titel.jpg / titel_hoch.jpg
```
Die bisherigen `assets/story/p01.jpg … p10.jpg` (1080 × 738, Foto) werden
durch die neuen ersetzt und gelöscht; `pubspec.yaml` bekommt
`assets/story/folge01/`.

## 6. Bild-Produktion (Ulis Picks, in dieser Reihenfolge)

1. **Runde 1 Foto:** 10 Panels × 2 Formate × 2 Seeds = 40 Bilder plus
   Titelbild: 3 Motive × 2 Formate × 2 Seeds = 12 Bilder. Ein Bogen je Format
   als Seite wie beim Gate; Uli pickt (Vorschlag von Claude liegt bei).
   Prüfliste der alten Inhaltsfehler steht auf dem Bogen.
2. **Runde 2 Manga:** Feinschliff (§2.3, 12 Bilder) → Uli wählt Standard →
   Vollrender aller Picks (11 Motive × 2 Formate) → Bogen → Freigabe oder
   Einzel-Nachbesserung (Canny-Ausweich, anderer Seed, Schirm-Prompt).
3. **Runde 3 Lettering:** Layout-Datei, gelettertes Set, Reaktions-Tönung,
   Bogen zur Sicht (Blasenlage in beiden Formaten).

Titelbild-Motive Folge 01 (aus der Anmoderation „Eine junge Frau steigt
allein aus dem Zug — es regnet"): (a) Mira von hinten am Bahnsteig, der Zug
fährt ab, Regen, fern die Lichter der Stadt; (b) Mira klein unter dem
Bahnsteigdach, Koffer neben ihr, Regenvorhang; (c) Nahaufnahme Miras Hand
mit dem verlaufenen Zettel, Regen. Alle mit ruhiger Fläche oben (quer) bzw.
unten (hoch) für den Titel. Die Texte (Folge, Titel, Anmoderation) werden
NICHT eingebrannt.

## 7. Reader (App)

### 7.1 Vollbild
- Beim Betreten der Lesephase: Statusleiste und Navigationsleiste
  ausblenden (`SystemUiMode.immersiveSticky`); beim Verlassen des Readers
  wieder herstellen (auch bei Zurück-Geste und beim Wechsel ins Sheet
  bleibt der Zustand konsistent).
- Beide Handy-Lagen sind erlaubt (keine Sperre). `OrientationBuilder`
  wählt `asset` (quer) oder `assetPortrait` (hoch).
- Das Bild füllt den ganzen Schirm mit `BoxFit.cover`, Beschnitt
  gleichmäßig an beiden Rändern. Ausnahme: Fehlt das Bild des angefragten
  Formats, wird das andere eingepasst (Letterbox) statt beschnitten —
  Übergangszustand ohne Verzerrung/Beschnitt (Ruling Befund 1).
- **Tippflächen unter Beschnitt:** Der Reader rechnet das angezeigte
  Bildrechteck aus (Skalierung = max(SchirmB/BildB, SchirmH/BildH), Versatz
  zentriert) und legt die Tippflächen relativ zu diesem Rechteck. Die
  Bild-Seitenverhältnisse sind je Format bekannte Konstanten (1920/1072,
  1080/1936); kein Bild muss dafür dekodiert werden. Tippflächen folgen
  dem eingepassten Rechteck, wenn das andere Format gezeigt wird.
- Das bisherige `AspectRatio(_panelAspectRatio)` + `SingleChildScrollView`
  entfällt in der Lesephase.

### 7.2 Overlays in der sicheren Zone
- Gedanken-Kasten oben, Mitmach-Hinweis unten, Reaktions-Zeile: wie bisher,
  aber innerhalb `SafeArea` + Rand der sicheren Zone.
- Zurück: kleiner halbtransparenter Chip oben links (die AppBar entfällt).
- Blasen ohne Tippfläche (Übergangs-Fallback aus Reader-Erleben §2.2)
  erscheinen als halbtransparente Fußzeile über dem Bild, nicht mehr
  „unter dem Bild".

### 7.3 Titelkarte mit Titelbild
- `cover`/`coverPortrait` vollflächig (`BoxFit.cover`, nach Lage), darüber
  ein dunkler Verlauf im unteren Drittel (quer) bzw. unteren Viertel (hoch).
- Text darüber: kleine Zeile „Folge 1", Titel groß mit japanischer
  Schreibung („雨 · Regen"; die japanische Schreibung ist ein neues
  optionales Feld `titleJa`), Anmoderation, „Tippe, um zu beginnen".
- Ohne `cover` bleibt die heutige reine Textkarte (kein Absturz, kein
  Platzhalterbild).
- Endkarte: unverändert.

### 7.4 Tests (Widget- und Unit-Tests)
- Bildwahl: quer → `asset`, hoch → `assetPortrait`, hoch ohne
  `assetPortrait` → `asset`; fehlt das Bild des angefragten Formats, wird
  das andere eingepasst (Letterbox) statt beschnitten — Tippflächen
  folgen dem eingepassten Rechteck.
- Tippflächen-Abbildung: ein Rechteck 0..1 landet unter Beschnitt an der
  errechneten Stelle (zwei Schirmgrößen, beide Lagen); Tap darauf löst
  Vorlesen + Wörterbuch aus wie bisher.
- Titelkarte: mit `cover` wird das Bild gezeigt und der Text liegt darüber;
  ohne `cover` die Textkarte; Tipp startet die Lesephase.
- Vollbild-Modus: beim Betreten gesetzt, beim Verlassen zurückgesetzt
  (über einen injizierbaren Adapter statt direkt `SystemChrome`, damit der
  Test es beobachten kann).
- Layout-Konsistenz: ein Test liest `tool/comic/folge01_layout.json` und
  vergleicht die Rechtecke mit `folge_01_layout.g.dart` (Bounding-Boxen
  gleich).
- Fehlendes Asset → grauer Platzhalter (bestehender `errorBuilder`).
- Bestehende Reader-Tests laufen weiter (Sprechmoment, Nachzeichnen,
  Wörterbuch, Fortschritt); wo sie das Layout berühren, werden sie auf das
  neue Vollbild-Layout umgestellt.

## 8. Invarianten

- **INV-14 Eine Quelle für Blasen und Tippflächen.** Blasenposition im Bild
  und Tippfläche in der App stammen aus derselben Layout-Datei; ein Test
  erzwingt die Übereinstimmung.
- **INV-15 Kein Text wird beschnitten.** Blasen, Hinweise, Titel liegen in
  der sicheren Zone; das Lettering-Skript bricht bei Verstoß ab.
- **INV-16 Kein Meta-Text im Bild.** Folgennummer, Titel, Anmoderation
  zeichnet die App (Reader-Erleben §1 gilt weiter: Deutsch ist Bedienung,
  Japanisch lebt im Artwork).
- Unverändert: INV-1 (kein story-kritisches Tor), INV-2 (Antippen = Audio +
  Kana), INV-7 (inerte Tokens bleiben inert).

## 9. Bewusst NICHT

- Kein Schwarz-Weiß-Manga (Farbe bleibt, Entscheidung vom 1.9.).
- Kein Umbau der Café-Bilder (PR #54); sie bekommen denselben
  Manga-Durchgang später, sobald die Picks dort stehen.
- Kein Rand-Ausmalen alter Bilder (Weg B verworfen).
- Kein Download-Paket; Folge 01 wird gebündelt.
- Keine Vollbild-Änderung an Café, Home oder Sheets.

## 10. Abnahme

1. Runde 1–3 (§6): Ulis Picks liegen vor, alle 28 Dateien (§5.3) im Repo,
   Layout-Test grün.
2. Vollsuite grün (bis auf die 8 bekannten nativen Tokenizer-Fehler).
3. Gerätetest S23 (cross-machine-test-deploy): Titelkarte mit Bild in beiden
   Lagen; Drehen mitten in der Folge wechselt das Bild ohne Sprung in der
   Position; Blasen tippbar in beiden Lagen; Statusleiste weg beim Lesen,
   wieder da im Café; Sprechmoment und Nachzeichnen wie vor dem Umbau.

## 11. Betrieb (aus dem Gate gelernt)

- Basis-Modell und Edit-Modell nie im selben Lauf abwechseln: der
  RAM-Cache der Box (12 + 12 + 8 GB) überschreitet 31 GB, `systemd-oomd`
  beendet ComfyUI. Methodenweise rendern; vor einem Modellwechsel
  `systemctl --user restart comfyui`.
- Laufzeiten auf der 3090: Foto-Render ≈ 80 s, Manga mit Zügel ≈ 130 s,
  erster Render nach Start + 2 Minuten. Runde 1 ≈ 70 Minuten, Runde 2 ≈ 1,5 Stunden (mit Feinschliff).
- Während langer Läufe Kill-Switch `~/.no-idle-suspend` setzen, danach
  entfernen; Bilder immer erst abholen, dann schlafen lassen.
