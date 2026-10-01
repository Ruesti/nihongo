#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_kern_geometry"""
import unittest

import kern_geometry as kg


class Window(unittest.TestCase):
    def test_window_width_is_hoch_ratio(self):
        self.assertEqual(kg.window_width(1664, 928), 518)   # 928 * 928 / 1664 = 517,5
        self.assertEqual(kg.window_width(1920, 1072), 598)


class Steps(unittest.TestCase):
    def test_top_steps_split_into_multiples_of_16_below_max(self):
        self.assertEqual(kg.top_steps(0), [])
        self.assertEqual(kg.top_steps(464), [464])
        steps = kg.top_steps(912)
        self.assertEqual(sum(steps), 912)
        self.assertEqual(len(steps), 2)
        self.assertTrue(all(s % 16 == 0 and 0 < s <= kg.STEP_MAX for s in steps), steps)
        steps = kg.top_steps(1040)
        self.assertEqual((sum(steps), len(steps)), (1040, 3))
        self.assertTrue(all(s % 16 == 0 and 0 < s <= kg.STEP_MAX for s in steps), steps)

    def test_top_steps_rejects_non_multiple(self):
        with self.assertRaises(ValueError):
            kg.top_steps(500)


class Plan(unittest.TestCase):
    def test_plan_crop_when_kern_fits(self):
        p = kg.plan_for([0.36, 0.64])            # 28 % < 31 %
        self.assertEqual(p["mode"], "crop")
        self.assertEqual(p["x1"] - p["x0"], 518)
        self.assertEqual((p["x0"] + p["x1"]) // 2, 832)   # mittig über dem Kern (Mitte 0,5 → 832)

    def test_plan_crop_clamps_to_edges(self):
        self.assertEqual(kg.plan_for([0.0, 0.2])["x0"], 0)
        p = kg.plan_for([0.85, 1.0])
        self.assertEqual(p["x1"], 1664)
        self.assertEqual(p["x0"], 1664 - 518)

    def test_plan_extend_when_kern_wider(self):
        p = kg.plan_for([0.13, 0.95])            # 82 % → 1364 px breit
        self.assertEqual(p["mode"], "extend")
        self.assertEqual((p["x0"], p["x1"]), (216, 1581))
        self.assertEqual(p["strip_h"] % 16, 0)
        self.assertEqual(p["strip_h"], 624)      # 928 * 928 / 1365 = 631 → 624
        self.assertEqual(p["bottom"], 128)
        self.assertEqual(p["top"], 1664 - 624 - 128)
        self.assertEqual(sum(p["top_steps"]), p["top"])
        self.assertTrue(all(s <= kg.STEP_MAX for s in p["top_steps"]))

    def test_plan_extend_near_window(self):
        # 33 % breit (550 px): Streifen 1568 hoch → unten nur 96 px, oben nichts, kein negativer Rand
        p = kg.plan_for([0.335, 0.665])
        self.assertEqual(p["mode"], "extend")
        self.assertGreaterEqual(p["bottom"], 0)
        self.assertEqual(p["strip_h"] + p["bottom"] + p["top"], 1664)
        self.assertEqual(p["top"], 0)
        self.assertEqual(p["top_steps"], [])

    def test_plan_rejects_bad_kern(self):
        for bad in ([0.5, 0.5], [-0.1, 0.5], [0.2, 1.1], [0.7, 0.3]):
            with self.assertRaises(ValueError):
                kg.plan_for(bad)


class Faces(unittest.TestCase):
    def test_map_rect_crop_shifts_and_scales_x_only(self):
        p = kg.plan_for([0.36, 0.64])            # Fenster 573..1091
        r = kg.map_rect([0.43, 0.29, 0.12, 0.19], p)
        self.assertAlmostEqual(r[0], (0.43 * 1664 - p["x0"]) / 518, places=3)   # map_rect rundet auf 4 Stellen
        self.assertAlmostEqual(r[1], 0.29, places=3)
        self.assertAlmostEqual(r[2], 0.12 * 1664 / 518, places=3)
        self.assertAlmostEqual(r[3], 0.19, places=3)

    def test_map_rect_extend_places_strip_in_canvas(self):
        p = kg.plan_for([0.13, 0.95])
        r = kg.map_rect([0.5, 0.0, 0.1, 1.0], p)   # volle Höhe des Streifens
        self.assertAlmostEqual(r[1], p["top"] / 1664, places=3)
        self.assertAlmostEqual(r[3], p["strip_h"] / 1664, places=3)

    def test_hoch_faces_clips_and_drops(self):
        p = kg.plan_for([0.36, 0.64])            # Fenster 573..1091 (0,344..0,656)
        faces = [[0.43, 0.29, 0.12, 0.19],        # ganz drin
                 [0.62, 0.2, 0.1, 0.1],           # ragt rechts raus → beschnitten
                 [0.05, 0.2, 0.1, 0.1]]           # ganz draußen → weg
        out = kg.hoch_faces(faces, p)
        self.assertEqual(len(out), 2)
        for f in out:
            self.assertTrue(0 <= f[0] and f[0] + f[2] <= 1.0001 and f[2] > 0, f)
        self.assertAlmostEqual(out[1][0] + out[1][2], 1.0, places=4)


if __name__ == "__main__":
    unittest.main()
