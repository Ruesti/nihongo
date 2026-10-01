#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_hoch (ohne Box: cc.run wird ersetzt)"""
import json
import os
import tempfile
import unittest

from PIL import Image, ImageDraw

import comfy_client as cc
import folge01_hoch as fh
import kern_geometry as kg

MOTIFS = ["p%02d" % i for i in range(1, 11)] + ["titel"]


def gradient(w, h):
    """Billiges Testbild mit Struktur (keine Pixelschleifen): farbige Kacheln."""
    im = Image.new("RGB", (w, h), (30, 30, 30))
    d = ImageDraw.Draw(im)
    s = 48
    for j in range(0, h, s):
        for i in range(0, w, s):
            k = (i // s + j // s) % 5
            d.rectangle([i, j, i + s - 1, j + s - 1], fill=(50 * k, 255 - 40 * k, (90 * k) % 256))
    return im


class Base(unittest.TestCase):
    def setUp(self):
        self.d = tempfile.mkdtemp()
        self.quer = {}
        for m in MOTIFS:
            p = os.path.join(self.d, "%s_quer_%s_quer_00001_.png" % (m, m))
            gradient(1664, 928).save(p)
            self.quer[m] = p
        self.picks = os.path.join(self.d, "picks_manga.txt")
        with open(self.picks, "w", encoding="utf-8") as f:
            for m in MOTIFS:
                f.write("%s_quer=%s\n" % (m, self.quer[m]))
                f.write("%s_hoch=%s/alt_%s_hoch.png\n" % (m, self.d, m))   # alte Hoch-Zeilen, Dateien fehlen
        self.layout = os.path.join(self.d, "layout.json")
        kern = {m: [0.4, 0.6] for m in MOTIFS}
        kern["p05"] = [0.13, 0.95]
        with open(self.layout, "w", encoding="utf-8") as f:
            json.dump({"kern": kern, "panels": {}}, f)
        self._saved = (fh.OUT, fh.TMP, fh.LAYOUT, fh.PICKS_OUT, cc.COMFY_INPUT, cc.run)
        fh.OUT, fh.TMP = os.path.join(self.d, "hoch"), os.path.join(self.d, "hoch_tmp")
        fh.LAYOUT, fh.PICKS_OUT = self.layout, os.path.join(self.d, "picks_hoch.txt")
        cc.COMFY_INPUT = os.path.join(self.d, "input")
        os.makedirs(cc.COMFY_INPUT)
        self.calls = []

        def fake_run(graph, prefix, out_dir, client_id="x"):
            pad = [v for v in graph.values() if v["class_type"] == "ImagePadForOutpaint"][0]["inputs"]
            with Image.open(os.path.join(cc.COMFY_INPUT, graph["IN"]["inputs"]["image"])) as im:
                w, h = im.size
            os.makedirs(out_dir, exist_ok=True)
            dest = os.path.join(out_dir, "%s_%s_00001_.png" % (prefix, prefix))
            Image.new("RGB", (w, h + pad["top"] + pad["bottom"]), (60, 60, 60)).save(dest)
            self.calls.append((prefix, pad["top"], pad["bottom"], graph["4"]["inputs"]["text"],
                               graph["5"]["inputs"]["text"]))
            return [dest]
        cc.run = fake_run

    def tearDown(self):
        fh.OUT, fh.TMP, fh.LAYOUT, fh.PICKS_OUT, cc.COMFY_INPUT, cc.run = self._saved


class ReadPicks(Base):
    def test_read_quer_picks_ignores_hoch_lines(self):
        picks = fh.read_quer_picks(self.picks)
        self.assertEqual(sorted(picks), sorted(m + "_quer" for m in MOTIFS))

    def test_read_quer_picks_checks_quer_files(self):
        with open(self.picks, "a", encoding="utf-8") as f:
            f.write("p99_quer=%s/nix.png\n" % self.d)
        with self.assertRaises(FileNotFoundError) as cm:
            fh.read_quer_picks(self.picks)
        self.assertIn("FEHLT p99_quer", str(cm.exception))

    def test_load_kerne_requires_all_motifs(self):
        self.assertEqual(sorted(fh.load_kerne(self.layout)), sorted(MOTIFS))
        with open(self.layout, "w", encoding="utf-8") as f:
            json.dump({"kern": {"p01": [0.1, 0.5]}}, f)
        with self.assertRaises(ValueError) as cm:
            fh.load_kerne(self.layout)
        self.assertIn("titel", str(cm.exception))


class Strip(Base):
    def test_strip_crop_keeps_native_resolution(self):
        plan = kg.plan_for([0.4, 0.6])
        s = fh.strip_image(gradient(1664, 928), plan)
        self.assertEqual(s.size, (518, 928))

    def test_strip_extend_is_928_wide_multiple_of_16(self):
        plan = kg.plan_for([0.13, 0.95])
        s = fh.strip_image(gradient(1664, 928), plan)
        self.assertEqual(s.size, (928, plan["strip_h"]))
        self.assertEqual(s.height % 16, 0)


class Main(Base):
    def test_crop_only_motifs_need_no_box_and_picks_file_is_complete(self):
        with open(self.layout, "w", encoding="utf-8") as f:
            json.dump({"kern": {m: [0.4, 0.6] for m in MOTIFS}, "panels": {}}, f)
        out = fh.main(self.picks)
        self.assertEqual(self.calls, [])
        with open(out, encoding="utf-8") as f:
            lines = [l for l in f.read().splitlines() if l and not l.startswith("#")]
        self.assertEqual(len(lines), 22)
        self.assertIn("p05_hoch=%s" % os.path.join(fh.OUT, "p05_hoch.png"), lines)
        self.assertIn("p05_quer=%s" % self.quer["p05"], lines)
        for m in MOTIFS:
            with Image.open(os.path.join(fh.OUT, m + "_hoch.png")) as im:
                self.assertEqual(im.size, (518, 928))

    def test_extend_runs_bottom_then_top_steps_and_writes_final(self):
        fh.main(self.picks)
        plan = kg.plan_for([0.13, 0.95])
        prefixes = [c[0] for c in self.calls]
        self.assertEqual(prefixes[0], "p05_hochB")
        self.assertEqual(self.calls[0][1:3], (0, plan["bottom"]))
        self.assertIn("legs and feet", self.calls[0][3])
        self.assertIn("duplicate person", self.calls[0][4])
        self.assertNotIn("human figure", self.calls[0][4])
        tops = [c[1] for c in self.calls[1:]]
        self.assertEqual(tops, plan["top_steps"])
        self.assertEqual(prefixes[-1], "p05_hoch")
        for c in self.calls[1:]:
            self.assertIn("empty background only", c[3])
            self.assertIn("human figure", c[4])
        with Image.open(os.path.join(fh.OUT, "p05_hoch.png")) as im:
            self.assertEqual(im.size, (928, 1664))

    def test_main_skips_existing_unless_force(self):
        fh.main(self.picks)
        n = len(self.calls)
        fh.main(self.picks)
        self.assertEqual(len(self.calls), n)                  # SKIP: nichts neu gerendert
        ov = os.path.join(self.d, "ov.txt")
        with open(ov, "w", encoding="utf-8") as f:
            f.write("p05_hoch seed=777 force\n")
        fh.main(self.picks, ov)
        self.assertGreater(len(self.calls), n)
        with open(ov, "w", encoding="utf-8") as f:
            f.write("p05_hoch control=canny\n")
        with self.assertRaises(ValueError):
            fh.main(self.picks, ov)                           # nur seed/force erlaubt


if __name__ == "__main__":
    unittest.main()
