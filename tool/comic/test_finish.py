#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_finish"""
import os
import tempfile
import unittest

import folge01_finish as ff


class Finish(unittest.TestCase):
    def test_targets(self):
        self.assertEqual(ff.target_for("p03_quer"), (1920, 1072))
        self.assertEqual(ff.target_for("titel_hoch"), (1080, 1936))
        with self.assertRaises(ValueError):
            ff.target_for("p03_breit")

    def test_require_complete_lists_missing(self):
        picks = {"%s_%s" % (m, f): "x" for m in ["p%02d" % i for i in range(1, 11)] + ["titel"]
                 for f in ("quer", "hoch")}
        ff.require_complete(picks)  # 22 Schlüssel → ok
        del picks["p07_hoch"]
        with self.assertRaises(ValueError) as cm:
            ff.require_complete(picks)
        self.assertIn("p07_hoch", str(cm.exception))

    def test_skip_only_when_target_newer_than_source(self):
        d = tempfile.mkdtemp()
        src, dest = os.path.join(d, "p01_quer_00001_.png"), os.path.join(d, "p01_quer.jpg")
        with open(src, "wb") as f:
            f.write(b"x")
        self.assertFalse(ff.up_to_date(dest, src))  # Ziel fehlt
        with open(dest, "wb") as f:
            f.write(b"y")
        os.utime(src, (1000, 1000))
        os.utime(dest, (2000, 2000))
        self.assertTrue(ff.up_to_date(dest, src))   # Ziel jünger → SKIP
        os.utime(src, (3000, 3000))
        self.assertFalse(ff.up_to_date(dest, src))  # Quelle neu gerendert → neu vergrößern

    def test_read_picks_checks_files(self):
        d = tempfile.mkdtemp()
        img = os.path.join(d, "p01_quer_00001_.png")
        with open(img, "wb") as f:
            f.write(b"x")
        p = os.path.join(d, "picks.txt")
        with open(p, "w", encoding="utf-8") as f:
            f.write("p01_quer=%s\np02_quer=%s/nix.png\n" % (img, d))
        with self.assertRaises(FileNotFoundError) as cm:
            ff.read_picks(p)
        self.assertIn("FEHLT p02_quer", str(cm.exception))


if __name__ == "__main__":
    unittest.main()
