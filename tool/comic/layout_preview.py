#!/usr/bin/env python3
"""Sichtbeweis Layout-Datei: Gesichter rot, Blasen weiss mit Text, sichere Zone gelb gestrichelt.
Schreibt build/layout_preview_quer.png (4 Spalten) und build/layout_preview_hoch.png (5 Spalten).
Quelle: Foto-Picks (tool/comic/picks_foto.txt) aus build/f01_foto. Aufruf im Repo-Wurzelverzeichnis:
  python3 tool/comic/layout_preview.py"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, "tool/comic")
import letter_folge01  # noqa: E402

FONT = "/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf"
WIDTH = 600

with open("tool/comic/folge01_layout.json", encoding="utf-8") as f:
    layout = json.load(f)
picks = {}
with open("tool/comic/picks_foto.txt", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith("#"):
            k, v = line.split("=", 1)
            picks[k] = "build/f01_foto/" + os.path.basename(v)

label_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)


def tile(pid, fmt):
    spec = layout["panels"][pid][fmt]
    img = Image.open(picks["%s_%s" % (pid, fmt)]).convert("RGB")
    img = letter_folge01.letter(img, spec["bubbles"])  # echtes Blasen-Lettering
    W, H = img.size
    d = ImageDraw.Draw(img)
    for x, y, w, h in spec["faces"]:
        d.rectangle((x * W, y * H, (x + w) * W, (y + h) * H), outline=(255, 0, 0), width=5)
    lo, hi = 0.1, 0.9
    if fmt == "quer":
        for yy in (lo, hi):
            d.line((0, yy * H, W, yy * H), fill=(255, 220, 0), width=3)
    else:
        for xx in (lo, hi):
            d.line((xx * W, 0, xx * W, H), fill=(255, 220, 0), width=3)
    img = img.resize((WIDTH, int(H * WIDTH / W)), Image.LANCZOS)
    ImageDraw.Draw(img).text((8, 6), "%s %s" % (pid, fmt), fill=(255, 0, 255), font=label_font,
                             stroke_width=2, stroke_fill="black")
    return img


def sheet(fmt, cols, out):
    tiles = [tile("p%02d" % n, fmt) for n in range(1, 11)]
    tw, th = tiles[0].size
    rows = -(-len(tiles) // cols)
    gap = 8
    s = Image.new("RGB", (cols * tw + (cols + 1) * gap, rows * th + (rows + 1) * gap), (40, 40, 40))
    for i, t in enumerate(tiles):
        s.paste(t, (gap + (i % cols) * (tw + gap), gap + (i // cols) * (th + gap)))
    s.save(out)
    print(out, s.size)


sheet("quer", 4, "build/layout_preview_quer.png")
sheet("hoch", 5, "build/layout_preview_hoch.png")
