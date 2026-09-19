#!/usr/bin/env python3
"""Kontaktbogen: sheet.py OUT.png COLS label=path [label=path ...]"""
import sys
from PIL import Image, ImageDraw

out, cols, items = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
W, H, PAD, LBL = 608, 416, 8, 28
rows = (len(items) + cols - 1) // cols
sheet = Image.new("RGB", (cols * (W + PAD) + PAD, rows * (H + LBL + PAD) + PAD), (24, 24, 24))
draw = ImageDraw.Draw(sheet)
for i, item in enumerate(items):
    label, path = item.split("=", 1)
    x = PAD + (i % cols) * (W + PAD)
    y = PAD + (i // cols) * (H + LBL + PAD)
    im = Image.open(path).convert("RGB")
    im.thumbnail((W, H))
    sheet.paste(im, (x, y + LBL))
    draw.text((x + 4, y + 6), label, fill=(230, 230, 230))
sheet.save(out)
print(out)
