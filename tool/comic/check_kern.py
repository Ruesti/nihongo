#!/usr/bin/env python3
"""INV-17 (Spec §12.5): der Kern des Hochbilds ist (bis auf Skalierung) der Kern des Querbilds.
Aufruf im Repo-Wurzelverzeichnis: python3 tool/comic/check_kern.py [build/f01_raw]
Je Motiv werden die Kern-Regionen beider Auslieferungsbilder ausgeschnitten, auf dieselbe Größe
gebracht und als Graustufen verglichen (mittlere Abweichung 0..255). Die Überblendzonen am oberen und
unteren Rand der Region (MARGIN) bleiben außen vor. Ausgabe `<motiv> <diff>`, Exit 1 über LIMIT."""
import json
import os
import sys

from PIL import Image, ImageChops, ImageStat

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kern_geometry as kg  # noqa: E402

MOTIFS = ["p%02d" % i for i in range(1, 11)] + ["titel"]
LIMIT = 10.0
MARGIN = 0.06
SIZE = (128, 256)


def kern_regions(plan):
    """Normierte Boxen (x0, y0, x1, y1) der Kern-Region im Quer- und im Hochbild."""
    quer = (plan["x0"] / kg.QUER[0], 0.0, plan["x1"] / kg.QUER[0], 1.0)
    if plan["mode"] == "crop":
        hoch = (0.0, 0.0, 1.0, 1.0)
    else:
        hoch = (0.0, plan["top"] / kg.HOCH[1], 1.0, (plan["top"] + plan["strip_h"]) / kg.HOCH[1])
    return quer, hoch


def _region(im, box):
    W, H = im.size
    x0, y0, x1, y1 = box
    dy = (y1 - y0) * MARGIN
    return im.crop((round(x0 * W), round((y0 + dy) * H), round(x1 * W), round((y1 - dy) * H)))


def diff(quer_img, hoch_img, plan):
    q, h = kern_regions(plan)
    a = _region(quer_img, q).convert("L").resize(SIZE, Image.LANCZOS)
    b = _region(hoch_img, h).convert("L").resize(SIZE, Image.LANCZOS)
    return ImageStat.Stat(ImageChops.difference(a, b)).mean[0]


def main(raw_dir="build/f01_raw", layout_path="tool/comic/folge01_layout.json"):
    with open(layout_path, encoding="utf-8") as f:
        kern = json.load(f)["kern"]
    bad = []
    for m in MOTIFS:
        plan = kg.plan_for(kern[m])
        with Image.open(os.path.join(raw_dir, m + "_quer.jpg")) as q, \
                Image.open(os.path.join(raw_dir, m + "_hoch.jpg")) as h:
            d = diff(q.convert("RGB"), h.convert("RGB"), plan)
        print("%s %.1f" % (m, d))
        if d > LIMIT:
            bad.append(m)
    if bad:
        print("KERN WEICHT AB: " + ", ".join(bad))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(*sys.argv[1:]))
