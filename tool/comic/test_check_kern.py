#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_check_kern"""
import json
import os
import tempfile
import unittest

from PIL import Image, ImageDraw

import check_kern as ck
import kern_geometry as kg


def pattern(w, h, shift=0):
    """Farbige Kacheln (48 px); `shift` verschiebt die Farbfolge → deutlich anderes Bild."""
    im = Image.new("RGB", (w, h), (30, 30, 30))
    d = ImageDraw.Draw(im)
    s = 48
    for j in range(0, h, s):
        for i in range(0, w, s):
            k = (i // s + j // s + shift) % 5
            d.rectangle([i, j, i + s - 1, j + s - 1], fill=(50 * k, 255 - 40 * k, (90 * k) % 256))
    return im


def hoch_from(quer, plan):
    W, H = quer.size
    sx = W / kg.QUER[0]
    part = quer.crop((int(plan["x0"] * sx), 0, int(plan["x1"] * sx), H))
    if plan["mode"] == "crop":
        return part.resize((1080, 1936), Image.LANCZOS)
    canvas = Image.new("RGB", (1080, 1936), (120, 120, 120))
    sh = round(plan["strip_h"] * 1936 / 1664)
    canvas.paste(part.resize((1080, sh), Image.LANCZOS), (0, round(plan["top"] * 1936 / 1664)))
    return canvas


class Diff(unittest.TestCase):
    def test_identical_kern_is_below_limit_crop_and_extend(self):
        quer = pattern(1920, 1072)
        for kern in ([0.4, 0.6], [0.13, 0.95]):
            plan = kg.plan_for(kern)
            self.assertLess(ck.diff(quer, hoch_from(quer, plan), plan), ck.LIMIT, kern)

    def test_shifted_kern_is_above_limit(self):
        quer = pattern(1920, 1072)
        plan = kg.plan_for([0.4, 0.6])
        wrong = hoch_from(pattern(1920, 1072, shift=2), plan)
        self.assertGreater(ck.diff(quer, wrong, plan), ck.LIMIT)

    def test_main_reports_and_exits(self):
        d = tempfile.mkdtemp()
        quer = pattern(1920, 1072)
        motifs = ["p%02d" % i for i in range(1, 11)] + ["titel"]
        kern = {m: [0.4, 0.6] for m in motifs}
        kern["p07"] = [0.1, 0.93]
        for m in motifs:
            quer.save(os.path.join(d, m + "_quer.jpg"), quality=95)
            src = quer if m != "p03" else pattern(1920, 1072, shift=2)
            hoch_from(src, kg.plan_for(kern[m])).save(os.path.join(d, m + "_hoch.jpg"), quality=95)
        layout = os.path.join(d, "layout.json")
        with open(layout, "w", encoding="utf-8") as f:
            json.dump({"kern": kern}, f)
        self.assertEqual(ck.main(d, layout), 1)       # p03 weicht ab
        pattern(1920, 1072).save(os.path.join(d, "p03_quer.jpg"), quality=95)
        hoch_from(pattern(1920, 1072), kg.plan_for(kern["p03"])).save(os.path.join(d, "p03_hoch.jpg"), quality=95)
        self.assertEqual(ck.main(d, layout), 0)


if __name__ == "__main__":
    unittest.main()
