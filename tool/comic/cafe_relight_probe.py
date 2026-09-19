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
