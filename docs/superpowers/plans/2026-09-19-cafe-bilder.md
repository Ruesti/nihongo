# Café-Bilder — Umsetzungsplan (Plan 2 von 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Das Café sieht aus wie ein Ort: derselbe Raum im Licht der Stunde, mit den anwesenden Gästen in kleinen Momenten — im Café-Raum, über jeder Frage und als Band auf der Erklärungskarte. Bibliothek: 38 Bilder (5 vorhanden, 33 neu), fotorealistischer Look A.

**Architecture:** Eine reine **Szenen-Bibliothek** (`cafe_scenes.dart`: Motiv × Licht → Asset-Pfad, mit Rückfallkette und einer Tabelle dessen, was gebündelt ist) wird von drei Bildschirmen konsumiert. Licht kommt aus der Uhr, Regen aus der Folge (`Episode.weather`). Die Bilder entstehen auf der GPU-Box in zwei kuratierten Runden (Tag-Motive, dann Lichtvarianten); ein **Gate** vorab prüft, ob Umleuchten im Foto-Look hält. Die App hängt nur an Manifest + gebündelten Dateien, nie an ComfyUI (CLAUDE.md §6).

**Tech Stack:** Flutter 3.44 / Dart 3; `flutter_test` mit `rootBundle` und `dart:io`; Python 3 (stdlib `urllib`, Pillow nur auf der Box) gegen die ComfyUI-HTTP-API (Qwen-Image GGUF + LoRA `shotengai_style_ckpt6`; Qwen-Image-Edit-2509 + Relight-LoRA). JPEG q88, 1216×832.

**Spec:** `docs/superpowers/specs/2026-09-18-cafe-szenen-und-stimmen-design.md` — §3.2 (Bibliothek), §3.3 (Orte), §5.3–5.6 (Bibliothek, Bildschirme, Stapel, Produktion), §7 (Nicht), §8 (Risiken), §9 (Tests), §10 (Reihenfolge). Ausführende lesen Spec und Plan.

**Voraussetzung:** Plan 1 (`2026-09-19-cafe-stimmen.md`) ist umgesetzt — Task 5 dieses Plans benutzt `_speakers`, `_speaker` und `speakerBlockOrdinal` aus dem Turn-Bildschirm.

## Global Constraints

- **Nie Crash bei fehlendem Bild:** Jedes `Image.asset` im Café hat einen `errorBuilder` mit neutraler Fläche (`Color(0xFF2A3035)`); `sceneAsset` liefert immer einen Pfad (Rückfallkette, Spec §5.3). App ohne fertige Assets voll nutzbar (CLAUDE.md §6).
- **Tabelle ⇔ Dateien:** `cafeSceneLibrary` ist die einzige Wahrheit darüber, was gebündelt ist. Der strukturelle Test erzwingt: jede Tabellenzeile hat eine Datei, jede Datei eine Zeile. Kein Dateisystem-Scan zur Laufzeit.
- **Dateinamen:** `assets/comic/cafe/{motiv}_{licht}.jpg`, JPEG Qualität 88, 1216×832. `pubspec.yaml` deklariert `- assets/comic/cafe/` (Flutter rekursiert nicht in Unterordner).
- **Licht:** 06–17 Uhr `tag`, 17–21 `abend`, sonst `nacht`; `rain` ersetzt nur `tag` durch `regen`. Regen nur in der Nachbesprechung aus `Episode.weather == 'rain'`; der normale Besuch kennt nur die Uhr (Spec §5.3).
- **Ein Bild pro Block**, nicht pro Frage: Rotation über `speakerBlockOrdinal` (Spec §3.3). Kein Zufall.
- **Szenen sind Stimmung, kein Abrufreiz:** I6 betrifft Konzeptbilder; das Konzeptbild auf der Karte bleibt fest. Nichts wird freigeschaltet oder gezählt (INV-10, Brief §6).
- **Keine Mehr-Gäste-Szenen, keine Nahaufnahmen, keine neue Figur, Mira bleibt hinter der Kamera** (Spec §7).
- **Produktion:** Text-zu-Bild mit LoRA **0,3**, Foto-Zusatz und Anti-Anime-Negativ (Rezept der fünf vorhandenen Bilder); **feste Figurenbeschreibungen** (Spec §5.6) werden zwischen Motiven nie verändert; 2–3 Seeds je Motiv, Uli kuratiert per Kontaktbogen. Licht bevorzugt per Umleuchten (Gate in Task 1), sonst Text-zu-Bild je Licht.
- **GPU-Box-Regeln (Gedächtnis `gpu-box-suspend-driver-wedge`):** Port 8188 ist vom NUC aus dicht → Skripte laufen **auf** der Box (`ssh pc`). Vor langen Jobs `touch ~/.no-idle-suspend` auf der Box, danach `rm` in derselben nohup-Kette; Timer nie disablen. `nvidia-smi` auf „Driver/library version mismatch" prüfen — bei Mismatch STOPP, Reboot kann nur Uli (`ssh -t pc sudo reboot`). Erst rendern und abholen, dann schlafen lassen. Der NUC hat kein Pillow → Bögen und JPEG-Konvertierung auf der Box.
- **Abgabe an Uli:** Kontaktbögen per SendUserFile in den Chat (für Renders ausdrücklich gewünscht, Gedächtnis `comic-render-delivery-chat-preview`) **und** Kopie nach `~/` mit Lese-Kommando; nie `/jobs`- oder Box-Pfade als Abgabe nennen.
- **Branch:** `impl/cafe-bilder`, abgezweigt von `impl/cafe-stimmen`; Draft-PR mit Basis `impl/cafe-stimmen`. Render-Skripte werden **versioniert** unter `tool/comic/` (bisher lagen sie in flüchtigen Job-Ordnern).
- **Tests:** `flutter test`; Baseline aus Plan 1 Task 6; die 8 roten `test/mining_packs/ja` sind vorbestehend.

---

## Dateistruktur

| Datei | Verantwortung | Änderung |
|---|---|---|
| `tool/comic/comfy_client.py` | ComfyUI-HTTP-Client + die zwei Graphen (Text-zu-Bild, Umleuchten); läuft auf der Box | neu (Task 1) |
| `tool/comic/cafe_motifs.py` | Feste Figurenbeschreibungen, Motiv-Prompts, Licht-Prompts, Licht-Matrix | neu (Task 1) |
| `tool/comic/sheet.py` | Kontaktbogen (Pillow, Box) | neu (Task 1) |
| `tool/comic/cafe_relight_probe.py` | Gate: zwei Motive × drei Lichter × zwei Seeds | neu (Task 1) |
| `tool/comic/cafe_library.py` | Bibliothek rendern: `tag`, `relight PICKS`, `t2i-lights` | neu (Task 7) |
| `tool/comic/cafe_assemble.py` | Auswahl → JPEG q88 mit Zielnamen | neu (Task 7) |
| `lib/features/cafe/cafe_scenes.dart` | **Szenen-Bibliothek:** `CafeLight`, `CafeMotif`, `lightFor`, `sceneAsset`, `turnScene`, Tabelle | neu (Task 2) |
| `assets/comic/cafe/*.jpg` + `pubspec.yaml` | Bilder + Deklaration | Task 2 (5 Stück), Task 7/8 (33 Stück) |
| `lib/features/story/episode.dart`, `lib/features/story/episodes/folge_01_regen.dart` | `Episode.weather` | Task 3 |
| `lib/features/cafe/cafe_screen.dart` | Café-Raum mit Szene | Task 4 |
| `lib/features/cafe/cafe_turn_screen.dart` | Szene über der Frage, klappt bei Tastatur | Task 5 |
| `lib/features/cafe/cafe_debrief_screen.dart` | Band auf der Erklärungskarte, Regen aus der Folge | Task 6 |
| `test/features/cafe/cafe_scenes_test.dart`, `cafe_scenes_assets_test.dart` | Bibliothek-Logik, Tabelle ⇔ Dateien | Task 2 |
| `test/features/story/episode_weather_test.dart` | Wetter-Feld | Task 3 |
| `test/features/cafe/cafe_screen_test.dart` (erweitern), `cafe_turn_screen_scenes_test.dart`, `cafe_debrief_screen_scene_test.dart` | Bildschirme | Task 4–6 |

Schnittstellen zwischen den Tasks:

```dart
// Task 2 (cafe_scenes.dart)
enum CafeLight { tag, regen, abend, nacht }
enum CafeMotif { leer, wirtinTresen, wirtinTee, wirtinTisch, schulkindNische, schulkindHausaufgaben,
  schulkindKakao, vielrednerZeitung, vielrednerGefaltet, vielrednerFenster, gleichaltrigeKaffee,
  gleichaltrigeHaende, gleichaltrigeFenster; final String stem; final CafeGuest? guest; }
const String cafeSceneDir = 'assets/comic/cafe';
const Map<CafeMotif, Set<CafeLight>> cafeSceneLibrary;
CafeLight lightFor(DateTime now, {bool rain = false});
CafeMotif stammplatzOf(CafeGuest guest);
bool hasScene(CafeMotif motif, CafeLight light);
String sceneAssetIn(Map<CafeMotif, Set<CafeLight>> library, CafeMotif motif, CafeLight light);
String sceneAsset(CafeMotif motif, CafeLight light);          // = sceneAssetIn(cafeSceneLibrary, …)
String turnScene(CafeGuest speaker, CafeLight light, int ordinal);

// Task 3 (episode.dart)
class Episode { final String? weather; /* 'rain' | null */ }

// Task 4–6: neue Konstruktor-Parameter `CafeLight? light` auf CafeScreen, CafeTurnScreen, CafeDebriefScreen
// Widget-Keys: 'cafe-scene-room', 'cafe-scene-empty', 'cafe-scene-guest-<wirtin|schulkind|vielredner|gleichaltrige>',
//              'cafe-turn-scene', 'cafe-debrief-band'
```

Test-Helfer, der in Task 4–6 identisch verwendet wird (in jeder Testdatei lokal definieren):

```dart
String assetOf(WidgetTester tester, String key) =>
    (tester.widget<Image>(find.byKey(ValueKey(key))).image as AssetImage)
        .assetName;
```

---

### Task 0: Branch und Baseline

- [ ] **Step 1: Branch**

```bash
cd /home/uli/projects/nihongo/.claude/worktrees/design-cafe-szenen-stimmen
git checkout -b impl/cafe-bilder impl/cafe-stimmen
```

- [ ] **Step 2: Baseline**

Run: `flutter test 2>&1 | tail -1`
Expected: `+<N> -8` mit N = Stand nach Plan 1. Notieren.

---

### Task 1: Werkzeuge auf der Box und der Umleuchten-Beweis (Gate)

**Files:**
- Create: `tool/comic/comfy_client.py`, `tool/comic/cafe_motifs.py`, `tool/comic/sheet.py`, `tool/comic/cafe_relight_probe.py`

**Interfaces:**
- Produces: `comfy_client.run(graph, prefix, out_dir) → List[str]`, `comfy_client.t2i_graph(...)`, `comfy_client.relight_graph(...)`; `cafe_motifs.TAG_MOTIFS`, `.EXISTING_TAG`, `.RELIGHT`, `.T2I_LIGHT`, `.lights_for(motif)`; `sheet.py OUT COLS label=path…`.
- Entscheidung am Ende: **Weg R** (Umleuchten hält) oder **Weg T** (Text-zu-Bild je Licht) — Ulis Urteil nach Sichtung.

- [ ] **Step 1: `tool/comic/comfy_client.py`**

```python
#!/usr/bin/env python3
"""ComfyUI-HTTP-Client für die GPU-Box. Läuft AUF der Box (Port 8188 ist vom
NUC aus dicht). Nur Python-Standardbibliothek.

run(graph, prefix, out_dir) -> Liste der abgeholten Dateipfade.
"""
import json
import os
import time
import urllib.parse
import urllib.request

BASE = os.environ.get("COMFY", "http://127.0.0.1:8188")
COMFY_INPUT = os.path.expanduser(
    "~/ComfyUI-Easy-Install/ComfyUI-Easy-Install/ComfyUI/input")


def post(path, data):
    req = urllib.request.Request(BASE + path, data=json.dumps(data).encode(),
                                 headers={"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req, timeout=30))


def wait(prompt_id, timeout=1200):
    end = time.time() + timeout
    while time.time() < end:
        hist = json.load(urllib.request.urlopen(BASE + "/history/" + prompt_id, timeout=30))
        if prompt_id in hist:
            status = hist[prompt_id]["status"]
            if status.get("status_str") == "error":
                raise RuntimeError("job error: " + json.dumps(status)[:500])
            if status.get("completed"):
                return hist[prompt_id]
        time.sleep(3)
    raise TimeoutError(prompt_id)


def fetch(filename, subfolder, dest):
    q = urllib.parse.urlencode({"filename": filename, "subfolder": subfolder, "type": "output"})
    with open(dest, "wb") as f:
        f.write(urllib.request.urlopen(BASE + "/view?" + q, timeout=180).read())


def run(graph, prefix, out_dir, client_id="cafe"):
    os.makedirs(out_dir, exist_ok=True)
    r = post("/prompt", {"prompt": graph, "client_id": client_id})
    if r.get("node_errors"):
        raise RuntimeError("node_errors %s: %s" % (prefix, json.dumps(r["node_errors"])[:800]))
    hist = wait(r["prompt_id"])
    got = []
    for node in hist.get("outputs", {}).values():
        for im in node.get("images", []):
            if im.get("type") == "output":
                dest = os.path.join(out_dir, "%s_%s" % (prefix, im["filename"]))
                fetch(im["filename"], im.get("subfolder", ""), dest)
                got.append(dest)
    return got


def t2i_graph(prompt, negative, seed, prefix, lora_strength=0.3, width=1216, height=832):
    """Basis-Text-zu-Bild, Rezept der Look-A-Finals (LoRA 0.3, 24 Steps, cfg 4)."""
    return {
        "1": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": "qwen-image-Q4_K_M.gguf"}},
        "L": {"class_type": "LoraLoaderModelOnly", "inputs": {"model": ["1", 0],
              "lora_name": "shotengai_style_ckpt6.safetensors", "strength_model": lora_strength}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen_2.5_vl_7b_fp8_scaled.safetensors", "type": "qwen_image"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_vae.safetensors"}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": "shotengai_style, " + prompt, "clip": ["2", 0]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": ["2", 0]}},
        "6": {"class_type": "EmptySD3LatentImage", "inputs": {"width": width, "height": height, "batch_size": 1}},
        "7": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 24, "cfg": 4.0, "sampler_name": "euler",
              "scheduler": "simple", "denoise": 1.0, "model": ["L", 0], "positive": ["4", 0],
              "negative": ["5", 0], "latent_image": ["6", 0]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["3", 0]}},
        "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["8", 0]}},
    }


def relight_graph(input_name, prompt, seed, prefix):
    """Umleuchten: Qwen-Image-Edit-2509 + Lightning-4step + Relight-LoRA (bewährt für
    die Anker A1–A7). input_name liegt in COMFY_INPUT. Keine Stil-LoRA — das Bild
    trägt den Look schon."""
    return {
        "1": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": "Qwen-Image-Edit-2509-Q4_K_M.gguf"}},
        "2": {"class_type": "LoraLoaderModelOnly", "inputs": {"model": ["1", 0],
              "lora_name": "Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors", "strength_model": 1.0}},
        "3": {"class_type": "LoraLoaderModelOnly", "inputs": {"model": ["2", 0],
              "lora_name": "Qwen-Image-Edit-2509-Relight.safetensors", "strength_model": 1.0}},
        "4": {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["3", 0], "shift": 3.0}},
        "5": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen_2.5_vl_7b_fp8_scaled.safetensors", "type": "qwen_image"}},
        "6": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_vae.safetensors"}},
        "7": {"class_type": "LoadImage", "inputs": {"image": input_name}},
        "8": {"class_type": "FluxKontextImageScale", "inputs": {"image": ["7", 0]}},
        "9": {"class_type": "VAEEncode", "inputs": {"pixels": ["8", 0], "vae": ["6", 0]}},
        "10": {"class_type": "TextEncodeQwenImageEditPlus", "inputs": {"clip": ["5", 0], "prompt": prompt,
               "vae": ["6", 0], "image1": ["8", 0]}},
        "11": {"class_type": "TextEncodeQwenImageEditPlus", "inputs": {"clip": ["5", 0], "prompt": "", "vae": ["6", 0]}},
        "12": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 4, "cfg": 1.0, "sampler_name": "euler",
               "scheduler": "simple", "denoise": 1.0, "model": ["4", 0], "positive": ["10", 0],
               "negative": ["11", 0], "latent_image": ["9", 0]}},
        "13": {"class_type": "VAEDecode", "inputs": {"samples": ["12", 0], "vae": ["6", 0]}},
        "14": {"class_type": "SaveImage", "inputs": {"filename_prefix": prefix, "images": ["13", 0]}},
    }
```

- [ ] **Step 2: `tool/comic/cafe_motifs.py`** (Spec §3.2 Tabelle, §5.6 Beschreibungen)

```python
"""Feste Beschreibungen und Prompts der Café-Bibliothek (Spec Café-Szenen-und-Stimmen
§3.2/§5.6). Die Figurenbeschreibungen werden zwischen Motiven NIE verändert — sie sind
der einzige Identitätsanker im Look A (kein Referenzbild)."""

LORA_STRENGTH = 0.3

CAFE = ("the interior of a small old 1990s cafe, wooden counter, green vinyl booths, "
        "formica tables, net curtains, warm pendant bulbs")
LAND = ("an older landlady in her sixties, grey hair tied back in a low bun, "
        "black short-sleeved dress and a beige apron")
GIRL = ("a small elementary-school girl with a short black bob with bangs, navy sailor "
        "uniform with white stripes and a grey neckerchief, white socks")
MAN = ("a middle-aged man in his forties, short black hair, stubble, "
       "a worn olive-brown work jacket over a dark sweater")
YW = "a young woman with a chin-length black bob, an oversized cream knit sweater"

PHOTO = (", muted desaturated cool grey-green 1990s palette, deep shadows, melancholic, "
         "cinematic, photorealistic film still, realistic detailed human faces, "
         "natural skin texture, 35mm photograph, sharp focus")
NEG = ("anime, manga, cartoon, cel shading, illustration, comic, drawing, flat colors, "
       "stylized, big anime eyes, 2d, painting, text, watermark, letters, oversaturated, "
       "bright, cute, kawaii, blurry, deformed hands, extra fingers, empty, no people, faceless")
NEG_EMPTY = NEG.replace(", empty, no people, faceless", "")

# Neue Tag-Motive (Task 7). Schlüssel = Dateistamm.
TAG_MOTIFS = {
    "wirtin_tisch": CAFE + ", " + LAND + ", sits at a formica table directly across from the viewer, "
                    "a teapot and two cups on the table, looking at the viewer kindly, medium shot",
    "wirtin_tee": CAFE + ", " + LAND + ", stands behind the wooden counter pouring tea from a teapot "
                  "into a cup, seen across the room",
    "schulkind_hausaufgaben": CAFE + ", " + GIRL + ", sits low in a green booth bent over an open "
                              "exercise book, pencil in hand, small in correct perspective",
    "schulkind_kakao": CAFE + ", " + GIRL + ", sits low in a green booth holding a cup of cocoa with "
                       "both hands, looking toward the viewer, small in correct perspective",
    "vielredner_gefaltet": CAFE + ", " + MAN + ", sits in a green booth, a folded newspaper on the "
                           "table, gesturing with one hand mid-sentence, seen across the room",
    "vielredner_fenster": CAFE + ", " + MAN + ", sits in a green booth by the window holding a coffee "
                          "cup, looking out of the window, seen across the room",
    "gleichaltrige_haende": CAFE + ", " + YW + ", sits at a formica table holding a coffee cup in both "
                            "hands, a slight smile toward the viewer",
    "gleichaltrige_fenster": CAFE + ", " + YW + ", sits at a table by the window looking out at the "
                             "rain, a coffee cup on the table",
}

# Die fünf vorhandenen Tag-Bilder (PR #46) — nur für Weg T (Text-zu-Bild je Licht) nötig.
EXISTING_TAG = {
    "leer": CAFE + ", a coffee siphon and an old radio on the counter, empty, quiet, wide interior view",
    "wirtin_tresen": CAFE + ", " + LAND + ", stands behind the counter wiping it with a cloth, clearly visible",
    "schulkind_nische": CAFE + ", " + GIRL + ", sits low in a green booth at a table on the right, "
                        "small in correct perspective",
    "vielredner_zeitung": CAFE + ", " + MAN + ", sits in a green booth reading an open newspaper",
    "gleichaltrige_kaffee": CAFE + ", " + YW + ", sits at a table with a cup of coffee",
}

# Weg R: Umleuchten (Trigger der Relight-LoRA am Anfang).
KEEP = " Keep the same room, same furniture, same people, same poses, same faces."
RELIGHT = {
    "regen": "重新照明, relight this scene as a grey rainy day: dim overcast daylight through the "
             "windows, rain streaks and drops on the window glass, slightly cooler and darker, "
             "the pendant bulbs glowing warm." + KEEP,
    "abend": "重新照明, relight this scene at evening golden hour: low warm amber sunlight through "
             "the windows, long soft shadows, the pendant bulbs on." + KEEP,
    "nacht": "重新照明, relight this scene at night: dark blue outside the windows, the room lit only "
             "by the warm pendant bulbs, deep shadows, cozy." + KEEP,
}

# Weg T: Licht als Prompt-Zusatz (Rückfall, falls das Gate durchfällt).
T2I_LIGHT = {
    "regen": ", on a grey rainy day, rain streaks on the windows, dim overcast light",
    "abend": ", in the evening, warm amber golden-hour light through the windows, long soft shadows",
    "nacht": ", at night, dark windows, the room lit only by warm pendant bulbs",
}

# Licht-Matrix (Spec §3.2): Raum, Stammplätze und Wirtin am Tisch in allen vier
# Lichtern; Momente nur Tag + Abend.
FULL = ["leer", "wirtin_tresen", "wirtin_tisch", "schulkind_nische",
        "vielredner_zeitung", "gleichaltrige_kaffee"]
MOMENTS = ["wirtin_tee", "schulkind_hausaufgaben", "schulkind_kakao", "vielredner_gefaltet",
           "vielredner_fenster", "gleichaltrige_haende", "gleichaltrige_fenster"]


def lights_for(motif):
    return ["regen", "abend", "nacht"] if motif in FULL else ["abend"]


def negative_for(motif):
    return NEG_EMPTY if motif == "leer" else NEG
```

- [ ] **Step 3: `tool/comic/sheet.py`** (Pillow, auf der Box)

```python
#!/usr/bin/env python3
"""Kontaktbogen: sheet.py OUT.png COLS label=path [label=path ...]"""
import sys
from PIL import Image, ImageDraw

out, cols, items = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
W, H, PAD, LBL = 608, 416, 8, 28
rows = (len(items) + cols - 1) // cols
sheet = Image.new("RGB", (cols * (W + PAD) + PAD, rows * (H + LBL + PAD) + PAD), (24, 24, 24))
draw = ImageDraw.Draw(sheet)
for i, item in enumerate(items):
    label, path = item.split("=", 1)
    x = PAD + (i % cols) * (W + PAD)
    y = PAD + (i // cols) * (H + LBL + PAD)
    im = Image.open(path).convert("RGB")
    im.thumbnail((W, H))
    sheet.paste(im, (x, y + LBL))
    draw.text((x + 4, y + 6), label, fill=(230, 230, 230))
sheet.save(out)
print(out)
```

- [ ] **Step 4: `tool/comic/cafe_relight_probe.py`**

```python
#!/usr/bin/env python3
"""Gate (Spec §5.6/§10 Schritt 1): hält Umleuchten im Foto-Look? Zwei Motive
(leer, wirtin_tresen) × drei Lichter × zwei Seeds = 12 Bilder + Bogen.
Erwartet cafe_probe_leer.png und cafe_probe_wirtin.png in COMFY_INPUT."""
import os
import subprocess
import comfy_client as cc
from cafe_motifs import RELIGHT

OUT = os.path.expanduser("~/comfy_cafe_probe")
INPUTS = {"leer": "cafe_probe_leer.png", "wirtin_tresen": "cafe_probe_wirtin.png"}
SEEDS = (11, 22)

items = []
for motif, input_name in INPUTS.items():
    for light, prompt in RELIGHT.items():
        for seed in SEEDS:
            prefix = "%s_%s_s%d" % (motif, light, seed)
            try:
                got = cc.run(cc.relight_graph(input_name, prompt, seed, prefix), prefix, OUT, "probe")
                items += ["%s=%s" % (prefix, p) for p in got]
                print("OK", prefix, flush=True)
            except Exception as e:  # noqa: BLE001 — weiterrendern, Fehler sichtbar lassen
                print("ERR", prefix, repr(e), flush=True)
subprocess.run(["python3", os.path.join(os.path.dirname(__file__), "sheet.py"),
                os.path.join(OUT, "probe_sheet.png"), "4"] + items, check=False)
print("PROBE_DONE", flush=True)
```

- [ ] **Step 5: Box wecken, prüfen, Eingaben bereitstellen** (vom NUC aus)

```bash
wakegpu
for i in $(seq 1 30); do ssh pc 'curl -sf localhost:8188/system_stats >/dev/null' && echo API_OK && break; sleep 5; done
ssh pc 'nvidia-smi --query-gpu=name --format=csv,noheader'
```
Expected: `API_OK` und `NVIDIA GeForce RTX 3090`. Steht dort „Driver/library version mismatch": **STOPP** — Uli muss `ssh -t pc sudo reboot` ausführen, dann von vorn.

```bash
ssh pc 'mkdir -p ~/cafe_tools && touch ~/.no-idle-suspend && ls ~/finals_A/CAFE-empty.png ~/finals_A/CAFE-wirtin.png'
scp tool/comic/*.py pc:~/cafe_tools/
ssh pc 'CE=~/ComfyUI-Easy-Install/ComfyUI-Easy-Install/ComfyUI/input; cp ~/finals_A/CAFE-empty.png $CE/cafe_probe_leer.png; cp ~/finals_A/CAFE-wirtin.png $CE/cafe_probe_wirtin.png'
```
Fehlen die PNG-Finals auf der Box (ls meldet „No such file"), die JPEGs aus PR #46 nehmen:
```bash
mkdir -p build/cafe-probe
git show comic/folge01-panels:assets/comic/cafe/cafe_empty.jpg  > build/cafe-probe/cafe_probe_leer.jpg
git show comic/folge01-panels:assets/comic/cafe/cafe_wirtin.jpg > build/cafe-probe/cafe_probe_wirtin.jpg
scp build/cafe-probe/*.jpg pc:~/ComfyUI-Easy-Install/ComfyUI-Easy-Install/ComfyUI/input/
```
und in `cafe_relight_probe.py` die `INPUTS`-Endungen auf `.jpg` setzen (LoadImage liest JPEG).

- [ ] **Step 6: Beweis rendern und Bogen holen**

```bash
ssh pc 'cd ~/cafe_tools && nohup sh -c "python3 cafe_relight_probe.py; rm -f ~/.no-idle-suspend" > ~/cafe_probe.log 2>&1 &'
```
Alle ~60 s: `ssh pc 'tail -2 ~/cafe_probe.log'` bis `PROBE_DONE` (12 Bilder à ~20 s → ≈ 5 Min).
```bash
scp pc:~/comfy_cafe_probe/probe_sheet.png ~/cafe-umleuchten-bogen.png
```
Expected: Bogen mit 12 Kacheln, beschriftet `leer_regen_s11` … `wirtin_tresen_nacht_s22`.

- [ ] **Step 7: An Uli — und WARTEN (Gate)**

Bogen per SendUserFile schicken und im Chat sagen: Kopie liegt unter `~/cafe-umleuchten-bogen.png`. Frage an Uli: *„Hält der Raum und die Wirtin beim Umleuchten (Weg R), oder wirkt es flach/verändert — dann rendere ich jedes Licht neu (Weg T)?"* Prüfpunkte für ihn: Möbel und Wirtin identisch, Gesicht bleibt Foto (nicht Comic), Licht glaubhaft (Regen grau mit Tropfen, Abend bernstein, Nacht nur Lampen).

**Nicht weiter mit Task 7/8, bis Uli entschieden hat.** Tasks 2–6 sind unabhängig davon und laufen weiter.

- [ ] **Step 8: Commit der Werkzeuge**

```bash
git add tool/comic/
git commit -m "tool(comic): ComfyUI-Client, Café-Motive, Kontaktbogen, Umleuchten-Beweis (versioniert statt Job-Ordner)"
```

---

### Task 2: Die Szenen-Bibliothek im Code + die fünf vorhandenen Bilder

**Files:**
- Create: `lib/features/cafe/cafe_scenes.dart`
- Create: `assets/comic/cafe/{leer,wirtin_tresen,schulkind_nische,vielredner_zeitung,gleichaltrige_kaffee}_tag.jpg`
- Modify: `pubspec.yaml` (Assets)
- Test: `test/features/cafe/cafe_scenes_test.dart`, `test/features/cafe/cafe_scenes_assets_test.dart`

**Interfaces:** siehe Kopf („Task 2").

- [ ] **Step 1: Bilder aus PR #46 übernehmen und deklarieren**

```bash
mkdir -p assets/comic/cafe
git show comic/folge01-panels:assets/comic/cafe/cafe_empty.jpg         > assets/comic/cafe/leer_tag.jpg
git show comic/folge01-panels:assets/comic/cafe/cafe_wirtin.jpg        > assets/comic/cafe/wirtin_tresen_tag.jpg
git show comic/folge01-panels:assets/comic/cafe/cafe_schulkind.jpg     > assets/comic/cafe/schulkind_nische_tag.jpg
git show comic/folge01-panels:assets/comic/cafe/cafe_vielredner.jpg    > assets/comic/cafe/vielredner_zeitung_tag.jpg
git show comic/folge01-panels:assets/comic/cafe/cafe_gleichaltrige.jpg > assets/comic/cafe/gleichaltrige_kaffee_tag.jpg
ls -l assets/comic/cafe/
```
Expected: 5 Dateien, je 90–130 KB.

In `pubspec.yaml` unter `assets:` nach `- assets/comic/` einfügen:
```yaml
    - assets/comic/cafe/
```

- [ ] **Step 2: Fehlschlagende Tests** — `test/features/cafe/cafe_scenes_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';

void main() {
  group('lightFor', () {
    DateTime at(int h, [int m = 0]) => DateTime(2026, 9, 19, h, m);
    test('Uhrgrenzen 06 / 17 / 21', () {
      expect(lightFor(at(5, 59)), CafeLight.nacht);
      expect(lightFor(at(6)), CafeLight.tag);
      expect(lightFor(at(16, 59)), CafeLight.tag);
      expect(lightFor(at(17)), CafeLight.abend);
      expect(lightFor(at(20, 59)), CafeLight.abend);
      expect(lightFor(at(21)), CafeLight.nacht);
      expect(lightFor(at(0)), CafeLight.nacht);
    });
    test('Regen ersetzt nur den Tag', () {
      expect(lightFor(at(10), rain: true), CafeLight.regen);
      expect(lightFor(at(18), rain: true), CafeLight.abend);
      expect(lightFor(at(23), rain: true), CafeLight.nacht);
    });
  });

  group('sceneAssetIn — Rückfallkette', () {
    const onlyTag = {
      CafeMotif.leer: {CafeLight.tag},
      CafeMotif.wirtinTresen: {CafeLight.tag},
      CafeMotif.schulkindNische: {CafeLight.tag},
      CafeMotif.vielrednerZeitung: {CafeLight.tag},
      CafeMotif.gleichaltrigeKaffee: {CafeLight.tag},
    };
    test('vorhanden → direkter Pfad', () {
      expect(sceneAssetIn(onlyTag, CafeMotif.leer, CafeLight.tag),
          'assets/comic/cafe/leer_tag.jpg');
    });
    test('Moment ohne Licht → Stammplatz im Licht, sonst Stammplatz bei Tag',
        () {
      const lib = {
        CafeMotif.schulkindNische: {CafeLight.tag, CafeLight.nacht},
        CafeMotif.leer: {CafeLight.tag},
      };
      expect(sceneAssetIn(lib, CafeMotif.schulkindKakao, CafeLight.nacht),
          'assets/comic/cafe/schulkind_nische_nacht.jpg');
      expect(sceneAssetIn(lib, CafeMotif.schulkindKakao, CafeLight.abend),
          'assets/comic/cafe/schulkind_nische_tag.jpg');
    });
    test('Raum ohne Licht → Raum bei Tag; gar nichts → leer_tag', () {
      expect(sceneAssetIn(onlyTag, CafeMotif.leer, CafeLight.nacht),
          'assets/comic/cafe/leer_tag.jpg');
      expect(sceneAssetIn(const {}, CafeMotif.wirtinTee, CafeLight.abend),
          'assets/comic/cafe/leer_tag.jpg');
    });
    test('jede Kombination liefert einen Pfad', () {
      for (final m in CafeMotif.values) {
        for (final l in CafeLight.values) {
          expect(sceneAsset(m, l), startsWith('assets/comic/cafe/'));
          expect(sceneAsset(m, l), endsWith('.jpg'));
        }
      }
    });
  });

  group('turnScene', () {
    test('Ordnungszahl rotiert über Stammplatz und Momente des Sprechers', () {
      final a = turnScene(CafeGuest.schulkind, CafeLight.tag, 0);
      expect(a, sceneAsset(CafeMotif.schulkindNische, CafeLight.tag));
      expect(turnScene(CafeGuest.schulkind, CafeLight.tag, 1),
          sceneAsset(CafeMotif.schulkindHausaufgaben, CafeLight.tag));
      expect(turnScene(CafeGuest.schulkind, CafeLight.tag, 2),
          sceneAsset(CafeMotif.schulkindKakao, CafeLight.tag));
      expect(turnScene(CafeGuest.schulkind, CafeLight.tag, 3), a);
    });
    test('jeder Gast hat genau drei Motive, Stammplatz zuerst', () {
      for (final g in CafeGuest.values) {
        final motifs = CafeMotif.values.where((m) => m.guest == g).toList();
        expect(motifs.length, 3, reason: '$g');
        expect(motifs.first, stammplatzOf(g));
      }
    });
  });

  test('Tabelle: nur Motive mit den vier Lichtern, Dateistämme eindeutig', () {
    final stems = CafeMotif.values.map((m) => m.stem).toSet();
    expect(stems.length, CafeMotif.values.length);
    for (final e in cafeSceneLibrary.entries) {
      expect(e.value, isNotEmpty, reason: '${e.key} ohne Licht');
    }
  });
}
```

`test/features/cafe/cafe_scenes_assets_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('jede Tabellenzeile hat eine gebündelte Datei (> 1 KB)', () async {
    for (final e in cafeSceneLibrary.entries) {
      for (final light in e.value) {
        final path = '$cafeSceneDir/${e.key.stem}_${light.name}.jpg';
        final data = await rootBundle.load(path);
        expect(data.lengthInBytes, greaterThan(1000), reason: '$path fehlt');
      }
    }
  });

  test('jede Datei im Ordner steht in der Tabelle (keine Leichen im Bundle)',
      () {
    final files = Directory(cafeSceneDir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.jpg'))
        .toSet();
    final listed = {
      for (final e in cafeSceneLibrary.entries)
        for (final l in e.value) '${e.key.stem}_${l.name}.jpg',
    };
    expect(files, listed);
  });
}
```

- [ ] **Step 3: Tests laufen lassen — müssen fehlschlagen**

Run: `flutter test test/features/cafe/cafe_scenes_test.dart 2>&1 | tail -3`
Expected: `Target of URI doesn't exist: 'package:nihongo_app/features/cafe/cafe_scenes.dart'`.

- [ ] **Step 4: `lib/features/cafe/cafe_scenes.dart` anlegen**

```dart
import 'cafe_occupancy.dart';

/// Die Szenen-Bibliothek des Cafés (Spec Café-Szenen-und-Stimmen §3.2/§5.3):
/// derselbe Raum im Licht der Stunde, die Gäste an ihren Stammplätzen und in
/// kleinen Momenten. Reine Funktionen über einer Tabelle — kein Zufall, kein
/// Dateisystem-Scan. Szenen sind Stimmung, kein Abrufreiz (I6 gilt für
/// Konzeptbilder) und kein Fortschritt (INV-10).
enum CafeLight { tag, regen, abend, nacht }

/// 06–17 Uhr Tag, 17–21 Abend, sonst Nacht. [rain] ersetzt nur den Tag
/// durch Regen — Abend und Nacht behalten ihr Licht (drinnen sieht man
/// nächtlichen Regen ohnehin nicht).
CafeLight lightFor(DateTime now, {bool rain = false}) {
  final h = now.hour;
  if (h >= 6 && h < 17) return rain ? CafeLight.regen : CafeLight.tag;
  if (h >= 17 && h < 21) return CafeLight.abend;
  return CafeLight.nacht;
}

/// Die Motive. Je Gast in der Reihenfolge Stammplatz, Moment 1, Moment 2 —
/// [turnScene] rotiert darüber. [stem] ist der Dateistamm.
enum CafeMotif {
  leer('leer', null),
  wirtinTresen('wirtin_tresen', CafeGuest.wirtin),
  wirtinTee('wirtin_tee', CafeGuest.wirtin),
  wirtinTisch('wirtin_tisch', CafeGuest.wirtin),
  schulkindNische('schulkind_nische', CafeGuest.schulkind),
  schulkindHausaufgaben('schulkind_hausaufgaben', CafeGuest.schulkind),
  schulkindKakao('schulkind_kakao', CafeGuest.schulkind),
  vielrednerZeitung('vielredner_zeitung', CafeGuest.vielredner),
  vielrednerGefaltet('vielredner_gefaltet', CafeGuest.vielredner),
  vielrednerFenster('vielredner_fenster', CafeGuest.vielredner),
  gleichaltrigeKaffee('gleichaltrige_kaffee', CafeGuest.gleichaltrige),
  gleichaltrigeHaende('gleichaltrige_haende', CafeGuest.gleichaltrige),
  gleichaltrigeFenster('gleichaltrige_fenster', CafeGuest.gleichaltrige);

  final String stem;
  final CafeGuest? guest;
  const CafeMotif(this.stem, this.guest);
}

/// Stammplatz je Gast — das Bild, auf das alles zurückfällt.
CafeMotif stammplatzOf(CafeGuest guest) => switch (guest) {
      CafeGuest.wirtin => CafeMotif.wirtinTresen,
      CafeGuest.schulkind => CafeMotif.schulkindNische,
      CafeGuest.vielredner => CafeMotif.vielrednerZeitung,
      CafeGuest.gleichaltrige => CafeMotif.gleichaltrigeKaffee,
    };

const String cafeSceneDir = 'assets/comic/cafe';

/// Was wirklich gebündelt ist. Einzige Wahrheit; `cafe_scenes_assets_test`
/// erzwingt Tabelle ⇔ Dateien. Wächst mit jedem Render-Schritt (Plan Bilder
/// Task 7/8).
const Map<CafeMotif, Set<CafeLight>> cafeSceneLibrary = {
  CafeMotif.leer: {CafeLight.tag},
  CafeMotif.wirtinTresen: {CafeLight.tag},
  CafeMotif.schulkindNische: {CafeLight.tag},
  CafeMotif.vielrednerZeitung: {CafeLight.tag},
  CafeMotif.gleichaltrigeKaffee: {CafeLight.tag},
};

String _path(CafeMotif motif, CafeLight light) =>
    '$cafeSceneDir/${motif.stem}_${light.name}.jpg';

bool hasScene(CafeMotif motif, CafeLight light) =>
    cafeSceneLibrary[motif]?.contains(light) ?? false;

/// Rückfallkette über einer beliebigen Tabelle (testbar ohne die echte):
/// gewünscht → Stammplatz des Gastes im Licht → Stammplatz bei Tag → `leer`
/// bei Tag. Liefert immer einen Pfad; ob die Datei existiert, sichert der
/// strukturelle Test, den Rest fängt der `errorBuilder` (nie Crash).
String sceneAssetIn(Map<CafeMotif, Set<CafeLight>> library, CafeMotif motif,
    CafeLight light) {
  bool has(CafeMotif m, CafeLight l) => library[m]?.contains(l) ?? false;
  if (has(motif, light)) return _path(motif, light);
  final guest = motif.guest;
  final home = guest == null ? CafeMotif.leer : stammplatzOf(guest);
  if (has(home, light)) return _path(home, light);
  if (has(home, CafeLight.tag)) return _path(home, CafeLight.tag);
  return _path(CafeMotif.leer, CafeLight.tag);
}

String sceneAsset(CafeMotif motif, CafeLight light) =>
    sceneAssetIn(cafeSceneLibrary, motif, light);

/// Szene über einer Frage: der [ordinal]-te Block dieses Sprechers zeigt
/// Stammplatz, Moment 1, Moment 2, … rotierend — ein Bild pro Block, nicht
/// pro Frage (Spec §3.3).
String turnScene(CafeGuest speaker, CafeLight light, int ordinal) {
  final motifs = CafeMotif.values.where((m) => m.guest == speaker).toList();
  return sceneAsset(motifs[ordinal % motifs.length], light);
}
```

- [ ] **Step 5: Tests grün**

Run: `flutter test test/features/cafe/cafe_scenes_test.dart test/features/cafe/cafe_scenes_assets_test.dart 2>&1 | tail -1`
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/cafe/cafe_scenes.dart assets/comic/cafe/ pubspec.yaml test/features/cafe/cafe_scenes_test.dart test/features/cafe/cafe_scenes_assets_test.dart
git commit -m "feat(cafe): Szenen-Bibliothek — Motiv × Licht mit Rückfallkette; die fünf Look-A-Bilder aus PR #46 als Grundstock"
```

---

### Task 3: `Episode.weather` — Regen kommt aus der Folge

**Files:**
- Modify: `lib/features/story/episode.dart` (Klasse `Episode`), `lib/features/story/episodes/folge_01_regen.dart`
- Test: `test/features/story/episode_weather_test.dart`

**Interfaces:**
- Produces: `Episode.weather: String?` (`'rain'` oder null), JSON-Schlüssel `weather`.

- [ ] **Step 1: Fehlschlagender Test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

Map<String, dynamic> _minimal({String? weather}) => {
      'id': 'ep_w',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      if (weather != null) 'weather': weather,
      'budget': {'items': [], 'glyphs': []},
      'pages': [],
    };

void main() {
  test('weather ist optional und wird aus JSON gelesen', () {
    expect(Episode.fromJson(_minimal()).weather, isNull);
    expect(Episode.fromJson(_minimal(weather: 'rain')).weather, 'rain');
  });

  test('Folge 01 „Regen" regnet', () {
    expect(loadFolge01().weather, 'rain');
  });
}
```

- [ ] **Step 2: Test laufen lassen — muss fehlschlagen**

Run: `flutter test test/features/story/episode_weather_test.dart 2>&1 | tail -3`
Expected: `The getter 'weather' isn't defined for the type 'Episode'`.

- [ ] **Step 3: Feld einbauen** — in `lib/features/story/episode.dart`, Klasse `Episode`:

Nach `final Map<String, DebriefNote> debrief;` einfügen:
```dart

  /// Wetter der Folge (`'rain'` oder null). Das Café nimmt daraus das Licht
  /// der Nachbesprechung (Spec Café-Szenen-und-Stimmen §5.3): Regen ersetzt
  /// den Tag. Kein Story-Inhalt, nur Stimmung.
  final String? weather;
```
Im Konstruktor nach `this.debrief = const {},`:
```dart
    this.weather,
```
In `fromJson` nach dem `debrief:`-Block (vor `);`):
```dart
        weather: j['weather'] as String?,
```
In `lib/features/story/episodes/folge_01_regen.dart` nach `'era': '1996',` einfügen:
```dart
  'weather': 'rain',
```

- [ ] **Step 4: Tests grün, Validator und Folge-01-Tests unverändert**

Run: `flutter test test/features/story 2>&1 | tail -1`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/episode.dart lib/features/story/episodes/folge_01_regen.dart test/features/story/episode_weather_test.dart
git commit -m "feat(story): Episode.weather — Folge 01 regnet, das Café nimmt das Licht daraus"
```

---

### Task 4: Der Café-Raum zeigt den Raum

**Files:**
- Modify: `lib/features/cafe/cafe_screen.dart`
- Test: `test/features/cafe/cafe_screen_test.dart` (erweitern)

**Interfaces:**
- Consumes: Task 2 (`sceneAsset`, `stammplatzOf`, `lightFor`, `CafeMotif`, `CafeLight`).
- Produces: Parameter `CafeLight? light` (null = Uhr); Keys `cafe-scene-room`, `cafe-scene-empty`, `cafe-scene-guest-<guest.name>`; reicht `light` an `CafeTurnScreen` weiter (Parameter kommt in Task 5 — bis dahin **nicht** durchreichen, sonst kompiliert es nicht; Task 5 trägt die Zeile nach).

- [ ] **Step 1: Fehlschlagende Tests** — in `cafe_screen_test.dart` Imports ergänzen und `tearDown` erweitern:

```dart
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
```
```dart
  tearDown(() async {
    // Image.asset lädt asynchron; ohne Leeren spricht der imageCache
    // zwischen Tests über (flaky) — wie in PR #46.
    imageCache.clear();
    imageCache.clearLiveImages();
    await db.close();
  });

  String assetOf(WidgetTester tester, String key) =>
      (tester.widget<Image>(find.byKey(ValueKey(key))).image as AssetImage)
          .assetName;
```
Neue Tests vor der schließenden `}` von `main`:
```dart
  testWidgets('leer: die Wirtin am Tresen im Licht der Stunde', (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: CafeScreen(db: db, light: CafeLight.abend)));
    await tester.pumpAndSettle();
    expect(assetOf(tester, 'cafe-scene-empty'),
        sceneAsset(CafeMotif.wirtinTresen, CafeLight.abend));
    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);
  });

  testWidgets('belegt: der Raum als Kopfbild, je Gast sein Stammplatz als '
      'Miniatur', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_a', rung: 1);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_b', rung: 3);
    await tester.pumpWidget(
        MaterialApp(home: CafeScreen(db: db, light: CafeLight.nacht)));
    await tester.pumpAndSettle();
    expect(assetOf(tester, 'cafe-scene-room'),
        sceneAsset(CafeMotif.leer, CafeLight.nacht));
    expect(assetOf(tester, 'cafe-scene-guest-wirtin'),
        sceneAsset(stammplatzOf(CafeGuest.wirtin), CafeLight.nacht));
    expect(assetOf(tester, 'cafe-scene-guest-schulkind'),
        sceneAsset(stammplatzOf(CafeGuest.schulkind), CafeLight.nacht));
    expect(find.byKey(const ValueKey('cafe-scene-guest-vielredner')),
        findsNothing);
  });
```

- [ ] **Step 2: Tests laufen lassen — müssen fehlschlagen**

Run: `flutter test test/features/cafe/cafe_screen_test.dart 2>&1 | tail -3`
Expected: `No named parameter with the name 'light'`.

- [ ] **Step 3: `cafe_screen.dart` ändern**

Import: `import 'cafe_scenes.dart';`

Widget-Feld + Konstruktor:
```dart
  /// Licht der Szenen; null = aus der Uhr (Spec Café-Szenen-und-Stimmen
  /// §5.3). Der normale Besuch kennt keinen Regen.
  final CafeLight? light;
  // … im Konstruktor:
    this.light,
```

State: nach `bool _autoOpened = false;`:
```dart
  late final CafeLight _light = widget.light ?? lightFor(DateTime.now());

  /// Szene; fehlendes Asset → neutrale Fläche, nie Crash (CLAUDE.md §6).
  static Widget _scene(String asset, {required String keyName, double? height}) =>
      Image.asset(
        asset,
        key: ValueKey(keyName),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: height ?? 160,
          color: const Color(0xFF2A3035),
        ),
      );
```

`build`: den Leerzustand ersetzen durch
```dart
              ? ListView(
                  key: const ValueKey('cafe-empty'),
                  children: [
                    _scene(sceneAsset(CafeMotif.wirtinTresen, _light),
                        keyName: 'cafe-scene-empty', height: 200),
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Die Wirtin wischt den Tresen und nickt dir zu.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
```
und in der Gästeliste als erstes Kind vor der `for`-Schleife
```dart
                    _scene(sceneAsset(CafeMotif.leer, _light),
                        keyName: 'cafe-scene-room', height: 200),
```
sowie je `ListTile` ein `leading`:
```dart
                          leading: SizedBox(
                            width: 96,
                            height: 64,
                            child: _scene(
                                sceneAsset(stammplatzOf(guest), _light),
                                keyName: 'cafe-scene-guest-${guest.name}',
                                height: 64),
                          ),
```

- [ ] **Step 4: Tests grün** (alte + 2 neue)

Run: `flutter test test/features/cafe/cafe_screen_test.dart test/features/cafe/cafe_screen_debrief_test.dart 2>&1 | tail -1`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_screen.dart test/features/cafe/cafe_screen_test.dart
git commit -m "feat(cafe): Café-Raum zeigt den Raum im Licht der Stunde, Gäste als Stammplatz-Miniaturen"
```

---

### Task 5: Die Szene über der Frage (klappt bei offener Tastatur)

**Files:**
- Modify: `lib/features/cafe/cafe_turn_screen.dart`, `lib/features/cafe/cafe_screen.dart` (eine Zeile: `light` durchreichen)
- Test: `test/features/cafe/cafe_turn_screen_scenes_test.dart`

**Interfaces:**
- Consumes: Plan 1 (`_speakers`, `_speaker`, `speakerBlockOrdinal`), Task 2 (`turnScene`, `lightFor`).
- Produces: Parameter `CafeLight? light`; Key `cafe-turn-scene`; Höhe 200 offen, 72 bei Tastatur.

Warum feste Höhen statt Seitenverhältnis: Auf der 800×600-Testfläche und auf kleinen Handys müssen Wort, Antwortfeld und Knöpfe ohne Scrollen sichtbar bleiben; 200 px Band im `BoxFit.cover`-Beschnitt zeigt den Raum, ohne die Steuerung zu verdrängen (Spec §8, Risiko Bildschirmplatz).

- [ ] **Step 1: Fehlschlagende Tests** — `test/features/cafe/cafe_turn_screen_scenes_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';

void main() {
  late LearningDb db;
  late List<LearnItem> items;
  const words = ['あめ', 'かさ', 'えき', 'みせ'];

  setUp(() async {
    db = LearningDb.forTesting();
    items = [];
    for (var i = 0; i < words.length; i++) {
      await db.into(db.concepts).insert(ConceptsCompanion.insert(
          id: 'concept_$i', glossKey: 'gloss_$i', partOfSpeech: 'noun',
          defaultAssetType: const Value('image')));
      await db.into(db.lexemes).insert(LexemesCompanion.insert(
          id: 'lex_ja_$i', languageId: 'lang_ja', conceptId: 'concept_$i',
          writtenForm: words[i], reading: words[i]));
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_$i', rung: 1);
      items.add((await db.getLearnItem('lang_ja:lexeme:lex_ja_$i'))!);
    }
  });
  tearDown(() async {
    imageCache.clear();
    imageCache.clearLiveImages();
    await db.close();
  });

  String assetOf(WidgetTester tester, String key) =>
      (tester.widget<Image>(find.byKey(ValueKey(key))).image as AssetImage)
          .assetName;

  Future<void> answerKnown(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
    await tester.pumpAndSettle();
  }

  Widget screen({List<CafeGuest>? speakers}) => MaterialApp(
        home: CafeTurnScreen(
          db: db,
          guest: CafeGuest.wirtin,
          initialQueue: items,
          speakers: speakers,
          light: CafeLight.abend,
        ),
      );

  testWidgets('die Szene gehört dem Sprecher des Blocks und wechselt mit ihm',
      (tester) async {
    await tester.pumpWidget(screen(speakers: const [
      CafeGuest.wirtin, CafeGuest.wirtin, CafeGuest.wirtin, CafeGuest.schulkind,
    ]));
    await tester.pumpAndSettle();
    expect(assetOf(tester, 'cafe-turn-scene'),
        turnScene(CafeGuest.wirtin, CafeLight.abend, 0));
    await answerKnown(tester);
    // Innerhalb des Blocks bleibt das Bild (ein Bild pro Block, §3.3).
    expect(assetOf(tester, 'cafe-turn-scene'),
        turnScene(CafeGuest.wirtin, CafeLight.abend, 0));
    await answerKnown(tester);
    await answerKnown(tester);
    expect(assetOf(tester, 'cafe-turn-scene'),
        turnScene(CafeGuest.schulkind, CafeLight.abend, 0));
    // Steuerung bleibt ohne Scrollen erreichbar.
    expect(find.byKey(const ValueKey('cafe-turn-known')), findsOneWidget);
  });

  testWidgets('zweiter Block desselben Sprechers → nächster Moment',
      (tester) async {
    await tester.pumpWidget(screen()); // Wirtin überall → Blöcke 0 und 1
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await answerKnown(tester);
    }
    expect(assetOf(tester, 'cafe-turn-scene'),
        turnScene(CafeGuest.wirtin, CafeLight.abend, 1));
  });

  testWidgets('bei offener Tastatur klappt die Szene auf ein Band',
      (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('cafe-turn-scene'))).height,
        200);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('cafe-turn-scene'))).height,
        72);
  });
}
```

- [ ] **Step 2: Tests laufen lassen — müssen fehlschlagen**

Run: `flutter test test/features/cafe/cafe_turn_screen_scenes_test.dart 2>&1 | tail -3`
Expected: `No named parameter with the name 'light'`.

- [ ] **Step 3: `cafe_turn_screen.dart` ändern**

Import: `import 'cafe_scenes.dart';`

Widget-Feld + Konstruktor:
```dart
  /// Licht der Szene; null = aus der Uhr. Die Nachbesprechung reicht das
  /// Licht mit Regen der Folge durch (Spec Café-Szenen-und-Stimmen §5.3).
  final CafeLight? light;
  // … im Konstruktor:
    this.light,
```

State, nach `CafeGuestScript get _script => scriptFor(_speaker);`:
```dart
  late final CafeLight _light = widget.light ?? lightFor(DateTime.now());

  /// Szene des Sprechers, ein Bild pro Block (Spec §3.3); bei offener
  /// Tastatur nur ein Band, damit Wort und Eingabe Platz behalten (§8).
  Widget _sceneHeader(BuildContext context) {
    final asset =
        turnScene(_speaker, _light, speakerBlockOrdinal(_speakers, _index));
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return SizedBox(
      height: keyboardOpen ? 72 : 200,
      width: double.infinity,
      child: Image.asset(
        asset,
        key: const ValueKey('cafe-turn-scene'),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(color: const Color(0xFF2A3035)),
      ),
    );
  }
```

`_buildTurn`: die Szene wird das erste Kind der `Column` — und das äußere `Padding` weicht einem `Column`, damit das Bild randlos ist:
```dart
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneHeader(context),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (key, line) in _blockIntro)
                // … (unverändert ab hier: Intro-Zeilen, Stimm-Zeile, Kopftext, Steuerung)
```
Die bisherige Kinderliste wird eins tiefer eingerückt; nichts wird gelöscht. Die Signatur `_buildTurn(CafeTurnContent content)` bleibt; `context` ist im State verfügbar.

In `cafe_screen.dart` beim Aufruf `CafeTurnScreen(...)` (normaler Besuch) ergänzen:
```dart
                                light: _light,
```

- [ ] **Step 4: Tests grün** (alle Turn-Screen-Tests)

Run: `flutter test test/features/cafe 2>&1 | tail -1`
Expected: `All tests passed!` — die alten Turn-Tests tippen ihre Knöpfe weiter ohne Scrollen (200 px Band + Inhalt < 600 px).

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_turn_screen.dart lib/features/cafe/cafe_screen.dart test/features/cafe/cafe_turn_screen_scenes_test.dart
git commit -m "feat(cafe): Szene des Sprechers über jeder Frage — ein Bild pro Block, Band bei offener Tastatur"
```

---

### Task 6: Das Band auf der Erklärungskarte, Regen aus der Folge

**Files:**
- Modify: `lib/features/cafe/cafe_debrief_screen.dart`
- Test: `test/features/cafe/cafe_debrief_screen_scene_test.dart`

**Interfaces:**
- Consumes: Task 2, Task 3 (`episode.weather`), Task 5 (`CafeTurnScreen(light:)`).
- Produces: Parameter `CafeLight? light` (null = `lightFor(now, rain: episode.weather == 'rain')`); Key `cafe-debrief-band`.

- [ ] **Step 1: Fehlschlagender Test** — `test/features/cafe/cafe_debrief_screen_scene_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_debrief_screen.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

Map<String, dynamic> _episodeJson() => {
      'id': 'ep_scene',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'weather': 'rain',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'assets/story/p01.jpg',
              'bubbles': [
                {
                  'speakerId': 'x',
                  'text': 'あめ',
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    };

void main() {
  late LearningDb db;
  late StoryProgressStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = StoryProgressStore(await SharedPreferences.getInstance());
    db = LearningDb.forTesting();
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_rain', glossKey: 'rain', partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ame', languageId: 'lang_ja', conceptId: 'concept_rain',
        writtenForm: 'あめ', reading: 'あめ'));
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
  });
  tearDown(() async {
    imageCache.clear();
    imageCache.clearLiveImages();
    await db.close();
  });

  String assetOf(WidgetTester tester, String key) =>
      (tester.widget<Image>(find.byKey(ValueKey(key))).image as AssetImage)
          .assetName;

  testWidgets('Akt 1 trägt das Band „Wirtin am Tisch" im übergebenen Licht; '
      'Akt 2 bekommt dasselbe Licht', (tester) async {
    await tester.pumpWidget(_wrap(CafeDebriefScreen(
      db: db,
      episode: Episode.fromJson(_episodeJson()),
      progressStore: store,
      light: CafeLight.regen,
    )));
    await tester.pumpAndSettle();
    expect(assetOf(tester, 'cafe-debrief-band'),
        sceneAsset(CafeMotif.wirtinTisch, CafeLight.regen));
    // Die Panel-Miniatur bleibt das Hauptbild der Karte.
    expect(find.byKey(const ValueKey('cafe-debrief-panel')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pumpAndSettle();
    expect(assetOf(tester, 'cafe-turn-scene'),
        turnScene(CafeGuest.wirtin, CafeLight.regen, 0));
  });

  test('ohne übergebenes Licht: Regen der Folge ersetzt den Tag', () {
    final episode = Episode.fromJson(_episodeJson());
    expect(lightFor(DateTime(2026, 9, 19, 10), rain: episode.weather == 'rain'),
        CafeLight.regen);
  });
}
```
(Import `CafeGuest` kommt über `cafe_occupancy.dart` — ergänzen: `import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';`.)

- [ ] **Step 2: Test laufen lassen — muss fehlschlagen**

Run: `flutter test test/features/cafe/cafe_debrief_screen_scene_test.dart 2>&1 | tail -3`
Expected: `No named parameter with the name 'light'`.

- [ ] **Step 3: `cafe_debrief_screen.dart` ändern**

Import: `import 'cafe_scenes.dart';`

Widget-Feld + Konstruktor:
```dart
  /// Licht der Szenen; null = Uhr plus Regen der Folge (Spec §5.3).
  final CafeLight? light;
  // … Konstruktor:
    this.light,
```

State, nach `bool _advancing = false;`:
```dart
  late final CafeLight _light = widget.light ??
      lightFor(DateTime.now(), rain: widget.episode.weather == 'rain');
```

In `_finishExplain` beim `CafeTurnScreen(...)` ergänzen:
```dart
        light: _light,
```

Im `build`, Zweig `_DebriefPhase.explain`, als erstes Kind der `Column` vor dem `Padding` mit `wirtinDebriefLine`:
```dart
              SizedBox(
                height: 96,
                width: double.infinity,
                child: Image.asset(
                  sceneAsset(CafeMotif.wirtinTisch, _light),
                  key: const ValueKey('cafe-debrief-band'),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: const Color(0xFF2A3035)),
                ),
              ),
```

- [ ] **Step 4: Tests grün**

Run: `flutter test test/features/cafe 2>&1 | tail -1`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_debrief_screen.dart test/features/cafe/cafe_debrief_screen_scene_test.dart
git commit -m "feat(cafe): Band „Wirtin am Tisch" auf der Erklärungskarte; Regen der Folge färbt die Nachbesprechung"
```

---

### Task 7: Runde 1 rendern — die acht neuen Tag-Motive (Kuratier-Gate)

**Files:**
- Create: `tool/comic/cafe_library.py`, `tool/comic/cafe_assemble.py`
- Modify: `assets/comic/cafe/` (+8 JPEG), `lib/features/cafe/cafe_scenes.dart` (Tabelle)

**Interfaces:**
- `cafe_library.py tag` → `~/comfy_cafe_lib/tag/<motif>_s<seed>_*.png` (8 × 3 = 24) + `tag_sheet.png`.
- `cafe_assemble.py PICKS OUTDIR` → `OUTDIR/<motif>_<licht>.jpg` (q88, 1216×832).

- [ ] **Step 1: `tool/comic/cafe_library.py`**

```python
#!/usr/bin/env python3
"""Café-Bibliothek rendern (Spec §3.2/§5.6). Läuft auf der Box.

  cafe_library.py tag                → 8 neue Tag-Motive × Seeds 901,902,903
  cafe_library.py relight PICKS      → Weg R: je Zeile "motif=/pfad/tag.png" die Lichter aus lights_for()
  cafe_library.py t2i-lights         → Weg T: alle 13 Motive × Lichter × Seeds 901,902
Jeder Lauf endet mit einem Kontaktbogen und der Zeile LIB_DONE."""
import os
import shutil
import subprocess
import sys
import comfy_client as cc
from cafe_motifs import (EXISTING_TAG, LORA_STRENGTH, PHOTO, RELIGHT, T2I_LIGHT,
                         TAG_MOTIFS, lights_for, negative_for)

ROOT = os.path.expanduser("~/comfy_cafe_lib")
HERE = os.path.dirname(os.path.abspath(__file__))


def sheet(out_dir, name, items, cols=3):
    subprocess.run(["python3", os.path.join(HERE, "sheet.py"),
                    os.path.join(out_dir, name), str(cols)] + items, check=False)


def render_tag():
    out = os.path.join(ROOT, "tag")
    items = []
    for motif, core in TAG_MOTIFS.items():
        for seed in (901, 902, 903):
            prefix = "%s_s%d" % (motif, seed)
            try:
                got = cc.run(cc.t2i_graph(core + PHOTO, negative_for(motif), seed, prefix,
                                          LORA_STRENGTH), prefix, out, "cafelib")
                items += ["%s=%s" % (prefix, p) for p in got]
                print("OK", prefix, flush=True)
            except Exception as e:  # noqa: BLE001
                print("ERR", prefix, repr(e), flush=True)
    sheet(out, "tag_sheet.png", items)


def render_relight(picks_path):
    out = os.path.join(ROOT, "light")
    items = []
    for line in open(picks_path, encoding="utf-8"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        motif, src = line.split("=", 1)
        input_name = "cafe_%s_tag%s" % (motif, os.path.splitext(src)[1])
        shutil.copy(os.path.expanduser(src), os.path.join(cc.COMFY_INPUT, input_name))
        for light in lights_for(motif):
            for seed in (11, 22):
                prefix = "%s_%s_s%d" % (motif, light, seed)
                try:
                    got = cc.run(cc.relight_graph(input_name, RELIGHT[light], seed, prefix),
                                 prefix, out, "cafelib")
                    items += ["%s=%s" % (prefix, p) for p in got]
                    print("OK", prefix, flush=True)
                except Exception as e:  # noqa: BLE001
                    print("ERR", prefix, repr(e), flush=True)
    sheet(out, "light_sheet.png", items, cols=4)


def render_t2i_lights():
    out = os.path.join(ROOT, "light")
    items = []
    for motif, core in {**EXISTING_TAG, **TAG_MOTIFS}.items():
        for light in lights_for(motif):
            for seed in (901, 902):
                prefix = "%s_%s_s%d" % (motif, light, seed)
                try:
                    got = cc.run(cc.t2i_graph(core + T2I_LIGHT[light] + PHOTO, negative_for(motif),
                                              seed, prefix, LORA_STRENGTH), prefix, out, "cafelib")
                    items += ["%s=%s" % (prefix, p) for p in got]
                    print("OK", prefix, flush=True)
                except Exception as e:  # noqa: BLE001
                    print("ERR", prefix, repr(e), flush=True)
    sheet(out, "light_sheet.png", items, cols=4)


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "tag"
    if mode == "tag":
        render_tag()
    elif mode == "relight":
        render_relight(sys.argv[2])
    elif mode == "t2i-lights":
        render_t2i_lights()
    else:
        raise SystemExit("usage: cafe_library.py tag | relight PICKS | t2i-lights")
    print("LIB_DONE", flush=True)
```

- [ ] **Step 2: `tool/comic/cafe_assemble.py`**

```python
#!/usr/bin/env python3
"""Auswahl → JPEG q88 mit Zielnamen (Spec §5.3). Läuft auf der Box (Pillow).
  cafe_assemble.py PICKS OUTDIR
PICKS-Zeilen: "<motif>_<licht>=/pfad/zum/render.png"  (z. B. wirtin_tisch_tag=~/comfy_cafe_lib/tag/wirtin_tisch_s902_....png)"""
import os
import sys
from PIL import Image

picks, out_dir = sys.argv[1], os.path.expanduser(sys.argv[2])
os.makedirs(out_dir, exist_ok=True)
n = 0
for line in open(picks, encoding="utf-8"):
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    name, src = line.split("=", 1)
    im = Image.open(os.path.expanduser(src)).convert("RGB")
    if im.size != (1216, 832):
        im = im.resize((1216, 832), Image.LANCZOS)
    dest = os.path.join(out_dir, name + ".jpg")
    im.save(dest, "JPEG", quality=88, optimize=True)
    n += 1
    print(dest, os.path.getsize(dest) // 1024, "KB")
print("ASSEMBLED", n)
```

- [ ] **Step 3: Rendern** (Box wach + `nvidia-smi` ok wie in Task 1 Step 5)

```bash
scp tool/comic/*.py pc:~/cafe_tools/
ssh pc 'touch ~/.no-idle-suspend; cd ~/cafe_tools && nohup sh -c "python3 cafe_library.py tag; rm -f ~/.no-idle-suspend" > ~/cafe_lib_tag.log 2>&1 &'
```
Alle 2 Min `ssh pc 'grep -c ^OK ~/cafe_lib_tag.log; tail -1 ~/cafe_lib_tag.log'` bis `LIB_DONE` (24 Bilder à ~60–90 s → ≈ 30 Min). `ERR`-Zeilen: Prefix notieren, nach dem Lauf einzeln nachrendern (Seed +10).

```bash
scp pc:~/comfy_cafe_lib/tag/tag_sheet.png ~/cafe-tag-bogen.png
```

- [ ] **Step 4: An Uli — und WARTEN (Kuratier-Gate 1)**

Bogen per SendUserFile + Hinweis `~/cafe-tag-bogen.png`. Bitte um je Motiv **einen** Seed (901/902/903), Prüfpunkte: dieselbe Person wie auf dem Stammplatz-Bild (Frisur, Kleidung), Foto-Look (kein Comic-Gesicht), Figur klein im Raum, Möbel wie im leeren Café. Wenn kein Seed trifft: Motiv mit Seeds 911–913 nachrendern (`render_tag` mit angepasstem Seed-Tupel), Bogen erneut.

- [ ] **Step 5: Zusammenbauen und bündeln** — Ulis Wahl als `build/picks_tag.txt` (im Worktree, nicht committen):

```
wirtin_tisch_tag=~/comfy_cafe_lib/tag/wirtin_tisch_s902_wirtin_tisch_s902_00001_.png
wirtin_tee_tag=~/comfy_cafe_lib/tag/wirtin_tee_s901_…png
schulkind_hausaufgaben_tag=…
schulkind_kakao_tag=…
vielredner_gefaltet_tag=…
vielredner_fenster_tag=…
gleichaltrige_haende_tag=…
gleichaltrige_fenster_tag=…
```
(Die exakten Dateinamen liefert `ssh pc 'ls ~/comfy_cafe_lib/tag/'`.)

```bash
scp build/picks_tag.txt pc:~/cafe_tools/picks_tag.txt
ssh pc 'cd ~/cafe_tools && python3 cafe_assemble.py picks_tag.txt ~/cafe_lib_jpg'
scp 'pc:~/cafe_lib_jpg/*_tag.jpg' assets/comic/cafe/
ls assets/comic/cafe/ | wc -l
```
Expected: `ASSEMBLED 8`; im Ordner 13 Dateien.

- [ ] **Step 6: Tabelle nachziehen** — in `cafe_scenes.dart` `cafeSceneLibrary` ersetzen durch:

```dart
const Map<CafeMotif, Set<CafeLight>> cafeSceneLibrary = {
  CafeMotif.leer: {CafeLight.tag},
  CafeMotif.wirtinTresen: {CafeLight.tag},
  CafeMotif.wirtinTee: {CafeLight.tag},
  CafeMotif.wirtinTisch: {CafeLight.tag},
  CafeMotif.schulkindNische: {CafeLight.tag},
  CafeMotif.schulkindHausaufgaben: {CafeLight.tag},
  CafeMotif.schulkindKakao: {CafeLight.tag},
  CafeMotif.vielrednerZeitung: {CafeLight.tag},
  CafeMotif.vielrednerGefaltet: {CafeLight.tag},
  CafeMotif.vielrednerFenster: {CafeLight.tag},
  CafeMotif.gleichaltrigeKaffee: {CafeLight.tag},
  CafeMotif.gleichaltrigeHaende: {CafeLight.tag},
  CafeMotif.gleichaltrigeFenster: {CafeLight.tag},
};
```

- [ ] **Step 7: Struktureller Test grün, dann Commit**

Run: `flutter test test/features/cafe/cafe_scenes_assets_test.dart test/features/cafe/cafe_scenes_test.dart 2>&1 | tail -1`
Expected: `All tests passed!` (Tabelle ⇔ 13 Dateien).

```bash
git add tool/comic/cafe_library.py tool/comic/cafe_assemble.py assets/comic/cafe/ lib/features/cafe/cafe_scenes.dart
git commit -m "feat(cafe): Bibliothek Runde 1 — acht neue Tag-Motive (Momente + Wirtin am Tisch), kuratiert"
```

---

### Task 8: Runde 2 rendern — die Lichtvarianten (Weg R oder T, Kuratier-Gate)

**Files:**
- Modify: `assets/comic/cafe/` (+25 JPEG), `lib/features/cafe/cafe_scenes.dart` (Tabelle)

**Voraussetzung:** Ulis Entscheidung aus Task 1 (R = Umleuchten, T = Text-zu-Bild je Licht).

- [ ] **Step 1a (Weg R): Umleuchten aller 13 Tag-Bilder** — `build/picks_relight.txt` mit den 13 kuratierten Tag-Quellen (die 5 alten aus `~/finals_A/CAFE-*.png` bzw. den JPEGs im Repo, die 8 neuen aus Runde 1):

```
leer=~/finals_A/CAFE-empty.png
wirtin_tresen=~/finals_A/CAFE-wirtin.png
schulkind_nische=~/finals_A/CAFE-schoolgirl.png
vielredner_zeitung=~/finals_A/CAFE-vielredner.png
gleichaltrige_kaffee=~/finals_A/CAFE-gleichaltrige.png
wirtin_tisch=~/comfy_cafe_lib/tag/wirtin_tisch_s902_….png
wirtin_tee=…
schulkind_hausaufgaben=…
schulkind_kakao=…
vielredner_gefaltet=…
vielredner_fenster=…
gleichaltrige_haende=…
gleichaltrige_fenster=…
```
```bash
scp build/picks_relight.txt pc:~/cafe_tools/
ssh pc 'touch ~/.no-idle-suspend; cd ~/cafe_tools && nohup sh -c "python3 cafe_library.py relight picks_relight.txt; rm -f ~/.no-idle-suspend" > ~/cafe_lib_light.log 2>&1 &'
```
Erwartet: 6 Motive × 3 Lichter × 2 Seeds + 7 Momente × 1 Licht × 2 Seeds = **50** Bilder à ~20 s ≈ 20 Min.

- [ ] **Step 1b (Weg T): Text-zu-Bild je Licht**

```bash
ssh pc 'touch ~/.no-idle-suspend; cd ~/cafe_tools && nohup sh -c "python3 cafe_library.py t2i-lights; rm -f ~/.no-idle-suspend" > ~/cafe_lib_light.log 2>&1 &'
```
Erwartet: 25 Motiv-Licht-Paare × 2 Seeds = **50** Bilder à ~60–90 s ≈ 60 Min.

- [ ] **Step 2: Bogen holen, an Uli — und WARTEN (Kuratier-Gate 2)**

```bash
scp pc:~/comfy_cafe_lib/light/light_sheet.png ~/cafe-licht-bogen.png
```
SendUserFile + Hinweis `~/cafe-licht-bogen.png`. Bitte um je Motiv-Licht **einen** Seed. Prüfpunkte: Raum identisch zum Tag-Bild (Weg R) bzw. glaubhaft derselbe Raum (Weg T), Personen unverändert, Licht klar unterscheidbar (Regen grau + Tropfen, Abend bernstein, Nacht nur Lampen).

- [ ] **Step 3: Zusammenbauen, bündeln, Tabelle** — `build/picks_light.txt` (25 Zeilen `motif_licht=pfad`), dann:

```bash
scp build/picks_light.txt pc:~/cafe_tools/
ssh pc 'cd ~/cafe_tools && python3 cafe_assemble.py picks_light.txt ~/cafe_lib_jpg'
scp 'pc:~/cafe_lib_jpg/*_regen.jpg' 'pc:~/cafe_lib_jpg/*_abend.jpg' 'pc:~/cafe_lib_jpg/*_nacht.jpg' assets/comic/cafe/
ls assets/comic/cafe/ | wc -l
du -sh assets/comic/cafe/
```
Expected: `ASSEMBLED 25`; 38 Dateien; ≈ 4 MB.

Tabelle in `cafe_scenes.dart` auf den Endstand:
```dart
const Set<CafeLight> _all = {CafeLight.tag, CafeLight.regen, CafeLight.abend, CafeLight.nacht};
const Set<CafeLight> _moment = {CafeLight.tag, CafeLight.abend};

const Map<CafeMotif, Set<CafeLight>> cafeSceneLibrary = {
  CafeMotif.leer: _all,
  CafeMotif.wirtinTresen: _all,
  CafeMotif.wirtinTee: _moment,
  CafeMotif.wirtinTisch: _all,
  CafeMotif.schulkindNische: _all,
  CafeMotif.schulkindHausaufgaben: _moment,
  CafeMotif.schulkindKakao: _moment,
  CafeMotif.vielrednerZeitung: _all,
  CafeMotif.vielrednerGefaltet: _moment,
  CafeMotif.vielrednerFenster: _moment,
  CafeMotif.gleichaltrigeKaffee: _all,
  CafeMotif.gleichaltrigeHaende: _moment,
  CafeMotif.gleichaltrigeFenster: _moment,
};
```

- [ ] **Step 4: Tests grün, Commit, Box schlafen lassen**

Run: `flutter test test/features/cafe 2>&1 | tail -1`
Expected: `All tests passed!` (Tabelle ⇔ 38 Dateien).

```bash
git add assets/comic/cafe/ lib/features/cafe/cafe_scenes.dart
git commit -m "feat(cafe): Bibliothek Runde 2 — Regen, Abend, Nacht für Raum und Stammplätze, Abend für die Momente (38 Bilder)"
ssh pc 'ls ~/.no-idle-suspend 2>/dev/null && echo KILLSWITCH_NOCH_DA || echo ok'
```
Expected: `ok` (der Kill-Switch wurde in der nohup-Kette entfernt; der Timer legt die Box 30 Min nach Ruhe schlafen). Steht `KILLSWITCH_NOCH_DA`: `ssh pc 'rm ~/.no-idle-suspend'`.

---

### Task 9: Gerätetest S23, Abnahme, Draft-PR

**Files:** keine (außer Fixes aus dem Test).

- [ ] **Step 1: Gesamtlauf**

Run: `flutter test 2>&1 | tail -1` → `-8` unverändert, `+` um die neuen Tests gewachsen.
Run: `flutter analyze 2>&1 | tail -1` → `No issues found!`

- [ ] **Step 2: Push und Draft-PR** (Basis `impl/cafe-stimmen`)

```bash
git push -u origin impl/cafe-bilder
gh pr create --draft --base impl/cafe-stimmen --head impl/cafe-bilder \
  --title "feat(cafe): Bilder — der Raum im Licht der Stunde, 38 Szenen, Band auf der Erklärungskarte" \
  --body-file - <<'EOF'
Plan 2 von 2 zur Spec „Café-Szenen und Stimmen" (PR #50).

- `cafe_scenes.dart`: Motiv × Licht → Asset, Rückfallkette, Tabelle ⇔ Dateien (struktureller Test).
- Licht aus der Uhr (06/17/21), Regen aus `Episode.weather` (Folge 01 regnet) nur in der Nachbesprechung.
- Café-Raum (Kopfbild + Stammplatz-Miniaturen), Frage-Bildschirm (ein Bild pro Block, Band bei Tastatur), Erklärungskarte (Band „Wirtin am Tisch").
- Bibliothek: 38 JPEG q88 unter `assets/comic/cafe/` (5 aus PR #46 übernommen, 33 neu, Look A, LoRA 0,3, kuratiert). Render-Skripte versioniert unter `tool/comic/`.
- Stapel-Hinweis: die fünf Café-Bilder und die `pubspec`-Zeile stammen aus PR #46; #46 trägt daneben die 24-Panel-Reader-Verdrahtung, die durch Folge 01 V3 (#45) überholt ist und getrennt bereinigt wird — #46 nicht zusätzlich mergen.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
```

- [ ] **Step 3: Gerätetest** — Skill `cross-machine-test-deploy` (Build auf dem PC/Laptop, S23 per USB). Prüfliste = Abnahme aus Spec §9:

1. Folge 01 zu Ende lesen → „Ins Café" → Akt 1 zeigt das Band (Regen, wenn tagsüber getestet).
2. Akt 2: mindestens drei verschiedene Stimmen fragen (Titel wechselt, Übergabe + Einstieg sichtbar, kein Zwischenscreen).
3. Mindestens sechs verschiedene Bilder in einer Nachbesprechung (Band, Wirtin, drei Gäste, Raum).
4. Lese-Frage (Sprosse 2, falls vorhanden) bzw. Eingabefeld antippen: Szene klappt auf das Band, Wort und Feld bleiben sichtbar.
5. Café-Raum: Kopfbild im Licht der Stunde, Miniaturen je anwesendem Gast; leeres Café: Wirtin am Tresen.
6. Kein Bild wirkt „reingeklebt", keine Figur wirkt wie eine andere Person, keine Comic-Gesichter.
7. Abends/nachts erneut öffnen: Licht wechselt.

Befunde als Issues/Fix-Commits auf `impl/cafe-bilder`; Screenshots nach `~/cafe-s23-screens/`.

- [ ] **Step 4: Gedächtnis-Notiz** — Memory `nihongo-lernmechanik-design.md` und `nihongo-comic-style-comfyui.md`: PR-Nummern, Weg R/T, Kuratier-Stand, Gerätetest-Ergebnis; Render-Skripte jetzt unter `tool/comic/` (nicht mehr Job-Ordner).

---

## Self-Review (durchgeführt beim Schreiben)

- **Spec-Abdeckung:** §3.2 Bibliothek (Task 2, 7, 8), §3.3 Orte (Task 4, 5, 6), §5.3 Bibliothek/Licht/Regen/Rückfall/Tabelle (Task 2, 3), §5.4 Raum + Karte (Task 4, 6), §5.5 Stapel/Herkunft (Task 2 Step 1, PR-Text), §5.6 Produktion/Beschreibungen/Umleuchten-Gate/Seeds/Kuratierung (Task 1, 7, 8), §7 Nicht (Constraints), §8 Risiken Identität/Umleuchten/Bildschirmplatz (Task 1 Gate, Task 5 feste Höhen), §9 Tests (Task 2–6), §10 Reihenfolge (Task 1 → 2–6 → 7 → 8 → 9). Abnahme-Messlatte = Task 9 Prüfliste.
- **Platzhalter:** Die `…` in den PICKS-Beispielen sind bewusst: exakte Dateinamen entstehen erst beim Rendern (ComfyUI hängt Zähler an) und werden per `ls` gelesen — der Plan sagt, wie.
- **Typen/Namen:** `CafeLight`, `CafeMotif.stem/guest`, `stammplatzOf`, `sceneAsset`, `sceneAssetIn`, `turnScene`, `lightFor`, `cafeSceneLibrary`, `cafeSceneDir`, Keys `cafe-scene-room/-empty/-guest-<name>`, `cafe-turn-scene`, `cafe-debrief-band`, Parameter `light` auf allen drei Screens — in Tasks 2–6 gleich benannt. Python: `comfy_client.run/t2i_graph/relight_graph/COMFY_INPUT`, `cafe_motifs.TAG_MOTIFS/EXISTING_TAG/RELIGHT/T2I_LIGHT/lights_for/negative_for/LORA_STRENGTH/PHOTO` — in Task 1 definiert, Task 7 importiert genau diese.
- **Abhängigkeit:** Task 5 setzt Plan 1 voraus (`_speakers`, `_speaker`, `speakerBlockOrdinal`); Task 4 reicht `light` erst in Task 5 an den Turn-Bildschirm durch (Reihenfolge im Text festgehalten).
