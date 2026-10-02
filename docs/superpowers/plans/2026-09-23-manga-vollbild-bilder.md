# Manga-Vollbild — Plan B: Bilder (Pipeline, drei Render-Runden, Lettering, Folge-01-Verdrahtung)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Folge 01 bekommt 28 fertige Bilddateien (10 Panels + Titelbild, je quer und hoch, plus 3 Reaktionen je Format) im Manga-Hausstil, geletttert aus einer Layout-Datei, und die Folge-01-Daten zeigen auf sie — mit Ulis Picks an drei Stellen.

**Architecture:** Versionierte Skripte unter `tool/comic/` laufen auf der GPU-Box (ComfyUI-HTTP-Client, nur Standardbibliothek + Pillow) und schreiben Bilder nach `~/comfy_f01/`; Kontaktbögen und eine Vergleichsseite gehen an Uli; Picks stehen in Textdateien im Repo. Das Lettering läuft auf dem NUC im Worktree (Pillow + Droid-Schrift vorhanden) aus **einer** Layout-Datei, aus der auch die Dart-Tippflächen erzeugt werden (INV-14). Foto-Pass → Manga-Pass (Depth-Zügel) → Vergrößern → Lettering → Verdrahtung.

**Tech Stack:** Python 3 (urllib, json, Pillow) auf Box und NUC; ComfyUI (Qwen-Image GGUF, Style-LoRA, InstantX ControlNet-Union, DepthAnythingV2, 4x-UltraSharp); Flutter-Tests für die Verdrahtung.

**Spec:** `docs/superpowers/specs/2026-09-23-manga-vollbild-titelbild-design.md` (§2 Rezept, §3 Formate, §4 Pipeline, §5 Daten, §6 Runden, §11 Betrieb). Voraussetzung: Plan A Task 1 (Schema-Felder) ist gemergt oder dieser Zweig setzt auf `impl/manga-vollbild-app` auf.

## Global Constraints

- Branch `impl/manga-vollbild-bilder` von `impl/manga-vollbild-app` (Plan A), damit `assetPortrait`, `hitAreaPortrait`, `cover`, `coverPortrait`, `titleJa` existieren. Worktree-Guard: keine Heredocs/Schleifen/mehrzeiligen `-m`; Dateien per Write-Tool, Commits `git commit -F <datei>`. Trailer wörtlich `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Box-Bedienung: Port 8188 ist vom NUC dicht → Skripte per `scp -r tool/comic pc:~/f01tool/` auf die Box und dort mit `nohup … &` starten; Fortschritt per `ssh pc 'cat ~/comfy_f01/<lauf>.log'`. Vorher `/usr/local/bin/wakegpu`, nach dem ersten SSH `ssh pc 'touch ~/.no-idle-suspend'`, nach dem Abholen `ssh pc 'rm -f ~/.no-idle-suspend'`. ComfyUI braucht nach dem Aufwachen ~15 s (`curl -s localhost:8188/system_stats` prüfen).
- Modelle liegen unter diesen Namen auf der Box: `qwen-image-Q4_K_M.gguf`, `shotengai_style_ckpt6.safetensors`, `qwen_2.5_vl_7b_fp8_scaled.safetensors`, `qwen_image_vae.safetensors`, `Qwen-Image-InstantX-ControlNet-Union.safetensors`, `4x-UltraSharp.pth`. Knoten: `ControlNetLoader`, `ControlNetApplyAdvanced` (mit `vae`), `DepthAnythingV2Preprocessor`, `CannyEdgePreprocessor`, `UpscaleModelLoader`, `ImageUpscaleWithModel`, `ImageScale`.
- Render-Größen `quer 1664×928`, `hoch 928×1664`; Auslieferung `quer 1920×1072`, `hoch 1080×1936`, JPEG q88 (Spec §3.1). Seeds Foto 701/702; Manga-Seed = Seed des gepickten Fotos.
- Manga-Rezept (Spec §2.2): LoRA 1,5, denoise 0,7, 24 Steps, cfg 4,0, Depth-Zügel Stärke 0,7, start 0, end 0,8; Ausweich Canny 100/200 Stärke 0,6. Positiv = Stil-Prompt + Panel-Inhalt mit festen Figurenbeschreibungen; Negativ ohne Anti-Anime.
- Sichere Zone = mittlere 80 % der beschnittenen Achse (quer: y in [0,10; 0,90], hoch: x in [0,10; 0,90]); Lettering bricht bei Verstoß ab (INV-15).
- Bilder liegen nie im `/jobs`-Scratch als Deliverable; Bögen und Seiten gehen an Uli (Kopien nach `~/f01-runde<N>/`), Picks kommen als Klartext zurück und werden in `tool/comic/picks_*.txt` eingetragen (versioniert).
- Vorbestehende Inhaltsfehler als Prüfliste auf jedem Foto-Bogen: p03 (P04) Mira trägt die dunkle Jacke; p09 (P11) steht draußen im Regen; p06 (P17) der kaputte Schirm liegt auf der Werkbank; keine Schrift/Wasserzeichen im Bild.

## Review Focus

1. **Picks-Datei nennt eine Datei, die es nicht gibt (Tippfehler):** Der Manga-Lauf bricht mit klarer Zeile `FEHLT <motiv>` ab, bevor die Box eine Stunde rechnet. Test in Task 3 (`load_picks` wirft `FileNotFoundError` mit Motivname).
2. **Ein Panel bekommt hochkant eine Blase außerhalb der sicheren Zone:** Lettering bricht mit `SICHERE ZONE` ab, nichts wird überschrieben. Test in Task 5 (`check_layout`).
3. **Layout-Datei und Dart laufen auseinander (jemand ändert nur eine Seite):** Der Dart-Test schlägt mit Panel- und Blasennummer fehl. Test in Task 5 (`folge_01_layout_test.dart`).
4. **Blasentext in der Layout-Datei weicht vom Blasentext in der Folge ab:** Der Dart-Test meldet beide Texte. Test in Task 5.
5. **Ein Motiv fehlt in Runde 2 (Render-Fehler, `ERR`-Zeile):** Der Bogen zeigt ein rotes „fehlt"-Feld statt zu verrutschen, `folge01_finish.py` lehnt unvollständige Picks ab. Test in Task 4 (`require_complete`).

---

### Task 1: `tool/comic/` Grundstock — Client, Kontaktbogen, Manga- und Vergrößerungs-Graph

**Files:**
- Create: `tool/comic/comfy_client.py` (Kopie von `origin/impl/cafe-bilder` + zwei neue Graphen)
- Create: `tool/comic/sheet.py` (Kopie von `origin/impl/cafe-bilder`)
- Create: `tool/comic/test_graphs.py`

**Interfaces:**
- Produces:
  - `comfy_client.run(graph, prefix, out_dir, client_id) -> list[str]` (unverändert)
  - `comfy_client.t2i_graph(prompt, negative, seed, prefix, lora_strength=0.3, width=1216, height=832) -> dict` (unverändert)
  - `comfy_client.manga_graph(input_name, prompt, negative, seed, prefix, control="depth", denoise=0.7, strength=0.7, end_percent=0.8, lora_strength=1.5) -> dict`
  - `comfy_client.upscale_graph(input_name, prefix, width, height) -> dict`
  - `comfy_client.COMFY_INPUT` (Pfad des ComfyUI-Input-Ordners)

- [ ] **Step 1: Dateien vom Café-Zweig übernehmen**

```bash
git fetch origin impl/cafe-bilder
mkdir -p tool/comic
git show origin/impl/cafe-bilder:tool/comic/comfy_client.py > tool/comic/comfy_client.py
git show origin/impl/cafe-bilder:tool/comic/sheet.py > tool/comic/sheet.py
```

- [ ] **Step 2: Failing Test schreiben** — `tool/comic/test_graphs.py`:

```python
#!/usr/bin/env python3
"""Verdrahtungs-Tests der ComfyUI-Graphen (ohne Box). Aufruf: cd tool/comic && python3 -m unittest test_graphs"""
import unittest

import comfy_client as cc


def _node(graph, class_type):
    hits = [k for k, v in graph.items() if v["class_type"] == class_type]
    assert len(hits) == 1, "%s: %d Treffer" % (class_type, len(hits))
    return hits[0]


class MangaGraph(unittest.TestCase):
    def test_depth_default_wiring(self):
        g = cc.manga_graph("gate_P03.png", "core", "neg", 555, "m_P03")
        ks = g[_node(g, "KSampler")]["inputs"]
        ca = _node(g, "ControlNetApplyAdvanced")
        self.assertEqual(ks["positive"], [ca, 0])
        self.assertEqual(ks["negative"], [ca, 1])
        self.assertAlmostEqual(ks["denoise"], 0.7)
        self.assertEqual(ks["seed"], 555)
        self.assertEqual(ks["latent_image"], [_node(g, "VAEEncode"), 0])
        self.assertIn("DepthAnythingV2Preprocessor", [v["class_type"] for v in g.values()])
        self.assertNotIn("CannyEdgePreprocessor", [v["class_type"] for v in g.values()])
        apply = g[ca]["inputs"]
        self.assertAlmostEqual(apply["strength"], 0.7)
        self.assertAlmostEqual(apply["end_percent"], 0.8)
        self.assertEqual(apply["vae"], [_node(g, "VAELoader"), 0])
        lora = g[_node(g, "LoraLoaderModelOnly")]["inputs"]
        self.assertAlmostEqual(lora["strength_model"], 1.5)
        self.assertEqual(g[_node(g, "LoadImage")]["inputs"]["image"], "gate_P03.png")

    def test_canny_fallback(self):
        g = cc.manga_graph("x.png", "core", "neg", 1, "p", control="canny", strength=0.6)
        self.assertIn("CannyEdgePreprocessor", [v["class_type"] for v in g.values()])
        pre = g[_node(g, "CannyEdgePreprocessor")]["inputs"]
        self.assertEqual((pre["low_threshold"], pre["high_threshold"]), (100, 200))
        self.assertAlmostEqual(g[_node(g, "ControlNetApplyAdvanced")]["inputs"]["strength"], 0.6)

    def test_prompt_carries_content(self):
        g = cc.manga_graph("x.png", "an elderly man in his seventies", "neg", 1, "p")
        texts = [v["inputs"]["text"] for v in g.values() if v["class_type"] == "CLIPTextEncode"]
        self.assertTrue(any("elderly man" in t and "shotengai_style" in t for t in texts))
        self.assertIn("neg", texts)

    def test_unknown_control_rejected(self):
        with self.assertRaises(ValueError):
            cc.manga_graph("x.png", "c", "n", 1, "p", control="pose")


class UpscaleGraph(unittest.TestCase):
    def test_sizes_and_model(self):
        g = cc.upscale_graph("in.png", "up", 1920, 1072)
        sc = g[_node(g, "ImageScale")]["inputs"]
        self.assertEqual((sc["width"], sc["height"]), (1920, 1072))
        self.assertEqual(sc["upscale_method"], "lanczos")
        self.assertEqual(g[_node(g, "UpscaleModelLoader")]["inputs"]["model_name"], "4x-UltraSharp.pth")
        self.assertEqual(g[_node(g, "LoadImage")]["inputs"]["image"], "in.png")


class T2IGraph(unittest.TestCase):
    def test_custom_size(self):
        g = cc.t2i_graph("core", "neg", 701, "p", 0.3, 928, 1664)
        lat = g[_node(g, "EmptySD3LatentImage")]["inputs"]
        self.assertEqual((lat["width"], lat["height"]), (928, 1664))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 3: Test laufen lassen, Fehlschlag sehen**

Run: `cd tool/comic && python3 -m unittest test_graphs -v`
Expected: `AttributeError: module 'comfy_client' has no attribute 'manga_graph'`.

- [ ] **Step 4: Graphen ergänzen** — am Ende von `tool/comic/comfy_client.py` anhängen:

```python
def manga_graph(input_name, prompt, negative, seed, prefix, control="depth", denoise=0.7,
                strength=0.7, end_percent=0.8, lora_strength=1.5):
    """Manga-Durchgang (Spec Manga-Vollbild §2.2): img2img über dem Foto-Final mit
    Hausstil-LoRA und Struktur-Zügel (InstantX ControlNet-Union). control = "depth"
    (Standard, Uli 23.9.) oder "canny" (Ausweich). input_name liegt in COMFY_INPUT."""
    if control == "depth":
        pre = {"class_type": "DepthAnythingV2Preprocessor",
               "inputs": {"image": ["IN", 0], "resolution": 928}}
    elif control == "canny":
        pre = {"class_type": "CannyEdgePreprocessor",
               "inputs": {"image": ["IN", 0], "low_threshold": 100, "high_threshold": 200, "resolution": 928}}
    else:
        raise ValueError("control muss depth oder canny sein, nicht %r" % control)
    return {
        "1": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": "qwen-image-Q4_K_M.gguf"}},
        "L": {"class_type": "LoraLoaderModelOnly", "inputs": {"model": ["1", 0],
              "lora_name": "shotengai_style_ckpt6.safetensors", "strength_model": lora_strength}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen_2.5_vl_7b_fp8_scaled.safetensors", "type": "qwen_image"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_vae.safetensors"}},
        "IN": {"class_type": "LoadImage", "inputs": {"image": input_name}},
        "EN": {"class_type": "VAEEncode", "inputs": {"pixels": ["IN", 0], "vae": ["3", 0]}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": "shotengai_style, " + prompt, "clip": ["2", 0]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": ["2", 0]}},
        "CN": {"class_type": "ControlNetLoader", "inputs": {"control_net_name": "Qwen-Image-InstantX-ControlNet-Union.safetensors"}},
        "PRE": pre,
        "CA": {"class_type": "ControlNetApplyAdvanced", "inputs": {"positive": ["4", 0], "negative": ["5", 0],
               "control_net": ["CN", 0], "image": ["PRE", 0], "strength": strength,
               "start_percent": 0.0, "end_percent": end_percent, "vae": ["3", 0]}},
        "7": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 24, "cfg": 4.0, "sampler_name": "euler",
              "scheduler": "simple", "denoise": denoise, "model": ["L", 0], "positive": ["CA", 0],
              "negative": ["CA", 1], "latent_image": ["EN", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["3", 0]}},
        "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["8", 0]}},
    }


def upscale_graph(input_name, prefix, width, height):
    """4x-UltraSharp hoch, dann per Lanczos auf die Auslieferungsgröße (Spec §4.3)."""
    return {
        "1": {"class_type": "LoadImage", "inputs": {"image": input_name}},
        "2": {"class_type": "UpscaleModelLoader", "inputs": {"model_name": "4x-UltraSharp.pth"}},
        "3": {"class_type": "ImageUpscaleWithModel", "inputs": {"upscale_model": ["2", 0], "image": ["1", 0]}},
        "4": {"class_type": "ImageScale", "inputs": {"image": ["3", 0], "upscale_method": "lanczos",
              "width": width, "height": height, "crop": "disabled"}},
        "5": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["4", 0]}},
    }
```

Die Preprocessor-`resolution` ist die kurze Seite des Renders (928 in beiden Formaten), damit das Zügel-Bild dem Latent entspricht.

- [ ] **Step 5: Tests grün**

Run: `cd tool/comic && python3 -m unittest test_graphs -v`
Expected: 6 Tests OK.

- [ ] **Step 6: Commit**

```bash
git add tool/comic/comfy_client.py tool/comic/sheet.py tool/comic/test_graphs.py
git commit -F /tmp/msg-b1.txt
```
Inhalt: `feat(comic): ComfyUI-Client mit Manga-Zügel-Graph und Vergrößerung` + Trailer.

---

### Task 2: Motive + Foto-Runde (Runde 1) + Vergleichsseite → Ulis Picks

**Files:**
- Create: `tool/comic/folge01_motifs.py`
- Create: `tool/comic/folge01_foto.py`
- Create: `tool/comic/review_page.py`
- Create: `tool/comic/test_motifs.py`
- Create (nach Ulis Antwort): `tool/comic/picks_foto.txt`

**Interfaces:**
- Consumes: `comfy_client.t2i_graph`, `comfy_client.run`, `sheet.py`.
- Produces:
  - `folge01_motifs.FIG` (dict `P`, `M`, `W`), `PHOTO`, `NEG_PHOTO`, `STY`, `NEG_MANGA`
  - `folge01_motifs.PANELS: dict[str, dict]` — Schlüssel `p01`…`p10`, Werte `{"src": "P01", "kind": "fig"|"det", "core": str}`
  - `folge01_motifs.COVERS: dict[str, str]` — `titel_a`, `titel_b`, `titel_c` → Prompt-Kern
  - `folge01_motifs.FORMATS = {"quer": (1664, 928), "hoch": (928, 1664)}`, `FORMAT_HINT`, `SEEDS = (701, 702)`
  - `folge01_motifs.motifs() -> dict[str, str]` — alle 13 Motive → Prompt-Kern (Panels + Titelbilder)
  - `folge01_motifs.negative_for(motif) -> str`
  - Bilder: `~/comfy_f01/foto/<motif>_<fmt>_s<seed>_<comfy>.png`, Bögen `foto_quer.png`, `foto_hoch.png`, Log `foto.log` mit `FOTO_DONE`
  - `review_page.py OUT.html "Titel" rows.json` → HTML mit eingebetteten Bildern
  - `picks_foto.txt`: eine Zeile je Motiv und Format `p01_quer=/home/uli/comfy_f01/foto/p01_quer_s701_00001_.png`

- [ ] **Step 1: Failing Test schreiben** — `tool/comic/test_motifs.py`:

```python
#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_motifs"""
import unittest

import folge01_motifs as m


class Motifs(unittest.TestCase):
    def test_ten_panels_and_three_covers(self):
        self.assertEqual(sorted(m.PANELS), ["p%02d" % i for i in range(1, 11)])
        self.assertEqual(sorted(m.COVERS), ["titel_a", "titel_b", "titel_c"])
        self.assertEqual(len(m.motifs()), 13)

    def test_reader_to_source_mapping(self):
        want = {"p01": "P01", "p02": "P02", "p03": "P04", "p04": "P05", "p05": "P07",
                "p06": "P17", "p07": "P21", "p08": "P22", "p09": "P11", "p10": "P03"}
        self.assertEqual({k: v["src"] for k, v in m.PANELS.items()}, want)

    def test_figure_panels_carry_fixed_descriptions(self):
        for pid, p in m.PANELS.items():
            if p["kind"] == "fig":
                self.assertTrue(any(fig in p["core"] for fig in m.FIG.values()),
                                "%s ohne feste Figurenbeschreibung" % pid)

    def test_content_fixes_from_13_9(self):
        self.assertIn("navy jacket", m.FIG["P"])
        self.assertIn("outside", m.PANELS["p09"]["core"])
        self.assertIn("lying on the workbench", m.PANELS["p06"]["core"])

    def test_formats_are_qwen_native(self):
        self.assertEqual(m.FORMATS, {"quer": (1664, 928), "hoch": (928, 1664)})
        self.assertEqual(m.SEEDS, (701, 702))

    def test_negative_keeps_people_for_figures_only(self):
        # Der Foto-Negativ endet auf "empty, no people, faceless": bei Figuren-Panels
        # verbietet er leere Bilder, bei Detail-/Ortspanels (det) wird der Teil entfernt.
        self.assertIn("no people", m.negative_for("p01"))      # fig
        self.assertNotIn("no people", m.negative_for("p04"))   # det: darf leer sein
        self.assertIn("anime", m.negative_for("p01"))          # Foto-Pass: Anti-Anime


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag sehen**

Run: `cd tool/comic && python3 -m unittest test_motifs -v`
Expected: `ModuleNotFoundError: No module named 'folge01_motifs'`.

- [ ] **Step 3: Motive schreiben** — `tool/comic/folge01_motifs.py`:

```python
#!/usr/bin/env python3
"""Feste Prompt-Bausteine für Folge 01 (Spec Manga-Vollbild §2.2/§4.1).
Quelle der Panel-Prompts: folge01_A.py / folge01_fix.py (Look A, 12.9.),
Zuordnung Reader-Panel → Quell-Render aus tool/letter_folge01.py (MAPPING)."""

FIG = {
    "P": ("a young woman in her early twenties, short straight black bob haircut, pale skin, "
          "slender, dark navy jacket over a pale blouse, dark skirt"),
    "M": ("an elderly man in his seventies, thin grey hair, wire-rim glasses, grey cardigan, "
          "gentle weathered face"),
    "W": "an older woman in her sixties, short greying hair, beige cardigan, holding a shopping bag",
}
P, M, W = FIG["P"], FIG["M"], FIG["W"]

# Foto-Pass (Look A): LoRA 0,3 + Foto-Zusatz + Anti-Anime-Negativ.
LORA_PHOTO = 0.3
PHOTO = (", muted desaturated cool grey-green 1990s palette, deep shadows, melancholic, "
         "cinematic, photorealistic film still, realistic detailed human faces, "
         "natural skin texture, 35mm photograph, sharp focus")
NEG_PHOTO = ("anime, manga, cartoon, cel shading, illustration, comic, drawing, flat colors, "
             "stylized, big anime eyes, 2d, painting, text, watermark, letters, oversaturated, "
             "bright, cute, kawaii, blurry, deformed hands, extra fingers, empty, no people, faceless")
NEG_PHOTO_DET = NEG_PHOTO.replace(", empty, no people, faceless", "")

# Manga-Pass: Stil-Prompt + Panel-Inhalt; Negativ OHNE Anti-Anime.
STY = ("muted painterly 1990s manga illustration, hand-drawn linework, deep shadows, "
       "melancholic, atmospheric")
NEG_MANGA = ("photo, photorealistic, text, watermark, oversaturated, bright, cute, kawaii, "
             "blurry, deformed hands, extra fingers, distorted face")
UMBRELLA_FIX = ", clean transparent umbrella without stains"

FORMATS = {"quer": (1664, 928), "hoch": (928, 1664)}
FORMAT_HINT = {"quer": ", wide cinematic framing", "hoch": ", vertical framing, tall composition"}
SEEDS = (701, 702)

PANELS = {
    "p01": {"src": "P01", "kind": "fig", "core":
            "a small rural train platform at night in the rain, rain slanting through a neon light, "
            "wet platform, distant hills, a station sign, " + P + ", standing small and alone with a "
            "travel bag, head lowered, wide establishing shot"},
    "p02": {"src": "P02", "kind": "det", "core":
            "close-up of a hand holding a handwritten paper note, ink bleeding and running in the rain, "
            "no face, shallow focus"},
    "p03": {"src": "P04", "kind": "fig", "core":
            P + ", wearing her dark navy jacket, seen from behind walking away down an empty wet "
            "residential street at night, old wooden houses, utility poles and wires against a grey sky, "
            "small in the wide scene"},
    "p04": {"src": "P05", "kind": "det", "core":
            "the arched entrance of a covered shopping arcade seen from outside at dusk, rain on the roof, "
            "hanging signs, warm light inside, no people, establishing wide shot"},
    "p05": {"src": "P07", "kind": "fig", "core":
            "in a covered shopping arcade, in the foreground " + P + " raises her hand to get attention, "
            "and " + W + " walks toward her; two people clearly visible"},
    "p06": {"src": "P17", "kind": "fig", "core":
            M + ", stands in a small repair workshop, turned around, pointing at a broken umbrella lying "
            "on the workbench, full upper body, tools and workbench around him"},
    "p07": {"src": "P21", "kind": "fig", "core":
            "at a small shop doorway, " + M + " holds out a repaired open transparent umbrella toward " + P +
            " who reaches to take it, two people clearly visible, emotional moment"},
    "p08": {"src": "P22", "kind": "fig", "core":
            P + ", at a shop doorway holds a transparent umbrella in both hands and bows slightly in thanks"},
    "p09": {"src": "P11", "kind": "fig", "core":
            "low angle view of " + P + " standing outside in the street looking up into the falling rain, "
            "wet face, a weather notice board on the wall behind her"},
    "p10": {"src": "P03", "kind": "fig", "core":
            "a close-up portrait of " + P + ", rain in her hair, eyes lowered, melancholic and thoughtful"},
}

# Titelbild-Motive (Spec §6): ruhige Fläche oben (quer) bzw. unten (hoch) für den Titel.
COVERS = {
    "titel_a": ("a small rural train platform at night in the rain, " + P + " seen from behind, standing "
                "still with a travel bag as a local train pulls away, red tail lights, far away the faint "
                "lights of a small town, large calm empty sky above, wide establishing shot"),
    "titel_b": ("a small rural train platform at night, " + P + " small under the platform roof, a suitcase "
                "beside her, a curtain of heavy rain in front, dim neon, large calm empty area in the "
                "composition, wide shot"),
    "titel_c": ("close-up of a young woman's hand holding a handwritten paper note with three lines of "
                "running ink in the rain, no face, shallow focus, dark calm background with empty space"),
}


def motifs():
    """Alle 13 Motive → Prompt-Kern (Panels + Titelbilder)."""
    out = {pid: p["core"] for pid, p in PANELS.items()}
    out.update(COVERS)
    return out


def negative_for(motif):
    kind = PANELS.get(motif, {}).get("kind")
    if kind == "det" or motif == "titel_c":
        return NEG_PHOTO_DET
    return NEG_PHOTO
```

- [ ] **Step 4: Tests grün**

Run: `cd tool/comic && python3 -m unittest test_motifs -v`
Expected: 6 Tests OK.

- [ ] **Step 5: Foto-Runde-Skript** — `tool/comic/folge01_foto.py`:

```python
#!/usr/bin/env python3
"""Runde 1: Foto-Pass (Look A) für alle 13 Motive × 2 Formate × 2 Seeds. Läuft auf der Box.
  folge01_foto.py            → alles
  folge01_foto.py p03 titel_a → nur diese Motive
Schreibt ~/comfy_f01/foto/, überspringt vorhandene Ausgaben, endet mit FOTO_DONE."""
import os
import subprocess
import sys

import comfy_client as cc
from folge01_motifs import FORMATS, FORMAT_HINT, LORA_PHOTO, PHOTO, SEEDS, motifs, negative_for

OUT = os.path.expanduser("~/comfy_f01/foto")
HERE = os.path.dirname(os.path.abspath(__file__))


def already(prefix):
    return any(f.startswith(prefix + "_") for f in os.listdir(OUT)) if os.path.isdir(OUT) else False


def main(only):
    os.makedirs(OUT, exist_ok=True)
    tiles = {fmt: [] for fmt in FORMATS}
    for motif, core in motifs().items():
        if only and motif not in only:
            continue
        for fmt, (w, h) in FORMATS.items():
            for seed in SEEDS:
                prefix = "%s_%s_s%d" % (motif, fmt, seed)
                if already(prefix):
                    print("SKIP", prefix, flush=True)
                    got = [os.path.join(OUT, f) for f in sorted(os.listdir(OUT)) if f.startswith(prefix + "_")]
                    tiles[fmt] += ["%s=%s" % (prefix, p) for p in got[:1]]
                    continue
                try:
                    got = cc.run(cc.t2i_graph(core + FORMAT_HINT[fmt] + PHOTO, negative_for(motif), seed,
                                              prefix, LORA_PHOTO, w, h), prefix, OUT, "f01foto")
                    tiles[fmt] += ["%s=%s" % (prefix, p) for p in got]
                    print("OK", prefix, flush=True)
                except Exception as e:  # noqa: BLE001
                    print("ERR", prefix, repr(e), flush=True)
    for fmt, items in tiles.items():
        if items:
            subprocess.run(["python3", os.path.join(HERE, "sheet.py"),
                            os.path.join(OUT, "foto_%s.png" % fmt), "4" if fmt == "quer" else "6"] + items,
                           check=False)
    print("FOTO_DONE", flush=True)


if __name__ == "__main__":
    main(set(sys.argv[1:]))
```

- [ ] **Step 6: Vergleichsseite** — `tool/comic/review_page.py` (läuft auf dem NUC, Pillow vorhanden):

```python
#!/usr/bin/env python3
"""Vergleichsseite für Ulis Picks: review_page.py OUT.html "Titel" rows.json
rows.json = [{"label": "p01 · Bahnsteig", "note": "Prüfliste …", "items": [{"label": "quer s701", "path": "/…/x.png"}, …]}, …]
Bilder werden auf 900 px Breite verkleinert und als data-URIs eingebettet (max ~16 MB)."""
import base64
import io
import json
import sys

from PIL import Image

CSS = """<style>
:root{--bg:#eef1ef;--ink:#1b2220;--muted:#5f6f6b;--line:#c9d3d0;--card:#f7f9f8;--accent:#3f6f68;color-scheme:light}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){--bg:#14191a;--ink:#e3e8e6;--muted:#93a39f;--line:#2c3736;--card:#1c2324;--accent:#7fb5ac;color-scheme:dark}}
:root[data-theme="dark"]{--bg:#14191a;--ink:#e3e8e6;--muted:#93a39f;--line:#2c3736;--card:#1c2324;--accent:#7fb5ac;color-scheme:dark}
body{background:var(--bg);color:var(--ink);font-family:"IBM Plex Sans","Segoe UI",system-ui,sans-serif;padding-inline:16px;padding-block:24px 48px;max-width:1400px;margin:0 auto;line-height:1.45}
h1{font-size:clamp(24px,4vw,34px);margin:0 0 14px}h2{font-size:17px;margin:26px 0 6px}
p.note{color:var(--muted);margin:0 0 8px;max-width:70ch}
.strip{display:flex;gap:8px;overflow-x:auto;padding-bottom:8px}
.strip figure{flex:0 0 auto;width:min(420px,84vw);margin:0}
.strip img{width:100%;height:auto;display:block;border:1px solid var(--line);background:#fff;cursor:zoom-in}
.strip figcaption{font-size:12px;color:var(--muted);margin-top:4px;text-transform:uppercase;letter-spacing:.05em}
.missing{display:flex;align-items:center;justify-content:center;aspect-ratio:16/9;border:1px dashed #c33;color:#c33;font-size:13px}
#lb{position:fixed;inset:0;background:rgba(0,0,0,.92);display:none;align-items:center;justify-content:center;z-index:9;cursor:zoom-out;padding:12px}
#lb img{max-width:100%;max-height:100%;object-fit:contain}#lb.on{display:flex}
</style>"""
JS = """<div id="lb"><img alt=""></div><script>
(function(){var lb=document.getElementById('lb'),im=lb.querySelector('img');
document.querySelectorAll('.strip img').forEach(function(el){el.addEventListener('click',function(){im.src=el.src;lb.classList.add('on');});});
lb.addEventListener('click',function(){lb.classList.remove('on');im.src='';});})();</script>"""


def uri(path):
    try:
        im = Image.open(path).convert("RGB")
    except OSError:
        return None
    w = 900
    im = im.resize((w, int(im.height * w / im.width)), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=82, optimize=True)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def main(out, title, rows_path):
    rows = json.load(open(rows_path, encoding="utf-8"))
    parts = ["<title>%s</title>" % title, CSS, "<h1>%s</h1>" % title]
    for row in rows:
        parts.append("<h2>%s</h2>" % row["label"])
        if row.get("note"):
            parts.append("<p class=\"note\">%s</p>" % row["note"])
        parts.append("<div class=\"strip\">")
        for item in row["items"]:
            u = uri(item["path"])
            body = "<img alt=\"%s\" src=\"%s\">" % (item["label"], u) if u else "<div class=\"missing\">fehlt</div>"
            parts.append("<figure>%s<figcaption>%s</figcaption></figure>" % (body, item["label"]))
        parts.append("</div>")
    parts.append(JS)
    html = "\n".join(parts)
    open(out, "w", encoding="utf-8").write(html)
    print(out, "%.1f MB" % (len(html.encode()) / 1e6))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
```

- [ ] **Step 7: Commit der Skripte (vor dem Lauf)**

```bash
git add tool/comic/folge01_motifs.py tool/comic/folge01_foto.py tool/comic/review_page.py tool/comic/test_motifs.py
git commit -F /tmp/msg-b2a.txt
```
Inhalt: `feat(comic): Folge-01-Motive, Foto-Runde und Vergleichsseite` + Trailer.

- [ ] **Step 8: Runde 1 auf der Box starten** (≈ 52 Bilder, ~70 Minuten)

```bash
/usr/local/bin/wakegpu; sleep 20
ssh pc 'touch ~/.no-idle-suspend; mkdir -p ~/f01tool ~/comfy_f01'
scp -r tool/comic/. pc:~/f01tool/
ssh pc 'cd ~/f01tool && nohup python3 folge01_foto.py > ~/comfy_f01/foto.log 2>&1 &'
```
Fortschritt: `ssh pc 'grep -c ^OK ~/comfy_f01/foto.log; grep -E "^(ERR|NODE_ERR)" ~/comfy_f01/foto.log'`. Ende: Zeile `FOTO_DONE`. `ERR`-Zeilen: Skript mit den betroffenen Motiven erneut starten (überspringt Fertiges).

- [ ] **Step 9: Bögen holen, Seite bauen, an Uli**

```bash
mkdir -p build/f01_foto && scp 'pc:~/comfy_f01/foto/*.png' build/f01_foto/
mkdir -p ~/f01-runde1 && cp build/f01_foto/foto_quer.png build/f01_foto/foto_hoch.png ~/f01-runde1/
```
`build/` ist in `.gitignore` (prüfen mit `git check-ignore build/f01_foto`; sonst Zeile `build/` ergänzen). Dann `rows.json` schreiben (Write-Tool): je Motiv eine Zeile mit den 4 Bildern (`quer s701`, `quer s702`, `hoch s701`, `hoch s702`) und als `note` die Prüfliste (p03 Jacke, p06 Schirm liegt, p09 draußen, keine Schrift). `python3 tool/comic/review_page.py build/f01_foto/runde1.html "Folge 01 · Runde 1 Foto" build/f01_foto/rows.json`, Seite mit dem Artifact-Tool veröffentlichen (Icon `image`), Link nackt auf eigener Zeile + Pfad `~/f01-runde1/` an Uli, mit Claudes Pick-Vorschlag je Motiv und Format (Kriterien: Figur wie beschrieben, Prüfliste, ruhige Fläche für Blasen/Titel).

**STOP — Ulis Picks abwarten.** Ohne Picks geht es nicht weiter (Spec §6 Runde 1).

- [ ] **Step 10: Picks eintragen und committen**

`tool/comic/picks_foto.txt` (Write-Tool), 22 Zeilen = 11 Motive (10 Panels + das eine gewählte Titelbild-Motiv) × 2 Formate, Format `p01_quer=/home/uli/comfy_f01/foto/p01_quer_s701_00001_.png`, Titelbild als `titel_quer=…` / `titel_hoch=…` (der Buchstabe des Motivs steht im Pfad). Kommentarzeilen mit `#`.

```bash
git add tool/comic/picks_foto.txt
git commit -F /tmp/msg-b2b.txt
```
Inhalt: `chore(comic): Ulis Picks Runde 1 (Foto)` + Trailer.

---

### Task 3: Manga-Runde (Runde 2): Feinschliff, dann Vollrender → Ulis Freigabe

**Files:**
- Create: `tool/comic/folge01_manga.py`
- Create: `tool/comic/test_manga_picks.py`
- Create (nach Ulis Antwort): `tool/comic/overrides_manga.txt` (optional), `tool/comic/picks_manga.txt`

**Interfaces:**
- Consumes: `comfy_client.manga_graph`, `comfy_client.run`, `comfy_client.COMFY_INPUT`, `folge01_motifs.motifs/STY/NEG_MANGA/UMBRELLA_FIX/FORMATS`, `picks_foto.txt`.
- Produces:
  - `folge01_manga.load_picks(path) -> dict[str, tuple[str, int]]` — `"p01_quer" -> (pfad, seed)`; wirft `FileNotFoundError("FEHLT p01_quer: <pfad>")`, `ValueError` bei Zeile ohne `=` oder ohne `_s<seed>_` im Dateinamen
  - `folge01_manga.load_overrides(path) -> dict[str, dict]` — `"p07_quer" -> {"control": "canny", "seed": 702, "extra": "…"}` (alle Schlüssel optional)
  - `folge01_manga.variants()` — die 6 Feinschliff-Varianten `D60 D70 D80 S60 S85 C70`
  - Bilder `~/comfy_f01/tune/<motif>_<variante>_…png`, `~/comfy_f01/manga/<motif>_<fmt>_…png`, Logs `tune.log`/`manga.log` mit `TUNE_DONE`/`MANGA_DONE`
  - `picks_manga.txt`: `p01_quer=/home/uli/comfy_f01/manga/p01_quer_00001_.png` (22 Zeilen)

- [ ] **Step 1: Failing Tests schreiben** — `tool/comic/test_manga_picks.py`:

```python
#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_manga_picks"""
import os
import tempfile
import unittest

import folge01_manga as fm


class Picks(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.img = os.path.join(self.dir, "p01_quer_s702_00001_.png")
        open(self.img, "wb").write(b"x")

    def write(self, text):
        p = os.path.join(self.dir, "picks.txt")
        open(p, "w", encoding="utf-8").write(text)
        return p

    def test_reads_path_and_seed(self):
        picks = fm.load_picks(self.write("# Kommentar\np01_quer=%s\n" % self.img))
        self.assertEqual(picks, {"p01_quer": (self.img, 702)})

    def test_missing_file_names_motif(self):
        with self.assertRaises(FileNotFoundError) as cm:
            fm.load_picks(self.write("p03_hoch=%s/nix.png\n" % self.dir))
        self.assertIn("FEHLT p03_hoch", str(cm.exception))

    def test_line_without_seed_rejected(self):
        bad = os.path.join(self.dir, "p01_quer_00001_.png")
        open(bad, "wb").write(b"x")
        with self.assertRaises(ValueError):
            fm.load_picks(self.write("p01_quer=%s\n" % bad))

    def test_overrides(self):
        p = os.path.join(self.dir, "ov.txt")
        open(p, "w", encoding="utf-8").write("p07_quer control=canny seed=702 extra=clean transparent umbrella\n")
        ov = fm.load_overrides(p)
        self.assertEqual(ov["p07_quer"]["control"], "canny")
        self.assertEqual(ov["p07_quer"]["seed"], 702)
        self.assertEqual(ov["p07_quer"]["extra"], "clean transparent umbrella")
        self.assertEqual(fm.load_overrides(os.path.join(self.dir, "fehlt.txt")), {})

    def test_variants(self):
        names = [v[0] for v in fm.variants()]
        self.assertEqual(names, ["D60", "D70", "D80", "S60", "S85", "C70"])
        d80 = dict(fm.variants())["D80"]
        self.assertEqual((d80["control"], d80["denoise"], d80["strength"]), ("depth", 0.8, 0.7))
        c70 = dict(fm.variants())["C70"]
        self.assertEqual((c70["control"], c70["strength"]), ("canny", 0.6))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag sehen**

Run: `cd tool/comic && python3 -m unittest test_manga_picks -v`
Expected: `ModuleNotFoundError: No module named 'folge01_manga'`.

- [ ] **Step 3: Skript schreiben** — `tool/comic/folge01_manga.py`:

```python
#!/usr/bin/env python3
"""Runde 2: Manga-Pass über den gepickten Fotos (Spec §2.2/§2.3/§6). Läuft auf der Box.
  folge01_manga.py tune picks_foto.txt              → Feinschliff: p10_quer + p07_quer × 6 Varianten
  folge01_manga.py full picks_foto.txt [overrides]  → alle Picks, Standard depth 0,7 / denoise 0,7
Endet mit TUNE_DONE bzw. MANGA_DONE."""
import os
import re
import shutil
import subprocess
import sys

import comfy_client as cc
from folge01_motifs import NEG_MANGA, STY, UMBRELLA_FIX, motifs

ROOT = os.path.expanduser("~/comfy_f01")
HERE = os.path.dirname(os.path.abspath(__file__))
SEED_RE = re.compile(r"_s(\d+)_")
UMBRELLA_MOTIFS = {"p07", "p08"}  # p06 zeigt den kaputten Schirm, kein Sauber-Zusatz


def load_picks(path):
    picks = {}
    for line in open(os.path.expanduser(path), encoding="utf-8"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise ValueError("Zeile ohne '=': %r" % line)
        key, src = line.split("=", 1)
        src = os.path.expanduser(src.strip())
        if not os.path.exists(src):
            raise FileNotFoundError("FEHLT %s: %s" % (key.strip(), src))
        m = SEED_RE.search(os.path.basename(src))
        if not m:
            raise ValueError("%s: Dateiname ohne _s<seed>_: %s" % (key, src))
        picks[key.strip()] = (src, int(m.group(1)))
    return picks


def load_overrides(path):
    out = {}
    path = os.path.expanduser(path)
    if not os.path.exists(path):
        return out
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, _, rest = line.partition(" ")
        opts = {}
        # extra=… darf Leerzeichen enthalten und steht deshalb zuletzt.
        m = re.search(r"\bextra=(.*)$", rest)
        if m:
            opts["extra"] = m.group(1).strip()
            rest = rest[:m.start()]
        for tok in rest.split():
            k, _, v = tok.partition("=")
            opts[k] = int(v) if k == "seed" else v
        out[key] = opts
    return out


def variants():
    return [
        ("D60", {"control": "depth", "denoise": 0.6, "strength": 0.7}),
        ("D70", {"control": "depth", "denoise": 0.7, "strength": 0.7}),
        ("D80", {"control": "depth", "denoise": 0.8, "strength": 0.7}),
        ("S60", {"control": "depth", "denoise": 0.7, "strength": 0.6}),
        ("S85", {"control": "depth", "denoise": 0.7, "strength": 0.85}),
        ("C70", {"control": "canny", "denoise": 0.7, "strength": 0.6}),
    ]


def prompt_for(key, extra=""):
    motif = key.rsplit("_", 1)[0]
    core = motifs()["titel_" + title_letter(key)] if motif == "titel" else motifs()[motif]
    fix = UMBRELLA_FIX if motif in UMBRELLA_MOTIFS else ""
    return STY + ", " + core + fix + ((", " + extra) if extra else "")


def title_letter(key):
    # Titelbild-Picks heißen titel_quer/titel_hoch; das Motiv (a/b/c) steht im gepickten Pfad.
    return _TITLE_LETTER.get(key, "a")


_TITLE_LETTER = {}


def _remember_title_letter(picks):
    for key, (src, _) in picks.items():
        if key.startswith("titel_"):
            m = re.search(r"titel_([abc])_", os.path.basename(src))
            _TITLE_LETTER[key] = m.group(1) if m else "a"


def render(key, src, seed, out, opts, tag=None):
    input_name = "f01_%s%s" % (key, os.path.splitext(src)[1])
    shutil.copy(src, os.path.join(cc.COMFY_INPUT, input_name))
    prefix = key if tag is None else "%s_%s" % (key, tag)
    graph = cc.manga_graph(input_name, prompt_for(key, opts.get("extra", "")), NEG_MANGA,
                           opts.get("seed", seed), prefix, control=opts.get("control", "depth"),
                           denoise=opts.get("denoise", 0.7), strength=opts.get("strength", 0.7))
    return cc.run(graph, prefix, out, "f01manga")


def tune(picks_path):
    picks = load_picks(picks_path)
    _remember_title_letter(picks)
    out = os.path.join(ROOT, "tune")
    items = []
    for key in ("p10_quer", "p07_quer"):
        src, seed = picks[key]
        items.append("%s_foto=%s" % (key, src))
        for name, opts in variants():
            try:
                got = render(key, src, seed, out, opts, tag=name)
                items += ["%s_%s=%s" % (key, name, p) for p in got]
                print("OK", key, name, flush=True)
            except Exception as e:  # noqa: BLE001
                print("ERR", key, name, repr(e), flush=True)
    subprocess.run(["python3", os.path.join(HERE, "sheet.py"), os.path.join(out, "tune.png"), "7"] + items, check=False)
    print("TUNE_DONE", flush=True)


def full(picks_path, overrides_path=None):
    picks = load_picks(picks_path)
    _remember_title_letter(picks)
    overrides = load_overrides(overrides_path) if overrides_path else {}
    out = os.path.join(ROOT, "manga")
    os.makedirs(out, exist_ok=True)
    items = []
    for key, (src, seed) in picks.items():
        if any(f.startswith(key + "_") for f in os.listdir(out)) and key not in overrides:
            print("SKIP", key, flush=True)
            continue
        try:
            got = render(key, src, seed, out, overrides.get(key, {}))
            items += ["%s_foto=%s" % (key, src)] + ["%s=%s" % (key, p) for p in got]
            print("OK", key, flush=True)
        except Exception as e:  # noqa: BLE001
            print("ERR", key, repr(e), flush=True)
    subprocess.run(["python3", os.path.join(HERE, "sheet.py"), os.path.join(out, "manga.png"), "4"] + items, check=False)
    print("MANGA_DONE", flush=True)


if __name__ == "__main__":
    if sys.argv[1] == "tune":
        tune(sys.argv[2])
    elif sys.argv[1] == "full":
        full(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
    else:
        raise SystemExit("tune|full")
```

Hinweis: Bei `full` löscht ein Override-Eintrag das vorhandene Bild nicht selbst — vor einem Neu-Render das alte `~/comfy_f01/manga/<key>_*.png` auf der Box entfernen (ComfyUI zählt sonst `_00002_` hoch, siehe Merke vom 13.9.).

- [ ] **Step 4: Tests grün**

Run: `cd tool/comic && python3 -m unittest test_manga_picks test_graphs -v`
Expected: alle OK.

- [ ] **Step 5: Commit**

```bash
git add tool/comic/folge01_manga.py tool/comic/test_manga_picks.py
git commit -F /tmp/msg-b3a.txt
```
Inhalt: `feat(comic): Manga-Runde — Feinschliff-Varianten und Vollrender über den Foto-Picks` + Trailer.

- [ ] **Step 6: Feinschliff auf der Box** (12 Bilder, ~30 Minuten)

```bash
scp -r tool/comic/. pc:~/f01tool/
ssh pc 'touch ~/.no-idle-suspend; cd ~/f01tool && nohup python3 folge01_manga.py tune picks_foto.txt > ~/comfy_f01/tune.log 2>&1 &'
```
Bei `TUNE_DONE`: `scp 'pc:~/comfy_f01/tune/*.png' build/f01_tune/`, Seite `runde2a.html` (zwei Zeilen: p10 und p07, je Foto + 6 Varianten, Beschriftung mit Werten), Kopie `~/f01-runde2/tune.png`, an Uli mit Empfehlung.

**STOP — Uli wählt den Standard** (eine Variante, z. B. „D70") und ggf. Panels für Canny.

- [ ] **Step 7: Standard eintragen, Vollrender** (22 Bilder, ~50 Minuten)

Weicht Ulis Standard von D70 ab: in `folge01_manga.py` die Defaults in `render()` (`denoise`, `strength`, `control`) anpassen und committen (`chore(comic): Manga-Standard nach Feinschliff = <Variante>`). Overrides (Canny/anderer Seed) in `tool/comic/overrides_manga.txt`.

```bash
scp -r tool/comic/. pc:~/f01tool/
ssh pc 'cd ~/f01tool && nohup python3 folge01_manga.py full picks_foto.txt overrides_manga.txt > ~/comfy_f01/manga.log 2>&1 &'
```
Bei `MANGA_DONE`: `scp 'pc:~/comfy_f01/manga/*.png' build/f01_manga/`, Seite `runde2b.html` (je Motiv eine Zeile: Foto quer | Manga quer | Foto hoch | Manga hoch), Kopie `~/f01-runde2/manga.png`, an Uli.

**STOP — Ulis Freigabe** („ok" oder Liste von Nachbesserungen → Overrides → Schritt 7 wiederholen für die genannten Motive; alte Dateien vorher auf der Box löschen).

- [ ] **Step 8: Picks Runde 2 eintragen**

`tool/comic/picks_manga.txt`: 22 Zeilen `p01_quer=/home/uli/comfy_f01/manga/p01_quer_00001_.png` … `titel_hoch=…`.

```bash
git add tool/comic/picks_manga.txt tool/comic/overrides_manga.txt
git commit -F /tmp/msg-b3b.txt
```
Inhalt: `chore(comic): Ulis Freigabe Runde 2 (Manga)` + Trailer. `ssh pc 'rm -f ~/.no-idle-suspend'`.

---

### Task 4: Vergrößern und Auslieferungsgröße (`folge01_finish.py`)

**Files:**
- Create: `tool/comic/folge01_finish.py`
- Create: `tool/comic/test_finish.py`

**Interfaces:**
- Consumes: `comfy_client.upscale_graph`, `comfy_client.run`, `picks_manga.txt`, `folge01_manga.load_picks`-Format ohne Seed-Pflicht (eigene Leserfunktion).
- Produces:
  - `folge01_finish.TARGET = {"quer": (1920, 1072), "hoch": (1080, 1936)}`
  - `folge01_finish.read_picks(path) -> dict[str, str]` (Schlüssel → Pfad; wirft `FileNotFoundError("FEHLT …")`)
  - `folge01_finish.require_complete(picks) -> None` — wirft `ValueError` mit den fehlenden Schlüsseln, wenn nicht alle 22 (`p01`…`p10`, `titel` × `quer`/`hoch`) da sind
  - `folge01_finish.target_for(key) -> tuple[int, int]`
  - Dateien `~/comfy_f01/final/<key>.jpg` (JPEG q88, exakt Zielgröße), Log `finish.log` mit `FINISH_DONE`
  - Auf dem NUC danach: `build/f01_raw/<key>.jpg` (22 Dateien)

- [ ] **Step 1: Failing Tests schreiben** — `tool/comic/test_finish.py`:

```python
#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_finish"""
import os
import tempfile
import unittest

import folge01_finish as ff


class Finish(unittest.TestCase):
    def test_targets(self):
        self.assertEqual(ff.target_for("p03_quer"), (1920, 1072))
        self.assertEqual(ff.target_for("titel_hoch"), (1080, 1936))
        with self.assertRaises(ValueError):
            ff.target_for("p03_breit")

    def test_require_complete_lists_missing(self):
        picks = {"%s_%s" % (m, f): "x" for m in ["p%02d" % i for i in range(1, 11)] + ["titel"]
                 for f in ("quer", "hoch")}
        ff.require_complete(picks)  # 22 Schlüssel → ok
        del picks["p07_hoch"]
        with self.assertRaises(ValueError) as cm:
            ff.require_complete(picks)
        self.assertIn("p07_hoch", str(cm.exception))

    def test_read_picks_checks_files(self):
        d = tempfile.mkdtemp()
        img = os.path.join(d, "p01_quer_00001_.png")
        open(img, "wb").write(b"x")
        p = os.path.join(d, "picks.txt")
        open(p, "w", encoding="utf-8").write("p01_quer=%s\np02_quer=%s/nix.png\n" % (img, d))
        with self.assertRaises(FileNotFoundError) as cm:
            ff.read_picks(p)
        self.assertIn("FEHLT p02_quer", str(cm.exception))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag sehen**

Run: `cd tool/comic && python3 -m unittest test_finish -v`
Expected: `ModuleNotFoundError`.

- [ ] **Step 3: Skript schreiben** — `tool/comic/folge01_finish.py`:

```python
#!/usr/bin/env python3
"""Runde 2 → Auslieferung: 4x-UltraSharp hoch, auf Zielgröße, JPEG q88 (Spec §4.3). Läuft auf der Box.
  folge01_finish.py picks_manga.txt → ~/comfy_f01/final/<key>.jpg, endet mit FINISH_DONE"""
import os
import shutil
import sys

from PIL import Image

import comfy_client as cc

ROOT = os.path.expanduser("~/comfy_f01")
TARGET = {"quer": (1920, 1072), "hoch": (1080, 1936)}
MOTIFS = ["p%02d" % i for i in range(1, 11)] + ["titel"]


def target_for(key):
    fmt = key.rsplit("_", 1)[-1]
    if fmt not in TARGET:
        raise ValueError("%s: Format muss quer oder hoch sein" % key)
    return TARGET[fmt]


def read_picks(path):
    picks = {}
    for line in open(os.path.expanduser(path), encoding="utf-8"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, src = line.split("=", 1)
        src = os.path.expanduser(src.strip())
        if not os.path.exists(src):
            raise FileNotFoundError("FEHLT %s: %s" % (key.strip(), src))
        picks[key.strip()] = src
    return picks


def require_complete(picks):
    want = ["%s_%s" % (m, f) for m in MOTIFS for f in ("quer", "hoch")]
    missing = [k for k in want if k not in picks]
    if missing:
        raise ValueError("Picks unvollständig, fehlt: %s" % ", ".join(missing))


def main(picks_path):
    picks = read_picks(picks_path)
    require_complete(picks)
    out = os.path.join(ROOT, "final")
    os.makedirs(out, exist_ok=True)
    for key, src in picks.items():
        w, h = target_for(key)
        dest = os.path.join(out, key + ".jpg")
        if os.path.exists(dest):
            print("SKIP", key, flush=True)
            continue
        input_name = "f01fin_%s%s" % (key, os.path.splitext(src)[1])
        shutil.copy(src, os.path.join(cc.COMFY_INPUT, input_name))
        try:
            got = cc.run(cc.upscale_graph(input_name, "fin_" + key, w, h), "fin_" + key,
                         os.path.join(ROOT, "final_png"), "f01fin")
            im = Image.open(got[0]).convert("RGB")
            assert im.size == (w, h), "%s: %s statt %s" % (key, im.size, (w, h))
            im.save(dest, "JPEG", quality=88, optimize=True)
            print("OK", key, im.size, flush=True)
        except Exception as e:  # noqa: BLE001
            print("ERR", key, repr(e), flush=True)
    print("FINISH_DONE", flush=True)


if __name__ == "__main__":
    main(sys.argv[1])
```

- [ ] **Step 4: Tests grün**

Run: `cd tool/comic && python3 -m unittest test_finish -v`
Expected: 3 Tests OK.

- [ ] **Step 5: Commit, Lauf, Abholen**

```bash
git add tool/comic/folge01_finish.py tool/comic/test_finish.py
git commit -F /tmp/msg-b4.txt
```
Inhalt: `feat(comic): Vergrößerung auf Auslieferungsgröße` + Trailer.

```bash
scp -r tool/comic/. pc:~/f01tool/
ssh pc 'touch ~/.no-idle-suspend; cd ~/f01tool && nohup python3 folge01_finish.py picks_manga.txt > ~/comfy_f01/finish.log 2>&1 &'
```
Bei `FINISH_DONE` (≈ 22 × 20 s): `mkdir -p build/f01_raw && scp 'pc:~/comfy_f01/final/*.jpg' build/f01_raw/ && ls build/f01_raw | wc -l` → 22. Dann `ssh pc 'rm -f ~/.no-idle-suspend'`.

---

### Task 5: Layout-Datei, Lettering je Format, generierte Tippflächen, Konsistenztest

**Files:**
- Create: `tool/comic/folge01_layout.json`
- Modify: `tool/letter_folge01.py` → verschieben nach `tool/comic/letter_folge01.py` und neu schreiben
- Create: `tool/comic/gen_layout_dart.py`
- Create: `lib/features/story/episodes/folge_01_layout.g.dart` (generiert)
- Create: `tool/comic/test_letter.py`
- Test: `test/features/story/folge_01_layout_test.dart`

**Interfaces:**
- Consumes: `build/f01_raw/<key>.jpg` (Task 4); Blasentexte aus `tool/letter_folge01.py` (`BUBBLES`) und `lib/features/story/episodes/folge_01_regen.dart`.
- Produces:
  - Layout-Schema (JSON):
    ```json
    {
      "safe": 0.8,
      "reactions": ["p02", "p05", "p08"],
      "panels": {
        "p01": {
          "quer": {"faces": [[0.58, 0.20, 0.10, 0.12]],
                   "bubbles": [{"text": "みなみまち駅", "rect": [0.06, 0.05, 0.42, 0.13], "furigana": ["駅", "えき"]}]},
          "hoch": {"faces": [[0.40, 0.18, 0.18, 0.10]],
                   "bubbles": [{"text": "みなみまち駅", "rect": [0.12, 0.06, 0.76, 0.09], "furigana": ["駅", "えき"]}]}
        }
      }
    }
    ```
    `rect` = `[x, y, w, h]` normiert; `faces` = Rechtecke; `furigana` optional.
  - `letter_folge01.check_layout(layout) -> list[str]` (leer = ok; Meldungen `GESICHT VERDECKT …` / `SICHERE ZONE …`)
  - `letter_folge01.main()` schreibt `assets/story/folge01/p01.jpg`, `p01_hoch.jpg`, `pNN_reaction(.jpg|_hoch.jpg)` für `reactions`, kopiert `titel.jpg`/`titel_hoch.jpg`
  - `gen_layout_dart.py` schreibt `folge_01_layout.g.dart` mit Konstanten `f01HitQuerP01B0`, `f01HitHochP01B0` … (Typ `List<Map<String, double>>`, 4 Punkte TL, TR, BR, BL)
  - Dart-Test: Layout-Datei ↔ Folge-01-Daten (Text + Rechteck je Blase, beide Formate) — INV-14

- [ ] **Step 1: Failing Python-Test** — `tool/comic/test_letter.py`:

```python
#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_letter"""
import unittest

import letter_folge01 as lf


def layout(bubble_rect, face=None, fmt="quer"):
    return {"safe": 0.8, "reactions": [], "panels": {"p01": {fmt: {
        "faces": [face] if face else [],
        "bubbles": [{"text": "あめ", "rect": bubble_rect}]}}}}


class CheckLayout(unittest.TestCase):
    def test_ok(self):
        self.assertEqual(lf.check_layout(layout([0.2, 0.2, 0.3, 0.1])), [])

    def test_face_overlap(self):
        msgs = lf.check_layout(layout([0.2, 0.2, 0.3, 0.1], face=[0.3, 0.22, 0.1, 0.1]))
        self.assertTrue(msgs and msgs[0].startswith("GESICHT VERDECKT p01 quer"))

    def test_safe_zone_quer_is_vertical(self):
        # quer wird oben/unten beschnitten: y muss in [0.10, 0.90] liegen
        self.assertTrue(any("SICHERE ZONE" in m for m in lf.check_layout(layout([0.2, 0.05, 0.3, 0.1]))))
        self.assertEqual(lf.check_layout(layout([0.02, 0.2, 0.3, 0.1])), [])  # x am Rand ist quer erlaubt

    def test_safe_zone_hoch_is_horizontal(self):
        self.assertTrue(any("SICHERE ZONE" in m for m in lf.check_layout(layout([0.02, 0.2, 0.3, 0.1], fmt="hoch"))))
        self.assertEqual(lf.check_layout(layout([0.2, 0.02, 0.3, 0.1], fmt="hoch")), [])

    def test_output_names(self):
        self.assertEqual(lf.out_name("p01", "quer"), "p01.jpg")
        self.assertEqual(lf.out_name("p01", "hoch"), "p01_hoch.jpg")
        self.assertEqual(lf.out_name("p02", "quer", reaction=True), "p02_reaction.jpg")
        self.assertEqual(lf.out_name("p02", "hoch", reaction=True), "p02_reaction_hoch.jpg")


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag sehen**

Run: `cd tool/comic && python3 -m unittest test_letter -v`
Expected: `ModuleNotFoundError: No module named 'letter_folge01'`.

- [ ] **Step 3: Lettering neu schreiben** — `git mv tool/letter_folge01.py tool/comic/letter_folge01.py`, dann Inhalt ersetzen (die Funktionen `wrap`, `fit_font` und der Blasen-Zeichencode aus `letter()` bleiben inhaltlich wie bisher):

```python
#!/usr/bin/env python3
"""Lettering fuer Folge 01 aus EINER Layout-Datei (Spec Manga-Vollbild §4.4, INV-14/15).
Quelle: build/f01_raw/<pid>_<fmt>.jpg (Task 4). Ziel: assets/story/folge01/.
Idempotent; bricht bei Gesichts- oder Zonen-Verstoss ab, ohne etwas zu schreiben.
Aufruf im Repo-Wurzelverzeichnis: python3 tool/comic/letter_folge01.py"""
import json
import os
import shutil

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
LAYOUT = os.path.join(HERE, "folge01_layout.json")
SRC = os.environ.get("LETTER_SRC", "build/f01_raw")
DST = "assets/story/folge01"
FONT = "/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf"


def out_name(pid, fmt, reaction=False):
    return pid + ("_reaction" if reaction else "") + ("_hoch" if fmt == "hoch" else "") + ".jpg"


def _overlaps(slot, face):
    sx, sy, sw, sh = slot
    fx, fy, fw, fh = face
    cx, cy, rx, ry = sx + sw / 2, sy + sh / 2, sw / 2, sh / 2
    px = min(max(cx, fx), fx + fw)
    py = min(max(cy, fy), fy + fh)
    return ((px - cx) / rx) ** 2 + ((py - cy) / ry) ** 2 <= 1.0


def _in_safe_zone(rect, fmt, safe):
    lo, hi = (1 - safe) / 2, 1 - (1 - safe) / 2
    x, y, w, h = rect
    if fmt == "quer":      # oben/unten beschnitten
        return lo <= y and y + h <= hi
    return lo <= x and x + w <= hi  # hoch: links/rechts beschnitten


def check_layout(layout):
    msgs = []
    safe = layout.get("safe", 0.8)
    for pid, formats in layout["panels"].items():
        for fmt, spec in formats.items():
            for b in spec.get("bubbles", []):
                for face in spec.get("faces", []):
                    if _overlaps(b["rect"], face):
                        msgs.append("GESICHT VERDECKT %s %s %r rect=%s face=%s" % (pid, fmt, b["text"], b["rect"], face))
                if not _in_safe_zone(b["rect"], fmt, safe):
                    msgs.append("SICHERE ZONE %s %s %r rect=%s" % (pid, fmt, b["text"], b["rect"]))
    return msgs


def wrap(text):
    if len(text) <= 9:
        return text
    if " " in text:
        parts = text.split(" ")
        n = 3 if len(parts) >= 6 else 2
        per = -(-len(parts) // n)
        return "\n".join(" ".join(parts[i:i + per]) for i in range(0, len(parts), per))
    dots = [i for i, c in enumerate(text[:-1]) if c == "。"]
    if dots:
        i = min(dots, key=lambda d: abs(d - len(text) / 2))
        return text[:i + 1] + "\n" + text[i + 1:]
    return text


def fit_font(draw, text, box_w, box_h, reserve_top=0):
    size = int(box_h * 0.55)
    while size > 10:
        font = ImageFont.truetype(FONT, size)
        l, t, r, b = draw.multiline_textbbox((0, 0), text, font=font)
        if r - l <= box_w * 0.86 and b - t <= box_h * 0.72 - reserve_top:
            return font
        size -= 2
    return ImageFont.truetype(FONT, 10)


def letter(img, bubbles):
    draw = ImageDraw.Draw(img)
    W, H = img.size
    for b in bubbles:
        x, y, w, h = b["rect"]
        furi = b.get("furigana")
        box = (x * W, y * H, (x + w) * W, (y + h) * H)
        draw.ellipse(box, fill="white", outline="black", width=4)
        shown = wrap(b["text"].replace("…", "・・・"))
        reserve = (box[3] - box[1]) * 0.22 if furi else 0
        font = fit_font(draw, shown, box[2] - box[0], box[3] - box[1], reserve)
        l, t, r, bb = draw.multiline_textbbox((0, 0), shown, font=font)
        cx = (box[0] + box[2]) / 2 - (r - l) / 2 - l
        cy = (box[1] + box[3]) / 2 - (bb - t) / 2 - t + reserve / 2
        draw.multiline_text((cx, cy), shown, fill="black", font=font, align="center")
        if furi:
            kanji, reading = furi
            small = ImageFont.truetype(FONT, max(10, font.size // 2))
            pre = shown[:shown.index(kanji)]
            kx = cx + draw.textlength(pre, font=font)
            kw = draw.textlength(kanji, font=font)
            rw = draw.textlength(reading, font=small)
            draw.text((kx + kw / 2 - rw / 2, cy + t - small.size - 2), reading, fill="black", font=small)
    return img


def main():
    layout = json.load(open(LAYOUT, encoding="utf-8"))
    problems = check_layout(layout)
    if problems:
        print("\n".join(problems))
        raise SystemExit("Lettering abgebrochen (%d Verstösse)." % len(problems))
    os.makedirs(DST, exist_ok=True)
    n = 0
    for pid, formats in layout["panels"].items():
        for fmt, spec in formats.items():
            img = Image.open(os.path.join(SRC, "%s_%s.jpg" % (pid, fmt))).convert("RGB")
            img = letter(img, spec.get("bubbles", []))
            img.save(os.path.join(DST, out_name(pid, fmt)), quality=88, optimize=True)
            n += 1
            if pid in layout.get("reactions", []):
                warm = ImageEnhance.Color(ImageEnhance.Brightness(img).enhance(1.12)).enhance(1.25)
                warm.save(os.path.join(DST, out_name(pid, fmt, reaction=True)), quality=88, optimize=True)
                n += 1
    for fmt in ("quer", "hoch"):
        shutil.copy(os.path.join(SRC, "titel_%s.jpg" % fmt), os.path.join(DST, out_name("titel", fmt)))
        n += 1
    print("OK: %d Dateien nach %s" % (n, DST))


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Python-Tests grün**

Run: `cd tool/comic && python3 -m unittest test_letter -v`
Expected: 5 Tests OK.

- [ ] **Step 5: Layout-Datei erstellen** — `tool/comic/folge01_layout.json` (Write-Tool)

Vorgehen je Panel und Format: das Bild `build/f01_raw/<pid>_<fmt>.jpg` mit dem Read-Tool ansehen, Gesichter als Rechtecke ablesen (`faces`), die Blasen-Slots setzen. Texte, Reihenfolge und Furigana **exakt** aus `BUBBLES` des alten `tool/letter_folge01.py` (Stand vor Schritt 3, per `git show HEAD~1:tool/letter_folge01.py`) übernehmen — sie sind die Textquelle der Folge-01-Daten:
p01 `みなみまち駅` (Furigana 駅/えき); p03 `あめ！あめ！`, `あめ、あめ… さむい、さむい`; p04 `傘` (傘/かさ), `…あめ`; p05 `あめ、あめ！`, `これ？かさ？みせ！`, `ひとり？`, `…はい。ひとり`; p06 `これ、こわれた`, `はい、こわれた、こわれた。だめ、だめ`, `…こわれた…？`; p07 `はい。かさ。どうぞ`, `え？いくら？いくら？`, `いいえ、いいえ。どうぞ、どうぞ。かさ！`, `…ほんとう？`, `ほんとう。だいじょうぶ、だいじょうぶ`; p08 `はいはい`, `ありがとう… すみません… あめ… かさ… いいえ… だいじょうぶ… えき… みせ…`; p09 `あめやどり`, `ここ…？あめ…やどり？`; p10 `ここ…`. p02 hat keine Blasen (nur `faces: []`, `bubbles: []`), beide Formate müssen trotzdem als Einträge existieren, damit die Dateien erzeugt werden. `reactions`: `["p02", "p05", "p08"]`, `safe`: `0.8`.
Quer-Slots liegen in y ∈ [0,10; 0,90], Hoch-Slots in x ∈ [0,10; 0,90]. Danach `python3 tool/comic/letter_folge01.py` — bei Verstoß Slots verschieben, nie die Prüfung lockern.

- [ ] **Step 6: Dart-Generator** — `tool/comic/gen_layout_dart.py`:

```python
#!/usr/bin/env python3
"""Erzeugt lib/features/story/episodes/folge_01_layout.g.dart aus folge01_layout.json (INV-14).
Aufruf im Repo-Wurzelverzeichnis: python3 tool/comic/gen_layout_dart.py"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
LAYOUT = os.path.join(HERE, "folge01_layout.json")
OUT = "lib/features/story/episodes/folge_01_layout.g.dart"


def const_name(pid, fmt, i):
    return "f01Hit%s%sB%d" % ("Quer" if fmt == "quer" else "Hoch", pid.capitalize(), i)


def points(rect):
    x, y, w, h = rect
    return [(x, y), (x + w, y), (x + w, y + h), (x, y + h)]


def main():
    layout = json.load(open(LAYOUT, encoding="utf-8"))
    lines = ["// GENERATED by tool/comic/gen_layout_dart.py aus tool/comic/folge01_layout.json.",
             "// Nicht von Hand ändern — Layout-Datei ändern und neu erzeugen (INV-14).", ""]
    for pid, formats in layout["panels"].items():
        for fmt, spec in formats.items():
            for i, b in enumerate(spec.get("bubbles", [])):
                pts = ", ".join("{'x': %s, 'y': %s}" % (round(px, 4), round(py, 4)) for px, py in points(b["rect"]))
                lines.append("/// %s %s: %s" % (pid, fmt, b["text"]))
                lines.append("const List<Map<String, double>> %s = [%s];" % (const_name(pid, fmt, i), pts))
                lines.append("")
    open(OUT, "w", encoding="utf-8").write("\n".join(lines))
    print(OUT)


if __name__ == "__main__":
    main()
```

Run: `python3 tool/comic/gen_layout_dart.py && dart format lib/features/story/episodes/folge_01_layout.g.dart`

- [ ] **Step 7: Failing Dart-Konsistenztest** — `test/features/story/folge_01_layout_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

/// INV-14: Blasenposition im Bild (Lettering) und Tippfläche in der App
/// stammen aus tool/comic/folge01_layout.json. Läuft im Repo-Wurzelverzeichnis.
void main() {
  late Map<String, dynamic> layout;
  late Episode episode;

  setUpAll(() {
    layout = jsonDecode(File('tool/comic/folge01_layout.json').readAsStringSync())
        as Map<String, dynamic>;
    episode = loadFolge01();
  });

  List<double> rectOf(List<StoryPoint> pts) => [
        pts[0].x,
        pts[0].y,
        pts[1].x - pts[0].x,
        pts[2].y - pts[1].y,
      ];

  test('jede Blase der Folge steht mit Text und Rechteck in beiden Formaten in der Layout-Datei',
      () {
    final panels = layout['panels'] as Map<String, dynamic>;
    var checked = 0;
    for (final panel in episode.allPanels) {
      final pid = 'p${(panel.index + 1).toString().padLeft(2, '0')}';
      final formats = panels[pid] as Map<String, dynamic>?;
      expect(formats, isNotNull, reason: '$pid fehlt in der Layout-Datei');
      for (final entry in {'quer': PanelFormat.landscape, 'hoch': PanelFormat.portrait}.entries) {
        final spec = formats![entry.key] as Map<String, dynamic>;
        final bubbles = (spec['bubbles'] as List).cast<Map<String, dynamic>>();
        final withHit = [for (final b in panel.bubbles) if (b.hitArea.points.isNotEmpty) b];
        expect(bubbles.length, withHit.length,
            reason: '$pid ${entry.key}: ${bubbles.length} Blasen im Layout, ${withHit.length} in der Folge');
        for (var i = 0; i < bubbles.length; i++) {
          expect(withHit[i].text, bubbles[i]['text'],
              reason: '$pid ${entry.key} Blase $i: Text weicht ab');
          final want = (bubbles[i]['rect'] as List).cast<num>().map((n) => n.toDouble()).toList();
          final got = rectOf(withHit[i].hitAreaFor(entry.value).points);
          for (var k = 0; k < 4; k++) {
            expect(got[k], closeTo(want[k], 1e-4),
                reason: '$pid ${entry.key} Blase $i: Rechteck weicht ab (Feld $k)');
          }
          checked++;
        }
      }
    }
    expect(checked, greaterThan(20));
  });

  test('Reaktions-Panels der Layout-Datei tragen Reaktionsbilder in beiden Formaten', () {
    final reactions = (layout['reactions'] as List).cast<String>();
    for (final panel in episode.allPanels) {
      final pid = 'p${(panel.index + 1).toString().padLeft(2, '0')}';
      final it = panel.interactions.where((i) => i.reactionAsset != null).toList();
      if (reactions.contains(pid)) {
        expect(it, isNotEmpty, reason: '$pid: Reaktion im Layout, aber keine Interaktion mit reactionAsset');
        expect(it.first.reactionAssetPortrait, isNotNull, reason: '$pid: Reaktions-Hochbild fehlt');
      }
    }
  });
}
```

Run: `flutter test test/features/story/folge_01_layout_test.dart`
Expected: FAIL — die Folge-01-Daten zeigen noch alte Rechtecke und keine `hitAreaPortrait` (wird in Task 6 verdrahtet). Der Test bleibt bis Task 6 rot; das ist beabsichtigt.

- [ ] **Step 8: Commit**

```bash
git add tool/comic/letter_folge01.py tool/comic/folge01_layout.json tool/comic/gen_layout_dart.py tool/comic/test_letter.py lib/features/story/episodes/folge_01_layout.g.dart test/features/story/folge_01_layout_test.dart assets/story/folge01/
git commit -F /tmp/msg-b5.txt
```
Inhalt: `feat(comic): Lettering je Format aus einer Layout-Datei + generierte Tippflächen` + Trailer. (`git rm tool/letter_folge01.py` ist durch `git mv` erledigt.)

---

### Task 6: Folge 01 verdrahten — neue Bilder, Hochformat, Titelbild

**Files:**
- Modify: `lib/features/story/episodes/folge_01_regen.dart`
- Modify: `pubspec.yaml` (Assets)
- Delete: `assets/story/p01.jpg` … `p10.jpg`, `p02_reaction.jpg`, `p05_reaction.jpg`, `p08_reaction.jpg`
- Modify: `test/features/story/folge_01_panel_assets_test.dart`, `test/features/story/folge_01_regen_test.dart`

**Interfaces:**
- Consumes: Konstanten aus `folge_01_layout.g.dart`; Dateien unter `assets/story/folge01/`; Felder aus Plan A Task 1.
- Produces: `loadFolge01()` liefert `cover`, `coverPortrait`, `titleJa`, je Panel `assetPortrait`, je Dialog-Blase `hitAreaPortrait`, je Reaktion `reactionAssetPortrait`.

- [ ] **Step 1: Failing Tests erweitern** — in `folge_01_panel_assets_test.dart` den Test ersetzen durch:

```dart
  test('jedes Panel der Folge 01 referenziert gebündelte Bilder in beiden Formaten',
      () async {
    final episode = loadFolge01();
    Future<void> bundled(String? asset, String what) async {
      expect(asset, isNotNull, reason: '$what fehlt');
      expect(asset, isNot(contains('placeholder')), reason: '$what zeigt den Platzhalter');
      final data = await rootBundle.load(asset!);
      expect(data.lengthInBytes, greaterThan(1000), reason: '$asset fehlt oder ist leer');
    }

    for (final panel in episode.allPanels) {
      await bundled(panel.asset, 'Panel ${panel.index} quer');
      await bundled(panel.assetPortrait, 'Panel ${panel.index} hoch');
      expect(panel.asset, startsWith('assets/story/folge01/'));
    }
    for (final it in episode.allPanels.expand((p) => p.interactions)) {
      if (it.reactionAsset != null) {
        await bundled(it.reactionAsset, 'Reaktion quer');
        await bundled(it.reactionAssetPortrait, 'Reaktion hoch');
      }
    }
    await bundled(episode.cover, 'Titelbild quer');
    await bundled(episode.coverPortrait, 'Titelbild hoch');
    expect(episode.titleJa, '雨');
  });
```
In `folge_01_regen_test.dart` im Test „traegt intro, outro und pro Dialog-Bubble eine hitArea" nach der `hasLength(4)`-Erwartung ergänzen:
```dart
          expect(bubble.hitAreaPortrait?.points, hasLength(4),
              reason: 'Panel ${panel.index}: Dialog-Bubble ohne Hoch-Tippflaeche');
```

Run: `flutter test test/features/story/folge_01_panel_assets_test.dart test/features/story/folge_01_regen_test.dart`
Expected: FAIL (alte Pfade, kein Hochbild, kein Titelbild).

- [ ] **Step 2: Assets und pubspec**

```bash
git rm assets/story/p01.jpg assets/story/p02.jpg assets/story/p03.jpg assets/story/p04.jpg assets/story/p05.jpg assets/story/p06.jpg assets/story/p07.jpg assets/story/p08.jpg assets/story/p09.jpg assets/story/p10.jpg assets/story/p02_reaction.jpg assets/story/p05_reaction.jpg assets/story/p08_reaction.jpg
```
In `pubspec.yaml` unter `assets:` nach `- assets/story/` die Zeile `- assets/story/folge01/` ergänzen (Unterordner werden nicht rekursiv gebündelt).

- [ ] **Step 3: Folge-01-Daten umstellen** — in `folge_01_regen.dart`:

Import ergänzen: `import 'folge_01_layout.g.dart';`
Auf Episodenebene nach `'title': 'Regen',` einfügen:
```dart
  'titleJa': '雨',
  'cover': 'assets/story/folge01/titel.jpg',
  'coverPortrait': 'assets/story/folge01/titel_hoch.jpg',
```
Je Panel (Index 0–9 ↔ p01–p10):
- `'asset': 'assets/story/folge01/pNN.jpg'` und neu `'assetPortrait': 'assets/story/folge01/pNN_hoch.jpg'`.
- Je Dialog-Blase (in der Reihenfolge der Layout-Datei): `'hitArea': f01HitQuerPNNBi,` und `'hitAreaPortrait': f01HitHochPNNBi,` — die handgeschriebenen Punktlisten entfallen.
- Je Reaktion: `'reactionAsset': 'assets/story/folge01/pNN_reaction.jpg'`, `'reactionAssetPortrait': 'assets/story/folge01/pNN_reaction_hoch.jpg'` (p02, p05, p08).
Den Kopfkommentar der Datei anpassen: Bilder sind jetzt der Manga-Satz vom Plan B, Tippflächen kommen aus `folge_01_layout.g.dart`.

- [ ] **Step 4: Tests grün**

Run: `flutter test test/features/story/folge_01_panel_assets_test.dart test/features/story/folge_01_regen_test.dart test/features/story/folge_01_layout_test.dart test/features/story/folge_01_dichte_test.dart test/fixtures/story/`
Expected: alle PASS (Layout-Test jetzt grün).

- [ ] **Step 5: Vollsuite + Commit + Push**

Run: `flutter analyze && flutter test`
Expected: „+N −8".

```bash
git add pubspec.yaml lib/features/story/episodes/folge_01_regen.dart test/features/story/ assets/story/folge01/
git commit -F /tmp/msg-b6.txt
git push -u origin impl/manga-vollbild-bilder
```
Inhalt: `feat(story): Folge 01 im Manga-Look in beiden Formaten mit Titelbild verdrahtet` + Trailer. Draft-PR `impl/manga-vollbild-bilder` → `impl/manga-vollbild-app` öffnen; im Text: Runden 1–3, Links der Seiten, Picks-Dateien.

---

### Task 7: Gerätetest am S23

**Files:** keine Änderung (Befunde → Fix-Commits auf demselben Zweig).

- [ ] **Step 1: Deploy** — Skill `cross-machine-test-deploy` (Checkout auf dem Laptop, Handy RFCW220PB7W, Ready-Marker „Flutter run key commands").

- [ ] **Step 2: Prüfliste (Spec §10.3)** — an Uli als Klartext, Ergebnisse zurück in den Chat:
1. Titelkarte hochkant: Titelbild füllt den Schirm, Text unten lesbar; Handy drehen: Quer-Titelbild, Text bleibt lesbar.
2. Lesen: Statusleiste weg; Panel füllt den Schirm in beiden Lagen; Drehen mitten in der Folge wechselt nur das Bild, Position bleibt.
3. Blasen: in beiden Lagen tippbar (Vorlesen + Wörterbuch), keine Blase über einem Gesicht, keine abgeschnitten.
4. Mitmach-Hinweis (p02 Nachzeichnen, p05 Sprechen) sichtbar und tippbar; Reaktionsbild erscheint nach Erfolg, auch hochkant.
5. Endkarte → Café: Statusleiste wieder da.

- [ ] **Step 3: Befunde beheben, committen, Uli abschließend fragen** — jeder Befund als eigener Commit `fix(story): …` mit Test, wo ein Test ihn abbilden kann. Abschluss: Ulis „ok" zum Gerätetest.
