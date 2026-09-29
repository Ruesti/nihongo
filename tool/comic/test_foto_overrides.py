#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_foto_overrides"""
import os
import tempfile
import unittest

import folge01_foto as ff
from folge01_motifs import FIG, FORMAT_HINT, PANELS, PHOTO, SEEDS, negative_for

HERE = os.path.dirname(os.path.abspath(__file__))
P, M = FIG["P"], FIG["M"]


class FotoOverrides(unittest.TestCase):
    def write(self, text):
        d = tempfile.mkdtemp()
        p = os.path.join(d, "ov.txt")
        with open(p, "w", encoding="utf-8") as f:
            f.write(text)
        return p

    def test_parsing_core_seed_extra_neg(self):
        ov = ff.load_overrides(self.write("p03_hoch seed=704 force core=some core, with comma; extra=x y; neg=a, b\n"))
        self.assertEqual(ov["p03_hoch"], {"seed": 704, "force": True, "core": "some core, with comma",
                                          "extra": "x y", "neg": "a, b"})

    def test_manga_only_keys_rejected(self):
        with self.assertRaises(ValueError):
            ff.load_overrides(self.write("p03_hoch control=canny\n"))

    def test_seed_selection(self):
        self.assertEqual(ff.seeds_for({}), SEEDS)
        self.assertEqual(ff.seeds_for({"seed": 707}), (707,))

    def test_key_filter(self):
        self.assertTrue(ff.selected("p03", "hoch", set()))
        self.assertTrue(ff.selected("p03", "quer", {"p03"}))
        self.assertTrue(ff.selected("p03", "hoch", {"p03_hoch"}))
        self.assertFalse(ff.selected("p03", "quer", {"p03_hoch"}))

    def test_args(self):
        self.assertEqual(ff.parse_args(["p03_hoch", "overrides_foto.txt"]), ({"p03_hoch"}, "overrides_foto.txt"))
        self.assertEqual(ff.parse_args([]), (set(), None))

    def test_default_prompt_unchanged(self):
        pos, neg = ff.prompts("p01", "quer", {})
        self.assertEqual(pos, PANELS["p01"]["core"] + FORMAT_HINT["quer"] + PHOTO)
        self.assertEqual(neg, negative_for("p01"))

    def test_free_core_and_extra(self):
        pos, neg = ff.prompts("p04", "hoch", {"core": "a door", "extra": "rain", "neg": "people"})
        self.assertEqual(pos, "a door" + FORMAT_HINT["hoch"] + ", rain" + PHOTO)
        self.assertEqual(neg, negative_for("p04") + ", people")

    def test_unknown_hoch_fix_rejected(self):
        with self.assertRaises(ValueError):
            ff.prompts("p03", "hoch", {"core": "@HOCH_FIX:p99"})

    def test_committed_file_reproduces_the_four_rerenders(self):
        ov = ff.load_overrides(os.path.join(HERE, "overrides_foto.txt"))
        self.assertEqual({k: v["seed"] for k, v in ov.items()},
                         {"p03_hoch": 704, "titel_a_hoch": 703, "p06_hoch": 705, "p07_hoch": 707})
        # Wortgleich mit foto_nachrender.py (28.9.): core + FORMAT_HINT + PHOTO.
        p03 = ("view from directly behind " + P + ", her back to the camera, we see only the back of her navy "
               "jacket and the back of her black bob haircut, no face visible, she walks away from the viewer "
               "down an empty wet residential street at night, old wooden houses, utility poles and wires "
               "against a grey sky, small in the wide scene")
        self.assertEqual(ff.prompts("p03", "hoch", ov["p03_hoch"]),
                         (p03 + FORMAT_HINT["hoch"] + PHOTO, negative_for("p03")))
        titel = ("a small rural train platform at night in the rain, " + P + " seen from behind at a "
                 "three-quarter angle, standing still with a travel bag, her head turned to watch a local train "
                 "pulling away, red tail lights, far away the faint lights of a small town, large calm empty sky "
                 "above, wide establishing shot")
        self.assertEqual(ff.prompts("titel_a", "hoch", ov["titel_a_hoch"]),
                         (titel + FORMAT_HINT["hoch"] + PHOTO, negative_for("titel_a")))
        # Wortgleich mit foto_nachrender2.py (29.9.): core + HINT + PHOTO, Negativ + NEG_EXTRA.
        hint = (", vertical portrait composition filling the entire tall frame from top edge to bottom edge, "
                "camera close to the figures, ceiling and floor of the room visible")
        neg2 = ", black bars, letterbox, letterboxing, black borders, frame, border, empty black areas"
        self.assertEqual(ff.prompts("p06", "hoch", ov["p06_hoch"]),
                         (PANELS["p06"]["core"] + hint + PHOTO, negative_for("p06") + neg2))
        # Wortgleich mit foto_nachrender3.py (29.9.): CORE + PHOTO, Negativ + NEG_EXTRA (+ Flur).
        core3 = ("outside on a wet shopping street at dusk, in the open doorway of a small old shop, " + M +
                 " stands on the threshold and holds out a repaired open transparent umbrella toward " + P +
                 " who stands on the street and reaches to take it, two people clearly visible, emotional moment, "
                 "the tall doorframe and the lit shop interior fill the vertical frame from top to bottom, "
                 "wet pavement in the foreground, shop sign above the door")
        self.assertEqual(ff.prompts("p07", "hoch", ov["p07_hoch"]),
                         (core3 + PHOTO, negative_for("p07") + neg2 + ", corridor, hallway"))


if __name__ == "__main__":
    unittest.main()
