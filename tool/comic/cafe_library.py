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
