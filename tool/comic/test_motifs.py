#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_motifs"""
import unittest

import folge01_motifs as m


class Motifs(unittest.TestCase):
    def test_ten_panels_and_three_covers(self):
        self.assertEqual(sorted(m.PANELS), ["p%02d" % i for i in range(1, 11)])
        self.assertEqual(sorted(m.COVERS), ["titel_a", "titel_b", "titel_c"])
        self.assertEqual(len(m.motifs()), 13)

    def test_reader_to_source_mapping(self):
        want = {"p01": "P01", "p02": "P02", "p03": "P04", "p04": "P05", "p05": "P07",
                "p06": "P17", "p07": "P21", "p08": "P22", "p09": "P11", "p10": "P03"}
        self.assertEqual({k: v["src"] for k, v in m.PANELS.items()}, want)

    def test_figure_panels_carry_fixed_descriptions(self):
        for pid, p in m.PANELS.items():
            if p["kind"] == "fig":
                self.assertTrue(any(fig in p["core"] for fig in m.FIG.values()),
                                "%s ohne feste Figurenbeschreibung" % pid)

    def test_content_fixes_from_13_9(self):
        self.assertIn("navy jacket", m.FIG["P"])
        self.assertIn("outside", m.PANELS["p09"]["core"])
        self.assertIn("lying on the workbench", m.PANELS["p06"]["core"])

    def test_formats_are_qwen_native(self):
        self.assertEqual(m.FORMATS, {"quer": (1664, 928), "hoch": (928, 1664)})
        self.assertEqual(m.SEEDS, (701, 702))

    def test_negative_keeps_people_for_figures_only(self):
        # Der Foto-Negativ endet auf "empty, no people, faceless": bei Figuren-Panels
        # verbietet er leere Bilder, bei Detail-/Ortspanels (det) wird der Teil entfernt.
        self.assertIn("no people", m.negative_for("p01"))      # fig
        self.assertNotIn("no people", m.negative_for("p04"))   # det: darf leer sein
        self.assertIn("anime", m.negative_for("p01"))          # Foto-Pass: Anti-Anime


class HochUmgebung(unittest.TestCase):
    def test_every_motif_has_a_surrounding_sentence(self):
        want = ["p%02d" % i for i in range(1, 11)] + ["titel"]
        self.assertEqual(sorted(m.HOCH_UMGEBUNG), sorted(want))
        for k, v in m.HOCH_UMGEBUNG.items():
            self.assertIn("above", v, k)
            self.assertIn("below", v, k)

    def test_hoch_negatives_build_on_manga_negative(self):
        self.assertTrue(m.NEG_HOCH_UNTEN.startswith(", "))
        self.assertIn("duplicate person", m.NEG_HOCH_UNTEN)
        self.assertIn("person", m.NEG_HOCH_OBEN)
        self.assertTrue(m.NEG_HOCH_OBEN.startswith(m.NEG_HOCH_UNTEN))
        self.assertIn("legs and feet", m.HOCH_HINT_UNTEN)


if __name__ == "__main__":
    unittest.main()
