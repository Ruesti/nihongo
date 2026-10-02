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
                                       feather=FEATHER_OBEN), prefix, TMP, "f01hoch")
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
        if opts.get("force") and os.path.exists(out_path):
            os.remove(out_path)   # sonst bliebe nach force + ERR ein veraltetes Bild stehen, das finish stillschweigend nimmt
        plan = kg.plan_for(kerne[m])
        try:
            with Image.open(src) as raw:
                if raw.size != kg.QUER:
                    raise ValueError("%s: Quelle ist %s, erwartet %s (Render-Maß)" % (m, raw.size, kg.QUER))
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
