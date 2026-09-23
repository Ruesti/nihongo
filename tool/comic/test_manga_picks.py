#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_manga_picks"""
import os
import tempfile
import unittest

import folge01_manga as fm


class Picks(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.img = os.path.join(self.dir, "p01_quer_s702_00001_.png")
        open(self.img, "wb").write(b"x")

    def write(self, text):
        p = os.path.join(self.dir, "picks.txt")
        open(p, "w", encoding="utf-8").write(text)
        return p

    def test_reads_path_and_seed(self):
        picks = fm.load_picks(self.write("# Kommentar\np01_quer=%s\n" % self.img))
        self.assertEqual(picks, {"p01_quer": (self.img, 702)})

    def test_missing_file_names_motif(self):
        with self.assertRaises(FileNotFoundError) as cm:
            fm.load_picks(self.write("p03_hoch=%s/nix.png\n" % self.dir))
        self.assertIn("FEHLT p03_hoch", str(cm.exception))

    def test_line_without_seed_rejected(self):
        bad = os.path.join(self.dir, "p01_quer_00001_.png")
        open(bad, "wb").write(b"x")
        with self.assertRaises(ValueError):
            fm.load_picks(self.write("p01_quer=%s\n" % bad))

    def test_overrides(self):
        p = os.path.join(self.dir, "ov.txt")
        open(p, "w", encoding="utf-8").write("p07_quer control=canny seed=702 extra=clean transparent umbrella\n")
        ov = fm.load_overrides(p)
        self.assertEqual(ov["p07_quer"]["control"], "canny")
        self.assertEqual(ov["p07_quer"]["seed"], 702)
        self.assertEqual(ov["p07_quer"]["extra"], "clean transparent umbrella")
        self.assertEqual(fm.load_overrides(os.path.join(self.dir, "fehlt.txt")), {})

    def test_variants(self):
        names = [v[0] for v in fm.variants()]
        self.assertEqual(names, ["D60", "D70", "D80", "S60", "S85", "C70"])
        d80 = dict(fm.variants())["D80"]
        self.assertEqual((d80["control"], d80["denoise"], d80["strength"]), ("depth", 0.8, 0.7))
        c70 = dict(fm.variants())["C70"]
        self.assertEqual((c70["control"], c70["strength"]), ("canny", 0.6))


if __name__ == "__main__":
    unittest.main()
