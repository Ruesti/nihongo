#!/usr/bin/env python3
"""Vorschau „Kern schützen, Rand beschneiden" (Spec §12.3): je Motiv das Querbild mit Kern (rot) und
Fenster bzw. Streifen (gelb), daneben das geplante Hochbild (Beschnitt oder Streifen in der Leinwand,
erfundener Rand grau). Aufruf im Repo-Wurzelverzeichnis:
  python3 tool/comic/kern_preview.py [build/f01_raw] [build/kern_preview.png]"""
import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kern_geometry as kg  # noqa: E402

MOTIFS = ["p%02d" % i for i in range(1, 11)] + ["titel"]
TH, PAD, LBL = 300, 10, 24


def planned_hoch(im, plan):
    """Hochbild, wie es das Hoch-Skript bauen wird; erfundener Rand als Grau."""
    W, H = im.size
    sx = W / kg.QUER[0]                      # Plan ist im Render-Maß, Bild evtl. größer (Auslieferung)
    part = im.crop((int(plan["x0"] * sx), 0, int(plan["x1"] * sx), H))
    if plan["mode"] == "crop":
        return part.resize(kg.HOCH, Image.LANCZOS)
    canvas = Image.new("RGB", kg.HOCH, (110, 110, 110))
    canvas.paste(part.resize((kg.HOCH[0], plan["strip_h"]), Image.LANCZOS), (0, plan["top"]))
    return canvas


def main(raw_dir="build/f01_raw", out="build/kern_preview.png", layout_path="tool/comic/folge01_layout.json"):
    with open(layout_path, encoding="utf-8") as f:
        kern = json.load(f)["kern"]
    cols = 2
    cell_w = round(TH * kg.QUER[0] / kg.QUER[1]) + PAD + round(TH * kg.HOCH[0] / kg.HOCH[1])
    rows = (len(MOTIFS) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (cell_w + PAD) + PAD, rows * (TH + LBL + PAD) + PAD), (24, 24, 24))
    d = ImageDraw.Draw(sheet)
    for i, m in enumerate(MOTIFS):
        with Image.open(os.path.join(raw_dir, m + "_quer.jpg")) as src:
            im = src.convert("RGB")
        W, H = im.size
        plan = kg.plan_for(kern[m])
        sx = W / kg.QUER[0]
        marked = im.copy()
        md = ImageDraw.Draw(marked)
        md.rectangle([kern[m][0] * W, 0, kern[m][1] * W, H - 1], outline=(255, 60, 60), width=6)
        md.rectangle([plan["x0"] * sx, 0, plan["x1"] * sx, H - 1], outline=(255, 220, 60), width=4)
        hoch = planned_hoch(im, plan)
        x = PAD + (i % cols) * (cell_w + PAD)
        y = PAD + (i // cols) * (TH + LBL + PAD)
        qt = marked.resize((round(TH * W / H), TH))
        sheet.paste(qt, (x, y + LBL))
        sheet.paste(hoch.resize((round(TH * kg.HOCH[0] / kg.HOCH[1]), TH)), (x + qt.width + PAD, y + LBL))
        label = "%s  kern=%s  %s" % (m, kern[m], "Beschnitt" if plan["mode"] == "crop"
                                      else "Verlängern: unten %d, oben %s" % (plan["bottom"], plan["top_steps"]))
        d.text((x + 4, y + 5), label, fill=(235, 235, 235))
    sheet.save(out)
    print(out, sheet.size)
    return out


if __name__ == "__main__":
    main(*sys.argv[1:])
