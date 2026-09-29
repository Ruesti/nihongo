#!/usr/bin/env python3
"""Kontaktbögen aus den GELETTERTEN Auslieferungsbildern (assets/story/folge01/).
Schreibt build/letter_preview_quer.png (4 Spalten) und build/letter_preview_hoch.png (5 Spalten).
Mit Argument 'faces' zusätzlich Gesichter (rot) + sichere Zone (gelb) aus der Layout-Datei ->
build/letter_preview_{quer,hoch}_faces.png. Aufruf im Repo-Wurzelverzeichnis:
  python3 tool/comic/letter_preview.py [faces]"""
import json
import sys

from PIL import Image, ImageDraw, ImageFont

DST = "assets/story/folge01"
WIDTH = 600
FACES = "faces" in sys.argv[1:]

with open("tool/comic/folge01_layout.json", encoding="utf-8") as f:
    layout = json.load(f)
label_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)


def tile(pid, fmt):
    name = pid + ("_hoch" if fmt == "hoch" else "") + ".jpg"
    img = Image.open("%s/%s" % (DST, name)).convert("RGB")
    W, H = img.size
    if FACES:
        d = ImageDraw.Draw(img)
        for x, y, w, h in layout["panels"][pid][fmt]["faces"]:
            d.rectangle((x * W, y * H, (x + w) * W, (y + h) * H), outline=(255, 0, 0), width=5)
        for v in (0.1, 0.9):
            if fmt == "quer":
                d.line((0, v * H, W, v * H), fill=(255, 220, 0), width=3)
            else:
                d.line((v * W, 0, v * W, H), fill=(255, 220, 0), width=3)
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


suffix = "_faces" if FACES else ""
sheet("quer", 4, "build/letter_preview_quer%s.png" % suffix)
sheet("hoch", 5, "build/letter_preview_hoch%s.png" % suffix)
