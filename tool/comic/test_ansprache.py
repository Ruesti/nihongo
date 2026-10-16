#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_ansprache -v"""
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


if __name__ == "__main__":
    unittest.main()
