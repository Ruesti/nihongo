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
    tw, th = 1216, 832
    print(name, im.size)
    if im.size != (tw, th):
        w, h = im.size
        if abs(w / h - tw / th) > 0.001:
            if w / h > tw / th:
                nw = int(round(h * tw / th))
                im = im.crop(((w - nw) // 2, 0, (w + nw) // 2, h))
            else:
                nh = int(round(w * th / tw))
                im = im.crop((0, (h - nh) // 2, w, (h + nh) // 2))
        im = im.resize((tw, th), Image.LANCZOS)
    dest = os.path.join(out_dir, name + ".jpg")
    im.save(dest, "JPEG", quality=88, optimize=True)
    n += 1
    print(dest, os.path.getsize(dest) // 1024, "KB")
print("ASSEMBLED", n)
