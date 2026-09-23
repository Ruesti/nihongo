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
