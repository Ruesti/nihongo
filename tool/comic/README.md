# Bild-Pipeline Manga-Vollbild (tool/comic/)

So entstehen die Panels einer Folge: erst ein **Foto** (Look A), dann wird das Foto in den
**Manga-Look** umgezeichnet (img2img mit Tiefen-Zügel), dann **vergrößert** und **gelettert**
(Sprechblasen). Alles, was auf der GPU-Box läuft, braucht nur die Dateien aus diesem Ordner.
Spec: `docs/superpowers/specs/2026-09-23-manga-vollbild-titelbild-design.md`.

Begriffe kurz:
- **Box** = GPU-Rechner `pc` (ComfyUI auf Port 8188, nur dort erreichbar). **NUC** = dieser Rechner.
- **Key** = Motiv + Format, z. B. `p03_hoch`, `titel_quer`. **Pick** = Ulis Wahl je Key.
- **Seed** = Zufallszahl eines Renders; gleicher Prompt + gleicher Seed = gleiches Bild.
- **Override** = Zeile in einer `overrides_*.txt`, die einen Key anders rendern lässt.

Alle Befehle auf dem NUC laufen im **Repo-Wurzelverzeichnis**; auf der Box im Ordner `~/f01tool`.

## Laufreihenfolge (Folge 01; für Folge 02 Dateinamen anpassen)

### 0. Box vorbereiten (vor jedem langen Lauf)

```
wakegpu                                        # Box aufwecken (Leisten-Menü/Skript auf dem Laptop)
ssh pc 'touch ~/.no-idle-suspend'              # Kill-Switch: Box schläft während des Laufs nicht ein
ssh pc 'mkdir -p ~/f01tool'
scp tool/comic/*.py tool/comic/*.sh tool/comic/*.txt pc:f01tool/
```

Nach dem Lauf und dem Abholen: `ssh pc 'rm -f ~/.no-idle-suspend'`. Bilder immer **erst abholen**,
dann schlafen lassen.

### 1. Foto-Runde (Runde 1)

```
ssh pc 'cd ~/f01tool && setsid nohup python3 folge01_foto.py > foto.log 2>&1 </dev/null &'
ssh pc 'tail -3 ~/f01tool/foto.log'            # Marken: OK/SKIP/ERR <prefix>, am Ende FOTO_DONE
```

Dauer ≈ 80 s je Bild (52 Bilder ≈ 70 Min). Danach abholen und Vergleichsseite bauen:

```
scp 'pc:comfy_f01/foto/*.png' build/f01_foto/
python3 tool/comic/make_sheets.py build/f01_foto
python3 tool/comic/rows_foto.py build/f01_foto build/f01_foto/rows.json
python3 tool/comic/review_page.py build/f01_foto/runde1.html "Folge 01 · Runde 1" build/f01_foto/rows.json
python3 tool/comic/check_bars.py build/f01_foto        # schwarze Balken? (> 5 % → Exit 1)
```

### 2. Ulis Picks → `picks_foto.txt`

Uli wählt je Key einen Seed. Eintragen als `key=<Box-Pfad>` in `tool/comic/picks_foto.txt`
(der Seed steckt im Dateinamen `_s70N_`). Danach Balken-Check der Picks:

```
python3 tool/comic/check_bars.py tool/comic/picks_foto.txt build/f01_foto
```

### 3. Nachrender über `overrides_foto.txt` (nur wenn ein Pick fehlt oder Balken hat)

Neuen Prompt als Eintrag in `folge01_motifs.HOCH_FIX` (oder frei mit `core=…`) ablegen und je Key
eine Zeile in `tool/comic/overrides_foto.txt` schreiben, z. B. `p03_hoch seed=704 core=@HOCH_FIX:p03`.
Mit `seed=` wird **nur** dieser Seed gerendert. Nachrender + Feinschliff in einem Lauf:

```
scp tool/comic/*.py tool/comic/*.sh tool/comic/*.txt pc:f01tool/
ssh pc 'setsid nohup sh ~/f01tool/run_foto_then_tune.sh p03_hoch titel_a_hoch > ~/f01tool/r2a.log 2>&1 </dev/null &'
```

Marken: `FOTO_DONE`, `--- tune`, `TUNE_DONE`, `RUN_DONE`. Neuen Pick in `picks_foto.txt` eintragen.

### 4. Feinschliff (tune) → Ulis Standard-Wahl

`folge01_manga.py tune picks_foto.txt` rendert `p10_quer` und `p07_quer` in 6 Varianten
(D60/D70/D80/S60/S85/C70). Läuft schon in Schritt 3 mit; sonst allein:

```
ssh pc 'cd ~/f01tool && setsid nohup python3 folge01_manga.py tune picks_foto.txt > tune.log 2>&1 </dev/null &'
scp 'pc:comfy_f01/tune/*.png' build/f01_tune/
```

Uli wählt den Standard (Folge 01: **D70** = Tiefe, denoise 0,7, Stärke 0,7 — das ist der Vorgabewert).

### 5. Manga-Vollrender (Runde 2)

```
ssh pc 'cd ~/f01tool && setsid nohup python3 folge01_manga.py full picks_foto.txt overrides_manga.txt > manga.log 2>&1 </dev/null &'
```

Marken: `OK/SKIP/ERR <key>`, `MANGA_DONE`. ≈ 130 s je Bild. `overrides_manga.txt` ändert nur, **wie**
ein Key gerendert wird (Ausdruck, Negativ, Zügel), nicht **ob**: Keys mit vorhandener Ausgabe in
`~/comfy_f01/manga/` werden übersprungen. Neu rendern nur mit dem Wort `force` in der Override-Zeile.

Abholen und Seite:

```
scp 'pc:comfy_f01/manga/*.png' build/f01_manga/
python3 tool/comic/rows_manga.py
python3 tool/comic/review_page.py build/f01_manga/runde2.html "Folge 01 · Runde 2" build/f01_manga/rows.json
```

### 6. Nachzug einzelner Keys (nach neuen Foto-Picks)

Nicht die volle Picks-Datei nochmal fahren, sondern eine **reduzierte** Picks-Datei nur mit den
betroffenen Keys, und vorher deren alte Ausgaben löschen (Regel unten):

```
grep -E '^(p06_hoch|p07_hoch)=' tool/comic/picks_foto.txt > build/picks_two.txt
scp build/picks_two.txt pc:f01tool/
ssh pc 'rm -f ~/comfy_f01/manga/p06_hoch_* ~/comfy_f01/manga/p07_hoch_*'
ssh pc 'cd ~/f01tool && setsid nohup python3 folge01_manga.py full picks_two.txt overrides_manga.txt > manga3.log 2>&1 </dev/null &'
```

### 7. Ulis Freigabe Runde 2 → `picks_manga.txt`

```
scp 'pc:comfy_f01/manga/*.png' build/f01_manga/
python3 tool/comic/finish_prep.py "Manga-Picks Folge 01 (Standard D70)"   # schreibt tool/comic/picks_manga.txt + Bogen
```

### 8. Vergrößern auf Auslieferungsgröße

```
scp tool/comic/picks_manga.txt tool/comic/run_finish.sh tool/comic/folge01_finish.py pc:f01tool/
ssh pc 'setsid nohup sh ~/f01tool/run_finish.sh > ~/f01tool/finish.log 2>&1 </dev/null &'
```

Marken: `--- finish`, `OK <key> (w, h)`, `FINISH_DONE`, `RUN_FINISH_DONE`. Ein Key wird nur
übersprungen, wenn `final/<key>.jpg` jünger ist als sein Manga-Bild. Abholen:

```
scp 'pc:comfy_f01/final/*.jpg' build/f01_raw/
ssh pc 'rm -f ~/.no-idle-suspend'
python3 tool/comic/check_bars.py build/f01_raw
```

### 9. Layout, Tippflächen, Lettering

```
python3 tool/comic/layout_preview.py          # Sichtprüfung: build/layout_preview_{quer,hoch}.png
python3 tool/comic/check_layout.py            # muss [] ausgeben
python3 tool/comic/gen_layout_dart.py         # schreibt + formatiert lib/features/story/episodes/folge_01_layout.g.dart
python3 tool/comic/letter_folge01.py          # 28 Dateien nach assets/story/folge01/
python3 tool/comic/letter_preview.py          # Sichtprüfung: build/letter_preview_{quer,hoch}.png
python3 tool/comic/letter_preview.py faces    # mit Gesichtern (rot), Nogo-Zonen (blau), sicherer Zone (gelb)
```

`gen_layout_dart.py` ruft am Ende selbst `dart format` auf (ohne `dart` bricht es ab). Die Reihenfolge
der Blasen in `folge01_layout.json` muss der in `folge_01_regen.dart` entsprechen.

Prüfregeln von `check_layout` (alle Meldungen werden gesammelt, dann bricht das Lettering ab):

- `GESICHT VERDECKT` — Blasen-Ellipse schneidet ein `faces`-Rechteck.
- `SICHERE ZONE` — Blase außerhalb des Bereichs, den das Cover-Beschneiden am Telefon stehen lässt
  (quer: y in 0,1–0,9; hoch: x in 0,1–0,9).
- `ÜBERLAGERUNG` — Blasen-Ellipse schneidet ein `nogo`-Rechteck. `nogo` (optional je Panel/Format,
  bildnormiert `[x, y, w, h]`) sind die Flächen, die die App über das Bild legt, gemessen am
  S23-Emulator (1080×2340, Dichte 2,625) im echten Vollbild:
  - Erzählkasten oben (jedes Panel mit `thoughts`): hoch volle Breite, y 0 bis Kastenunterkante +
    Rand (0,18 bei 2–3 Zeilen … 0,34 bei p01 mit 10 Zeilen); quer x 0–0,72 (Kasten ist dort auf 58 %
    der Schirmbreite gedeckelt, plus Kamera-Ausschnitt/Zurück-Chip), y 0 bis 0,26 … 0,42.
  - Mitmach-/Reaktionszeile unten (Panels mit `interactions`, p02/p05/p08): hoch y ab 0,86, quer y ab
    0,80, volle Breite.
  Ändern sich Erzähltexte oder Overlay-Layout in der App, die Zonen neu messen.
- `KLEINSCHRIFT` — die größte passende Schrift liegt unter der Mindestgröße (quer 34 px auf 1920
  breit, hoch 30 px auf 1080 breit). Abhilfe: Blase im Layout vergrößern oder für lange Aufzählungen
  `"lines": 4` setzen — nie die Schrift verkleinern.

### 10. App-Verdrahtung (Task 6)

Episode, Titelbild und Tippflächen verdrahten, dann:

```
flutter test test/features/story/folge_01_layout_test.dart test/features/story/folge_01_panel_assets_test.dart test/features/story/folge_01_regen_test.dart
```

## Regeln und Fallen

- **Vor jedem Neu-Render die alte Ausgabe löschen.** ComfyUI zählt den Dateizähler hoch
  (`_00001_` → `_00002_`), die alte Datei bleibt liegen, und die Skripte überspringen einen Key,
  sobald irgendeine Datei mit seinem Präfix existiert. `comfy_client.run()` setzt das Präfix doppelt
  in den Dateinamen (`p03_hoch_s704_p03_hoch_s704_00001_.png`) — beim Löschen mit `<prefix>_*` arbeiten.
- **Override ≠ Neu-Render.** Nur `force` (oder `force=1`) in der Override-Zeile erzwingt ihn.
- **nohup per ssh:** immer `setsid nohup … </dev/null &` — ohne `</dev/null` hängt der ssh-Client,
  ohne `setsid` stirbt der Lauf mit der Verbindung.
- **pkill per ssh:** das Suchmuster darf nicht im eigenen ssh-Kommando vorkommen, sonst trifft
  `pkill -f` die eigene Shell. Klammer-Trick: `ssh pc 'pkill -f "[f]olge01_manga.py"'`.
- **Box schlafen legen / ComfyUI hängt:** siehe Spec §11 (Kill-Switch, Modellwechsel = ComfyUI-Neustart).
- **Mira nachdenklich, nicht traurig** (Uli 29.9.): Ausdruck über `extra=`/`neg=` in `overrides_manga.txt`.

## Dateien

| Datei | Wo | Zweck |
|---|---|---|
| `comfy_client.py` | Box | HTTP-Client + Graphen (t2i, manga, upscale) |
| `folge01_motifs.py` | Box | Prompt-Kerne, Figuren, `HOCH_FIX` (Nachrender) |
| `folge01_foto.py` | Box | Runde 1 Foto, Overrides `overrides_foto.txt` |
| `folge01_manga.py` | Box | Feinschliff (`tune`) und Vollrender (`full`), Overrides `overrides_manga.txt` |
| `folge01_finish.py` | Box | Vergrößern + JPEG |
| `run_foto_then_tune.sh`, `run_finish.sh` | Box | Lauf-Wrapper mit Log-Marken |
| `sheet.py` | beide | Kontaktbogen |
| `make_sheets.py`, `rows_foto.py`, `rows_manga.py`, `review_page.py` | NUC | Bögen und Vergleichsseiten |
| `check_bars.py` | NUC | Balken-Check (schwarze Ränder) |
| `finish_prep.py` | NUC | `picks_manga.txt` + Bogen |
| `folge01_layout.json`, `check_layout.py`, `layout_preview.py` | NUC | Blasen-Layout + Prüfung |
| `gen_layout_dart.py` | NUC | Tippflächen-Dart aus dem Layout |
| `letter_folge01.py`, `letter_preview.py` | NUC | Lettering + Sichtprüfung |

Tests: `cd tool/comic && python3 -W error::ResourceWarning -m unittest discover -s . -p "test_*.py" -v`
