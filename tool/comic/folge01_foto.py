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
