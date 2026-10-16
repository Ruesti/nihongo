# Plan A2 — Ansprache-Bilder (Pipeline tool/comic, GPU-Box)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 60 Motive (4 Gäste × 3 Stimmungen × 5 Varianten) in hoch und quer als JPEG unter `assets/comic/cafe/ansprache/`, mit einer generierten Dart-Tabelle, die sagt, was vorliegt.

**Architecture:** Ein neues Skript `tool/comic/cafe_ansprache.py` baut auf `comfy_client.py` auf: fragend-Bilder als Text-zu-Bild im Foto-Look, zufrieden/abwinkend als Bearbeitung des fragend-Fotos über einen neuen `edit_graph` (Edit-Modell ohne Relight-LoRA), danach für alle der Manga-Durchgang D70 und das Vergrößern auf Auslieferungsgröße. Bögen über `sheet.py`, Picks und Nachbesserungen über Textdateien wie bei Folge 01. Drei Lauf-Stufen mit Ulis Entscheidung dazwischen: Gate, Runde 1 (fragend), Runde 2 (Stimmungen).

**Tech Stack:** Python 3 (unittest, PIL), ComfyUI 0.26 auf `pc` (RTX 3090, `COMFY=http://127.0.0.1:8188`), Modelle wie in `comfy_client.py` (qwen-image-Q4 + `shotengai_style_ckpt6` LoRA; `Qwen-Image-Edit-2509-Q4` + Lightning-LoRA; ControlNet-Union + DepthAnything; 4x-UltraSharp).

**Spec:** `docs/superpowers/specs/2026-10-15-cafe-ansprache-design.md` §2 (Bilder), §6 (Dateien), §8 (Tests), §9 (Pläne), §10 (Risiken).

## Global Constraints

- Gäste-Stems und Figurenbeschreibungen aus `cafe_motifs.py`: `wirtin` = `LAND`, `schulkind` = `GIRL`, `vielredner` = `MAN`, `gleichaltrige` = `YW`; Raum = `CAFE`; Foto-Zusatz `PHOTO`, Negativ `NEG`, LoRA-Stärke `LORA_STRENGTH` (0,3). Nichts davon kopieren, importieren.
- Formate (Spec §2.2): Text-zu-Bild quer 1664 × 928, hoch 928 × 1664; Auslieferung quer 1920 × 1072, hoch 1080 × 1936, JPEG q88 optimize.
- Dateinamen (Spec §2.4): `{gast}_{stimmung}_{n}_{format}.jpg`, `stimmung` ∈ `fragend`, `zufrieden`, `abwinkend`; `n` 1–5; `format` ∈ `quer`, `hoch`.
- Manga-Durchgang wie Folge 01: `cc.manga_graph(..., control="depth", denoise=0.7, strength=0.7, end_percent=0.8, lora_strength=1.5)`, Prompt `STY + ", " + core`, Negativ `NEG_MANGA` (beide aus `folge01_motifs.py`).
- Tests laufen ohne ComfyUI: `cd tool/comic && python3 -W error::ResourceWarning -m unittest discover -s . -p "test_*.py" -v`.
- Läufe auf der Box: `wakegpu`, `ssh pc 'touch ~/.no-idle-suspend'`, `scp tool/comic/*.py tool/comic/*.sh tool/comic/*.txt pc:f01tool/`, Start `ssh pc 'cd ~/f01tool && setsid nohup python3 cafe_ansprache.py <stufe> … > ansprache_<stufe>.log 2>&1 </dev/null &'`, Ende an der Marke `ANSPRACHE_DONE`, danach `ssh pc 'rm -f ~/.no-idle-suspend'`. Ausgaben unter `~/comfy_cafe_ansprache/`.
- Uli sieht Bögen als PNG unter `~/` auf dem NUC (Kopie per scp), keine Panels.

## Review Focus

1. Ein Pick in `picks_ansprache.txt` zeigt auf eine Datei, die es nicht gibt → Fehler mit Dateiname vor dem ersten Render, kein halber Lauf (Task 3).
2. Ein Edit liefert ein Bild in anderer Größe als die Quelle → Finish bricht mit Größenangabe ab, statt ein verzerrtes JPEG zu schreiben (Task 6).
3. Zwei Picks derselben Zelle bekommen dieselbe Nummer → Parser lehnt die Datei ab (Task 3).
4. Runde 2 soll nur eine Zelle nachrendern (`overrides`), nicht alles neu → `should_skip` greift, vorhandene Ausgaben bleiben (Task 4).
5. Der Generator findet eine Datei mit falschem Namen im Asset-Ordner → er bricht ab und nennt die Datei, statt sie stumm zu ignorieren (Task 6).

---

### Task 1: Prompt-Tabelle und Namen

**Files:**
- Create: `tool/comic/cafe_ansprache.py`
- Test: `tool/comic/test_ansprache.py`

**Interfaces:**
- Consumes: `cafe_motifs.LAND/GIRL/MAN/YW/CAFE/PHOTO/NEG/LORA_STRENGTH`, `folge01_motifs.STY/NEG_MANGA`.
- Produces:
  - `GUESTS: dict[str, dict]` mit Schlüsseln `wirtin`, `schulkind`, `vielredner`, `gleichaltrige`; je Gast `figure` (aus `cafe_motifs`), `place` (Stammplatz-Satz), `moods: dict[str, str]` (Bearbeitungs-Anweisung je Stimmung, s. u.).
  - `MOODS = ("fragend", "zufrieden", "abwinkend")`, `FORMATS = {"quer": (1664, 928), "hoch": (928, 1664)}`, `TARGET = {"quer": (1920, 1072), "hoch": (1080, 1936)}`, `VARIANTS = 5`.
  - `name_for(gast: str, stimmung: str, n: int, fmt: str) -> str` → `"wirtin_fragend_3_quer"` (ValueError bei unbekanntem Gast/Stimmung/Format, n außerhalb 1–5).
  - `all_names() -> list[str]` (120 Einträge, Reihenfolge Gast → Stimmung → n → Format).
  - `t2i_prompt(gast: str, fmt: str) -> tuple[str, str]` (positiv, negativ) für fragend.
  - `edit_prompt(gast: str, stimmung: str) -> str` für zufrieden/abwinkend (ValueError bei `fragend`).
  - `manga_prompt(gast: str) -> tuple[str, str]` = (`STY + ", " + figure + ", " + place`, `NEG_MANGA`).

Festgelegte Texte (Spec §2.1), wörtlich in die Tabelle:

- `place`: wirtin `"behind the wooden counter of the cafe"`, schulkind `"in a green vinyl booth with school notebooks on the table"`, vielredner `"at the window table with a folded newspaper"`, gleichaltrige `"at a formica table with a cup of coffee"`.
- Gemeinsamer fragend-Kern: `"looks straight into the camera and speaks to the viewer, mouth slightly open, eyebrows raised in a question, medium shot from head to hips, alone"`; dazu je Gast die Note: wirtin `"warm"`, schulkind `"cheeky, chin forward"`, vielredner `"grumpy, glancing over the newspaper"`, gleichaltrige `"friendly but indifferent"`.
- Format-Satz: quer `", the figure in the left half of the frame, the room continues to the right, wide framing"`; hoch `", the face in the upper half of the frame, table or counter in the lower half, vertical framing"`.
- `t2i_prompt` positiv = `"shotengai_style, " + CAFE + ", " + figure + ", " + place + ", " + kern + ", " + note + formatsatz + PHOTO`; negativ = `NEG + ", two people, looking away, profile view, closed eyes, back turned"`.
- `moods` (Edit-Anweisung, jeweils mit festem Schluss `", keep the same person, clothes, pose, lighting, background and framing"`):
  - wirtin: zufrieden `"change her expression to a warm satisfied smile with a slight nod"`, abwinkend `"change her expression to a kind but disappointed look, head slightly tilted, one hand raised in a small dismissive wave"`.
  - schulkind: zufrieden `"change her expression to a big cheeky grin, one fist raised in triumph"`, abwinkend `"change her expression to rolled eyes and a flat mouth, one hand waving the idea away"`.
  - vielredner: zufrieden `"change his expression to a satisfied grunt, a small nod, eyes a little softer"`, abwinkend `"change his expression to a frown with furrowed brow, the newspaper lowered"`.
  - gleichaltrige: zufrieden `"change her expression to a brief genuine smile"`, abwinkend `"change her expression to a shrug with raised shoulders and a flat mouth"`.

- [ ] **Step 1: Write the failing tests** in `test_ansprache.py` (unittest):

```python
class Names(unittest.TestCase):
    def test_name_for(self): self.assertEqual(ca.name_for("wirtin","fragend",3,"quer"), "wirtin_fragend_3_quer")
    def test_name_rejects(self):
        for bad in [("x","fragend",1,"quer"),("wirtin","froh",1,"quer"),("wirtin","fragend",6,"quer"),("wirtin","fragend",1,"breit")]:
            with self.assertRaises(ValueError): ca.name_for(*bad)
    def test_all_names_120_unique(self):
        names = ca.all_names(); self.assertEqual(len(names), 120); self.assertEqual(len(set(names)), 120)
class Prompts(unittest.TestCase):
    def test_t2i_contains_camera_and_format(self):
        pos, neg = ca.t2i_prompt("wirtin", "hoch")
        for s in ["looks straight into the camera", "upper half", cm.LAND, cm.CAFE, cm.PHOTO]: self.assertIn(s, pos)
        self.assertTrue(pos.startswith("shotengai_style, ")); self.assertIn("looking away", neg); self.assertIn(cm.NEG, neg)
    def test_edit_prompts_all_moods(self):
        for g in ca.GUESTS:
            for m in ("zufrieden", "abwinkend"): self.assertIn("keep the same person", ca.edit_prompt(g, m))
        with self.assertRaises(ValueError): ca.edit_prompt("wirtin", "fragend")
    def test_manga_prompt(self):
        pos, neg = ca.manga_prompt("schulkind"); self.assertTrue(pos.startswith(fm.STY)); self.assertIn(cm.GIRL, pos); self.assertEqual(neg, fm.NEG_MANGA)
```

- [ ] **Step 2: Run** `cd tool/comic && python3 -m unittest test_ansprache -v` → FAIL (ModuleNotFoundError cafe_ansprache)
- [ ] **Step 3: Implement** die Konstanten und die vier Funktionen in `cafe_ansprache.py` (Modul-Docstring: Zweck, Spec-Verweis).
- [ ] **Step 4: Run** → PASS; Gesamtlauf `python3 -W error::ResourceWarning -m unittest discover -s . -p "test_*.py"` grün.
- [ ] **Step 5: Commit** `feat(comic): Ansprache — Prompt-Tabelle, Stimmungen, Namen`

### Task 2: `edit_graph` im comfy_client

**Files:**
- Modify: `tool/comic/comfy_client.py` (neben `relight_graph`, Z. 79)
- Test: `tool/comic/test_graphs.py`

**Interfaces:**
- Produces: `edit_graph(input_name: str, prompt: str, seed: int, prefix: str, negative: str = "") -> dict` — derselbe Graph wie `relight_graph`, aber **ohne** den `Qwen-Image-Edit-2509-Relight`-LoRA-Lader (nur Lightning-LoRA 1.0), `negative` geht in den negativen `TextEncodeQwenImageEditPlus`; Sampler 4 Steps, cfg 1.0, denoise 1.0, `ModelSamplingAuraFlow` shift 3.0, Ausgabegröße = Eingabegröße (`FluxKontextImageScale` wie bisher).

- [ ] **Step 1: Write the failing test** in `test_graphs.py` (Helfer `_node` wiederverwenden):

```python
def test_edit_graph_has_no_relight_lora(self):
    g = cc.edit_graph("in.png", "smile", 7, "pfx")
    loras = [n for n in g.values() if n["class_type"] == "LoraLoaderModelOnly"]
    self.assertEqual(len(loras), 1); self.assertIn("Lightning", loras[0]["inputs"]["lora_name"])
    ks = _node(g, "KSampler"); self.assertEqual(ks["inputs"]["steps"], 4); self.assertEqual(ks["inputs"]["seed"], 7)
    self.assertEqual(_node(g, "SaveImage")["inputs"]["filename_prefix"], "pfx")
def test_edit_graph_negative_text(self):
    g = cc.edit_graph("in.png", "smile", 7, "pfx", negative="anime")
    encs = [n for n in g.values() if n["class_type"] == "TextEncodeQwenImageEditPlus"]
    self.assertEqual(sorted(e["inputs"]["prompt"] for e in encs), ["anime", "smile"])
```

- [ ] **Step 2: Run** `python3 -m unittest test_graphs -v` → FAIL (AttributeError edit_graph)
- [ ] **Step 3: Implement** `edit_graph` durch Kopie von `relight_graph` ohne den Relight-Loader und mit `negative`; Knoten-Ids so vergeben, dass `_node` eindeutig trifft.
- [ ] **Step 4: Run** → PASS, `test_graphs` komplett grün (bestehende Relight-Tests unverändert).
- [ ] **Step 5: Commit** `feat(comic): edit_graph — Edit-Modell ohne Relight-LoRA für Stimmungen`

### Task 3: Picks und Nachbesserungen lesen

**Files:**
- Modify: `tool/comic/cafe_ansprache.py`
- Create: `tool/comic/picks_ansprache.txt` (nur Kopfkommentar mit Format), `tool/comic/overrides_ansprache.txt` (nur Kopfkommentar)
- Test: `tool/comic/test_ansprache.py`

**Interfaces:**
- Produces:
  - `load_picks(path) -> dict[str, str]`: Zeilen `"{gast}_{fmt}_{n}=/pfad/zum/fragend_foto.png"` (Runde 1, Nummer 1–5 je Zelle), `#` und Leerzeilen überspringen, `expanduser`. Fehler (ValueError mit Zeile): Schlüssel nicht aus `{gast}_{fmt}_{n}`, Nummer doppelt in derselben Zelle, Datei fehlt. Rückgabe Schlüssel → Pfad.
  - `cells_missing(picks) -> list[str]`: Zellen `{gast}_{fmt}`, die weniger als `VARIANTS` Nummern haben.
  - `load_overrides(path) -> dict[str, dict]`: Wiederverwendung `folge01_manga.load_overrides(path, allowed={"seed", "extra", "force"})`; Schlüssel sind volle Namen `{gast}_{stimmung}_{n}_{fmt}`.

- [ ] **Step 1: Write the failing tests** (Temp-Dateien wie in `test_foto_overrides.py`, Helfer `write(text)`; eine echte leere PNG-Datei als Pick-Ziel anlegen):

```python
def test_load_picks_ok(self): self.assertEqual(ca.load_picks(self.p), {"wirtin_quer_1": self.img})
def test_load_picks_missing_file(self):
    with self.assertRaisesRegex(ValueError, "fehlt.*nix.png"): ca.load_picks(self.write("wirtin_quer_1=/tmp/nix.png"))
def test_load_picks_duplicate_number(self):
    with self.assertRaisesRegex(ValueError, "doppelt"): ca.load_picks(self.write(f"wirtin_quer_1={self.img}\nwirtin_quer_1={self.img}"))
def test_load_picks_bad_key(self):
    with self.assertRaisesRegex(ValueError, "Schlüssel"): ca.load_picks(self.write(f"wirtin_1={self.img}"))
def test_cells_missing(self): self.assertIn("wirtin_hoch", ca.cells_missing({"wirtin_quer_1": self.img}))
def test_load_overrides(self): self.assertEqual(ca.load_overrides(self.write("wirtin_zufrieden_2_quer seed=5 force")), {"wirtin_zufrieden_2_quer": {"seed": 5, "force": True}})
```

- [ ] **Step 2: Run** → FAIL
- [ ] **Step 3: Implement** die drei Funktionen; Kopfkommentare in die beiden Textdateien (Format je eine Zeile).
- [ ] **Step 4: Run** → PASS
- [ ] **Step 5: Commit** `feat(comic): Ansprache — Picks und Nachbesserungen lesen`

### Task 4: Render-Stufen Foto, Bearbeitung, Manga

**Files:**
- Modify: `tool/comic/cafe_ansprache.py`
- Test: `tool/comic/test_ansprache.py`

**Interfaces:**
- Consumes: `cc.run(graph, prefix, out_dir, client_id) -> list[Path]`, `cc.t2i_graph(prompt, negative, seed, prefix, lora_strength, width, height)`, `cc.edit_graph(...)` (Task 2), `cc.manga_graph(input_name, prompt, negative, seed, prefix, ...)`, `cc.COMFY_INPUT`, `folge01_manga.should_skip(key, out_dir, opts)`.
- Produces:
  - `ROOT = Path("~/comfy_cafe_ansprache").expanduser()`; Unterordner `foto`, `edit`, `manga`, `final`, `sheets`.
  - `render_fragend(guests: list[str], fmts: list[str], seeds: list[int], out: Path = ROOT/"foto") -> list[Path]`: je Gast/Format/Seed `cc.run(cc.t2i_graph(pos, neg, seed, prefix, LORA_STRENGTH, w, h), prefix, out)`, Prefix `"{gast}_fragend_{fmt}_s{seed}"`; vorhandene Ausgabe (glob `prefix_*`) überspringen.
  - `render_edits(picks: dict[str, str], seed: int = 21, out: Path = ROOT/"edit", overrides: dict | None = None) -> list[Path]`: je Pick und je Stimmung ∈ zufrieden/abwinkend: Quelle nach `cc.COMFY_INPUT` als `"ans_{name}.png"` kopieren, `cc.run(cc.edit_graph(input_name, edit_prompt(gast, stimmung), seed, prefix, negative=NEG), prefix, out)`, Prefix = `name_for(gast, stimmung, n, fmt)`; `overrides[name]["seed"]` überschreibt den Seed, `force` erzwingt, sonst `should_skip`.
  - `render_manga(sources: dict[str, str], out: Path = ROOT/"manga", overrides=None) -> list[Path]`: `sources` = Name → Foto-Pfad (fragend-Picks umbenannt auf `name_for(gast,"fragend",n,fmt)` plus Edit-Ausgaben); Quelle nach `COMFY_INPUT` als `"ansm_{name}.png"`, `cc.run(cc.manga_graph(input_name, *manga_prompt(gast), seed=831, prefix=name), name, out)`; Seed aus Overrides, Skip wie oben.
  - `edit_outputs(out: Path = ROOT/"edit") -> dict[str, str]`: Name → neueste Datei je Prefix.
  - `fragend_sources(picks) -> dict[str, str]`: `{gast}_{fmt}_{n}` → `name_for(gast,"fragend",n,fmt)`-Schlüssel mit Pfad.

- [ ] **Step 1: Write the failing tests** mit Fake-Run (Muster `test_hoch.py:49-69`: `cc.run = fake_run`, der eine Datei `out/prefix_00001_.png` anlegt und die Graph-Prefixe protokolliert; `cc.COMFY_INPUT` auf Temp):

```python
def test_render_fragend_prefixes_and_sizes(self):
    ca.render_fragend(["wirtin"], ["quer","hoch"], [911], out=self.out)
    self.assertEqual(self.prefixes, ["wirtin_fragend_quer_s911", "wirtin_fragend_hoch_s911"])
    self.assertEqual([(g["w"], g["h"]) for g in self.sizes], [(1664, 928), (928, 1664)])
def test_render_fragend_skips_existing(self):
    ca.render_fragend(["wirtin"], ["quer"], [911], out=self.out); ca.render_fragend(["wirtin"], ["quer"], [911], out=self.out)
    self.assertEqual(len(self.prefixes), 1)
def test_render_edits_two_moods_per_pick(self):
    ca.render_edits({"wirtin_quer_2": self.img}, out=self.out)
    self.assertEqual(self.prefixes, ["wirtin_zufrieden_2_quer", "wirtin_abwinkend_2_quer"])
    self.assertTrue((Path(cc.COMFY_INPUT) / "ans_wirtin_quer_2.png").exists())
def test_render_edits_override_seed_and_force(self):
    ca.render_edits({"wirtin_quer_2": self.img}, out=self.out)
    ca.render_edits({"wirtin_quer_2": self.img}, out=self.out, overrides={"wirtin_zufrieden_2_quer": {"seed": 5, "force": True}})
    self.assertEqual(self.prefixes[2:], ["wirtin_zufrieden_2_quer"]); self.assertEqual(self.seeds[-1], 5)
def test_render_manga_uses_manga_prompt(self):
    ca.render_manga({"wirtin_fragend_2_quer": self.img}, out=self.out)
    self.assertEqual(self.prefixes, ["wirtin_fragend_2_quer"]); self.assertTrue(self.positives[0].startswith(fm.STY))
```

(Fake sammelt aus dem Graph: Prefix des SaveImage, `width/height` des EmptyLatent, Seed des KSampler, Prompt des positiven Encoders.)

- [ ] **Step 2: Run** → FAIL
- [ ] **Step 3: Implement** die Funktionen; Logzeilen `OK <prefix>` / `ERR <prefix>: <e>` wie `cafe_library.py`, Fehler eines Renders bricht den Lauf nicht ab.
- [ ] **Step 4: Run** → PASS
- [ ] **Step 5: Commit** `feat(comic): Ansprache — Render-Stufen Foto, Bearbeitung, Manga`

### Task 5: Bögen, Gate-Stufe, CLI, Lauf-Skript, README

**Files:**
- Modify: `tool/comic/cafe_ansprache.py`, `tool/comic/README.md` (neuer Abschnitt „Café-Ansprache“ vor „Regeln und Fallen“)
- Create: `tool/comic/run_ansprache.sh`
- Test: `tool/comic/test_ansprache.py`

**Interfaces:**
- Produces:
  - `make_sheet(name: str, items: list[tuple[str, Path]], cols: int, out: Path = ROOT/"sheets") -> Path`: ruft `sheet.py` per subprocess (`[sys.executable, HERE/"sheet.py", out/f"{name}.png", str(cols), *[f"{label}={path}"]]`), wie `cafe_library.sheet`.
  - `gate(seeds=(911, 912)) -> Path`: `render_fragend(["wirtin"], ["quer","hoch"], seeds)` → Picks aus den Ausgaben (alle, Nummer = Seed-Index 1..2) → `render_edits` → `render_manga` für fragend+Edits → Bogen `gate.png` mit 3 Spalten (je Zeile: fragend, zufrieden, abwinkend; Zeilen: quer s911, quer s912, hoch s911, hoch s912) aus den **Manga**-Ausgaben; Rückgabe Bogenpfad.
  - `runde1(seeds=tuple(range(921, 929))) -> list[Path]`: `render_fragend(alle Gäste, beide Formate, 8 Seeds)` → je Zelle `{gast}_{fmt}` ein Bogen `r1_{gast}_{fmt}.png` (4 Spalten, Label `s{seed}`) aus den **Foto**-Ausgaben.
  - `runde2(picks_path, overrides_path=None) -> list[Path]`: `load_picks` → `render_edits` → `render_manga(fragend_sources ∪ edit_outputs)` → je Gast ein Bogen `r2_{gast}.png` (3 Spalten: fragend, zufrieden, abwinkend; Zeilen n=1..5 × quer/hoch) aus den Manga-Ausgaben.
  - CLI (`main(argv)`): `gate | runde1 | runde2 PICKS [OVERRIDES] | finish PICKS OUT` (finish in Task 6); am Ende `print("ANSPRACHE_DONE")`.
  - `run_ansprache.sh <stufe> [args]`: wartet auf `localhost:8188/system_stats` wie `run_finish.sh`, dann `python3 cafe_ansprache.py "$@"`.

- [ ] **Step 1: Write the failing tests** (Fake-Run wie Task 4; `make_sheet` durch Fake ersetzen, der die Items protokolliert):

```python
def test_gate_sheet_rows(self):
    ca.gate(seeds=(1, 2))
    labels = [l for l, _ in self.sheet_items["gate"]]
    self.assertEqual(len(labels), 12); self.assertEqual(labels[:3], ["quer s1 fragend", "quer s1 zufrieden", "quer s1 abwinkend"])
def test_runde1_sheets_per_cell(self):
    ca.runde1(seeds=(1, 2, 3))
    self.assertEqual(sorted(self.sheet_items), sorted(f"r1_{g}_{f}" for g in ca.GUESTS for f in ca.FORMATS))
    self.assertEqual(len(self.sheet_items["r1_wirtin_quer"]), 3)
def test_runde2_sheet_per_guest(self):
    ca.runde2(self.picks_two_guests)
    self.assertEqual(sorted(self.sheet_items), ["r2_schulkind", "r2_wirtin"]); self.assertEqual(len(self.sheet_items["r2_wirtin"]), 30)
def test_cli_unknown_stage(self):
    with self.assertRaises(SystemExit): ca.main(["nix"])
```

- [ ] **Step 2: Run** → FAIL
- [ ] **Step 3: Implement** Bögen, Stufen, CLI; `run_ansprache.sh` (ausführbar); README-Abschnitt: Rezept (Modelle, Größen, Seeds 911/912 Gate, 921–928 Runde 1, Edit-Seed 21, Manga-Seed 831), die drei Stufen, Picks-/Overrides-Format, Lauf-Befehle, Marke `ANSPRACHE_DONE`.
- [ ] **Step 4: Run** → PASS; `bash -n run_ansprache.sh` ohne Fehler.
- [ ] **Step 5: Commit** `feat(comic): Ansprache — Gate, Runde 1, Runde 2, Bögen, Lauf-Skript, README`

### Task 6: Finish, Ablage, Dart-Tabelle

**Files:**
- Modify: `tool/comic/cafe_ansprache.py`, `pubspec.yaml` (Asset-Eintrag `- assets/comic/cafe/ansprache/` nach Z. 75)
- Create: `tool/comic/gen_portraits_dart.py`, `lib/features/cafe/cafe_portrait_library.g.dart` (zunächst leere Tabelle), `assets/comic/cafe/ansprache/.gitkeep`
- Test: `tool/comic/test_ansprache.py`, `tool/comic/test_gen_portraits.py`

**Interfaces:**
- Consumes: `cc.upscale_graph(input_name, prefix, width, height)`, `cc.run`, `TARGET`.
- Produces:
  - `final_picks(manga_dir: Path = ROOT/"manga") -> dict[str, Path]`: alle 120 Namen → neueste Manga-Datei; ValueError mit Liste der fehlenden Namen, wenn einer fehlt (Aufruf mit `allow_missing=True` liefert die vorhandenen).
  - `finish(sources: dict[str, Path], out: Path = ROOT/"final") -> list[Path]`: je Name Quelle nach `COMFY_INPUT` als `"ansf_{name}.png"`, `cc.run(cc.upscale_graph(input_name, "fin_"+name, w, h), ...)`, Ergebnis öffnen, `assert im.size == TARGET[fmt]` (AssertionError nennt Name und Größe), JPEG `out/{name}.jpg` q88 optimize; `up_to_date` wie `folge01_finish` überspringt vorhandene.
  - `gen_portraits_dart.py main(asset_dir="assets/comic/cafe/ansprache", out="lib/features/cafe/cafe_portrait_library.g.dart") -> str`: liest die `*.jpg`, prüft jeden Namen gegen `name_for` (unbekannter Name → SystemExit mit Dateiname), schreibt:

    ```dart
    // GENERIERT von tool/comic/gen_portraits_dart.py — nicht von Hand ändern.
    /// Vorhandene Ansprache-Bilder: '{gast}_{stimmung}' → Format → Nummern.
    const Map<String, Map<String, List<int>>> cafePortraitFiles = {
      'wirtin_fragend': {'quer': [1, 2, 3, 4, 5], 'hoch': [1, 2, 3, 4, 5]},
    };
    ```
    Schlüssel alphabetisch, Nummern aufsteigend, leerer Ordner → `= {};`. (Plan A3 liest genau diese Konstante; er legt dieselbe Datei mit leerer Tabelle an, falls sie fehlt. Wer zuerst kommt, gewinnt, der Inhalt ist gleich.)

- [ ] **Step 1: Write the failing tests** (Fake-Run liefert ein PNG in Zielgröße; ein zweiter Fake in falscher Größe):

```python
def test_finish_names_and_quality(self):
    paths = ca.finish({"wirtin_fragend_1_hoch": self.src}, out=self.out)
    self.assertEqual(paths[0].name, "wirtin_fragend_1_hoch.jpg"); self.assertEqual(Image.open(paths[0]).size, (1080, 1936))
def test_finish_wrong_size_raises(self):
    cc.run = self.fake_run_wrong_size
    with self.assertRaisesRegex(AssertionError, "wirtin_fragend_1_hoch.*1080"): ca.finish({"wirtin_fragend_1_hoch": self.src}, out=self.out)
def test_final_picks_missing_lists_names(self):
    with self.assertRaisesRegex(ValueError, "schulkind_abwinkend_5_hoch"): ca.final_picks(self.manga_dir_with_one_file)
# test_gen_portraits.py
def test_gen_from_dir(self):
    touch("wirtin_fragend_1_quer.jpg", "wirtin_fragend_2_quer.jpg", "wirtin_fragend_1_hoch.jpg")
    src = gp.main(self.dir, self.out)
    self.assertIn("'wirtin_fragend': {'hoch': [1], 'quer': [1, 2]}", src)
def test_gen_empty_dir(self): self.assertIn("cafePortraitFiles = {};", gp.main(self.empty, self.out))
def test_gen_rejects_bad_name(self):
    touch("wirtin_froh_1_quer.jpg")
    with self.assertRaises(SystemExit): gp.main(self.dir, self.out)
```

- [ ] **Step 2: Run** → FAIL
- [ ] **Step 3: Implement** `final_picks`, `finish`, CLI-Zweig `finish PICKS OUT` (PICKS = Manga-Ordner), `gen_portraits_dart.py`; `.g.dart` mit leerer Tabelle erzeugen (`python3 tool/comic/gen_portraits_dart.py`); pubspec-Eintrag.
- [ ] **Step 4: Run** → PASS; `flutter analyze --no-pub` ohne neue Fehler (die `.g.dart` wird noch von niemandem importiert).
- [ ] **Step 5: Commit** `feat(comic): Ansprache — Finish auf Auslieferungsgröße, Dart-Tabelle, Asset-Ordner`

### Task 7: Gate auf der Box (Ulis Entscheidung)

**Files:** keine Code-Änderung; Ausgaben `~/cafe-ansprache-gate.png` auf dem NUC.

- [ ] **Step 1:** Box wecken und sichern: `wakegpu`; `ssh pc 'touch ~/.no-idle-suspend; curl -s -m 3 localhost:8188/system_stats | head -c 60'` → JSON erscheint.
- [ ] **Step 2:** Skripte hinlegen: `scp tool/comic/*.py tool/comic/*.sh tool/comic/*.txt pc:f01tool/`.
- [ ] **Step 3:** Starten: `ssh pc 'cd ~/f01tool && setsid nohup bash run_ansprache.sh gate > ansprache_gate.log 2>&1 </dev/null &'`.
- [ ] **Step 4:** Warten (Monitor/Until-Schleife auf `ANSPRACHE_DONE` in `pc:f01tool/ansprache_gate.log`, Fehlerzeilen `ERR` zählen; Erwartung 4 Fotos + 8 Edits + 12 Manga ≈ 40 Minuten). Bricht ein Render mit `AcceleratorError` ab: README „Regeln und Fallen“ (Verklemmer nach Resume) anwenden, Stufe neu starten (vorhandene Ausgaben werden übersprungen).
- [ ] **Step 5:** Bogen holen: `scp pc:comfy_cafe_ansprache/sheets/gate.png ~/cafe-ansprache-gate.png`; `ssh pc 'rm -f ~/.no-idle-suspend'`.
- [ ] **Step 6:** Uli den Bogen zeigen (Pfad nennen, Lesebefehl). **Stopp bis Uli entscheidet:** Blick, Nähe, Stil, Bearbeitungsweg ja/nein. Bei Nein: Prompts/Edit-Anweisungen in Task 1 anpassen (neuer Commit), Gate wiederholen. Fällt der Edit-Weg durch (Gesicht verfremdet): Spec §10 Ausweich — zufrieden/abwinkend als eigene T2I-Erzeugungen; dann `render_edits` auf `t2i_graph` mit Stimmungs-Note umstellen (neuer Task, vor Runde 2).

### Task 8: Runde 1 — fragend (Ulis Streichungen)

- [ ] **Step 1:** Box sichern wie Task 7 Schritt 1–2; Start `run_ansprache.sh runde1` (64 Fotos ≈ 1 Stunde); warten auf `ANSPRACHE_DONE`.
- [ ] **Step 2:** Bögen holen: `scp 'pc:comfy_cafe_ansprache/sheets/r1_*.png' ~/cafe-ansprache-r1/`; Kill-Schalter entfernen.
- [ ] **Step 3:** Uli streicht je Zelle auf fünf. **Stopp bis Ulis Antwort** (Form: je Zelle die Seeds, die bleiben, oder die, die weg sollen).
- [ ] **Step 4:** `picks_ansprache.txt` schreiben: je Zelle fünf Zeilen `{gast}_{fmt}_{n}=/home/uli/comfy_cafe_ansprache/foto/{gast}_fragend_{fmt}_s{seed}_…png`, Nummern 1–5 in Ulis Reihenfolge. Bleiben in einer Zelle weniger als fünf: `render_fragend` für diese Zelle mit Seeds 931+ nachrendern (CLI `runde1` nimmt `--seeds 931,932`; Ergänzung in `main`, Test: Seeds werden durchgereicht), Bogen, erneut streichen.
- [ ] **Step 5:** Prüfen: `python3 -c "import cafe_ansprache as ca; print(ca.cells_missing(ca.load_picks('picks_ansprache.txt')))"` → `[]` (auf der Box ausführen, Pfade liegen dort).
- [ ] **Step 6:** Commit `data(comic): Ansprache — Picks Runde 1 (40 fragend-Fotos)`

### Task 9: Runde 2 — Stimmungen, Finish, Ablage

- [ ] **Step 1:** Box sichern; `scp picks_ansprache.txt pc:f01tool/`; Start `run_ansprache.sh runde2 picks_ansprache.txt` (80 Edits ≈ 15 Minuten, 120 Manga ≈ 4 Stunden); warten auf `ANSPRACHE_DONE`.
- [ ] **Step 2:** Bögen holen (`r2_*.png` nach `~/cafe-ansprache-r2/`), Kill-Schalter entfernen. Uli streicht einzelne Bilder. **Stopp bis Ulis Antwort.**
- [ ] **Step 3:** Gestrichene in `overrides_ansprache.txt` eintragen (`{name} seed=22 force`, bei fragend-Bildern stattdessen in Runde-1-Logik: anderer Pick), `runde2 picks_ansprache.txt overrides_ansprache.txt` erneut (nur die Zellen mit `force` werden gerendert), Bogen, bis Uli nichts mehr streicht.
- [ ] **Step 4:** Finish auf der Box: `run_ansprache.sh finish ~/comfy_cafe_ansprache/manga ~/comfy_cafe_ansprache/final` (120 Vergrößerungen ≈ 1 Stunde); Erwartung Log `OK` × 120, `ANSPRACHE_DONE`.
- [ ] **Step 5:** Holen und ablegen: `scp 'pc:comfy_cafe_ansprache/final/*.jpg' assets/comic/cafe/ansprache/`; `ls assets/comic/cafe/ansprache | wc -l` → 120; Gesamtgröße notieren (Spec §10: über 200 MB Build → q82).
- [ ] **Step 6:** `python3 tool/comic/gen_portraits_dart.py` → `.g.dart` mit 12 Schlüsseln × 2 Formaten × `[1, 2, 3, 4, 5]`; `flutter analyze --no-pub`; Vollsuite `flutter test --no-pub` (Erwartung: wie Stapelspitze, nur die 8 bekannten Tokenizer-Fehler; läuft Plan A3 schon, auch dessen Strukturtest grün).
- [ ] **Step 7:** Commit `data(comic): Ansprache — 120 Bilder, Dart-Tabelle, Picks und Nachbesserungen`; Kill-Schalter weg; Draft-PR auf den Stapel (Basis: der Branch, auf dem dieser Plan ausgeführt wird), Bogen-Pfade im PR-Text.
