#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_letter"""
import unittest

import letter_folge01 as lf


def layout(bubble_rect, face=None, fmt="quer"):
    return {"safe": 0.8, "reactions": [], "panels": {"p01": {fmt: {
        "faces": [face] if face else [],
        "bubbles": [{"text": "あめ", "rect": bubble_rect}]}}}}


class CheckLayout(unittest.TestCase):
    def test_ok(self):
        self.assertEqual(lf.check_layout(layout([0.2, 0.2, 0.3, 0.1])), [])

    def test_face_overlap(self):
        msgs = lf.check_layout(layout([0.2, 0.2, 0.3, 0.1], face=[0.3, 0.22, 0.1, 0.1]))
        self.assertTrue(msgs and msgs[0].startswith("GESICHT VERDECKT p01 quer"))

    def test_safe_zone_quer_is_vertical(self):
        # quer wird oben/unten beschnitten: y muss in [0.10, 0.90] liegen
        self.assertTrue(any("SICHERE ZONE" in m for m in lf.check_layout(layout([0.2, 0.05, 0.3, 0.1]))))
        self.assertEqual(lf.check_layout(layout([0.02, 0.2, 0.3, 0.1])), [])  # x am Rand ist quer erlaubt

    def test_safe_zone_hoch_is_horizontal(self):
        self.assertTrue(any("SICHERE ZONE" in m for m in lf.check_layout(layout([0.02, 0.2, 0.3, 0.1], fmt="hoch"))))
        self.assertEqual(lf.check_layout(layout([0.2, 0.02, 0.3, 0.1], fmt="hoch")), [])

    def test_output_names(self):
        self.assertEqual(lf.out_name("p01", "quer"), "p01.jpg")
        self.assertEqual(lf.out_name("p01", "hoch"), "p01_hoch.jpg")
        self.assertEqual(lf.out_name("p02", "quer", reaction=True), "p02_reaction.jpg")
        self.assertEqual(lf.out_name("p02", "hoch", reaction=True), "p02_reaction_hoch.jpg")


if __name__ == "__main__":
    unittest.main()
