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
    with open(os.path.expanduser(path), encoding="utf-8") as f:
        for line in f:
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
