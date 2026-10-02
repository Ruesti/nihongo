# Café-Bilder im Manga-Weg — Implementation Plan (Plan 3 von 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die 38 Café-Motive entstehen auf demselben Weg wie die Panels der Folge (Foto → Manga mit Tiefen-Zügel → Hochbild aus dem Kern) und liegen in beiden Formaten in der App; die Szenen-Bibliothek kennt das Format.

**Architecture:** Die Hochbild-Ableitung aus `folge01_hoch.py` wird ein gemeinsames Modul `hoch_derive.py` (ein Code, zwei Aufrufer). Ein Café-Treiber `cafe_manga.py` auf der Box hat Unterbefehle je Stufe (`foto`, `gate`, `lights`, `manga`, `hoch`, `finish`), jede Stufe endet mit einer Marke und einem Kontaktbogen; Uli pickt zwischen den Stufen. Die App bekommt neben der Quer-Tabelle eine Hoch-Tabelle und `sceneFor(motif, light, format)`, das bei fehlendem Hochbild das Querbild meldet (Plan 4 passt es dann ein).

**Tech Stack:** Python 3 + Pillow + ComfyUI-HTTP (`comfy_client.py`) auf der GPU-Box, `unittest` ohne Box (cc.run ersetzt); Flutter/Dart für die Bibliothek.

**Spec:** `docs/superpowers/specs/2026-10-02-mira-schweigt-erzaehl-mal-cafe-manga-design.md` (§6.1, §6.2, §7, §8 INV-17, §12 Plan 3). Rezept-Quellen: Manga-Vollbild-Spec §2.2 (Manga-Durchgang) und §12 (Hochbild), Café-Szenen-Spec §3.2 (Bibliothek) und §5.6 (Figurenbeschreibungen).

**Basis:** frischer Branch `impl/cafe-bilder-manga` von `origin/main`; Spec und dieser Plan per `git checkout origin/design/mira-schweigt-cafe-manga -- <spec> <plan>` mitnehmen. Unabhängig von Plan 1.

## Global Constraints

- Render-Maß quer **1664 × 928**, hoch **928 × 1664**; Auslieferung quer **1920 × 1072**, hoch **1080 × 1936**, JPEG q88.
- Foto: Look A, LoRA `shotengai_style_ckpt6` **0,3**, `PHOTO`-Zusatz und `NEG` aus `cafe_motifs.py`, Seeds **901, 902**.
- Manga: `cc.manga_graph`, Tiefe, **denoise 0,7, Zügel 0,7, end 0,8, LoRA 1,5**, Seed = Seed des Fotos (Standard „D70“ wie bei den Panels).
- Hochbild: `kern_geometry` unverändert (Fenster 31 % der Breite, `BOTTOM` 128, Schritte ≤ 480), Rezept Manga-Vollbild §12.4.
- Figurenbeschreibungen `LAND`, `GIRL`, `MAN`, `YW` und `CAFE` in `cafe_motifs.py` werden NIE geändert.
- Dateinamen in der App: quer `assets/comic/cafe/{stem}_{licht}.jpg`, hoch `assets/comic/cafe/{stem}_{licht}_hoch.jpg`. Lichter `tag`, `regen`, `abend`, `nacht`.
- Bibliothek (Spec §3.2 der Café-Szenen-Spec): `FULL` (6 Motive) in 4 Lichtern, `MOMENTS` (7 Motive) in `tag` + `abend` = 38 Motive, 76 Dateien.
- Mira nie im Bild, keine Nahaufnahmen, keine Gruppen.
- Box-Betrieb: vor langen Läufen `ssh pc touch ~/.no-idle-suspend`, danach `ssh pc rm ~/.no-idle-suspend`; Box wecken mit `wakegpu`; Modellwechsel Basis ↔ Edit (Relight) nie im selben Lauf ohne `systemctl --user restart comfyui` dazwischen (OOM-Falle, Manga-Vollbild §11). Werkzeuge liegen auf der Box in `~/cafe_tools` (per `scp tool/comic/*.py pc:~/cafe_tools/`).
- Bögen an Uli: Kopie nach `~/<name>.png` auf dem NUC, im Chat zeigen; Uli pickt. Keine `/jobs`-Pfade als Abgabe.
- Python-Tests: `cd tool/comic && python3 -W error::ResourceWarning -m unittest discover -s . -p "test_*.py" -v`.
- Flutter-Tests: Einzeldateien auf dem NUC (`~/flutter/bin/flutter test <datei>`), Vollsuite auf der Box; grün = „+N −8“ (8 bekannte Native-Tokenizer-Tests).

## Review Focus

1. **Relight liefert ein anderes Maß als 1664 × 928** — vor dem Manga-Durchgang wird auf das Render-Maß gebracht (Mitte beschneiden, dann skalieren), nie verzerrt. Test in Task 3 (`normalize`).
2. **Pick zeigt auf eine fehlende oder falsch große Datei** — Abbruch mit `FEHLT`/Maß-Meldung vor jedem Render, nicht still überspringen. Test in Task 3.
3. **Hochbild fehlt in der App** (Übergang, Runde 2 noch nicht da) — `sceneFor(..., portrait)` meldet das Querbild mit `format == landscape`, nie einen Pfad auf eine nicht gebündelte Datei. Test in Task 4.
4. **Figur sitzt rechts im Querbild** und wird in Plan 4 von der Fläche (rechtes Drittel) verdeckt — die Foto-Prompts tragen den Kompositions-Satz, und der Pick-Bogen markiert das rechte Drittel. Test in Task 2 (jeder Figuren-Prompt enthält den Satz).
5. **Kern fehlt für ein Motiv/Licht** — `hoch` bricht mit Meldung ab, statt ein zentriertes Fenster zu raten. Test in Task 3.

---

## File Structure

| Datei | Verantwortung | Task |
|---|---|---|
| `tool/comic/hoch_derive.py` (neu) | Hochbild aus Querbild: Fenster/Streifen, Verlängern unten + oben | 1 |
| `tool/comic/folge01_hoch.py` | ruft `hoch_derive` (dünne Hüllen `strip_image`, `extend` bleiben) | 1 |
| `tool/comic/test_hoch_derive.py` (neu) | Tests des Moduls | 1 |
| `tool/comic/cafe_motifs.py` | Manga-Prompts, Kompositions-Satz, Hoch-Umgebung je Licht, Schlüssel-Helfer | 2 |
| `tool/comic/cafe_layout.json` (neu) | Kern je Motiv (optional je Motiv+Licht) | 2, 6 |
| `tool/comic/test_cafe_motifs.py` (neu) | Prompt- und Matrix-Tests | 2 |
| `tool/comic/cafe_manga.py` (neu) | Treiber auf der Box: foto, gate, lights, manga, hoch, finish | 3 |
| `tool/comic/test_cafe_manga.py` (neu) | Treiber-Tests ohne Box | 3 |
| `tool/comic/cafe_library.py`, `cafe_assemble.py`, `cafe_relight_probe.py` | gelöscht (abgelöst) | 8 |
| `lib/features/cafe/cafe_scenes.dart` | Hoch-Tabelle, `CafeScene`, `sceneFor` | 4, 6, 7 |
| `test/features/cafe/cafe_scenes_test.dart`, `cafe_scenes_assets_test.dart` | Logik + Tabelle ⇔ Dateien, beide Formate | 4 |
| `assets/comic/cafe/*.jpg` | 76 Dateien | 6, 7 |
| `tool/comic/README.md` | Abschnitt „Café“ | 8 |

---

### Task 1: `hoch_derive.py` — gemeinsame Hochbild-Ableitung

**Files:**
- Create: `tool/comic/hoch_derive.py`
- Modify: `tool/comic/folge01_hoch.py` (Funktionen `strip_image`, `_to_input`, `extend` werden Hüllen)
- Test: `tool/comic/test_hoch_derive.py` (neu); `tool/comic/test_hoch.py` bleibt unverändert grün

**Interfaces:**
- Produces:
  - `hoch_derive.strip_image(im: Image, plan: dict) -> Image`
  - `hoch_derive.derive(src_img: Image, kern: list[float], out_path: str, *, prompt_bottom: str, prompt_top: str, neg_bottom: str, neg_top: str, seed: int, tag: str, tmp_dir: str, client_id: str) -> str` (gibt `"crop"` oder `"extend"` zurück; schreibt `out_path` als PNG 928 × 1664 bzw. Fenster in Originalauflösung bei `crop`)
  - Konstanten `FEATHER_UNTEN = 96`, `FEATHER_OBEN = 64`

- [ ] **Step 1: Write the failing test**

`tool/comic/test_hoch_derive.py`:

```python
#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_hoch_derive (ohne Box: cc.run wird ersetzt)"""
import os
import tempfile
import unittest

from PIL import Image

import comfy_client as cc
import hoch_derive as hd
import kern_geometry as kg


def solid(w, h, rgb=(40, 120, 200)):
    return Image.new("RGB", (w, h), rgb)


class DeriveTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.calls = []
        self._saved = (cc.COMFY_INPUT, cc.run)
        cc.COMFY_INPUT = os.path.join(self.tmp.name, "input")
        os.makedirs(cc.COMFY_INPUT)

        def fake_run(graph, prefix, out_dir, client_id="x"):
            pad = graph["PAD"]["inputs"]
            src = os.path.join(cc.COMFY_INPUT, graph["IN"]["inputs"]["image"])
            with Image.open(src) as im:
                w, h = im.size
            self.calls.append((prefix, pad["top"], pad["bottom"], graph["4"]["inputs"]["text"]))
            os.makedirs(out_dir, exist_ok=True)
            p = os.path.join(out_dir, prefix + "_00001_.png")
            solid(w, h + pad["top"] + pad["bottom"]).save(p)
            return [p]

        cc.run = fake_run

    def tearDown(self):
        cc.COMFY_INPUT, cc.run = self._saved
        self.tmp.cleanup()

    def _derive(self, kern):
        out = os.path.join(self.tmp.name, "out.png")
        mode = hd.derive(solid(*kg.QUER), kern, out, prompt_bottom="PB", prompt_top="PT",
                         neg_bottom="NB", neg_top="NT", seed=5, tag="t", tmp_dir=os.path.join(self.tmp.name, "tmp"),
                         client_id="test")
        return mode, out

    def test_crop_needs_no_box(self):
        mode, out = self._derive([0.40, 0.55])
        self.assertEqual(mode, "crop")
        self.assertEqual(self.calls, [])
        with Image.open(out) as im:
            self.assertEqual(im.size, (kg.window_width(*kg.QUER), kg.QUER[1]))

    def test_extend_runs_bottom_then_top_and_ends_928x1664(self):
        mode, out = self._derive([0.10, 0.90])
        self.assertEqual(mode, "extend")
        plan = kg.plan_for([0.10, 0.90])
        self.assertEqual(self.calls[0][1:3], (0, plan["bottom"]))
        self.assertEqual(self.calls[0][3], "shotengai_style, PB")
        self.assertEqual([c[1] for c in self.calls[1:]], plan["top_steps"])
        self.assertTrue(all(c[3] == "shotengai_style, PT" for c in self.calls[1:]))
        with Image.open(out) as im:
            self.assertEqual(im.size, kg.HOCH)

    def test_wrong_source_size_raises(self):
        with self.assertRaises(ValueError):
            hd.derive(solid(1216, 832), [0.4, 0.5], os.path.join(self.tmp.name, "x.png"),
                      prompt_bottom="", prompt_top="", neg_bottom="", neg_top="", seed=1, tag="t",
                      tmp_dir=self.tmp.name, client_id="t")


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd tool/comic && python3 -m unittest test_hoch_derive -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'hoch_derive'`.

- [ ] **Step 3: Write the module and switch `folge01_hoch.py` to it**

`tool/comic/hoch_derive.py`:

```python
#!/usr/bin/env python3
"""Hochbild aus dem Querbild (Manga-Vollbild-Spec §12) — gemeinsam für Folge und Café.
Beschnitt (Kern passt ins Fenster) braucht keine Box. Verlängern: Kernstreifen 928 breit, unten
BOTTOM px mit Figuren-Prompt, oben in Schritten ≤ STEP_MAX mit Umgebungs-Prompt (outpaint_graph).
Prompts kommen vom Aufrufer; comfy_client setzt „shotengai_style, " davor."""
import os
import shutil

from PIL import Image

import comfy_client as cc
import kern_geometry as kg

FEATHER_UNTEN, FEATHER_OBEN = 96, 64


def strip_image(im, plan):
    """Fenster (crop, Originalauflösung) bzw. Kernstreifen (extend, 928 × strip_h) aus dem Querbild."""
    W, H = im.size
    part = im.crop((plan["x0"], 0, plan["x1"], H))
    if plan["mode"] == "crop":
        return part
    return part.resize((kg.HOCH[0], plan["strip_h"]), Image.LANCZOS)


def to_input(path_or_img, name):
    dest = os.path.join(cc.COMFY_INPUT, name)
    if isinstance(path_or_img, str):
        shutil.copy(path_or_img, dest)
    else:
        path_or_img.save(dest)
    return name


def extend(strip, plan, out_path, *, prompt_bottom, prompt_top, neg_bottom, neg_top, seed, tag,
           tmp_dir, client_id):
    cur = to_input(strip, "hoch_%s.png" % tag)
    last_file = None
    if plan["bottom"]:
        got = cc.run(cc.outpaint_graph(cur, 0, plan["bottom"], prompt_bottom, neg_bottom, seed,
                                       "%s_hochB" % tag, feather=FEATHER_UNTEN),
                     "%s_hochB" % tag, tmp_dir, client_id)
        last_file = got[0]
        cur = to_input(last_file, "hoch_%s_B.png" % tag)
    steps = plan["top_steps"]
    for i, top in enumerate(steps):
        last = i == len(steps) - 1
        prefix = "%s_hoch" % tag if last else "%s_hochT%d" % (tag, i + 1)
        got = cc.run(cc.outpaint_graph(cur, top, 0, prompt_top, neg_top, seed + i, prefix,
                                       feather=FEATHER_OBEN), prefix, tmp_dir, client_id)
        last_file = got[0]
        if not last:
            cur = to_input(last_file, "hoch_%s_T%d.png" % (tag, i + 1))
    if last_file is None:
        strip.save(out_path)
    else:
        shutil.copy(last_file, out_path)


def derive(src_img, kern, out_path, *, prompt_bottom, prompt_top, neg_bottom, neg_top, seed, tag,
           tmp_dir, client_id):
    """Schreibt das Hochbild nach out_path; gibt "crop" oder "extend" zurück."""
    if src_img.size != kg.QUER:
        raise ValueError("%s: Quelle ist %s, erwartet %s (Render-Maß)" % (tag, src_img.size, kg.QUER))
    os.makedirs(tmp_dir, exist_ok=True)
    plan = kg.plan_for(kern)
    strip = strip_image(src_img.convert("RGB"), plan)
    if plan["mode"] == "crop":
        strip.save(out_path)
        return "crop"
    extend(strip, plan, out_path, prompt_bottom=prompt_bottom, prompt_top=prompt_top,
           neg_bottom=neg_bottom, neg_top=neg_top, seed=seed, tag=tag, tmp_dir=tmp_dir,
           client_id=client_id)
    return "extend"
```

In `tool/comic/folge01_hoch.py`: `import hoch_derive as hd`; die Körper ersetzen durch

```python
def strip_image(im, plan):
    return hd.strip_image(im, plan)


def _to_input(path_or_img, name):
    return hd.to_input(path_or_img, name)


def extend(motif, strip, plan, seed, out_path):
    hd.extend(strip, plan, out_path,
              prompt_bottom=prompt_for(motif + "_hoch") + HOCH_HINT_UNTEN,
              prompt_top=STY + ", empty background only, " + HOCH_UMGEBUNG[motif]
              + ", vertical framing, tall composition",
              neg_bottom=NEG_MANGA + NEG_HOCH_UNTEN, neg_top=NEG_MANGA + NEG_HOCH_OBEN,
              seed=seed, tag=motif, tmp_dir=TMP, client_id="f01hoch")
```

und `FEATHER_UNTEN, FEATHER_OBEN` aus `hd` beziehen (die lokale Zeile löschen). `main()` bleibt unverändert.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd tool/comic && python3 -W error::ResourceWarning -m unittest test_hoch_derive test_hoch test_kern_geometry test_kern_tools -v`
Expected: PASS (auch alle bestehenden `test_hoch`-Fälle — das Verhalten von `folge01_hoch` ist unverändert).

- [ ] **Step 5: Commit**

```bash
git add tool/comic/hoch_derive.py tool/comic/folge01_hoch.py tool/comic/test_hoch_derive.py
git commit -m "refactor(comic): Hochbild-Ableitung als gemeinsames Modul hoch_derive"
```

---

### Task 2: Café-Prompts für Manga und Hochbild, Kern-Datei

**Files:**
- Modify: `tool/comic/cafe_motifs.py`
- Create: `tool/comic/cafe_layout.json`
- Test: `tool/comic/test_cafe_motifs.py` (neu)

**Interfaces:**
- Produces (in `cafe_motifs.py`):
  - `ALL_MOTIFS: list[str]` = `FULL + MOMENTS` (13)
  - `LIGHTS = ["tag", "regen", "abend", "nacht"]`
  - `all_lights(motif) -> list[str]` = `["tag"] + lights_for(motif)`
  - `core(motif) -> str` (aus `EXISTING_TAG` ∪ `TAG_MOTIFS`)
  - `COMPOSE = ", the person sits or stands in the left half of the picture, the right third of the picture is calm background"`
  - `foto_prompt(motif, light) -> (pos, neg)`; `manga_prompt(motif, light) -> (pos, neg)`; `hoch_prompts(motif, light) -> dict(prompt_bottom, prompt_top, neg_bottom, neg_top)`
  - `split_key(key) -> (motif, light)` für Schlüssel `<motif>_<light>`
- `cafe_layout.json`: `{"kern": {"<motif>": [x0, x1], "<motif>_<light>": [x0, x1]}}`; `kern_for(layout, key)` in `cafe_manga.py` (Task 3) nimmt erst `<motif>_<light>`, dann `<motif>`.

- [ ] **Step 1: Write the failing test**

`tool/comic/test_cafe_motifs.py`:

```python
#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_cafe_motifs"""
import json
import os
import unittest

import cafe_motifs as m

HERE = os.path.dirname(os.path.abspath(__file__))


class CafeMotifsTest(unittest.TestCase):
    def test_matrix_is_38(self):
        self.assertEqual(len(m.ALL_MOTIFS), 13)
        self.assertEqual(sum(len(m.all_lights(x)) for x in m.ALL_MOTIFS), 38)
        self.assertEqual(m.all_lights("leer"), ["tag", "regen", "abend", "nacht"])
        self.assertEqual(m.all_lights("wirtin_tee"), ["tag", "abend"])

    def test_split_key_handles_underscored_motifs(self):
        self.assertEqual(m.split_key("schulkind_hausaufgaben_abend"), ("schulkind_hausaufgaben", "abend"))
        self.assertEqual(m.split_key("leer_tag"), ("leer", "tag"))
        with self.assertRaises(KeyError):
            m.split_key("leer_mittag")

    def test_figure_prompts_carry_identity_and_composition(self):
        for motif in m.ALL_MOTIFS:
            for light in m.all_lights(motif):
                pos, neg = m.foto_prompt(motif, light)
                self.assertIn(m.CAFE, pos)
                self.assertTrue(pos.endswith(m.PHOTO))
                if motif != "leer":
                    self.assertIn(m.COMPOSE, pos, motif)
                    self.assertTrue(any(f in pos for f in (m.LAND, m.GIRL, m.MAN, m.YW)), motif)
                mpos, mneg = m.manga_prompt(motif, light)
                self.assertTrue(mpos.startswith(m.STY), motif)
                self.assertIn("photo", mneg)
                if light != "tag":
                    self.assertIn(m.T2I_LIGHT[light], mpos)

    def test_hoch_prompts_keep_people_out_of_the_top(self):
        h = m.hoch_prompts("wirtin_tresen", "nacht")
        self.assertIn("people", h["neg_top"])
        self.assertNotIn("people", h["neg_bottom"])
        self.assertIn("ceiling", h["prompt_top"])
        self.assertIn(m.T2I_LIGHT["nacht"], h["prompt_top"])

    def test_layout_file_parses(self):
        with open(os.path.join(HERE, "cafe_layout.json"), encoding="utf-8") as f:
            data = json.load(f)
        for key, (x0, x1) in data["kern"].items():
            self.assertTrue(0 <= x0 < x1 <= 1, key)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd tool/comic && python3 -m unittest test_cafe_motifs -v`
Expected: FAIL — `AttributeError: module 'cafe_motifs' has no attribute 'ALL_MOTIFS'`.

- [ ] **Step 3: Write minimal implementation**

An `tool/comic/cafe_motifs.py` anhängen:

```python
# --- Manga-Weg (Spec Mira schweigt/Café §6.1) ---------------------------------------------
from folge01_motifs import HOCH_HINT_UNTEN, NEG_HOCH_OBEN, NEG_HOCH_UNTEN, NEG_MANGA, STY  # noqa: E402

ALL_MOTIFS = FULL + MOMENTS
LIGHTS = ["tag", "regen", "abend", "nacht"]
COMPOSE = (", the person sits or stands in the left half of the picture, "
           "the right third of the picture is calm background")
CAFE_CEILING = ("the old cafe ceiling with dark wooden beams and warm pendant bulbs, "
                "upper walls with a shelf and a wall clock")


def all_lights(motif):
    return ["tag"] + lights_for(motif)


def core(motif):
    table = {**EXISTING_TAG, **TAG_MOTIFS}
    if motif not in table:
        raise KeyError(motif)
    return table[motif]


def split_key(key):
    """'<motif>_<light>' → (motif, light); Motive enthalten selbst Unterstriche."""
    motif, _, light = key.rpartition("_")
    if motif not in ALL_MOTIFS or light not in all_lights(motif):
        raise KeyError(key)
    return motif, light


def _light(light):
    return "" if light == "tag" else T2I_LIGHT[light]


def foto_prompt(motif, light):
    compose = "" if motif == "leer" else COMPOSE
    return core(motif) + compose + _light(light) + PHOTO, negative_for(motif)


def manga_prompt(motif, light):
    """Positiv beginnt mit STY (comfy_client setzt „shotengai_style, " davor)."""
    compose = "" if motif == "leer" else COMPOSE
    return STY + ", " + core(motif) + compose + _light(light), NEG_MANGA


def hoch_prompts(motif, light):
    pos, _ = manga_prompt(motif, light)
    return {
        "prompt_bottom": pos + HOCH_HINT_UNTEN,
        "prompt_top": STY + ", empty background only, " + CAFE_CEILING + _light(light)
        + ", vertical framing, tall composition",
        "neg_bottom": NEG_MANGA + NEG_HOCH_UNTEN,
        "neg_top": NEG_MANGA + NEG_HOCH_OBEN,
    }
```

(Der Import steht unten, weil `folge01_motifs` nichts aus `cafe_motifs` braucht — kein Zyklus. Prüfen, dass `HOCH_HINT_UNTEN` nicht „people“ enthält; `NEG_HOCH_OBEN` enthält „people“, `NEG_HOCH_UNTEN` nicht — so in `folge01_motifs.py` Zeilen 49–54.)

`tool/comic/cafe_layout.json` — Startwerte (werden in Task 6 nach Sicht gesetzt; Startwert = mittleres Fenster der linken Hälfte, weil `COMPOSE` die Figur dorthin legt):

```json
{
  "kern": {
    "leer": [0.30, 0.61],
    "wirtin_tresen": [0.15, 0.46],
    "wirtin_tisch": [0.15, 0.46],
    "wirtin_tee": [0.15, 0.46],
    "schulkind_nische": [0.15, 0.46],
    "schulkind_hausaufgaben": [0.15, 0.46],
    "schulkind_kakao": [0.15, 0.46],
    "vielredner_zeitung": [0.15, 0.46],
    "vielredner_gefaltet": [0.15, 0.46],
    "vielredner_fenster": [0.15, 0.46],
    "gleichaltrige_kaffee": [0.15, 0.46],
    "gleichaltrige_haende": [0.15, 0.46],
    "gleichaltrige_fenster": [0.15, 0.46]
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd tool/comic && python3 -W error::ResourceWarning -m unittest test_cafe_motifs test_motifs -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tool/comic/cafe_motifs.py tool/comic/cafe_layout.json tool/comic/test_cafe_motifs.py
git commit -m "feat(comic): Café-Prompts für Manga und Hochbild, Kern-Datei"
```

---

### Task 3: Treiber `cafe_manga.py`

**Files:**
- Create: `tool/comic/cafe_manga.py`
- Test: `tool/comic/test_cafe_manga.py` (neu)

**Interfaces:**
- Consumes: `cafe_motifs` (Task 2), `hoch_derive.derive` (Task 1), `comfy_client.{t2i_graph, relight_graph, manga_graph, upscale_graph, run, COMFY_INPUT}`, `kern_geometry.QUER/HOCH`.
- Produces (Box-Verzeichnis `ROOT = ~/comfy_cafe`):
  - `foto [motif ...]` → `ROOT/foto/<motif>_tag_s<seed>_*.png`, Bogen `foto_sheet.png`, Marke `CAFE_FOTO_DONE`
  - `gate PICKS` (Zeilen `<motif>_tag=<pfad>`) → je Motiv Weg R und Weg T in allen vier Lichtern, schon im Manga-Look; Bogen `gate_sheet.png` (Zeile = Motiv × Weg, Spalten tag/regen/abend/nacht), Marke `CAFE_GATE_DONE`
  - `lights R|T PICKS` (Zeilen `<motif>_tag=<pfad>`) → Fotos der übrigen Lichter des Motivs nach `ROOT/foto_light/<motif>_<light>_s<seed>_*.png` (R: Relight des Tag-Fotos, Seed 11; T: Text-zu-Bild, Seeds 901/902), Bogen `lights_sheet.png`, Marke `CAFE_LIGHTS_DONE`
  - `manga PICKS [OVERRIDES]` (Zeilen `<motif>_<light>=<foto>`) → `ROOT/manga/<key>.png` (fester Name), Bogen `manga_sheet.png` (Foto | Manga), Marke `CAFE_MANGA_DONE`; Overrides wie `folge01_manga.load_overrides` (Felder `seed`, `denoise`, `strength`, `control`, `extra`, `neg`, `force`)
  - `hoch PICKS` (Zeilen `<key>=<manga>`, Kern aus `cafe_layout.json`) → `ROOT/hoch/<key>_hoch.png`, Bogen `hoch_sheet.png` (quer | hoch), Marke `CAFE_HOCH_DONE`
  - `finish PICKS` → `ROOT/final/<key>.jpg` (1920 × 1072) und `<key>_hoch.jpg` (1080 × 1936), Marke `CAFE_FINISH_DONE`
  - reine Helfer: `seed_of(path) -> int` (aus `_s<zahl>_`, sonst 901), `normalize(im) -> Image` (Mitte beschneiden auf 1664:928, dann auf 1664 × 928), `read_picks(path, want_size=None) -> dict[key, path]` (prüft Existenz und optional Maß), `kern_for(layout, key) -> list[float]`

- [ ] **Step 1: Write the failing test**

`tool/comic/test_cafe_manga.py`:

```python
#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_cafe_manga (ohne Box: cc.run wird ersetzt)"""
import os
import tempfile
import unittest

from PIL import Image

import cafe_manga as cm
import comfy_client as cc
import kern_geometry as kg


class Helpers(unittest.TestCase):
    def test_seed_of(self):
        self.assertEqual(cm.seed_of("/x/leer_tag_s902_00001_.png"), 902)
        self.assertEqual(cm.seed_of("/x/irgendwas.png"), 901)

    def test_normalize_crops_center_then_scales(self):
        im = Image.new("RGB", (1024, 1024), (0, 0, 0))
        out = cm.normalize(im)
        self.assertEqual(out.size, kg.QUER)
        same = cm.normalize(Image.new("RGB", kg.QUER))
        self.assertEqual(same.size, kg.QUER)

    def test_kern_for_prefers_light_specific(self):
        layout = {"kern": {"leer": [0.3, 0.6], "leer_nacht": [0.2, 0.5]}}
        self.assertEqual(cm.kern_for(layout, "leer_nacht"), [0.2, 0.5])
        self.assertEqual(cm.kern_for(layout, "leer_tag"), [0.3, 0.6])
        with self.assertRaises(KeyError):
            cm.kern_for(layout, "wirtin_tresen_tag")

    def test_read_picks_checks_files_and_size(self):
        with tempfile.TemporaryDirectory() as d:
            good = os.path.join(d, "a.png")
            Image.new("RGB", kg.QUER).save(good)
            small = os.path.join(d, "b.png")
            Image.new("RGB", (100, 100)).save(small)
            picks = os.path.join(d, "p.txt")
            with open(picks, "w") as f:
                f.write("# k\nleer_tag=%s\n" % good)
            self.assertEqual(cm.read_picks(picks, kg.QUER), {"leer_tag": good})
            with open(picks, "w") as f:
                f.write("leer_tag=%s\n" % os.path.join(d, "fehlt.png"))
            with self.assertRaises(FileNotFoundError):
                cm.read_picks(picks)
            with open(picks, "w") as f:
                f.write("leer_tag=%s\n" % small)
            with self.assertRaises(ValueError):
                cm.read_picks(picks, kg.QUER)
            with open(picks, "w") as f:
                f.write("leer_mittag=%s\n" % good)
            with self.assertRaises(KeyError):
                cm.read_picks(picks)


class Stages(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.graphs = []
        self._saved = (cm.ROOT, cc.COMFY_INPUT, cc.run, cm.LAYOUT)
        cm.ROOT = os.path.join(self.tmp.name, "root")
        cc.COMFY_INPUT = os.path.join(self.tmp.name, "input")
        os.makedirs(cc.COMFY_INPUT)

        def fake_run(graph, prefix, out_dir, client_id="x"):
            self.graphs.append((prefix, graph))
            os.makedirs(out_dir, exist_ok=True)
            size = kg.QUER
            if "PAD" in graph:
                with Image.open(os.path.join(cc.COMFY_INPUT, graph["IN"]["inputs"]["image"])) as im:
                    w, h = im.size
                p = graph["PAD"]["inputs"]
                size = (w, h + p["top"] + p["bottom"])
            if graph.get("5", {}).get("class_type") == "SaveImage" and "4" in graph \
                    and graph["4"]["class_type"] == "ImageScale":
                size = (graph["4"]["inputs"]["width"], graph["4"]["inputs"]["height"])
            path = os.path.join(out_dir, prefix + "_00001_.png")
            Image.new("RGB", size, (90, 90, 90)).save(path)
            return [path]

        cc.run = fake_run

    def tearDown(self):
        cm.ROOT, cc.COMFY_INPUT, cc.run, cm.LAYOUT = self._saved
        self.tmp.cleanup()

    def _picks(self, lines):
        p = os.path.join(self.tmp.name, "picks.txt")
        with open(p, "w") as f:
            f.write("\n".join(lines) + "\n")
        return p

    def _img(self, name, size=kg.QUER):
        p = os.path.join(self.tmp.name, name)
        Image.new("RGB", size).save(p)
        return p

    def test_manga_uses_d70_and_seed_of_the_photo(self):
        src = self._img("wirtin_tresen_tag_s902_00001_.png")
        cm.manga(self._picks(["wirtin_tresen_tag=%s" % src]))
        prefix, g = self.graphs[0]
        self.assertEqual(g["7"]["inputs"]["seed"], 902)
        self.assertEqual(g["7"]["inputs"]["denoise"], 0.7)
        self.assertEqual(g["CA"]["inputs"]["strength"], 0.7)
        self.assertTrue(os.path.exists(os.path.join(cm.ROOT, "manga", "wirtin_tresen_tag.png")))

    def test_hoch_requires_kern_and_writes_fixed_name(self):
        layout = os.path.join(self.tmp.name, "layout.json")
        with open(layout, "w") as f:
            f.write('{"kern": {"leer": [0.40, 0.55]}}')
        cm.LAYOUT = layout
        src = self._img("m.png")
        cm.hoch(self._picks(["leer_tag=%s" % src]))
        self.assertTrue(os.path.exists(os.path.join(cm.ROOT, "hoch", "leer_tag_hoch.png")))
        with self.assertRaises(KeyError):
            cm.hoch(self._picks(["wirtin_tresen_tag=%s" % src]))

    def test_finish_writes_both_formats_in_delivery_size(self):
        q = self._img("q.png")
        os.makedirs(os.path.join(cm.ROOT, "hoch"))
        Image.new("RGB", kg.HOCH).save(os.path.join(cm.ROOT, "hoch", "leer_tag_hoch.png"))
        cm.finish(self._picks(["leer_tag=%s" % q]))
        with Image.open(os.path.join(cm.ROOT, "final", "leer_tag.jpg")) as im:
            self.assertEqual(im.size, (1920, 1072))
        with Image.open(os.path.join(cm.ROOT, "final", "leer_tag_hoch.jpg")) as im:
            self.assertEqual(im.size, (1080, 1936))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd tool/comic && python3 -m unittest test_cafe_manga -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'cafe_manga'`.

- [ ] **Step 3: Write the driver**

`tool/comic/cafe_manga.py`:

```python
#!/usr/bin/env python3
"""Café-Bibliothek im Manga-Weg (Spec Mira schweigt/Café §6.1). Läuft auf der Box in ~/cafe_tools.
  cafe_manga.py foto [motif ...]          Tag-Fotos 1664×928, Seeds 901/902        → CAFE_FOTO_DONE
  cafe_manga.py gate PICKS                Weg R und T in 4 Lichtern, im Manga-Look → CAFE_GATE_DONE
  cafe_manga.py lights R|T PICKS          Fotos der übrigen Lichter je Motiv        → CAFE_LIGHTS_DONE
  cafe_manga.py manga PICKS [OVERRIDES]   Manga D70 (Tiefe), Seed des Fotos         → CAFE_MANGA_DONE
  cafe_manga.py hoch PICKS                Hochbild aus dem Kern (cafe_layout.json)  → CAFE_HOCH_DONE
  cafe_manga.py finish PICKS              Auslieferung quer 1920×1072, hoch 1080×1936 → CAFE_FINISH_DONE
PICKS-Zeilen: <motif>_<licht>=<pfad>. Jede Stufe schreibt einen Kontaktbogen nach ROOT/<stufe>_sheet.png."""
import json
import os
import re
import shutil
import subprocess
import sys

from PIL import Image

import comfy_client as cc
import hoch_derive as hd
import kern_geometry as kg
from cafe_motifs import (ALL_MOTIFS, LORA_STRENGTH, RELIGHT, all_lights, foto_prompt, hoch_prompts,
                         manga_prompt, split_key)
from folge01_manga import load_overrides

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.expanduser("~/comfy_cafe")
LAYOUT = os.path.join(HERE, "cafe_layout.json")
SEEDS = (901, 902)
RELIGHT_SEED = 11
TARGET = {"quer": (1920, 1072), "hoch": (1080, 1936)}
SEED_RE = re.compile(r"_s(\d+)_")
MANGA_KEYS = frozenset({"control", "seed", "denoise", "strength", "extra", "neg", "force"})


# --- reine Helfer ---------------------------------------------------------------------------
def seed_of(path):
    m = SEED_RE.search(os.path.basename(path))
    return int(m.group(1)) if m else SEEDS[0]


def normalize(im):
    """Auf das Render-Maß: Mitte auf 1664:928 beschneiden, dann skalieren — nie verzerren."""
    tw, th = kg.QUER
    w, h = im.size
    if (w, h) == (tw, th):
        return im
    if w / h > tw / th:
        nw = int(round(h * tw / th))
        im = im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    else:
        nh = int(round(w * th / tw))
        im = im.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))
    return im.resize((tw, th), Image.LANCZOS)


def read_picks(path, want_size=None):
    picks = {}
    with open(os.path.expanduser(path), encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            key, src = (s.strip() for s in line.split("=", 1))
            split_key(key)                                  # KeyError bei falschem Schlüssel
            src = os.path.expanduser(src)
            if not os.path.exists(src):
                raise FileNotFoundError("FEHLT %s: %s" % (key, src))
            if want_size:
                with Image.open(src) as im:
                    if im.size != tuple(want_size):
                        raise ValueError("%s: %s statt %s" % (key, im.size, tuple(want_size)))
            picks[key] = src
    return picks


def kern_for(layout, key):
    motif, _ = split_key(key)
    kern = layout["kern"]
    if key in kern:
        return kern[key]
    if motif in kern:
        return kern[motif]
    raise KeyError("kern fehlt für %s (cafe_layout.json)" % key)


def _sheet(name, items, cols):
    subprocess.run(["python3", os.path.join(HERE, "sheet.py"), os.path.join(ROOT, name), str(cols)]
                   + items, check=False)


def _input(path_or_img, name):
    return hd.to_input(path_or_img, name)


# --- Stufen ---------------------------------------------------------------------------------
def _foto(motif, light, seed, out):
    pos, neg = foto_prompt(motif, light)
    prefix = "%s_%s_s%d" % (motif, light, seed)
    w, h = kg.QUER
    return cc.run(cc.t2i_graph(pos, neg, seed, prefix, LORA_STRENGTH, w, h), prefix, out, "cafefoto")[0]


def _manga(key, src, out_path, opts=None):
    opts = opts or {}
    motif, light = split_key(key)
    pos, neg = manga_prompt(motif, light)
    if opts.get("extra"):
        pos += ", " + opts["extra"]
    if opts.get("neg"):
        neg += ", " + opts["neg"]
    name = _input(normalize(Image.open(src).convert("RGB")), "cafe_manga_%s.png" % key)
    seed = opts.get("seed", seed_of(src))
    got = cc.run(cc.manga_graph(name, pos, neg, seed, "cm_" + key, control=opts.get("control", "depth"),
                                denoise=opts.get("denoise", 0.7), strength=opts.get("strength", 0.7)),
                 "cm_" + key, os.path.join(ROOT, "manga_raw"), "cafemanga")
    shutil.copy(got[0], out_path)
    return out_path


def foto(only):
    out = os.path.join(ROOT, "foto")
    tiles = []
    for motif in (only or ALL_MOTIFS):
        for seed in SEEDS:
            try:
                p = _foto(motif, "tag", seed, out)
                tiles.append("%s_s%d=%s" % (motif, seed, p))
                print("OK", motif, seed, flush=True)
            except Exception as e:  # noqa: BLE001
                print("ERR", motif, seed, repr(e)[:300], flush=True)
    _sheet("foto_sheet.png", tiles, 4)
    print("CAFE_FOTO_DONE", flush=True)


def _light_fotos(way, motif, tag_src, lights, out):
    """Fotos der Lichter `lights` für ein Motiv: R = Relight des Tag-Fotos, T = Text-zu-Bild."""
    got = []
    for light in lights:
        if way == "R":
            name = _input(tag_src, "cafe_relight_%s.png" % motif)
            prefix = "%s_%s_s%d" % (motif, light, RELIGHT_SEED)
            p = cc.run(cc.relight_graph(name, RELIGHT[light], RELIGHT_SEED, prefix), prefix, out, "caferel")[0]
            got.append((light, RELIGHT_SEED, p))
        else:
            for seed in SEEDS:
                got.append((light, seed, _foto(motif, light, seed, out)))
    return got


def gate(picks_path):
    """Weg R und T für die Gate-Motive, alle vier Lichter, direkt im Manga-Look (D70)."""
    picks = read_picks(picks_path, kg.QUER)
    out = os.path.join(ROOT, "gate")
    os.makedirs(out, exist_ok=True)
    tiles = []
    for key, src in picks.items():
        motif, _ = split_key(key)
        others = [lt for lt in all_lights(motif) if lt != "tag"]
        tag_manga = _manga(key, src, os.path.join(out, "%s_tag.png" % motif))
        for way in ("R", "T"):
            row = ["%s_%s_tag=%s" % (motif, way, tag_manga)]
            for light, seed, p in _light_fotos(way, motif, src, others, os.path.join(out, "foto_" + way)):
                if way == "T" and seed != SEEDS[0]:
                    continue
                k = "%s_%s" % (motif, light)
                m = _manga(k, p, os.path.join(out, "%s_%s_%s.png" % (motif, light, way)))
                row.append("%s_%s_%s=%s" % (motif, way, light, m))
            tiles += row
            print("OK", motif, way, flush=True)
        # Relight lädt das Edit-Modell: vor dem nächsten Basis-Lauf ComfyUI neu starten
        # (OOM-Falle) — der Aufrufer startet gate darum mit einem Motiv je Lauf, siehe Task 5.
    _sheet("gate_sheet.png", tiles, 4)
    print("CAFE_GATE_DONE", flush=True)


def lights(way, picks_path):
    picks = read_picks(picks_path, kg.QUER)
    out = os.path.join(ROOT, "foto_light")
    tiles = []
    for key, src in picks.items():
        motif, light = split_key(key)
        if light != "tag":
            raise ValueError("%s: lights braucht Tag-Fotos als Quelle" % key)
        others = [lt for lt in all_lights(motif) if lt != "tag"]
        tiles.append("%s_tag=%s" % (motif, src))
        for lt, seed, p in _light_fotos(way, motif, src, others, out):
            tiles.append("%s_%s_s%d=%s" % (motif, lt, seed, p))
        print("OK", motif, flush=True)
    _sheet("lights_sheet.png", tiles, 7 if way == "T" else 4)
    print("CAFE_LIGHTS_DONE", flush=True)


def manga(picks_path, overrides_path=None):
    picks = read_picks(picks_path)
    ov = load_overrides(overrides_path, allowed=MANGA_KEYS) if overrides_path else {}
    out = os.path.join(ROOT, "manga")
    os.makedirs(out, exist_ok=True)
    tiles = []
    for key, src in picks.items():
        dest = os.path.join(out, key + ".png")
        opts = ov.get(key, {})
        if os.path.exists(dest) and not opts.get("force"):
            print("SKIP", key, flush=True)
        else:
            try:
                _manga(key, src, dest, opts)
                print("OK", key, flush=True)
            except Exception as e:  # noqa: BLE001
                print("ERR", key, repr(e)[:300], flush=True)
                continue
        tiles += ["%s_foto=%s" % (key, src), "%s_manga=%s" % (key, dest)]
    _sheet("manga_sheet.png", tiles, 4)
    print("CAFE_MANGA_DONE", flush=True)


def hoch(picks_path):
    picks = read_picks(picks_path, kg.QUER)
    with open(LAYOUT, encoding="utf-8") as f:
        layout = json.load(f)
    kerne = {key: kern_for(layout, key) for key in picks}       # KeyError vor jedem Render
    out = os.path.join(ROOT, "hoch")
    os.makedirs(out, exist_ok=True)
    tiles = []
    for key, src in picks.items():
        motif, light = split_key(key)
        dest = os.path.join(out, key + "_hoch.png")
        with Image.open(src) as im:
            mode = hd.derive(im.convert("RGB"), kerne[key], dest, seed=831, tag=key,
                             tmp_dir=os.path.join(ROOT, "hoch_tmp"), client_id="cafehoch",
                             **hoch_prompts(motif, light))
        print(mode.upper(), key, flush=True)
        tiles += ["%s_quer=%s" % (key, src), "%s_hoch=%s" % (key, dest)]
    _sheet("hoch_sheet.png", tiles, 6)
    print("CAFE_HOCH_DONE", flush=True)


def finish(picks_path):
    picks = read_picks(picks_path, kg.QUER)
    out = os.path.join(ROOT, "final")
    os.makedirs(out, exist_ok=True)
    for key, src in picks.items():
        hoch_src = os.path.join(ROOT, "hoch", key + "_hoch.png")
        if not os.path.exists(hoch_src):
            raise FileNotFoundError("FEHLT Hochbild %s" % hoch_src)
        for fmt, path in (("quer", src), ("hoch", hoch_src)):
            w, h = TARGET[fmt]
            name = key if fmt == "quer" else key + "_hoch"
            inp = _input(path, "cafefin_%s.png" % name)
            got = cc.run(cc.upscale_graph(inp, "cfin_" + name, w, h), "cfin_" + name,
                         os.path.join(ROOT, "final_png"), "cafefin")
            im = Image.open(got[0]).convert("RGB")
            if im.size != (w, h):
                raise ValueError("%s: %s statt %s" % (name, im.size, (w, h)))
            im.save(os.path.join(out, name + ".jpg"), "JPEG", quality=88, optimize=True)
            print("OK", name, flush=True)
    print("CAFE_FINISH_DONE", flush=True)


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a:
        raise SystemExit(__doc__)
    cmd, rest = a[0], a[1:]
    if cmd == "foto":
        foto(rest)
    elif cmd == "gate":
        gate(rest[0])
    elif cmd == "lights":
        lights(rest[0], rest[1])
    elif cmd == "manga":
        manga(rest[0], rest[1] if len(rest) > 1 else None)
    elif cmd == "hoch":
        hoch(rest[0])
    elif cmd == "finish":
        finish(rest[0])
    else:
        raise SystemExit(__doc__)
```

`cc.manga_graph` setzt selbst `"shotengai_style, "` vor den Prompt; `manga_prompt` beginnt darum mit `STY` ohne diesen Vorsatz. `finish` prüft das Hochbild vor jeder Vergrößerung dieses Schlüssels; fehlt es, bricht der Lauf ab (Review Focus 2).

Im Test `test_manga_uses_d70_and_seed_of_the_photo` zusätzlich (mit `import cafe_motifs as m` oben):

```python
        self.assertTrue(g["4"]["inputs"]["text"].startswith("shotengai_style, " + m.STY))
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd tool/comic && python3 -W error::ResourceWarning -m unittest discover -s . -p "test_*.py" -v`
Expected: PASS (alle Comic-Tests).

- [ ] **Step 5: Commit**

```bash
git add tool/comic/cafe_manga.py tool/comic/test_cafe_manga.py
git commit -m "feat(comic): Café-Treiber im Manga-Weg (foto, gate, lights, manga, hoch, finish)"
```

---

### Task 4: App — Szenen-Bibliothek kennt das Format

**Files:**
- Modify: `lib/features/cafe/cafe_scenes.dart`
- Test: `test/features/cafe/cafe_scenes_test.dart` (neue Gruppe), `test/features/cafe/cafe_scenes_assets_test.dart` (beide Formate)

**Interfaces:**
- Consumes: `PanelFormat` aus `lib/features/story/episode.dart`.
- Produces:
  - `const Map<CafeMotif, Set<CafeLight>> cafeScenePortrait` (welche Hochbilder gebündelt sind; zunächst leer `{}`)
  - `class CafeScene { final String path; final PanelFormat format; const CafeScene(this.path, this.format); }`
  - `CafeScene sceneForIn(Map<CafeMotif, Set<CafeLight>> landscape, Map<CafeMotif, Set<CafeLight>> portrait, CafeMotif motif, CafeLight light, PanelFormat want)`
  - `CafeScene sceneFor(CafeMotif motif, CafeLight light, PanelFormat want)`
  - `String sceneAsset(CafeMotif, CafeLight)` und `turnScene(...)` bleiben unverändert (quer), damit die heutigen Bildschirme laufen; Plan 4 stellt sie auf `sceneFor` um. Zusätzlich `CafeMotif turnMotif(CafeGuest speaker, int ordinal)` (die Motiv-Wahl aus `turnScene` herausgelöst).

- [ ] **Step 1: Write the failing test**

An `test/features/cafe/cafe_scenes_test.dart` anhängen (Imports: `package:nihongo_app/features/story/episode.dart`):

```dart
  group('sceneForIn — Format', () {
    const land = {
      CafeMotif.leer: {CafeLight.tag, CafeLight.nacht},
      CafeMotif.wirtinTresen: {CafeLight.tag},
    };
    const hoch = {
      CafeMotif.leer: {CafeLight.tag},
    };

    test('Hochbild vorhanden → Hochbild', () {
      final s = sceneForIn(land, hoch, CafeMotif.leer, CafeLight.tag,
          PanelFormat.portrait);
      expect(s.path, 'assets/comic/cafe/leer_tag_hoch.jpg');
      expect(s.format, PanelFormat.portrait);
    });

    test('Hochbild fehlt → Querbild desselben Motivs und Lichts, als quer gemeldet',
        () {
      final s = sceneForIn(land, hoch, CafeMotif.leer, CafeLight.nacht,
          PanelFormat.portrait);
      expect(s.path, 'assets/comic/cafe/leer_nacht.jpg');
      expect(s.format, PanelFormat.landscape);
    });

    test('quer gewünscht → Rückfallkette wie sceneAssetIn', () {
      final s = sceneForIn(land, hoch, CafeMotif.wirtinTee, CafeLight.abend,
          PanelFormat.landscape);
      expect(s.path, sceneAssetIn(land, CafeMotif.wirtinTee, CafeLight.abend));
      expect(s.format, PanelFormat.landscape);
    });

    test('hoch gewünscht, Motiv fällt zurück → Hochbild des Rückfall-Motivs, sonst quer',
        () {
      // wirtinTee fehlt ganz → Stammplatz wirtinTresen bei Tag; davon kein Hochbild.
      final s = sceneForIn(land, hoch, CafeMotif.wirtinTee, CafeLight.tag,
          PanelFormat.portrait);
      expect(s.path, 'assets/comic/cafe/wirtin_tresen_tag.jpg');
      expect(s.format, PanelFormat.landscape);
    });

    test('turnMotif rotiert wie turnScene', () {
      expect(turnMotif(CafeGuest.wirtin, 0), CafeMotif.wirtinTresen);
      expect(turnMotif(CafeGuest.wirtin, 1), CafeMotif.wirtinTee);
      expect(turnMotif(CafeGuest.wirtin, 3), CafeMotif.wirtinTresen);
    });
  });
```

`test/features/cafe/cafe_scenes_assets_test.dart` ersetzen durch:

```dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Set<String> listed() => {
        for (final e in cafeSceneLibrary.entries)
          for (final l in e.value) '${e.key.stem}_${l.name}.jpg',
        for (final e in cafeScenePortrait.entries)
          for (final l in e.value) '${e.key.stem}_${l.name}_hoch.jpg',
      };

  test('jede Tabellenzeile (quer und hoch) hat eine gebündelte Datei (> 1 KB)',
      () async {
    for (final name in listed()) {
      final data = await rootBundle.load('$cafeSceneDir/$name');
      expect(data.lengthInBytes, greaterThan(1000), reason: '$name fehlt');
    }
  });

  test('jedes Hochbild hat sein Querbild', () {
    for (final e in cafeScenePortrait.entries) {
      for (final l in e.value) {
        expect(cafeSceneLibrary[e.key]?.contains(l), isTrue,
            reason: '${e.key.stem}_${l.name}: hoch ohne quer');
      }
    }
  });

  test('jede Datei im Ordner steht in einer Tabelle (keine Leichen im Bundle)',
      () {
    final files = Directory(cafeSceneDir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.jpg'))
        .toSet();
    expect(files, listed());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/features/cafe/cafe_scenes_test.dart test/features/cafe/cafe_scenes_assets_test.dart`
Expected: FAIL — `sceneForIn`, `cafeScenePortrait`, `turnMotif` unbekannt.

- [ ] **Step 3: Write minimal implementation**

In `lib/features/cafe/cafe_scenes.dart` (Import `'../story/episode.dart' show PanelFormat;`):

```dart
/// Welche Hochbilder gebündelt sind (Spec Mira schweigt/Café §6.2). Jedes
/// Hochbild hat sein Querbild in [cafeSceneLibrary]; der Asset-Test erzwingt
/// Tabelle ⇔ Dateien für beide Formate.
const Map<CafeMotif, Set<CafeLight>> cafeScenePortrait = {};

/// Eine aufgelöste Szene: Pfad und das Format, in dem die Datei geschnitten
/// ist. Fragt man hoch und es gibt nur quer, ist [format] quer — der
/// Bildschirm passt es dann ein (Letterbox), statt zu beschneiden.
class CafeScene {
  final String path;
  final PanelFormat format;
  const CafeScene(this.path, this.format);
}

CafeScene sceneForIn(
  Map<CafeMotif, Set<CafeLight>> landscape,
  Map<CafeMotif, Set<CafeLight>> portrait,
  CafeMotif motif,
  CafeLight light,
  PanelFormat want,
) {
  final quer = sceneAssetIn(landscape, motif, light);
  if (want == PanelFormat.landscape) {
    return CafeScene(quer, PanelFormat.landscape);
  }
  // Das Querbild der Rückfallkette bestimmt Motiv und Licht; gibt es davon
  // ein Hochbild, nimm es.
  for (final m in CafeMotif.values) {
    for (final l in CafeLight.values) {
      if (_path(m, l) == quer && (portrait[m]?.contains(l) ?? false)) {
        return CafeScene(
            '$cafeSceneDir/${m.stem}_${l.name}_hoch.jpg', PanelFormat.portrait);
      }
    }
  }
  return CafeScene(quer, PanelFormat.landscape);
}

CafeScene sceneFor(CafeMotif motif, CafeLight light, PanelFormat want) =>
    sceneForIn(cafeSceneLibrary, cafeScenePortrait, motif, light, want);

/// Motiv des [ordinal]-ten Blocks dieses Sprechers: Stammplatz, Moment 1,
/// Moment 2, … rotierend.
CafeMotif turnMotif(CafeGuest speaker, int ordinal) {
  final motifs = CafeMotif.values.where((m) => m.guest == speaker).toList();
  return motifs[ordinal % motifs.length];
}
```

`turnScene` umschreiben auf `sceneAsset(turnMotif(speaker, ordinal), light)`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `~/flutter/bin/flutter test test/features/cafe/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_scenes.dart test/features/cafe/cafe_scenes_test.dart test/features/cafe/cafe_scenes_assets_test.dart
git commit -m "feat(cafe): Szenen-Bibliothek kennt Hochbilder (sceneFor, Letterbox-Meldung)"
```

---

### Task 5: Gate — Weg R oder Weg T für das Licht (Ulis Entscheidung)

**Files:** keine im Repo; Ergebnis ist Ulis Wahl, notiert im PR und in `tool/comic/README.md` (Task 8).

- [ ] **Step 1: Werkzeuge auf die Box, Tag-Fotos der zwei Gate-Motive**

```bash
wakegpu; ssh pc 'mkdir -p ~/cafe_tools && touch ~/.no-idle-suspend'
scp tool/comic/*.py tool/comic/cafe_layout.json pc:~/cafe_tools/
ssh pc 'cd ~/cafe_tools && nohup python3 cafe_manga.py foto leer wirtin_tresen > ~/cafe_foto.log 2>&1 &'
```

Warten auf `CAFE_FOTO_DONE` in `~/cafe_foto.log` (≈ 6 Minuten; Fortschritt per `ssh pc tail -3 ~/cafe_foto.log`). Bogen holen: `scp pc:~/comfy_cafe/foto_sheet.png ~/cafe-gate-foto.png`. Claude wählt je Motiv den besseren der zwei Seeds (Figur links, Gesicht klar), schreibt `~/cafe_tools/picks_gate.txt` auf der Box:

```
leer_tag=/home/uli/comfy_cafe/foto/leer_tag_s901_00001_.png
wirtin_tresen_tag=/home/uli/comfy_cafe/foto/wirtin_tresen_tag_s90X_00001_.png
```

- [ ] **Step 2: Gate laufen lassen — ein Motiv je Lauf, ComfyUI-Neustart dazwischen**

Weg R lädt das Edit-Modell, Weg T und Manga das Basis-Modell (OOM-Falle). Darum je Motiv ein Lauf mit Neustart davor:

```bash
ssh pc 'cd ~/cafe_tools && grep leer_tag picks_gate.txt > g1.txt && grep wirtin_tresen picks_gate.txt > g2.txt && nohup sh -c "systemctl --user restart comfyui; sleep 90; python3 cafe_manga.py gate g1.txt; systemctl --user restart comfyui; sleep 90; python3 cafe_manga.py gate g2.txt" > ~/cafe_gate.log 2>&1 &'
```

Ende: zweimal `CAFE_GATE_DONE` (≈ 50 Minuten). Der zweite Lauf überschreibt `gate_sheet.png`; darum nach dem ersten `CAFE_GATE_DONE` den Bogen holen (`scp pc:~/comfy_cafe/gate_sheet.png ~/cafe-gate-leer.png`), nach dem zweiten `~/cafe-gate-wirtin.png`.

- [ ] **Step 3: Bögen an Uli, Entscheidung abwarten**

Im Chat zeigen: je Bogen zwei Zeilen (R, T) × vier Lichter. Frage an Uli: „Weg R (umgeleuchtet, derselbe Raum) oder Weg T (je Licht neu gezeichnet)?“ Mit Claudes Empfehlung. **Hier anhalten, bis Uli wählt.** Seine Wahl in `~/cafe_tools/WEG.txt` auf der Box schreiben (`R` oder `T`).

---

### Task 6: Runde 1 — 13 Motive bei Tag, beide Formate, in die App

**Files:**
- Modify: `tool/comic/cafe_layout.json` (Kerne nach Sicht)
- Replace/Create: `assets/comic/cafe/{stem}_tag.jpg` (13) und `{stem}_tag_hoch.jpg` (13)
- Modify: `lib/features/cafe/cafe_scenes.dart` (Tabellen: 13 Motive `tag` in beiden Tabellen)

- [ ] **Step 1: Fotos aller 13 Motive** (die zwei Gate-Motive werden übersprungen, wenn ihre Fotos schon da sind — `foto` hat kein Skip; darum nur die elf übrigen nennen)

```bash
ssh pc 'cd ~/cafe_tools && nohup python3 cafe_manga.py foto wirtin_tisch wirtin_tee schulkind_nische schulkind_hausaufgaben schulkind_kakao vielredner_zeitung vielredner_gefaltet vielredner_fenster gleichaltrige_kaffee gleichaltrige_haende gleichaltrige_fenster > ~/cafe_foto2.log 2>&1 &'
```

Ende `CAFE_FOTO_DONE` (≈ 30 Minuten). Bogen `~/cafe-runde1-foto.png` an Uli mit Claudes Vorschlag je Motiv (Seed 901 oder 902; Kriterien: dieselbe Person wie im Steckbrief, Figur in der linken Hälfte, keine verdrehten Hände). **Ulis Picks abwarten.** Picks als `~/cafe_tools/picks_r1_foto.txt` (13 Zeilen `<motif>_tag=<pfad>`).

- [ ] **Step 2: Manga-Durchgang**

```bash
ssh pc 'cd ~/cafe_tools && nohup sh -c "systemctl --user restart comfyui; sleep 90; python3 cafe_manga.py manga picks_r1_foto.txt" > ~/cafe_manga1.log 2>&1 &'
```

Ende `CAFE_MANGA_DONE` (≈ 30 Minuten). Bogen `~/cafe-runde1-manga.png` (Foto | Manga) an Uli. Nachbesserungen über `~/cafe_tools/overrides_r1.txt` (eine Zeile je Schlüssel, z. B. `vielredner_gefaltet_tag control=canny strength=0.6 force` oder `schulkind_kakao_tag seed=903 force`) und erneuten `manga`-Lauf mit der Override-Datei. **Ulis Freigabe abwarten.** Danach `picks_r1_manga.txt` (13 Zeilen `<key>=/home/uli/comfy_cafe/manga/<key>.png`).

- [ ] **Step 3: Kerne setzen**

Manga-Bilder holen (`scp 'pc:~/comfy_cafe/manga/*_tag.png' build/cafe_manga/`) und für jedes Motiv in `tool/comic/cafe_layout.json` den Kern so setzen, dass Figur und ihr Tisch/Tresen darin liegen. Vorschau mit `kern_preview.py`-Logik: `python3 -c` mit `kern_geometry.plan_for(kern)` und einem Rechteck auf dem Bild, oder `kern_preview.py` mit angepasster `MOTIFS`-Liste — dafür in `kern_preview.py` die Motivliste und die Layout-Datei als Argumente annehmen (`python3 tool/comic/kern_preview.py build/cafe_manga build/cafe_kern.png tool/comic/cafe_layout.json`; Standard bleibt Folge 01). Ziel: möglichst „crop“ (Kernbreite ≤ 0,31), die Figur bleibt links; Bogen bei Zweifel an Uli.

- [ ] **Step 4: Hochbilder und Auslieferung**

```bash
scp tool/comic/cafe_layout.json pc:~/cafe_tools/
ssh pc 'cd ~/cafe_tools && nohup sh -c "python3 cafe_manga.py hoch picks_r1_manga.txt && python3 cafe_manga.py finish picks_r1_manga.txt" > ~/cafe_hoch1.log 2>&1 &'
```

Ende `CAFE_HOCH_DONE` und `CAFE_FINISH_DONE`. Bogen `hoch_sheet.png` → `~/cafe-runde1-hoch.png` an Uli (quer | hoch). Nachbesserung: Kern ändern oder Hochbild löschen und `hoch` erneut. **Ulis Freigabe abwarten.**

- [ ] **Step 5: In die App**

```bash
scp 'pc:~/comfy_cafe/final/*_tag.jpg' 'pc:~/comfy_cafe/final/*_tag_hoch.jpg' assets/comic/cafe/
ls assets/comic/cafe | wc -l    # 26
python3 tool/comic/check_kern.py   # nur wenn check_kern Pfade/Motive als Argument annimmt; sonst Schritt 6
```

In `cafe_scenes.dart` beide Tabellen auf alle 13 Motive mit `{CafeLight.tag}` setzen. Die fünf alten 1216×832-Dateien sind durch gleichnamige neue überschrieben.

- [ ] **Step 6: INV-17 für das Café**

`check_kern.py` vergleicht den Kern von quer und hoch am Auslieferungsbild. Es auf die Café-Dateien anwenden: Argumente `--layout tool/comic/cafe_layout.json --dir assets/comic/cafe --suffix _tag` (in `check_kern.py` ergänzen, Standard unverändert für Folge 01; Test in `test_check_kern.py` für den Café-Aufruf mit zwei erzeugten Testbildern — Muster: die vorhandenen Fälle dort). Erwartet: Exit 0.

- [ ] **Step 7: Tests und Commit**

Run: `~/flutter/bin/flutter test test/features/cafe/` und `cd tool/comic && python3 -m unittest discover -s . -p "test_*.py"`
Expected: PASS.

```bash
git add assets/comic/cafe/ lib/features/cafe/cafe_scenes.dart tool/comic/cafe_layout.json tool/comic/kern_preview.py tool/comic/check_kern.py tool/comic/test_check_kern.py
git commit -m "feat(cafe): Runde 1 — 13 Café-Motive bei Tag im Manga-Look, quer und hoch"
```

---

### Task 7: Runde 2 — die übrigen 25 Lichter

**Files:** `assets/comic/cafe/*_{regen,abend,nacht}{,_hoch}.jpg` (50), `lib/features/cafe/cafe_scenes.dart` (Tabellen vollständig), ggf. `tool/comic/cafe_layout.json` (Kerne je Motiv+Licht, falls Weg T die Figur verschiebt)

- [ ] **Step 1: Fotos der Lichter auf dem gewählten Weg**

`picks_r1_foto.txt` ist die Quelle (Tag-Fotos). Weg aus `WEG.txt`:

```bash
ssh pc 'cd ~/cafe_tools && nohup sh -c "systemctl --user restart comfyui; sleep 90; python3 cafe_manga.py lights $(cat WEG.txt) picks_r1_foto.txt" > ~/cafe_lights.log 2>&1 &'
```

Ende `CAFE_LIGHTS_DONE` (R ≈ 40 Minuten, T ≈ 70 Minuten). Bogen `~/cafe-runde2-licht.png` an Uli; bei Weg T pickt Uli je Motiv und Licht einen Seed. Picks `picks_r2_foto.txt` (25 Zeilen `<motif>_<licht>=<pfad>`).

- [ ] **Step 2: Manga, Kerne, Hoch, Auslieferung** — wie Task 6 Step 2–4, mit `picks_r2_*`; bei Weg R gelten die Kerne der Motive (Raum gleich), bei Weg T je Motiv+Licht prüfen und bei Bedarf `"<motif>_<licht>": [x0, x1]` eintragen. ComfyUI-Neustart vor `manga` (Wechsel vom Edit-Modell bei Weg R).

- [ ] **Step 3: In die App, Tabellen vollständig**

`scp` der 50 Dateien; `cafeSceneLibrary` und `cafeScenePortrait` = `FULL`-Motive mit allen vier Lichtern, `MOMENTS` mit `tag` und `abend` (dieselbe Matrix wie `cafe_motifs.lights_for`). Ein Test in `cafe_scenes_test.dart`:

```dart
  test('Tabellen decken die Bibliothek der Spec ab: 38 Motive je Format', () {
    int count(Map<CafeMotif, Set<CafeLight>> t) =>
        t.values.fold(0, (n, s) => n + s.length);
    expect(count(cafeSceneLibrary), 38);
    expect(count(cafeScenePortrait), 38);
  });
```

- [ ] **Step 4: Tests, Größe, Commit**

```bash
du -sh assets/comic/cafe     # Erwartung grob 25–35 MB
~/flutter/bin/flutter test test/features/cafe/
git add assets/comic/cafe/ lib/features/cafe/cafe_scenes.dart test/features/cafe/cafe_scenes_test.dart tool/comic/cafe_layout.json
git commit -m "feat(cafe): Runde 2 — Café in vier Lichtern, 76 Bilder quer und hoch"
ssh pc rm -f ~/.no-idle-suspend
```

---

### Task 8: Aufräumen, Doku, Vollsuite, PR

**Files:**
- Delete: `tool/comic/cafe_library.py`, `tool/comic/cafe_assemble.py`, `tool/comic/cafe_relight_probe.py` (vorher `grep -rn "cafe_library\|cafe_assemble\|cafe_relight_probe" tool lib test` — nur der alte Plan von 19.9. darf noch darauf verweisen)
- Modify: `tool/comic/README.md` — Abschnitt „Café im Manga-Weg“: Befehlsfolge foto → (gate) → manga → Kerne → hoch → finish → lights; Ulis Weg-Entscheidung; Zeitbedarf; Fallen (OOM beim Modellwechsel, `foto` überspringt nichts, Kern je Motiv+Licht bei Weg T); Werkzeug-Tabelle um `hoch_derive.py`, `cafe_manga.py`, `cafe_layout.json` ergänzen

- [ ] **Step 1: Löschen, Doku, Python-Tests**

```bash
git rm tool/comic/cafe_library.py tool/comic/cafe_assemble.py tool/comic/cafe_relight_probe.py
cd tool/comic && python3 -W error::ResourceWarning -m unittest discover -s . -p "test_*.py" -v && cd -
```

Expected: PASS.

- [ ] **Step 2: Vollsuite auf der Box**

```bash
git push -u origin impl/cafe-bilder-manga
ssh pc 'cd ~/projects/nihongo && git fetch -q origin && git checkout -q -B impl/cafe-bilder-manga origin/impl/cafe-bilder-manga && export PATH=$HOME/development/flutter/bin:$PATH && flutter pub get >/dev/null && flutter analyze --no-fatal-infos | tail -3 && flutter test --reporter compact 2>&1 | tail -5; git checkout -q main'
```

Expected: keine `error •`; „+N −8“.

- [ ] **Step 3: Commit und Draft-PR**

```bash
git add tool/comic/README.md
git commit -m "docs(comic): Café im Manga-Weg — Ablauf, Entscheidung, Fallen; alte Café-Skripte entfernt"
git push
gh pr create --draft --base main --title "feat(cafe): Café-Bilder im Manga-Weg — 38 Motive, quer und hoch" --body "<Plan 3 von 4 aus Spec #58: Gate-Ergebnis, Runden, Picks, Tests; Abnahme Ulis Picks + check_kern>"
```

Abnahme (Spec §12): Ulis Picks liegen vor, `check_kern.py` grün für das Café, Bibliothekstest grün. Die Sicht im Vollbild prüft Plan 4.
