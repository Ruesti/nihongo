#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_ansprache -v"""
import contextlib
import io
import os
import shutil
import tempfile
import unittest
from pathlib import Path

import cafe_ansprache as ca
import cafe_motifs as cm
import comfy_client as cc
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


class Render(unittest.TestCase):
    """Render-Stufen mit Fake-Run: kein ComfyUI nötig."""

    def setUp(self):
        self.d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.d)
        self.log = io.StringIO()  # OK/ERR-Zeilen der Render-Funktionen nicht ins Testprotokoll
        redirect = contextlib.redirect_stdout(self.log)
        redirect.__enter__()
        self.addCleanup(redirect.__exit__, None, None, None)
        self.out = Path(self.d) / "out"
        self.img = os.path.join(self.d, "foto.png")
        with open(self.img, "wb") as f:
            f.write(b"png")
        self.prefixes, self.sizes, self.seeds, self.positives, self.inputs = [], [], [], [], []
        self._saved = (cc.COMFY_INPUT, cc.run)
        cc.COMFY_INPUT = os.path.join(self.d, "input")
        os.makedirs(cc.COMFY_INPUT)

        def fake_run(graph, prefix, out_dir, client_id="x"):
            nodes = list(graph.values())

            def first(cls):
                return [n["inputs"] for n in nodes if n["class_type"] == cls]
            self.prefixes.append(first("SaveImage")[0]["filename_prefix"])
            for lat in first("EmptySD3LatentImage"):
                self.sizes.append({"w": lat["width"], "h": lat["height"]})
            self.seeds.append(first("KSampler")[0]["seed"])
            node = graph[first("KSampler")[0]["positive"][0]]
            if node["class_type"] == "ControlNetApplyAdvanced":  # Manga: Zügel sitzt vor dem Sampler
                node = graph[node["inputs"]["positive"][0]]
            pos = node["inputs"]
            text = pos.get("text", pos.get("prompt"))
            # t2i/manga setzen "shotengai_style, " vor den Prompt; für den Vergleich abziehen
            self.positives.append(text[len("shotengai_style, "):] if text.startswith("shotengai_style, ") else text)
            for li in first("LoadImage"):
                self.inputs.append(li["image"])
            os.makedirs(out_dir, exist_ok=True)
            dest = os.path.join(out_dir, "%s_00001_.png" % prefix)
            with open(dest, "wb") as f:
                f.write(b"x")
            return [dest]
        cc.run = fake_run

    def tearDown(self):
        cc.COMFY_INPUT, cc.run = self._saved

    def test_render_fragend_prefixes_and_sizes(self):
        ca.render_fragend(["wirtin"], ["quer", "hoch"], [911], out=self.out)
        self.assertEqual(self.prefixes, ["wirtin_fragend_quer_s911", "wirtin_fragend_hoch_s911"])
        self.assertEqual([(g["w"], g["h"]) for g in self.sizes], [(1664, 928), (928, 1664)])

    def test_render_fragend_skips_existing(self):
        ca.render_fragend(["wirtin"], ["quer"], [911], out=self.out)
        ca.render_fragend(["wirtin"], ["quer"], [911], out=self.out)
        self.assertEqual(len(self.prefixes), 1)

    def test_render_edits_two_moods_per_pick(self):
        ca.render_edits({"wirtin_quer_2": self.img}, out=self.out)
        self.assertEqual(self.prefixes, ["wirtin_zufrieden_2_quer", "wirtin_abwinkend_2_quer"])
        self.assertTrue((Path(cc.COMFY_INPUT) / "ans_wirtin_quer_2.png").exists())

    def test_render_edits_override_seed_and_force(self):
        ca.render_edits({"wirtin_quer_2": self.img}, out=self.out)
        ca.render_edits({"wirtin_quer_2": self.img}, out=self.out,
                        overrides={"wirtin_zufrieden_2_quer": {"seed": 5, "force": True}})
        self.assertEqual(self.prefixes[2:], ["wirtin_zufrieden_2_quer"])
        self.assertEqual(self.seeds[-1], 5)

    def test_render_manga_uses_manga_prompt(self):
        ca.render_manga({"wirtin_fragend_2_quer": self.img}, out=self.out)
        self.assertEqual(self.prefixes, ["wirtin_fragend_2_quer"])
        self.assertTrue(self.positives[0].startswith(fm.STY))
        self.assertEqual(self.inputs, ["ansm_wirtin_fragend_2_quer.png"])

    def test_missing_source_logs_err_and_continues(self):
        res = ca.render_edits({"wirtin_quer_2": self.img + ".fehlt", "wirtin_hoch_1": self.img}, out=self.out)
        self.assertEqual(self.prefixes, ["wirtin_zufrieden_1_hoch", "wirtin_abwinkend_1_hoch"])
        self.assertEqual(len(res), 2)
        self.assertIn("ERR wirtin_zufrieden_2_quer", self.log.getvalue())

    def test_edit_outputs_and_fragend_sources(self):
        ca.render_edits({"wirtin_quer_2": self.img}, out=self.out)
        got = ca.edit_outputs(self.out)
        self.assertEqual(sorted(got), ["wirtin_abwinkend_2_quer", "wirtin_zufrieden_2_quer"])
        self.assertTrue(got["wirtin_zufrieden_2_quer"].endswith("wirtin_zufrieden_2_quer_00001_.png"))
        self.assertEqual(ca.fragend_sources({"wirtin_quer_2": self.img}),
                         {"wirtin_fragend_2_quer": self.img})


if __name__ == "__main__":
    unittest.main()
