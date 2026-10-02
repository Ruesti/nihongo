# Hochbild aus dem Querbild — Umsetzungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die 11 Hochbilder der Folge 01 (10 Panels + Titel, dazu automatisch 3 Reaktionsbilder) werden aus den freigegebenen Manga-Querbildern abgeleitet, sodass beide Lagen dieselbe Szene zeigen (Spec §12).

**Architecture:** Das Querbild bleibt Master. Je Motiv steht ein Kern (`kern: [x0, x1]`, Anteile der Querbreite) in der Layout-Datei. Passt der Kern ins Hochfenster (31 % der Breite, volle Höhe), wird nur beschnitten; sonst wird der Kernstreifen auf 928 px Breite gebracht und per Rand-Ausmalen (ComfyUI `ImagePadForOutpaint` + `InpaintModelConditioning`, Hausstil-LoRA 1,5, kein ControlNet) unten um 128 px mit Figuren-Prompt und oben schrittweise (≤ 480 px je Schritt) mit Umgebungs-Prompt verlängert. Eine reine Geometrie-Bibliothek (`kern_geometry.py`) wird von Box-Skript, Vorschau, Gesichter-Ableitung und Kern-Prüfung gemeinsam genutzt. Vergrößerung, Lettering, Tippflächen-Generator und App bleiben unverändert; nur Dateien und Hoch-Layout ändern sich.

**Tech Stack:** Python 3 (Standardbibliothek + Pillow), ComfyUI-HTTP-API auf der GPU-Box `pc` (Qwen-Image Q4 GGUF, LoRA `shotengai_style_ckpt6`), Flutter/Dart (nur regenerierte Konstanten + bestehende Tests), `unittest`.

**Spec:** `docs/superpowers/specs/2026-09-23-manga-vollbild-titelbild-design.md`, Abschnitt 12 (Nachtrag 1.10.), dazu §3.1 (Zahlen), §4.3/§4.4 (Vergrößerung, Lettering), §8 (INV-14/15/16), §11 (Betrieb).

## Global Constraints

- Render-Maße: quer **1664 × 928**, hoch **928 × 1664**; Auslieferung quer **1920 × 1072**, hoch **1080 × 1936**, JPEG Qualität **88**, Ablage `assets/story/folge01/` (Spec §3.1, §5.3).
- Hochfenster = volle Höhe des Querbilds, Breite im Verhältnis 928 : 1664 (⇒ 518 px im Render-Maß, 31 %) (Spec §12.1).
- Verlängern: unten **128 px**, Überblendung **96 px**, Figuren-Prompt; oben Schritte von höchstens **480 px**, Überblendung **64 px**, Umgebungs-Prompt mit Personen im Negativ; Modell Qwen-Image Q4 + LoRA **1,5**, **24 Steps, cfg 4,0, denoise 1,0**, **kein ControlNet**; Standard-Seed **831**, ein Seed je Motiv (Spec §12.4).
- Alle Latent-Maße Vielfache von **16** (Qwen-VAE).
- Sichere Zone = mittlere **80 %** der beschnittenen Achse; Mindest-Schriftgröße **34 px quer / 30 px hoch**; keine Blase über Gesicht oder Nogo-Zone (Spec §4.4, §8 INV-15; `letter_folge01.check_layout`).
- INV-14: Blasen und Tippflächen aus **einer** Layout-Datei (`tool/comic/folge01_layout.json` → `gen_layout_dart.py` → `lib/features/story/episodes/folge_01_layout.g.dart`). INV-17: Kern hoch = Kern quer (`check_kern.py`, Spec §12.5).
- Reaktionsbilder p02/p05/p08 entstehen durch `letter_folge01.py` als getönte Varianten, auch hoch (Spec §12.1).
- Betrieb (Spec §11): Box wecken `/usr/local/bin/wakegpu`, Kill-Switch `touch ~/.no-idle-suspend` während langer Läufe und danach entfernen; Hintergrundläufe per `setsid nohup … > log 2>&1 </dev/null &`; `pkill`-Muster nie im eigenen ssh-Kommando (`[k]ern`-Trick); ComfyUI zählt Dateinamen in seinem eigenen Ausgabeordner hoch, deshalb schreibt das Hoch-Skript jedes Ergebnis unter einem **festen** Namen (`<motiv>_hoch.png`) um.
- Skripte in `tool/comic/` laufen mit `cd tool/comic` (Imports untereinander) oder vom Repo-Wurzelverzeichnis (NUC-Werkzeuge mit `sys.path.insert(0, "tool/comic")`). Tests: `cd tool/comic && python3 -W error::ResourceWarning -m unittest discover -s . -p "test_*.py" -v` (bisher 69 OK).
- Worktree-Regeln dieser Sitzung: nur einfache Bash-Befehle (keine Heredocs, Schleifen, Variablen, `git -C`); Dateien per Write/Edit; Commits per `git commit -F <datei>` mit den Attributionszeilen aus der Sitzung; Branch `impl/manga-vollbild-app`, Push nach `origin`.
- Dokumentation, Kommentare, Marken in Logs: Deutsch (Prompts Englisch).

## Review Focus

1. **Kern knapp breiter als das Fenster** (z. B. 33 %): der Streifen wird fast 1664 hoch, unten bleibt weniger als 128 px, oben nichts. Erwartung: kein negativer Rand, kein Absturz, `bottom` schrumpft, `top_steps` leer. → Test in Task 1 (`test_plan_extend_near_window`).
2. **Kern am Bildrand** (`x0 = 0` oder `x1 = 1`): Beschnitt-Fenster darf nicht aus dem Bild ragen. → Test in Task 1 (`test_plan_crop_clamps_to_edges`).
3. **Gesicht beim Beschnitt angeschnitten:** abgeleitete Hoch-Gesichter ragen aus dem Bild; `check_layout` erwartet gültige Rechtecke. → Task 1 (`test_hoch_faces_clips_and_drops`) und Task 7 Schritt „Gesichter prüfen".
4. **Alte Hochbilder in `~/comfy_f01/hoch/` nach geändertem Kern** werden übersprungen und liefern ein veraltetes Bild. → Task 4 (`test_main_skips_existing_unless_force`) und README-Regel in Task 8.
5. **Picks-Datei mit alten `*_hoch`-Zeilen**, deren Dateien auf einer frischen Box fehlen: das Hoch-Skript darf nur die `*_quer`-Zeilen lesen. → Task 4 (`test_read_quer_picks_ignores_hoch_lines`).

---

### Task 1: `kern_geometry.py` — Fenster, Streifen, Schritte, Gesichter-Abbildung

**Files:**
- Create: `tool/comic/kern_geometry.py`
- Test: `tool/comic/test_kern_geometry.py`

**Interfaces:**
- Consumes: nichts (reine Funktionen).
- Produces (von Task 3–6 genutzt):
  - `QUER = (1664, 928)`, `HOCH = (928, 1664)`, `BOTTOM = 128`, `STEP_MAX = 480`, `MULT = 16`
  - `window_width(img_w: int, img_h: int) -> int`
  - `top_steps(total: int) -> list[int]`
  - `plan_for(kern: list[float], img_w=1664, img_h=928) -> dict` mit `mode: "crop"` (`x0`, `x1`) oder `mode: "extend"` (`x0`, `x1`, `strip_h`, `bottom`, `top`, `top_steps`)
  - `map_rect(rect, plan, img_w=1664, img_h=928) -> list[float]`
  - `clip_rect(rect) -> list[float] | None`
  - `hoch_faces(faces, plan) -> list[list[float]]`

- [ ] **Step 1: Test schreiben**

```python
#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_kern_geometry"""
import unittest

import kern_geometry as kg


class Window(unittest.TestCase):
    def test_window_width_is_hoch_ratio(self):
        self.assertEqual(kg.window_width(1664, 928), 518)   # 928 * 928 / 1664 = 517,5
        self.assertEqual(kg.window_width(1920, 1072), 598)


class Steps(unittest.TestCase):
    def test_top_steps_split_into_multiples_of_16_below_max(self):
        self.assertEqual(kg.top_steps(0), [])
        self.assertEqual(kg.top_steps(464), [464])
        steps = kg.top_steps(912)
        self.assertEqual(sum(steps), 912)
        self.assertEqual(len(steps), 2)
        self.assertTrue(all(s % 16 == 0 and 0 < s <= kg.STEP_MAX for s in steps), steps)
        steps = kg.top_steps(1040)
        self.assertEqual((sum(steps), len(steps)), (1040, 3))
        self.assertTrue(all(s % 16 == 0 and 0 < s <= kg.STEP_MAX for s in steps), steps)

    def test_top_steps_rejects_non_multiple(self):
        with self.assertRaises(ValueError):
            kg.top_steps(500)


class Plan(unittest.TestCase):
    def test_plan_crop_when_kern_fits(self):
        p = kg.plan_for([0.36, 0.64])            # 28 % < 31 %
        self.assertEqual(p["mode"], "crop")
        self.assertEqual(p["x1"] - p["x0"], 518)
        self.assertEqual((p["x0"] + p["x1"]) // 2, 832)   # mittig über dem Kern (Mitte 0,5 → 832)

    def test_plan_crop_clamps_to_edges(self):
        self.assertEqual(kg.plan_for([0.0, 0.2])["x0"], 0)
        p = kg.plan_for([0.85, 1.0])
        self.assertEqual(p["x1"], 1664)
        self.assertEqual(p["x0"], 1664 - 518)

    def test_plan_extend_when_kern_wider(self):
        p = kg.plan_for([0.13, 0.95])            # 82 % → 1364 px breit
        self.assertEqual(p["mode"], "extend")
        self.assertEqual((p["x0"], p["x1"]), (216, 1581))
        self.assertEqual(p["strip_h"] % 16, 0)
        self.assertEqual(p["strip_h"], 624)      # 928 * 928 / 1365 = 631 → 624
        self.assertEqual(p["bottom"], 128)
        self.assertEqual(p["top"], 1664 - 624 - 128)
        self.assertEqual(sum(p["top_steps"]), p["top"])
        self.assertTrue(all(s <= kg.STEP_MAX for s in p["top_steps"]))

    def test_plan_extend_near_window(self):
        # 33 % breit (550 px): Streifen 1568 hoch → unten nur 96 px, oben nichts, kein negativer Rand
        p = kg.plan_for([0.335, 0.665])
        self.assertEqual(p["mode"], "extend")
        self.assertGreaterEqual(p["bottom"], 0)
        self.assertEqual(p["strip_h"] + p["bottom"] + p["top"], 1664)
        self.assertEqual(p["top"], 0)
        self.assertEqual(p["top_steps"], [])

    def test_plan_rejects_bad_kern(self):
        for bad in ([0.5, 0.5], [-0.1, 0.5], [0.2, 1.1], [0.7, 0.3]):
            with self.assertRaises(ValueError):
                kg.plan_for(bad)


class Faces(unittest.TestCase):
    def test_map_rect_crop_shifts_and_scales_x_only(self):
        p = kg.plan_for([0.36, 0.64])            # Fenster 573..1091
        r = kg.map_rect([0.43, 0.29, 0.12, 0.19], p)
        self.assertAlmostEqual(r[0], (0.43 * 1664 - p["x0"]) / 518, places=3)   # map_rect rundet auf 4 Stellen
        self.assertAlmostEqual(r[1], 0.29, places=3)
        self.assertAlmostEqual(r[2], 0.12 * 1664 / 518, places=3)
        self.assertAlmostEqual(r[3], 0.19, places=3)

    def test_map_rect_extend_places_strip_in_canvas(self):
        p = kg.plan_for([0.13, 0.95])
        r = kg.map_rect([0.5, 0.0, 0.1, 1.0], p)   # volle Höhe des Streifens
        self.assertAlmostEqual(r[1], p["top"] / 1664, places=3)
        self.assertAlmostEqual(r[3], p["strip_h"] / 1664, places=3)

    def test_hoch_faces_clips_and_drops(self):
        p = kg.plan_for([0.36, 0.64])            # Fenster 573..1091 (0,344..0,656)
        faces = [[0.43, 0.29, 0.12, 0.19],        # ganz drin
                 [0.62, 0.2, 0.1, 0.1],           # ragt rechts raus → beschnitten
                 [0.05, 0.2, 0.1, 0.1]]           # ganz draußen → weg
        out = kg.hoch_faces(faces, p)
        self.assertEqual(len(out), 2)
        for f in out:
            self.assertTrue(0 <= f[0] and f[0] + f[2] <= 1.0001 and f[2] > 0, f)
        self.assertAlmostEqual(out[1][0] + out[1][2], 1.0, places=4)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag sehen**

Run: `cd tool/comic && python3 -m unittest test_kern_geometry -v`
Expected: FAIL / ERROR mit `ModuleNotFoundError: No module named 'kern_geometry'`

- [ ] **Step 3: Modul schreiben**

```python
#!/usr/bin/env python3
"""Geometrie „Hochbild aus dem Querbild" (Spec §12). Reine Funktionen, laufen auf NUC und Box.

Kern = [x0, x1] als Anteile der Querbreite. Hochfenster = volle Höhe, Breite im Hochformat-Verhältnis.
Passt der Kern ins Fenster → "crop" (Fenster mittig über dem Kern, an den Rand geklemmt).
Sonst → "extend": Kernstreifen (volle Höhe) auf HOCH-Breite skaliert, unten BOTTOM px, oben der Rest in
Schritten ≤ STEP_MAX. Alle Maße Vielfache von MULT (Qwen-VAE)."""

QUER = (1664, 928)
HOCH = (928, 1664)
MULT = 16
BOTTOM = 128
STEP_MAX = 480


def _mult(v):
    return int(round(v / MULT)) * MULT


def window_width(img_w, img_h):
    """Breite des Hochfensters bei voller Höhe des Querbilds."""
    return int(round(img_h * HOCH[0] / HOCH[1]))


def top_steps(total):
    """Teilt `total` (Vielfaches von MULT) in möglichst wenige Schritte ≤ STEP_MAX, alle Vielfache von MULT."""
    if total % MULT:
        raise ValueError("top muss Vielfaches von %d sein, nicht %d" % (MULT, total))
    if total <= 0:
        return []
    n = -(-total // STEP_MAX)            # aufrunden
    base = _mult(total / n)
    steps = [base] * n
    steps[-1] = total - base * (n - 1)
    return steps


def plan_for(kern, img_w=QUER[0], img_h=QUER[1]):
    x0f, x1f = kern
    if not (0 <= x0f < x1f <= 1):
        raise ValueError("kern muss 0 <= x0 < x1 <= 1 sein, nicht %r" % (kern,))
    kx0, kx1 = int(round(x0f * img_w)), int(round(x1f * img_w))
    win = window_width(img_w, img_h)
    if kx1 - kx0 <= win:
        cx = (kx0 + kx1) / 2
        x0 = int(round(cx - win / 2))
        x0 = max(0, min(img_w - win, x0))
        return {"mode": "crop", "x0": x0, "x1": x0 + win}
    sh = min(_mult(img_h * HOCH[0] / (kx1 - kx0)), HOCH[1])
    bottom = min(BOTTOM, HOCH[1] - sh)
    top = HOCH[1] - sh - bottom
    return {"mode": "extend", "x0": kx0, "x1": kx1, "strip_h": sh, "bottom": bottom,
            "top": top, "top_steps": top_steps(top)}


def map_rect(rect, plan, img_w=QUER[0], img_h=QUER[1]):
    """Rechteck [x, y, w, h] (normiert im Querbild) → normiert im Hochbild (ohne Beschnitt)."""
    x, y, w, h = rect
    kw = plan["x1"] - plan["x0"]
    nx = (x * img_w - plan["x0"]) / kw
    nw = w * img_w / kw
    if plan["mode"] == "crop":
        ny, nh = y, h
    else:
        ny = (plan["top"] + y * plan["strip_h"]) / HOCH[1]
        nh = h * plan["strip_h"] / HOCH[1]
    return [round(v, 4) for v in (nx, ny, nw, nh)]


def clip_rect(rect):
    """Auf 0..1 beschneiden; None, wenn nichts übrig bleibt."""
    x, y, w, h = rect
    x0, y0, x1, y1 = max(0.0, x), max(0.0, y), min(1.0, x + w), min(1.0, y + h)
    if x1 <= x0 or y1 <= y0:
        return None
    return [round(v, 4) for v in (x0, y0, x1 - x0, y1 - y0)]


def hoch_faces(faces, plan, img_w=QUER[0], img_h=QUER[1]):
    out = []
    for f in faces:
        c = clip_rect(map_rect(f, plan, img_w, img_h))
        if c:
            out.append(c)
    return out
```

- [ ] **Step 4: Test laufen lassen, grün sehen**

Run: `cd tool/comic && python3 -m unittest test_kern_geometry -v`
Expected: alle Tests `ok`. Falls `test_plan_extend_when_kern_wider` an `strip_h` scheitert, die Rundung nachrechnen: 928 · 928 / (1581 − 216) = 630,9 → `_mult` → 624 (630,9 / 16 = 39,4 → 39 · 16).

- [ ] **Step 5: Commit**

Commit-Text in `build/kern/msg_t1.txt` (Write-Tool), dann:
```bash
git add tool/comic/kern_geometry.py tool/comic/test_kern_geometry.py
git commit -F build/kern/msg_t1.txt
```
Text: `feat(comic): kern_geometry — Hochfenster, Kernstreifen, Schrittfolge und Gesichter-Abbildung (Spec §12)` + Attributionszeilen.

---

### Task 2: `outpaint_graph` im ComfyUI-Client und Hoch-Prompts in den Motiven

**Files:**
- Modify: `tool/comic/comfy_client.py` (nach `manga_graph`, vor `upscale_graph`)
- Modify: `tool/comic/folge01_motifs.py` (nach `UMBRELLA_FIX`)
- Test: `tool/comic/test_graphs.py` (Klasse anhängen), `tool/comic/test_motifs.py` (Test anhängen)

**Interfaces:**
- Consumes: Knoten-Namen wie in `manga_graph` (UnetLoaderGGUF, LoraLoaderModelOnly, CLIPLoader, VAELoader, CLIPTextEncode, KSampler, VAEDecode, SaveImage).
- Produces:
  - `cc.outpaint_graph(input_name, top, bottom, prompt, negative, seed, prefix, feather=64, lora_strength=1.5) -> dict`
  - `folge01_motifs.HOCH_UMGEBUNG: dict[str, str]` (Schlüssel p01…p10, titel)
  - `folge01_motifs.HOCH_HINT_UNTEN: str`, `NEG_HOCH_UNTEN: str`, `NEG_HOCH_OBEN: str`

- [ ] **Step 1: Graph-Test anhängen** (an `tool/comic/test_graphs.py`, vor `if __name__`)

```python
class OutpaintGraph(unittest.TestCase):
    def test_wiring_pad_mask_inpaint_no_controlnet(self):
        g = cc.outpaint_graph("hoch_p05.png", 464, 0, "bg", "neg", 831, "p05_hochT1", feather=64)
        pad = g[_node(g, "ImagePadForOutpaint")]["inputs"]
        self.assertEqual((pad["left"], pad["top"], pad["right"], pad["bottom"]), (0, 464, 0, 0))
        self.assertEqual(pad["feathering"], 64)
        self.assertEqual(pad["image"], [_node(g, "LoadImage"), 0])
        ic = _node(g, "InpaintModelConditioning")
        self.assertEqual(g[ic]["inputs"]["pixels"], [_node(g, "ImagePadForOutpaint"), 0])
        self.assertEqual(g[ic]["inputs"]["mask"], [_node(g, "ImagePadForOutpaint"), 1])
        self.assertTrue(g[ic]["inputs"]["noise_mask"])
        ks = g[_node(g, "KSampler")]["inputs"]
        self.assertEqual(ks["positive"], [ic, 0])
        self.assertEqual(ks["negative"], [ic, 1])
        self.assertEqual(ks["latent_image"], [ic, 2])
        self.assertAlmostEqual(ks["denoise"], 1.0)
        self.assertEqual((ks["steps"], ks["cfg"], ks["seed"]), (24, 4.0, 831))
        self.assertNotIn("ControlNetApplyAdvanced", [v["class_type"] for v in g.values()])
        self.assertAlmostEqual(g[_node(g, "LoraLoaderModelOnly")]["inputs"]["strength_model"], 1.5)
        self.assertTrue(g["4"]["inputs"]["text"].startswith("shotengai_style, "))   # "4" = positiver Prompt

    def test_bottom_pass(self):
        g = cc.outpaint_graph("x.png", 0, 128, "p", "n", 1, "p", feather=96)
        pad = g[_node(g, "ImagePadForOutpaint")]["inputs"]
        self.assertEqual((pad["top"], pad["bottom"], pad["feathering"]), (0, 128, 96))
```

Hinweis: `_node(g, "CLIPTextEncode")` hätte zwei Treffer (positiv/negativ); der Test greift den positiven Knoten deshalb über den festen Schlüssel `"4"` (Eingabebild: `"IN"`, Negativ: `"5"`).

- [ ] **Step 2: Motiv-Test anhängen** (an `tool/comic/test_motifs.py`, vor `if __name__`; `import folge01_motifs as fm` steht dort schon — prüfen mit `grep -n "^import\|^from" tool/comic/test_motifs.py`, sonst den Import-Namen übernehmen, der dort verwendet wird)

```python
class HochUmgebung(unittest.TestCase):
    def test_every_motif_has_a_surrounding_sentence(self):
        want = ["p%02d" % i for i in range(1, 11)] + ["titel"]
        self.assertEqual(sorted(fm.HOCH_UMGEBUNG), sorted(want))
        for k, v in fm.HOCH_UMGEBUNG.items():
            self.assertIn("above", v, k)
            self.assertIn("below", v, k)

    def test_hoch_negatives_build_on_manga_negative(self):
        self.assertTrue(fm.NEG_HOCH_UNTEN.startswith(", "))
        self.assertIn("duplicate person", fm.NEG_HOCH_UNTEN)
        self.assertIn("person", fm.NEG_HOCH_OBEN)
        self.assertTrue(fm.NEG_HOCH_OBEN.startswith(fm.NEG_HOCH_UNTEN))
        self.assertIn("legs and feet", fm.HOCH_HINT_UNTEN)
```

- [ ] **Step 3: Tests laufen lassen, Fehlschlag sehen**

Run: `cd tool/comic && python3 -m unittest test_graphs test_motifs -v`
Expected: `AttributeError: module 'comfy_client' has no attribute 'outpaint_graph'` und `… has no attribute 'HOCH_UMGEBUNG'`

- [ ] **Step 4: `outpaint_graph` in `comfy_client.py` einfügen** (zwischen `manga_graph` und `upscale_graph`)

```python
def outpaint_graph(input_name, top, bottom, prompt, negative, seed, prefix, feather=64, lora_strength=1.5):
    """Rand-Ausmalen (Spec §12.4): das Eingabebild wird oben/unten um `top`/`bottom` Pixel gepolstert,
    nur der Rand (Maske, mit `feather` px Überblendung ins Bild) wird neu gezeichnet — Basis-Modell +
    Hausstil-LoRA, kein ControlNet, denoise 1.0 im maskierten Bereich. input_name liegt in COMFY_INPUT."""
    return {
        "1": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": "qwen-image-Q4_K_M.gguf"}},
        "L": {"class_type": "LoraLoaderModelOnly", "inputs": {"model": ["1", 0],
              "lora_name": "shotengai_style_ckpt6.safetensors", "strength_model": lora_strength}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen_2.5_vl_7b_fp8_scaled.safetensors", "type": "qwen_image"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_vae.safetensors"}},
        "IN": {"class_type": "LoadImage", "inputs": {"image": input_name}},
        "PAD": {"class_type": "ImagePadForOutpaint", "inputs": {"image": ["IN", 0], "left": 0, "top": top,
                "right": 0, "bottom": bottom, "feathering": feather}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": "shotengai_style, " + prompt, "clip": ["2", 0]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": ["2", 0]}},
        "IC": {"class_type": "InpaintModelConditioning", "inputs": {"positive": ["4", 0], "negative": ["5", 0],
               "vae": ["3", 0], "pixels": ["PAD", 0], "mask": ["PAD", 1], "noise_mask": True}},
        "7": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 24, "cfg": 4.0, "sampler_name": "euler",
              "scheduler": "simple", "denoise": 1.0, "model": ["L", 0], "positive": ["IC", 0],
              "negative": ["IC", 1], "latent_image": ["IC", 2]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["3", 0]}},
        "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["8", 0]}},
    }
```

- [ ] **Step 5: Hoch-Prompts in `folge01_motifs.py` einfügen** (direkt nach der Zeile `UMBRELLA_FIX = …`)

```python
# Hochbild aus dem Querbild (Spec §12.4): was oben und unten an Umgebung dazukommt, wenn der Kern breiter
# als das Hochfenster ist. Nur Umgebung, keine Figuren — die Figuren sind maskiert und bleiben.
HOCH_UMGEBUNG = {
    "p01": "the station platform roof and a grey rainy night sky above, wet platform surface below",
    "p02": "rain-streaked grey air above, wet ground below",
    "p03": "grey evening sky with utility poles and wires above, wet asphalt with reflections below",
    "p04": "grey dusk sky above the arcade roof, wet street with reflections below",
    "p05": "the arcade's glass roof and hanging signs above, wet tiled arcade floor below",
    "p06": "the workshop's ceiling with a bare fluorescent lamp and shelves above, "
           "the workbench legs and the workshop floor below",
    "p07": "the shop's upper facade with windows and a sign above the doorway, wet pavement with reflections below",
    "p08": "the shop's awning and facade above, wet pavement below",
    "p09": "the building's wall and eaves in the rain above, wet pavement below",
    "p10": "grey rain-filled sky above, wet ground below",
    "titel": "a wide open grey rainy night sky above, no roof overhead, wet platform edge below",
}
# Unten (kleiner Rand mit Figuren-Prompt): Beine/Füße laufen weiter, sonst nichts.
HOCH_HINT_UNTEN = (", the figures' legs and feet continue naturally down to the floor, nothing else added "
                   "below them, vertical framing")
NEG_HOCH_UNTEN = (", black bars, letterbox, frame, border, seam, visible edge, duplicate person, second body, "
                  "extra body, doubled figure, cloned figure, extra legs, extra arms, floating torso")
# Oben (großer Rand mit Umgebungs-Prompt): zusätzlich keine Personen — der Kern ist maskiert.
NEG_HOCH_OBEN = NEG_HOCH_UNTEN + ", people, person, human figure, face, character, portrait"
```

- [ ] **Step 6: Tests laufen lassen, grün sehen**

Run: `cd tool/comic && python3 -m unittest test_graphs test_motifs -v`
Expected: alle `ok` (bisherige Tests weiter grün).

- [ ] **Step 7: Commit**

```bash
git add tool/comic/comfy_client.py tool/comic/folge01_motifs.py tool/comic/test_graphs.py tool/comic/test_motifs.py
git commit -F build/kern/msg_t2.txt
```
Text: `feat(comic): outpaint_graph (Pad + Inpaint-Konditionierung) und Hoch-Umgebungsprompts je Motiv` + Attributionszeilen.

---

### Task 3: Kern-Feld in der Layout-Datei, Prüfung, Vorschau und Gesichter-Helfer

**Files:**
- Modify: `tool/comic/folge01_layout.json` (neues Top-Level-Feld `kern`)
- Modify: `tool/comic/check_layout.py` (Zeilen 44–46: Asserts ergänzen)
- Create: `tool/comic/kern_preview.py`, `tool/comic/kern_faces.py`
- Test: `tool/comic/test_kern_tools.py`

**Interfaces:**
- Consumes: `kern_geometry.plan_for`, `hoch_faces` (Task 1).
- Produces:
  - Layout-Datei: `"kern": {"p01": [x0, x1], …, "titel": [x0, x1]}` (11 Einträge).
  - `kern_preview.main(raw_dir="build/f01_raw", out="build/kern_preview.png", layout_path="tool/comic/folge01_layout.json") -> str`
  - `kern_faces.derive(layout: dict) -> dict[str, list]` (pid → Hoch-Gesichter) und CLI, das je Panel eine Zeile `pid faces=[…]` druckt.

- [ ] **Step 1: Test schreiben**

```python
#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_kern_tools"""
import json
import os
import tempfile
import unittest

from PIL import Image

import kern_faces
import kern_preview

HERE = os.path.dirname(os.path.abspath(__file__))
MOTIFS = ["p%02d" % i for i in range(1, 11)] + ["titel"]


class LayoutKern(unittest.TestCase):
    def test_layout_has_kern_for_all_motifs(self):
        with open(os.path.join(HERE, "folge01_layout.json"), encoding="utf-8") as f:
            layout = json.load(f)
        self.assertEqual(sorted(layout["kern"]), sorted(MOTIFS))
        for k, (x0, x1) in layout["kern"].items():
            self.assertTrue(0 <= x0 < x1 <= 1, (k, x0, x1))


class Faces(unittest.TestCase):
    def test_derive_maps_quer_faces_per_panel(self):
        layout = {"kern": {"p01": [0.36, 0.64]},
                  "panels": {"p01": {"quer": {"faces": [[0.43, 0.29, 0.12, 0.19]]}, "hoch": {"faces": []}}}}
        out = kern_faces.derive(layout)
        self.assertEqual(list(out), ["p01"])
        self.assertEqual(len(out["p01"]), 1)
        self.assertAlmostEqual(out["p01"][0][1], 0.29, places=4)


class Preview(unittest.TestCase):
    def test_sheet_written_with_all_motifs(self):
        d = tempfile.mkdtemp()
        for m in MOTIFS:
            Image.new("RGB", (192, 107), (90, 120, 90)).save(os.path.join(d, m + "_quer.jpg"))
        layout_path = os.path.join(d, "layout.json")
        with open(layout_path, "w", encoding="utf-8") as f:
            json.dump({"kern": {m: ([0.1, 0.9] if m in ("p05", "titel") else [0.4, 0.6]) for m in MOTIFS},
                       "panels": {}}, f)
        out = kern_preview.main(d, os.path.join(d, "sheet.png"), layout_path)
        self.assertTrue(os.path.exists(out))
        with Image.open(out) as im:
            self.assertGreater(im.width, 192)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag sehen**

Run: `cd tool/comic && python3 -m unittest test_kern_tools -v`
Expected: `ModuleNotFoundError: No module named 'kern_faces'`

- [ ] **Step 3: `kern_faces.py` schreiben**

```python
#!/usr/bin/env python3
"""Leitet die Hoch-Gesichter aus den Quer-Gesichtern und dem Kern ab (Spec §12.3).
Aufruf im Repo-Wurzelverzeichnis: python3 tool/comic/kern_faces.py
Druckt je Panel eine Zeile `pid faces=[…]` zum Einsetzen unter panels.<pid>.hoch.faces (die Layout-Datei
ist von Hand formatiert und wird nicht automatisch umgeschrieben)."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kern_geometry as kg  # noqa: E402

LAYOUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "folge01_layout.json")


def derive(layout):
    out = {}
    for pid, formats in layout["panels"].items():
        plan = kg.plan_for(layout["kern"][pid])
        out[pid] = kg.hoch_faces(formats["quer"].get("faces", []), plan)
    return out


def main():
    with open(LAYOUT, encoding="utf-8") as f:
        layout = json.load(f)
    for pid, faces in derive(layout).items():
        print("%s faces=%s" % (pid, json.dumps(faces)))


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: `kern_preview.py` schreiben**

```python
#!/usr/bin/env python3
"""Vorschau „Kern schützen, Rand beschneiden" (Spec §12.3): je Motiv das Querbild mit Kern (rot) und
Fenster bzw. Streifen (gelb), daneben das geplante Hochbild (Beschnitt oder Streifen in der Leinwand,
erfundener Rand grau). Aufruf im Repo-Wurzelverzeichnis:
  python3 tool/comic/kern_preview.py [build/f01_raw] [build/kern_preview.png]"""
import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kern_geometry as kg  # noqa: E402

MOTIFS = ["p%02d" % i for i in range(1, 11)] + ["titel"]
TH, PAD, LBL = 300, 10, 24


def planned_hoch(im, plan):
    """Hochbild, wie es das Hoch-Skript bauen wird; erfundener Rand als Grau."""
    W, H = im.size
    sx = W / kg.QUER[0]                      # Plan ist im Render-Maß, Bild evtl. größer (Auslieferung)
    part = im.crop((int(plan["x0"] * sx), 0, int(plan["x1"] * sx), H))
    if plan["mode"] == "crop":
        return part.resize(kg.HOCH, Image.LANCZOS)
    canvas = Image.new("RGB", kg.HOCH, (110, 110, 110))
    canvas.paste(part.resize((kg.HOCH[0], plan["strip_h"]), Image.LANCZOS), (0, plan["top"]))
    return canvas


def main(raw_dir="build/f01_raw", out="build/kern_preview.png", layout_path="tool/comic/folge01_layout.json"):
    with open(layout_path, encoding="utf-8") as f:
        kern = json.load(f)["kern"]
    cols = 2
    cell_w = round(TH * kg.QUER[0] / kg.QUER[1]) + PAD + round(TH * kg.HOCH[0] / kg.HOCH[1])
    rows = (len(MOTIFS) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (cell_w + PAD) + PAD, rows * (TH + LBL + PAD) + PAD), (24, 24, 24))
    d = ImageDraw.Draw(sheet)
    for i, m in enumerate(MOTIFS):
        with Image.open(os.path.join(raw_dir, m + "_quer.jpg")) as src:
            im = src.convert("RGB")
        W, H = im.size
        plan = kg.plan_for(kern[m])
        sx = W / kg.QUER[0]
        marked = im.copy()
        md = ImageDraw.Draw(marked)
        md.rectangle([kern[m][0] * W, 0, kern[m][1] * W, H - 1], outline=(255, 60, 60), width=6)
        md.rectangle([plan["x0"] * sx, 0, plan["x1"] * sx, H - 1], outline=(255, 220, 60), width=4)
        hoch = planned_hoch(im, plan)
        x = PAD + (i % cols) * (cell_w + PAD)
        y = PAD + (i // cols) * (TH + LBL + PAD)
        qt = marked.resize((round(TH * W / H), TH))
        sheet.paste(qt, (x, y + LBL))
        sheet.paste(hoch.resize((round(TH * kg.HOCH[0] / kg.HOCH[1]), TH)), (x + qt.width + PAD, y + LBL))
        label = "%s  kern=%s  %s" % (m, kern[m], "Beschnitt" if plan["mode"] == "crop"
                                      else "Verlängern: unten %d, oben %s" % (plan["bottom"], plan["top_steps"]))
        d.text((x + 4, y + 5), label, fill=(235, 235, 235))
    sheet.save(out)
    print(out, sheet.size)
    return out


if __name__ == "__main__":
    main(*sys.argv[1:])
```

- [ ] **Step 5: Kern-Feld in die Layout-Datei einsetzen** (Edit-Tool; direkt nach der Zeile mit `"reactions": […]`, als eigenes Top-Level-Feld; Startwerte aus der Vorschau vom 30.9., Spec §12.2)

```json
  "kern": {
    "p01": [0.36, 0.64],
    "p02": [0.42, 0.72],
    "p03": [0.38, 0.62],
    "p04": [0.35, 0.65],
    "p05": [0.13, 0.95],
    "p06": [0.14, 0.76],
    "p07": [0.10, 0.93],
    "p08": [0.38, 0.66],
    "p09": [0.38, 0.80],
    "p10": [0.33, 0.63],
    "titel": [0.25, 0.90]
  },
```

Dann `python3 -c "import json; json.load(open('tool/comic/folge01_layout.json'))"` — darf keinen Fehler werfen.

- [ ] **Step 6: `check_layout.py` erweitern** (nach `assert layout["safe"] == 0.8`)

```python
MOTIFS = sorted(EXPECTED) + ["titel"]
assert sorted(layout["kern"]) == sorted(MOTIFS), sorted(layout["kern"])
for m, (kx0, kx1) in layout["kern"].items():
    assert 0 <= kx0 < kx1 <= 1, ("kern", m, kx0, kx1)
```
und die Erfolgszeile ändern in `print("OK: 10 Panels x 2 Formate, Texte = Git-Quelle, reactions ok, kern 11/11")`.

- [ ] **Step 7: Tests und Vorschau laufen lassen**

Run: `cd tool/comic && python3 -m unittest test_kern_tools -v && cd ../.. && python3 tool/comic/check_layout.py && python3 tool/comic/kern_preview.py && python3 tool/comic/kern_faces.py`
Expected: Tests `ok`; `check_layout` druckt `[]` und `OK: … kern 11/11`; `build/kern_preview.png` entsteht; `kern_faces` druckt 10 Zeilen.
Vorschau mit dem Read-Tool ansehen und je Motiv prüfen: Ist der Kern (rot) vollständig im gelben Fenster bzw. Streifen? Kerne, die sichtbar zu eng oder zu weit sind, in der Layout-Datei nachziehen (Spec §12.2 ist die Vorgabe: p01 Mira mit Koffer, p06 Mann und Schirm, p09 Mira und Tafel, Titel Mira und Zug) und die Vorschau wiederholen. Die Datei `build/kern_preview.png` nach `~/kern-vorschau2.png` kopieren (Uli sieht sie nur bei Zweifel, Spec §12.7 Schritt 1).

- [ ] **Step 8: Commit**

```bash
git add tool/comic/folge01_layout.json tool/comic/check_layout.py tool/comic/kern_preview.py tool/comic/kern_faces.py tool/comic/test_kern_tools.py
git commit -F build/kern/msg_t3.txt
```
Text: `feat(comic): Kern je Motiv in der Layout-Datei, Vorschau und Gesichter-Ableitung fürs Hochbild` + Attributionszeilen.

---

### Task 4: `folge01_hoch.py` — Beschnitt oder Verlängern auf der Box, `picks_hoch.txt`

**Files:**
- Create: `tool/comic/folge01_hoch.py`, `tool/comic/overrides_hoch.txt`, `tool/comic/run_hoch.sh`
- Test: `tool/comic/test_hoch.py`

**Interfaces:**
- Consumes: `kern_geometry.plan_for/HOCH` (Task 1), `cc.outpaint_graph`, `cc.run`, `cc.COMFY_INPUT` (Task 2), `folge01_manga.load_overrides`, `folge01_manga.prompt_for`, `folge01_motifs.HOCH_UMGEBUNG/HOCH_HINT_UNTEN/NEG_HOCH_UNTEN/NEG_HOCH_OBEN/STY/NEG_MANGA`.
- Produces:
  - `read_quer_picks(path) -> dict[str, str]` (nur `*_quer`-Schlüssel, Dateien geprüft)
  - `load_kerne(path) -> dict[str, list]`
  - `strip_image(im, plan) -> PIL.Image` (crop: Fenster in Originalauflösung; extend: Streifen 928 × strip_h)
  - `extend(motif, strip, plan, seed, out_path) -> None`
  - `main(picks_path, overrides_path=None) -> str` (Pfad der geschriebenen `picks_hoch.txt`)
  - Ausgabe `~/comfy_f01/hoch/<motiv>_hoch.png`; `picks_hoch.txt` neben dem Skript mit 22 Zeilen (11 quer aus den Picks, 11 hoch).
  - Marken: `CROP <m> x0 x1`, `EXTEND <m> strip_h bottom top_steps`, `OK <m>`, `SKIP <m>`, `ERR <m> …`, `HOCH_DONE`.

- [ ] **Step 1: Test schreiben**

```python
#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_hoch (ohne Box: cc.run wird ersetzt)"""
import json
import os
import tempfile
import unittest

from PIL import Image, ImageDraw

import comfy_client as cc
import folge01_hoch as fh
import kern_geometry as kg

MOTIFS = ["p%02d" % i for i in range(1, 11)] + ["titel"]


def gradient(w, h):
    """Billiges Testbild mit Struktur (keine Pixelschleifen): farbige Kacheln."""
    im = Image.new("RGB", (w, h), (30, 30, 30))
    d = ImageDraw.Draw(im)
    s = 48
    for j in range(0, h, s):
        for i in range(0, w, s):
            k = (i // s + j // s) % 5
            d.rectangle([i, j, i + s - 1, j + s - 1], fill=(50 * k, 255 - 40 * k, (90 * k) % 256))
    return im


class Base(unittest.TestCase):
    def setUp(self):
        self.d = tempfile.mkdtemp()
        self.quer = {}
        for m in MOTIFS:
            p = os.path.join(self.d, "%s_quer_%s_quer_00001_.png" % (m, m))
            gradient(1664, 928).save(p)
            self.quer[m] = p
        self.picks = os.path.join(self.d, "picks_manga.txt")
        with open(self.picks, "w", encoding="utf-8") as f:
            for m in MOTIFS:
                f.write("%s_quer=%s\n" % (m, self.quer[m]))
                f.write("%s_hoch=%s/alt_%s_hoch.png\n" % (m, self.d, m))   # alte Hoch-Zeilen, Dateien fehlen
        self.layout = os.path.join(self.d, "layout.json")
        kern = {m: [0.4, 0.6] for m in MOTIFS}
        kern["p05"] = [0.13, 0.95]
        with open(self.layout, "w", encoding="utf-8") as f:
            json.dump({"kern": kern, "panels": {}}, f)
        self._saved = (fh.OUT, fh.TMP, fh.LAYOUT, fh.PICKS_OUT, cc.COMFY_INPUT, cc.run)
        fh.OUT, fh.TMP = os.path.join(self.d, "hoch"), os.path.join(self.d, "hoch_tmp")
        fh.LAYOUT, fh.PICKS_OUT = self.layout, os.path.join(self.d, "picks_hoch.txt")
        cc.COMFY_INPUT = os.path.join(self.d, "input")
        os.makedirs(cc.COMFY_INPUT)
        self.calls = []

        def fake_run(graph, prefix, out_dir, client_id="x"):
            pad = [v for v in graph.values() if v["class_type"] == "ImagePadForOutpaint"][0]["inputs"]
            with Image.open(os.path.join(cc.COMFY_INPUT, graph["IN"]["inputs"]["image"])) as im:
                w, h = im.size
            os.makedirs(out_dir, exist_ok=True)
            dest = os.path.join(out_dir, "%s_%s_00001_.png" % (prefix, prefix))
            Image.new("RGB", (w, h + pad["top"] + pad["bottom"]), (60, 60, 60)).save(dest)
            self.calls.append((prefix, pad["top"], pad["bottom"], graph["4"]["inputs"]["text"],
                               graph["5"]["inputs"]["text"]))
            return [dest]
        cc.run = fake_run

    def tearDown(self):
        fh.OUT, fh.TMP, fh.LAYOUT, fh.PICKS_OUT, cc.COMFY_INPUT, cc.run = self._saved


class ReadPicks(Base):
    def test_read_quer_picks_ignores_hoch_lines(self):
        picks = fh.read_quer_picks(self.picks)
        self.assertEqual(sorted(picks), sorted(m + "_quer" for m in MOTIFS))

    def test_read_quer_picks_checks_quer_files(self):
        with open(self.picks, "a", encoding="utf-8") as f:
            f.write("p99_quer=%s/nix.png\n" % self.d)
        with self.assertRaises(FileNotFoundError) as cm:
            fh.read_quer_picks(self.picks)
        self.assertIn("FEHLT p99_quer", str(cm.exception))

    def test_load_kerne_requires_all_motifs(self):
        self.assertEqual(sorted(fh.load_kerne(self.layout)), sorted(MOTIFS))
        with open(self.layout, "w", encoding="utf-8") as f:
            json.dump({"kern": {"p01": [0.1, 0.5]}}, f)
        with self.assertRaises(ValueError) as cm:
            fh.load_kerne(self.layout)
        self.assertIn("titel", str(cm.exception))


class Strip(Base):
    def test_strip_crop_keeps_native_resolution(self):
        plan = kg.plan_for([0.4, 0.6])
        s = fh.strip_image(gradient(1664, 928), plan)
        self.assertEqual(s.size, (518, 928))

    def test_strip_extend_is_928_wide_multiple_of_16(self):
        plan = kg.plan_for([0.13, 0.95])
        s = fh.strip_image(gradient(1664, 928), plan)
        self.assertEqual(s.size, (928, plan["strip_h"]))
        self.assertEqual(s.height % 16, 0)


class Main(Base):
    def test_crop_only_motifs_need_no_box_and_picks_file_is_complete(self):
        with open(self.layout, "w", encoding="utf-8") as f:
            json.dump({"kern": {m: [0.4, 0.6] for m in MOTIFS}, "panels": {}}, f)
        out = fh.main(self.picks)
        self.assertEqual(self.calls, [])
        with open(out, encoding="utf-8") as f:
            lines = [l for l in f.read().splitlines() if l and not l.startswith("#")]
        self.assertEqual(len(lines), 22)
        self.assertIn("p05_hoch=%s" % os.path.join(fh.OUT, "p05_hoch.png"), lines)
        self.assertIn("p05_quer=%s" % self.quer["p05"], lines)
        for m in MOTIFS:
            with Image.open(os.path.join(fh.OUT, m + "_hoch.png")) as im:
                self.assertEqual(im.size, (518, 928))

    def test_extend_runs_bottom_then_top_steps_and_writes_final(self):
        fh.main(self.picks)
        plan = kg.plan_for([0.13, 0.95])
        prefixes = [c[0] for c in self.calls]
        self.assertEqual(prefixes[0], "p05_hochB")
        self.assertEqual(self.calls[0][1:3], (0, plan["bottom"]))
        self.assertIn("legs and feet", self.calls[0][3])
        self.assertIn("duplicate person", self.calls[0][4])
        self.assertNotIn("human figure", self.calls[0][4])
        tops = [c[1] for c in self.calls[1:]]
        self.assertEqual(tops, plan["top_steps"])
        self.assertEqual(prefixes[-1], "p05_hoch")
        for c in self.calls[1:]:
            self.assertIn("empty background only", c[3])
            self.assertIn("human figure", c[4])
        with Image.open(os.path.join(fh.OUT, "p05_hoch.png")) as im:
            self.assertEqual(im.size, (928, 1664))

    def test_main_skips_existing_unless_force(self):
        fh.main(self.picks)
        n = len(self.calls)
        fh.main(self.picks)
        self.assertEqual(len(self.calls), n)                  # SKIP: nichts neu gerendert
        ov = os.path.join(self.d, "ov.txt")
        with open(ov, "w", encoding="utf-8") as f:
            f.write("p05_hoch seed=777 force\n")
        fh.main(self.picks, ov)
        self.assertGreater(len(self.calls), n)
        with open(ov, "w", encoding="utf-8") as f:
            f.write("p05_hoch control=canny\n")
        with self.assertRaises(ValueError):
            fh.main(self.picks, ov)                           # nur seed/force erlaubt


if __name__ == "__main__":
    unittest.main()
```

Hinweis zur Fälschung von `cc.run`: sie liest den Eingabenamen aus `graph["IN"]["inputs"]["image"]`, die Polsterung aus dem `ImagePadForOutpaint`-Knoten und die Prompts aus `"4"`/`"5"` — genau die Schlüssel, die `outpaint_graph` (Task 2) setzt. Oben in der Testdatei `from PIL import Image, ImageDraw` importieren.

- [ ] **Step 2: Test laufen lassen, Fehlschlag sehen**

Run: `cd tool/comic && python3 -m unittest test_hoch -v`
Expected: `ModuleNotFoundError: No module named 'folge01_hoch'`

- [ ] **Step 3: `folge01_hoch.py` schreiben**

```python
#!/usr/bin/env python3
"""Hochbild aus dem Querbild (Spec §12). Läuft auf der Box in ~/f01tool.
  folge01_hoch.py picks_manga.txt [overrides_hoch.txt]
Quelle je Motiv: die *_quer-Zeile aus picks_manga.txt (alte *_hoch-Zeilen werden ignoriert). Kern aus
folge01_layout.json (Feld "kern"). Beschnitt → Fenster in Originalauflösung (518 × 928), keine Erzeugung.
Verlängern → Kernstreifen 928 breit, unten BOTTOM px mit Figuren-Prompt, oben in Schritten mit
Umgebungs-Prompt (outpaint_graph). Ergebnis unter festem Namen ~/comfy_f01/hoch/<motiv>_hoch.png;
picks_hoch.txt (11 quer + 11 hoch) für folge01_finish.py. Übersprungen wird ein Motiv, wenn seine
Ausgabe existiert und kein `force` in overrides_hoch.txt steht (erlaubt: seed=N, force).
Marken: CROP/EXTEND/OK/SKIP/ERR je Motiv, HOCH_DONE."""
import json
import os
import shutil
import sys

from PIL import Image

import comfy_client as cc
import kern_geometry as kg
from folge01_manga import load_overrides, prompt_for
from folge01_motifs import HOCH_HINT_UNTEN, HOCH_UMGEBUNG, NEG_HOCH_OBEN, NEG_HOCH_UNTEN, NEG_MANGA, STY

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.expanduser("~/comfy_f01")
OUT = os.path.join(ROOT, "hoch")
TMP = os.path.join(ROOT, "hoch_tmp")
LAYOUT = os.path.join(HERE, "folge01_layout.json")
PICKS_OUT = os.path.join(HERE, "picks_hoch.txt")
MOTIFS = ["p%02d" % i for i in range(1, 11)] + ["titel"]
HOCH_KEYS = frozenset({"seed", "force"})
DEFAULT_SEED = 831
FEATHER_UNTEN, FEATHER_OBEN = 96, 64


def read_quer_picks(path):
    picks = {}
    with open(os.path.expanduser(path), encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            key, src = line.split("=", 1)
            key, src = key.strip(), os.path.expanduser(src.strip())
            if not key.endswith("_quer"):
                continue
            if not os.path.exists(src):
                raise FileNotFoundError("FEHLT %s: %s" % (key, src))
            picks[key] = src
    return picks


def load_kerne(path=LAYOUT):
    with open(path, encoding="utf-8") as f:
        kern = json.load(f).get("kern", {})
    missing = [m for m in MOTIFS if m not in kern]
    if missing:
        raise ValueError("kern fehlt in der Layout-Datei für: %s" % ", ".join(missing))
    return kern


def strip_image(im, plan):
    """Fenster (crop, Originalauflösung) bzw. Kernstreifen (extend, 928 × strip_h) aus dem Querbild."""
    W, H = im.size
    part = im.crop((plan["x0"], 0, plan["x1"], H))
    if plan["mode"] == "crop":
        return part
    return part.resize((kg.HOCH[0], plan["strip_h"]), Image.LANCZOS)


def _to_input(path_or_img, name):
    dest = os.path.join(cc.COMFY_INPUT, name)
    if isinstance(path_or_img, str):
        shutil.copy(path_or_img, dest)
    else:
        path_or_img.save(dest)
    return name


def extend(motif, strip, plan, seed, out_path):
    cur = _to_input(strip, "hoch_%s.png" % motif)
    last_file = None
    if plan["bottom"]:
        prompt = prompt_for(motif + "_hoch") + HOCH_HINT_UNTEN
        got = cc.run(cc.outpaint_graph(cur, 0, plan["bottom"], prompt, NEG_MANGA + NEG_HOCH_UNTEN, seed,
                                       "%s_hochB" % motif, feather=FEATHER_UNTEN), "%s_hochB" % motif, TMP, "f01hoch")
        last_file = got[0]
        cur = _to_input(last_file, "hoch_%s_B.png" % motif)
    prompt = STY + ", empty background only, " + HOCH_UMGEBUNG[motif] + ", vertical framing, tall composition"
    steps = plan["top_steps"]
    for i, top in enumerate(steps):
        last = i == len(steps) - 1
        prefix = "%s_hoch" % motif if last else "%s_hochT%d" % (motif, i + 1)
        got = cc.run(cc.outpaint_graph(cur, top, 0, prompt, NEG_MANGA + NEG_HOCH_OBEN, seed + i, prefix,
                                       feather=FEATHER_OBEN), prefix, OUT if last else TMP, "f01hoch")
        last_file = got[0]
        if not last:
            cur = _to_input(last_file, "hoch_%s_T%d.png" % (motif, i + 1))
    if last_file is None:
        strip.save(out_path)
    else:
        shutil.copy(last_file, out_path)


def main(picks_path, overrides_path=None):
    picks = read_quer_picks(picks_path)
    kerne = load_kerne(LAYOUT)
    ov = load_overrides(overrides_path, allowed=HOCH_KEYS) if overrides_path else {}
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(TMP, exist_ok=True)
    lines = ["# picks_hoch.txt — von folge01_hoch.py geschrieben (Spec §12): quer aus picks_manga.txt,",
             "# hoch = aus dem Querbild abgeleitet. Eingabe für folge01_finish.py."]
    for m in MOTIFS:
        src = picks["%s_quer" % m]
        out_path = os.path.join(OUT, "%s_hoch.png" % m)
        lines.append("%s_quer=%s" % (m, src))
        lines.append("%s_hoch=%s" % (m, out_path))
        opts = ov.get("%s_hoch" % m, {})
        if os.path.exists(out_path) and not opts.get("force"):
            print("SKIP", m, flush=True)
            continue
        plan = kg.plan_for(kerne[m])
        try:
            with Image.open(src) as raw:
                strip = strip_image(raw.convert("RGB"), plan)
            if plan["mode"] == "crop":
                print("CROP", m, plan["x0"], plan["x1"], flush=True)
                strip.save(out_path)
            else:
                print("EXTEND", m, plan["strip_h"], plan["bottom"], plan["top_steps"], flush=True)
                extend(m, strip, plan, opts.get("seed", DEFAULT_SEED), out_path)
            print("OK", m, flush=True)
        except Exception as e:  # noqa: BLE001
            print("ERR", m, repr(e)[:300], flush=True)
    with open(PICKS_OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("HOCH_DONE", flush=True)
    return PICKS_OUT


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
```

- [ ] **Step 4: Test laufen lassen, grün sehen**

Run: `cd tool/comic && python3 -m unittest test_hoch -v`
Expected: alle `ok`. Hinweis: `test_crop_only_motifs…` erwartet `(518, 928)` — `strip_image` liefert im Fall crop das Fenster in Originalauflösung; die Vergrößerung (`folge01_finish.py`) bringt es per 4x-UltraSharp auf 1080 × 1936 (Seitenverhältnis 518/928 = 0,5582 gegen 0,5579, Abweichung 0,05 %, unsichtbar).

- [ ] **Step 5: `overrides_hoch.txt` und `run_hoch.sh` anlegen**

`tool/comic/overrides_hoch.txt`:
```
# Overrides für das Hochbild aus dem Querbild (folge01_hoch.py picks_manga.txt overrides_hoch.txt).
# Grammatik: <motiv>_hoch [seed=N] [force]   — Standard-Seed 831; force erzwingt Neu-Ableitung trotz
# vorhandener Ausgabe in ~/comfy_f01/hoch/. Umgebungssätze stehen in folge01_motifs.HOCH_UMGEBUNG.
```

`tool/comic/run_hoch.sh`:
```sh
#!/bin/sh
# Hochbild aus dem Querbild (Spec §12). Läuft auf der Box in ~/f01tool, Log ~/comfy_f01/hoch.log.
cd ~/f01tool
until curl -s -m 3 localhost:8188/system_stats > /dev/null; do sleep 5; done
echo "--- hoch $(date +%H:%M:%S)"
python3 folge01_hoch.py picks_manga.txt overrides_hoch.txt
echo "RUN_HOCH_DONE"
```

- [ ] **Step 6: Gesamte Werkzeug-Testsuite**

Run: `cd tool/comic && python3 -W error::ResourceWarning -m unittest discover -s . -p "test_*.py"`
Expected: `OK`, mindestens 69 + 14 Tests.

- [ ] **Step 7: Commit**

```bash
git add tool/comic/folge01_hoch.py tool/comic/overrides_hoch.txt tool/comic/run_hoch.sh tool/comic/test_hoch.py
git commit -F build/kern/msg_t4.txt
```
Text: `feat(comic): folge01_hoch — Hochbild aus dem Querbild (Beschnitt oder Verlängern), picks_hoch.txt` + Attributionszeilen.

---

### Task 5: `check_kern.py` — INV-17 am Auslieferungsbild

**Files:**
- Create: `tool/comic/check_kern.py`
- Test: `tool/comic/test_check_kern.py`

**Interfaces:**
- Consumes: `kern_geometry.plan_for` (Task 1).
- Produces: `kern_regions(plan) -> (quer_box, hoch_box)` (normierte Boxen `(x0, y0, x1, y1)`), `diff(quer_img, hoch_img, plan) -> float`, `main(raw_dir="build/f01_raw", layout_path="tool/comic/folge01_layout.json") -> int` (Exit-Code), CLI `python3 tool/comic/check_kern.py [build/f01_raw]`; Ausgabe je Motiv `<m> <diff>`; `LIMIT = 10.0`.

- [ ] **Step 1: Test schreiben**

```python
#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_check_kern"""
import json
import os
import tempfile
import unittest

from PIL import Image, ImageDraw

import check_kern as ck
import kern_geometry as kg


def pattern(w, h, shift=0):
    """Farbige Kacheln (48 px); `shift` verschiebt die Farbfolge → deutlich anderes Bild."""
    im = Image.new("RGB", (w, h), (30, 30, 30))
    d = ImageDraw.Draw(im)
    s = 48
    for j in range(0, h, s):
        for i in range(0, w, s):
            k = (i // s + j // s + shift) % 5
            d.rectangle([i, j, i + s - 1, j + s - 1], fill=(50 * k, 255 - 40 * k, (90 * k) % 256))
    return im


def hoch_from(quer, plan):
    W, H = quer.size
    sx = W / kg.QUER[0]
    part = quer.crop((int(plan["x0"] * sx), 0, int(plan["x1"] * sx), H))
    if plan["mode"] == "crop":
        return part.resize((1080, 1936), Image.LANCZOS)
    canvas = Image.new("RGB", (1080, 1936), (120, 120, 120))
    sh = round(plan["strip_h"] * 1936 / 1664)
    canvas.paste(part.resize((1080, sh), Image.LANCZOS), (0, round(plan["top"] * 1936 / 1664)))
    return canvas


class Diff(unittest.TestCase):
    def test_identical_kern_is_below_limit_crop_and_extend(self):
        quer = pattern(1920, 1072)
        for kern in ([0.4, 0.6], [0.13, 0.95]):
            plan = kg.plan_for(kern)
            self.assertLess(ck.diff(quer, hoch_from(quer, plan), plan), ck.LIMIT, kern)

    def test_shifted_kern_is_above_limit(self):
        quer = pattern(1920, 1072)
        plan = kg.plan_for([0.4, 0.6])
        wrong = hoch_from(pattern(1920, 1072, shift=2), plan)
        self.assertGreater(ck.diff(quer, wrong, plan), ck.LIMIT)

    def test_main_reports_and_exits(self):
        d = tempfile.mkdtemp()
        quer = pattern(1920, 1072)
        motifs = ["p%02d" % i for i in range(1, 11)] + ["titel"]
        kern = {m: [0.4, 0.6] for m in motifs}
        kern["p07"] = [0.1, 0.93]
        for m in motifs:
            quer.save(os.path.join(d, m + "_quer.jpg"), quality=95)
            src = quer if m != "p03" else pattern(1920, 1072, shift=2)
            hoch_from(src, kg.plan_for(kern[m])).save(os.path.join(d, m + "_hoch.jpg"), quality=95)
        layout = os.path.join(d, "layout.json")
        with open(layout, "w", encoding="utf-8") as f:
            json.dump({"kern": kern}, f)
        self.assertEqual(ck.main(d, layout), 1)       # p03 weicht ab
        pattern(1920, 1072).save(os.path.join(d, "p03_quer.jpg"), quality=95)
        hoch_from(pattern(1920, 1072), kg.plan_for(kern["p03"])).save(os.path.join(d, "p03_hoch.jpg"), quality=95)
        self.assertEqual(ck.main(d, layout), 0)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag sehen**

Run: `cd tool/comic && python3 -m unittest test_check_kern -v`
Expected: `ModuleNotFoundError: No module named 'check_kern'`

- [ ] **Step 3: `check_kern.py` schreiben**

```python
#!/usr/bin/env python3
"""INV-17 (Spec §12.5): der Kern des Hochbilds ist (bis auf Skalierung) der Kern des Querbilds.
Aufruf im Repo-Wurzelverzeichnis: python3 tool/comic/check_kern.py [build/f01_raw]
Je Motiv werden die Kern-Regionen beider Auslieferungsbilder ausgeschnitten, auf dieselbe Größe
gebracht und als Graustufen verglichen (mittlere Abweichung 0..255). Die Überblendzonen am oberen und
unteren Rand der Region (MARGIN) bleiben außen vor. Ausgabe `<motiv> <diff>`, Exit 1 über LIMIT."""
import json
import os
import sys

from PIL import Image, ImageChops, ImageStat

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kern_geometry as kg  # noqa: E402

MOTIFS = ["p%02d" % i for i in range(1, 11)] + ["titel"]
LIMIT = 10.0
MARGIN = 0.06
SIZE = (128, 256)


def kern_regions(plan):
    """Normierte Boxen (x0, y0, x1, y1) der Kern-Region im Quer- und im Hochbild."""
    quer = (plan["x0"] / kg.QUER[0], 0.0, plan["x1"] / kg.QUER[0], 1.0)
    if plan["mode"] == "crop":
        hoch = (0.0, 0.0, 1.0, 1.0)
    else:
        hoch = (0.0, plan["top"] / kg.HOCH[1], 1.0, (plan["top"] + plan["strip_h"]) / kg.HOCH[1])
    return quer, hoch


def _region(im, box):
    W, H = im.size
    x0, y0, x1, y1 = box
    dy = (y1 - y0) * MARGIN
    return im.crop((round(x0 * W), round((y0 + dy) * H), round(x1 * W), round((y1 - dy) * H)))


def diff(quer_img, hoch_img, plan):
    q, h = kern_regions(plan)
    a = _region(quer_img, q).convert("L").resize(SIZE, Image.LANCZOS)
    b = _region(hoch_img, h).convert("L").resize(SIZE, Image.LANCZOS)
    return ImageStat.Stat(ImageChops.difference(a, b)).mean[0]


def main(raw_dir="build/f01_raw", layout_path="tool/comic/folge01_layout.json"):
    with open(layout_path, encoding="utf-8") as f:
        kern = json.load(f)["kern"]
    bad = []
    for m in MOTIFS:
        plan = kg.plan_for(kern[m])
        with Image.open(os.path.join(raw_dir, m + "_quer.jpg")) as q, \
                Image.open(os.path.join(raw_dir, m + "_hoch.jpg")) as h:
            d = diff(q.convert("RGB"), h.convert("RGB"), plan)
        print("%s %.1f" % (m, d))
        if d > LIMIT:
            bad.append(m)
    if bad:
        print("KERN WEICHT AB: " + ", ".join(bad))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(*sys.argv[1:]))
```

- [ ] **Step 4: Test laufen lassen, grün sehen**

Run: `cd tool/comic && python3 -m unittest test_check_kern -v`
Expected: alle `ok`. Liegt `test_identical_kern…` knapp über `LIMIT` (JPEG und Lanczos-Doppelskalierung), erst die Zahl ansehen (`print`), dann `LIMIT` höchstens auf 14 anheben und den Verschiebungs-Test gegenprüfen (muss deutlich darüber liegen, typisch > 40).

- [ ] **Step 5: Commit**

```bash
git add tool/comic/check_kern.py tool/comic/test_check_kern.py
git commit -F build/kern/msg_t5.txt
```
Text: `feat(comic): check_kern — INV-17, Kern des Hochbilds gleich Kern des Querbilds` + Attributionszeilen.

---

### Task 6: Box-Lauf — Hochbilder ableiten, Bogen für Uli (STOP)

**Files:**
- keine Code-Änderung; Ergebnisse unter `build/f01_hoch/` (nicht versioniert) und `~/f01-hoch-bogen.png`.

**Interfaces:**
- Consumes: `run_hoch.sh`, `folge01_hoch.py`, `overrides_hoch.txt`, Layout mit `kern` (Tasks 1–4); Quer-Master auf der Box `~/comfy_f01/manga/*_quer_*.png` (laut `picks_manga.txt`).
- Produces: `pc:~/comfy_f01/hoch/<motiv>_hoch.png` (11), `pc:~/f01tool/picks_hoch.txt`, lokaler Bogen `build/f01_hoch/bogen.png` → `~/f01-hoch-bogen.png`.

- [ ] **Step 1: Box vorbereiten und Skripte hochladen**

```bash
/usr/local/bin/wakegpu
ssh pc 'touch ~/.no-idle-suspend; until curl -s -m 3 localhost:8188/system_stats > /dev/null; do sleep 5; done; echo COMFY_OBEN'
scp tool/comic/kern_geometry.py tool/comic/comfy_client.py tool/comic/folge01_motifs.py tool/comic/folge01_manga.py tool/comic/folge01_hoch.py tool/comic/folge01_layout.json tool/comic/overrides_hoch.txt tool/comic/run_hoch.sh tool/comic/picks_manga.txt pc:f01tool/
ssh pc 'ls ~/comfy_f01/manga/ | grep -c "_quer_"'
```
Expected: `COMFY_OBEN`; die letzte Zeile ≥ 11.

- [ ] **Step 2: Lauf starten und Marken beobachten**

```bash
ssh pc 'rm -f ~/comfy_f01/hoch.log; setsid nohup sh ~/f01tool/run_hoch.sh > ~/comfy_f01/hoch.log 2>&1 </dev/null &'
```
(Der ssh-Aufruf hängt nach dem Start — mit `timeout 20` davor; der Lauf läuft weiter.) Monitor auf `~/comfy_f01/hoch.log` mit den Marken `CROP|EXTEND|OK|SKIP|ERR|Traceback|HOCH_DONE|RUN_HOCH_DONE`. Erwartung: 6 × `CROP`, 5 × `EXTEND` (p05, p06, p07, p09, titel), 11 × `OK`, dann `HOCH_DONE`. Dauer ≈ 5 × 5 Minuten. Bei `ERR`: Log lesen (`ssh pc 'tail -n 30 ~/comfy_f01/hoch.log'`), typische Ursachen: ComfyUI nach Modellwechsel aus (`systemctl --user restart comfyui`), Node-Fehler im Graph (Test in Task 2 deckt die Verdrahtung), fehlende Quelle (Picks).

- [ ] **Step 3: Abholen und Bogen bauen**

```bash
mkdir -p build/f01_hoch
scp 'pc:comfy_f01/hoch/*_hoch.png' build/f01_hoch/
scp pc:f01tool/picks_hoch.txt build/f01_hoch/picks_hoch.txt
```
Bogen mit `tool/comic/sheet.py` (Kontaktbogen `sheet.py OUT.png COLS label=path …`): je Motiv das Querbild aus `build/f01_raw/<m>_quer.jpg` und das Hochbild aus `build/f01_hoch/<m>_hoch.png`, 4 Spalten (quer, hoch, quer, hoch):
```bash
python3 tool/comic/sheet.py build/f01_hoch/bogen.png 4 p01_quer=build/f01_raw/p01_quer.jpg p01_hoch=build/f01_hoch/p01_hoch.png p02_quer=build/f01_raw/p02_quer.jpg p02_hoch=build/f01_hoch/p02_hoch.png p03_quer=build/f01_raw/p03_quer.jpg p03_hoch=build/f01_hoch/p03_hoch.png p04_quer=build/f01_raw/p04_quer.jpg p04_hoch=build/f01_hoch/p04_hoch.png p05_quer=build/f01_raw/p05_quer.jpg p05_hoch=build/f01_hoch/p05_hoch.png p06_quer=build/f01_raw/p06_quer.jpg p06_hoch=build/f01_hoch/p06_hoch.png p07_quer=build/f01_raw/p07_quer.jpg p07_hoch=build/f01_hoch/p07_hoch.png p08_quer=build/f01_raw/p08_quer.jpg p08_hoch=build/f01_hoch/p08_hoch.png p09_quer=build/f01_raw/p09_quer.jpg p09_hoch=build/f01_hoch/p09_hoch.png p10_quer=build/f01_raw/p10_quer.jpg p10_hoch=build/f01_hoch/p10_hoch.png titel_quer=build/f01_raw/titel_quer.jpg titel_hoch=build/f01_hoch/titel_hoch.png
cp build/f01_hoch/bogen.png ~/f01-hoch-bogen.png
```
Bogen mit dem Read-Tool ansehen. Selbstprüfung je Motiv „Verlängern": kein zweiter Körper, keine Naht am Kernrand, oben keine wiederholte Szene, unten laufen Beine/Boden weiter. Fällt ein Motiv durch: `overrides_hoch.txt` Zeile `<motiv>_hoch seed=<neu> force`, Umgebungssatz in `HOCH_UMGEBUNG` schärfen (z. B. „no roof overhead"), `scp` der beiden Dateien, Lauf wiederholen (nur dieses Motiv rendert neu, Rest `SKIP`), Bogen neu.

- [ ] **Step 4: STOP — Ulis Freigabe**

An Uli: Bogen `~/f01-hoch-bogen.png`, Satz je Motiv (Beschnitt/Verlängern), Bitte um „ok" oder Nennung der Motive mit Seed-/Kern-/Umgebungswunsch. **Nicht weiter, bevor Uli freigibt** (Spec §12.7 Schritt 3). Nach Freigabe: Kill-Switch bleibt bis Task 7 Schritt 1 gesetzt (Vergrößerung braucht die Box).

---

### Task 7: Vergrößern, Prüfen, Hoch-Layout, Lettering, Tippflächen, Flutter-Tests

**Files:**
- Modify: `tool/comic/folge01_layout.json` (`panels.*.hoch`: `faces`, `bubbles`, bei Bedarf `nogo`)
- Regenerate: `lib/features/story/episodes/folge_01_layout.g.dart` (per `gen_layout_dart.py`)
- Replace: `assets/story/folge01/*_hoch.jpg` (11) und `*_reaction_hoch.jpg` (3) (per `letter_folge01.py`)
- Test: bestehende `test/features/story/folge_01_layout_test.dart`, `folge_01_panel_assets_test.dart`, `folge_01_regen_test.dart`; Werkzeug-Suite.

**Interfaces:**
- Consumes: `picks_hoch.txt` (Task 6), `folge01_finish.py` (unverändert), `check_bars.py`, `check_kern.py` (Task 5), `kern_faces.py` (Task 3), `letter_preview.py`, `letter_folge01.py`, `gen_layout_dart.py`.
- Produces: `build/f01_raw/<m>_hoch.jpg` (11, 1080 × 1936), neue Hoch-Assets, neue Hoch-Tippflächen.

- [ ] **Step 1: Vergrößerung auf der Box**

```bash
scp build/f01_hoch/picks_hoch.txt tool/comic/folge01_finish.py pc:f01tool/
ssh pc 'cd ~/f01tool && cp run_finish.sh run_finish_hoch.sh && sed -i "s/picks_manga.txt/picks_hoch.txt/" run_finish_hoch.sh && grep picks run_finish_hoch.sh'
ssh pc 'setsid nohup sh ~/f01tool/run_finish_hoch.sh > ~/f01tool/finish_hoch.log 2>&1 </dev/null &'
```
Monitor auf `~/f01tool/finish_hoch.log` (`OK|SKIP|ERR|FINISH_DONE`). Erwartung: 11 × `SKIP` (quer, Ziel jünger als Quelle) und 11 × `OK <m>_hoch (1080, 1936)`; Dauer ≈ 11 × 40 s. Dann:
```bash
scp 'pc:comfy_f01/final/*_hoch.jpg' build/f01_raw/
ssh pc 'rm -f ~/.no-idle-suspend'
```

- [ ] **Step 2: Balken- und Kern-Prüfung**

Run: `python3 tool/comic/check_bars.py build/f01_raw; python3 tool/comic/check_kern.py build/f01_raw`
Expected: `check_bars` alle ≤ 5 % (Exit 0); `check_kern` je Motiv ein Wert unter 10 (Exit 0). Liegt ein „Verlängern"-Motiv knapp darüber, den Wert mit dem Bogen abgleichen: Überblendung nagt am Rand der Region (deshalb `MARGIN`); erst wenn der Kern sichtbar anders ist, ist es ein Fehler (Seed/Lauf prüfen).

- [ ] **Step 3: Hoch-Gesichter ableiten und eintragen**

Run: `python3 tool/comic/kern_faces.py`
Je Panel die gedruckte Liste in `tool/comic/folge01_layout.json` unter `panels.<pid>.hoch.faces` eintragen (Edit-Tool, Werte auf 2–3 Nachkommastellen gerundet). Panels ohne Quer-Gesichter (p02, p04) behalten `[]`.

- [ ] **Step 4: Hoch-Blasen neu setzen**

Für jedes Panel die Blasen in `panels.<pid>.hoch.bubbles` auf das neue Hochbild legen (Texte unverändert, `lines`/`furigana` beibehalten). Regeln: innerhalb der sicheren Zone (x in 0,10..0,90), nicht über abgeleiteten Gesichtern, nicht in den `nogo`-Zonen (Erzählkasten oben, Hinweis unten — bleiben wie bisher), Schrift ≥ 30 px (KLEINSCHRIFT-Prüfung), Lesereihenfolge der Blasen = Reihenfolge in der Datei. Arbeitsweise: `python3 tool/comic/layout_preview.py` (zeichnet Rechtecke auf `build/f01_raw`) und `python3 tool/comic/check_layout.py` nach jeder Änderung; Vorschau mit dem Read-Tool ansehen (`build/layout_preview_hoch.png`). Erwartung am Ende: `check_layout` druckt `[]` und `OK: … kern 11/11`.

- [ ] **Step 5: Tippflächen, Lettering, Sichtprüfung**

Run:
```bash
python3 tool/comic/gen_layout_dart.py
python3 tool/comic/letter_folge01.py
python3 tool/comic/letter_preview.py faces
```
Expected: `lib/features/story/episodes/folge_01_layout.g.dart` neu (nur Hoch-Konstanten geändert), `OK: 28 Dateien nach assets/story/folge01`, `git status` zeigt genau die 14 Hoch-Dateien geändert (11 `_hoch.jpg`, 3 `_reaction_hoch.jpg`); `build/letter_preview_hoch_faces.png` mit dem Read-Tool ansehen: Blasen lesbar, nichts über Gesichtern, kein Text angeschnitten.

- [ ] **Step 6: Tests**

Run:
```bash
cd tool/comic && python3 -W error::ResourceWarning -m unittest discover -s . -p "test_*.py"
cd ../.. && flutter test test/features/story/folge_01_layout_test.dart test/features/story/folge_01_panel_assets_test.dart test/features/story/folge_01_regen_test.dart
```
Expected: Werkzeug-Suite `OK`; Flutter `All tests passed!`.

- [ ] **Step 7: Commit und Push**

```bash
git add tool/comic/folge01_layout.json lib/features/story/episodes/folge_01_layout.g.dart assets/story/folge01/
git commit -F build/kern/msg_t7.txt
git push origin impl/manga-vollbild-app
```
Text: `feat(story): Folge 01 Hochbilder aus den Querbildern abgeleitet — Kern, Hoch-Layout, Lettering, Tippflächen (Spec §12)` + Attributionszeilen.

---

### Task 8: README, Emulator-Sichtprüfung, Gerätetest S23, Abschluss

**Files:**
- Modify: `tool/comic/README.md` (neuer Abschnitt nach „8. Vergrößern…", Tabelle „Dateien", „Regeln und Fallen")
- keine Code-Änderung.

**Interfaces:**
- Consumes: alles aus Task 1–7; Emulator-Weg laut Gedächtnis `android-emulator-gpu-box` (AVD `s23` auf `pc`), S23-Weg laut `cross-machine-test-deploy` + Build-Nummer-Regel (`--build-number` > 2002).

- [ ] **Step 1: README ergänzen** (nach Abschnitt 8, neue Nummer „8b. Hochbild aus dem Querbild (Spec §12)")

```markdown
### 8b. Hochbild aus dem Querbild (Spec §12, seit 1.10.)

Das Hochbild wird nicht mehr gerendert, sondern aus dem freigegebenen Manga-Querbild abgeleitet:
Kern (`"kern": {motiv: [x0, x1]}` in `folge01_layout.json`) passt ins Hochfenster → Beschnitt;
Kern breiter → Streifen + Rand-Ausmalen (unten 128 px Figuren-Prompt, oben Schritte ≤ 480 px
Umgebungs-Prompt aus `folge01_motifs.HOCH_UMGEBUNG`).

```
python3 tool/comic/kern_preview.py                     # Vorschau: build/kern_preview.png (Kern rot, Fenster gelb)
scp tool/comic/*.py tool/comic/*.sh tool/comic/*.txt tool/comic/folge01_layout.json pc:f01tool/
ssh pc 'setsid nohup sh ~/f01tool/run_hoch.sh > ~/comfy_f01/hoch.log 2>&1 </dev/null &'
```
Marken: `CROP/EXTEND/OK/SKIP/ERR <motiv>`, `HOCH_DONE`. Ergebnis `~/comfy_f01/hoch/<motiv>_hoch.png`
(fester Name, kein ComfyUI-Zähler) und `~/f01tool/picks_hoch.txt` (quer + hoch) für die Vergrößerung:
```
scp 'pc:comfy_f01/hoch/*_hoch.png' build/f01_hoch/ ; scp pc:f01tool/picks_hoch.txt build/f01_hoch/
scp build/f01_hoch/picks_hoch.txt pc:f01tool/ ; ssh pc 'cd ~/f01tool && python3 folge01_finish.py picks_hoch.txt'
scp 'pc:comfy_f01/final/*_hoch.jpg' build/f01_raw/
python3 tool/comic/check_bars.py build/f01_raw && python3 tool/comic/check_kern.py build/f01_raw   # INV-17
python3 tool/comic/kern_faces.py                       # Hoch-Gesichter zum Eintragen
```
Danach Abschnitt 9 (Layout, Tippflächen, Lettering). Nachbesserung einzelner Motive:
`overrides_hoch.txt` → `<motiv>_hoch seed=<N> force`, Umgebungssatz in `HOCH_UMGEBUNG`, Lauf wiederholen.
```

In „Regeln und Fallen" anhängen:
```markdown
- **Hochbild aus Querbild — Kern geändert?** `folge01_hoch.py` überspringt Motive mit vorhandener
  Ausgabe. Nach einer Kern-Änderung `force` setzen oder `~/comfy_f01/hoch/<motiv>_hoch.png` löschen.
- **Rand-Ausmalen:** nie mehr als ~650 px auf einmal (Szene wiederholt sich), Kern nie mittig mit
  großem unteren Rand (zweiter Oberkörper), Personen-Negativ nur für den oberen Rand (sonst enden
  die Beine an einer Kante). Alles in `kern_geometry`/`folge01_hoch` fest verdrahtet.
```

In der Tabelle „Dateien" ergänzen:
```markdown
| `kern_geometry.py` | beide | Hochfenster, Kernstreifen, Schrittfolge, Gesichter-Abbildung (Spec §12) |
| `folge01_hoch.py`, `run_hoch.sh`, `overrides_hoch.txt` | Box | Hochbild aus dem Querbild, schreibt `picks_hoch.txt` |
| `kern_preview.py`, `kern_faces.py`, `check_kern.py` | NUC | Kern-Vorschau, Hoch-Gesichter, INV-17-Prüfung |
```

- [ ] **Step 2: Commit README**

```bash
git add tool/comic/README.md
git commit -F build/kern/msg_t8.txt
git push origin impl/manga-vollbild-app
```
Text: `docs(comic): README — Hochbild aus dem Querbild (Ablauf, Marken, Fallen)` + Attributionszeilen.

- [ ] **Step 3: Emulator-Sichtprüfung hoch (Box, AVD `s23`)**

Checkout auf `pc` spiegeln (`rsync` des Worktrees nach `pc:~/agent-test-checkouts/nihongo-impl-manga-vollbild-app/` ohne `.git`, `build`, `.dart_tool`), dort `flutter build apk --release` (≈ 5 Minuten), Emulator `s23` starten (falls nicht schon da: `pgrep -fc "[e]mulator.*-avd s23"`), `adb -e install -r`, App starten, Lesen-Tab → „Folge 1: Regen", hochkant durch p01–p10 tippen (Fahr-Skript-Vorlage `/home/uli/.claude/jobs/27b654de/tmp/emu.sh`, Vordergrund-Prüfung vor jedem Tipp), je Panel Screenshot nach `build/emu3/`. Erwartung: jedes Hochbild zeigt denselben Kern wie das Querbild, Blasen sichtbar, kein Erzählkasten über einer Blase. Bogen `build/emu3/emu3_sheet.png` → `~/f01-hoch-emulator.png`.

- [ ] **Step 4: Gerätetest S23 (Laptop)**

`ssh laptop 'cd ~/agent-test-checkouts/nihongo-impl-manga-vollbild-app && git pull && export PATH=$PATH:$HOME/development/flutter/bin && flutter build apk --debug --build-number=2003'` (Nummer > installierte, vorher prüfen: `adb -s RFCW220PB7W shell dumpsys package com.softbrew.nihongo_app | grep versionCode`), dann `adb -s RFCW220PB7W install -r …app-debug.apk` und die Ausgabe auf `Success` prüfen, App starten. An Uli: Prüfliste (Drehen mitten in der Folge: dieselbe Szene, andere Lage; Blasen tippbar; Reaktionsbild hoch; Titelkarte beide Lagen).

- [ ] **Step 5: Abschluss**

Uli „ok" zum Bogen (Task 6) und zum Gerätetest (Schritt 4) einholen; danach `finishing-a-development-branch` (PR #56 bleibt der Draft; Beschreibung um Abschnitt „Hochbild aus dem Querbild" ergänzen: `gh pr edit 56 --body-file build/kern/pr_body.md`). Gedächtnis aktualisieren (Comic-Stil-Datei + Index).

---

## Selbstprüfung des Plans

- **Spec-Abdeckung §12:** 12.1 Prinzip → Task 1/4; 12.2 Kerne → Task 3 (Werte) + Task 6 (Vorschau); 12.3 Daten/Werkzeuge: `kern`-Feld (T3), `HOCH_UMGEBUNG` (T2), `folge01_hoch.py` + `overrides_hoch.txt` (T4), `kern_preview.py` (T3), `check_kern.py` (T5), Vergrößerung über `picks_hoch.txt` (T4/T7), alte Hoch-Renders bleiben Protokoll (keine Löschung, README T8); 12.4 Rezept → T2 (Graph, Prompts) + T4 (Pässe, Feder, Seeds); 12.5 Reader unverändert, INV-17 → T5/T7; 12.6 Fallen → in T1/T4 fest verdrahtet, README T8; 12.7 Produktion/Abnahme → T6 (STOP), T7, T8.
- **Platzhalter:** keine; alle Code-Schritte tragen Code, alle Lauf-Schritte Befehle und Erwartungen.
- **Typen/Namen:** `plan_for` liefert `x0/x1/strip_h/bottom/top/top_steps` (T1) und wird so in T3 (`kern_preview`, `kern_faces`), T4 (`strip_image`, `extend`) und T5 (`kern_regions`) gelesen; `outpaint_graph(input_name, top, bottom, prompt, negative, seed, prefix, feather, lora_strength)` (T2) wird in T4 mit Schlüsselwort `feather=` aufgerufen; Prompt-Knoten sind `"4"`/`"5"`, Eingabe `"IN"` (T2-Test und T4-Fälschung lesen genau diese); `read_quer_picks`, `load_kerne`, `PICKS_OUT`, `OUT`, `TMP`, `LAYOUT` (T4) werden im T4-Test ersetzt.
- **Review Focus:** 1 → `test_plan_extend_near_window` (T1); 2 → `test_plan_crop_clamps_to_edges` (T1); 3 → `test_hoch_faces_clips_and_drops` (T1) + T7 Schritt 3/4; 4 → `test_main_skips_existing_unless_force` (T4) + README (T8); 5 → `test_read_quer_picks_ignores_hoch_lines` (T4).
