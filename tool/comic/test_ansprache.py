#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_ansprache -v"""
import os
import shutil
import tempfile
import unittest

import cafe_ansprache as ca
import cafe_motifs as cm
import folge01_motifs as fm


class Names(unittest.TestCase):
    def test_name_for(self):
        self.assertEqual(ca.name_for("wirtin", "fragend", 3, "quer"), "wirtin_fragend_3_quer")

    def test_name_rejects(self):
        for bad in [("x", "fragend", 1, "quer"), ("wirtin", "froh", 1, "quer"),
                    ("wirtin", "fragend", 6, "quer"), ("wirtin", "fragend", 1, "breit")]:
            with self.assertRaises(ValueError):
                ca.name_for(*bad)

    def test_all_names_120_unique(self):
        names = ca.all_names()
        self.assertEqual(len(names), 120)
        self.assertEqual(len(set(names)), 120)


class Prompts(unittest.TestCase):
    def test_t2i_contains_camera_and_format(self):
        pos, neg = ca.t2i_prompt("wirtin", "hoch")
        for s in ["looks straight into the camera", "upper half", cm.LAND, cm.CAFE, cm.PHOTO]:
            self.assertIn(s, pos)
        self.assertTrue(pos.startswith("shotengai_style, "))
        self.assertIn("looking away", neg)
        self.assertIn(cm.NEG, neg)

    def test_edit_prompts_all_moods(self):
        for g in ca.GUESTS:
            for m in ("zufrieden", "abwinkend"):
                self.assertIn("keep the same person", ca.edit_prompt(g, m))
        with self.assertRaises(ValueError):
            ca.edit_prompt("wirtin", "fragend")

    def test_manga_prompt(self):
        pos, neg = ca.manga_prompt("schulkind")
        self.assertTrue(pos.startswith(fm.STY))
        self.assertIn(cm.GIRL, pos)
        self.assertEqual(neg, fm.NEG_MANGA)


class PicksAndOverrides(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.dir, True)
        self.img = os.path.join(self.dir, "foto.png")
        open(self.img, "wb").close()
        self.p = self.write(f"# Kommentar\n\nwirtin_quer_1={self.img}\n")

    def write(self, text):
        p = os.path.join(self.dir, "t%d.txt" % len(os.listdir(self.dir)))
        with open(p, "w", encoding="utf-8") as f:
            f.write(text)
        return p

    def test_load_picks_ok(self):
        self.assertEqual(ca.load_picks(self.p), {"wirtin_quer_1": self.img})

    def test_load_picks_missing_file(self):
        with self.assertRaisesRegex(ValueError, "fehlt.*nix.png"):
            ca.load_picks(self.write("wirtin_quer_1=/tmp/nix.png"))

    def test_load_picks_duplicate_number(self):
        with self.assertRaisesRegex(ValueError, "doppelt"):
            ca.load_picks(self.write(f"wirtin_quer_1={self.img}\nwirtin_quer_1={self.img}"))

    def test_load_picks_bad_key(self):
        for bad in ("wirtin_1", "wirtin_quer_6", "koch_quer_1", "wirtin_breit_1", "wirtin_quer_x"):
            with self.assertRaisesRegex(ValueError, "Schlüssel"):
                ca.load_picks(self.write(f"{bad}={self.img}"))

    def test_load_picks_expanduser(self):
        old = os.environ.get("HOME")
        os.environ["HOME"] = self.dir
        try:
            got = ca.load_picks(self.write("wirtin_hoch_2=~/foto.png"))
        finally:
            if old is None:
                del os.environ["HOME"]
            else:
                os.environ["HOME"] = old
        self.assertEqual(got, {"wirtin_hoch_2": self.img})

    def test_cells_missing(self):
        self.assertIn("wirtin_hoch", ca.cells_missing({"wirtin_quer_1": self.img}))

    def test_cells_missing_order_and_full(self):
        miss = ca.cells_missing({})
        self.assertEqual(len(miss), 8)
        self.assertEqual(miss[:2], ["wirtin_quer", "wirtin_hoch"])
        full = {f"wirtin_quer_{n}": self.img for n in range(1, 6)}
        self.assertNotIn("wirtin_quer", ca.cells_missing(full))

    def test_load_overrides(self):
        self.assertEqual(ca.load_overrides(self.write("wirtin_zufrieden_2_quer seed=5 force")),
                         {"wirtin_zufrieden_2_quer": {"seed": 5, "force": True}})

    def test_load_overrides_rejects_other_fields(self):
        with self.assertRaises(ValueError):
            ca.load_overrides(self.write("wirtin_zufrieden_2_quer denoise=0.5"))


if __name__ == "__main__":
    unittest.main()
