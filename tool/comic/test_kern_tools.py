#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_kern_tools"""
import json
import os
import tempfile
import unittest

from PIL import Image

import kern_faces
import kern_preview

HERE = os.path.dirname(os.path.abspath(__file__))
MOTIFS = ["p%02d" % i for i in range(1, 11)] + ["titel"]


class LayoutKern(unittest.TestCase):
    def test_layout_has_kern_for_all_motifs(self):
        with open(os.path.join(HERE, "folge01_layout.json"), encoding="utf-8") as f:
            layout = json.load(f)
        self.assertEqual(sorted(layout["kern"]), sorted(MOTIFS))
        for k, (x0, x1) in layout["kern"].items():
            self.assertTrue(0 <= x0 < x1 <= 1, (k, x0, x1))


class Faces(unittest.TestCase):
    def test_derive_maps_quer_faces_per_panel(self):
        layout = {"kern": {"p01": [0.36, 0.64]},
                  "panels": {"p01": {"quer": {"faces": [[0.43, 0.29, 0.12, 0.19]]}, "hoch": {"faces": []}}}}
        out = kern_faces.derive(layout)
        self.assertEqual(list(out), ["p01"])
        self.assertEqual(len(out["p01"]), 1)
        self.assertAlmostEqual(out["p01"][0][1], 0.29, places=4)


class Preview(unittest.TestCase):
    def test_sheet_written_with_all_motifs(self):
        d = tempfile.mkdtemp()
        for m in MOTIFS:
            Image.new("RGB", (192, 107), (90, 120, 90)).save(os.path.join(d, m + "_quer.jpg"))
        layout_path = os.path.join(d, "layout.json")
        with open(layout_path, "w", encoding="utf-8") as f:
            json.dump({"kern": {m: ([0.1, 0.9] if m in ("p05", "titel") else [0.4, 0.6]) for m in MOTIFS},
                       "panels": {}}, f)
        out = kern_preview.main(d, os.path.join(d, "sheet.png"), layout_path)
        self.assertTrue(os.path.exists(out))
        with Image.open(out) as im:
            self.assertGreater(im.width, 192)


if __name__ == "__main__":
    unittest.main()
