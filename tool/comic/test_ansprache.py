#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_ansprache -v"""
import contextlib
import io
import json
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
        for s in ["looks straight into the camera", "upper third", cm.LAND, cm.CAFE, cm.PHOTO]:
            self.assertIn(s, pos)
        self.assertTrue(pos.startswith("waist-up portrait photo")); self.assertIn(cm.CAFE, pos)
        self.assertNotIn("shotengai_style", pos)
        self.assertIn("looking away", neg)
        self.assertIn(cm.NEG, neg)

    def test_t2i_variant_selects_pose_and_expression(self):
        pos, _ = ca.t2i_prompt("schulkind", "quer", 3)
        self.assertIn(ca.GUESTS["schulkind"]["poses"][3], pos)
        self.assertIn(ca._EXPRESSIONS[3], pos)
        self.assertNotEqual(ca.t2i_prompt("schulkind", "quer", 0), ca.t2i_prompt("schulkind", "quer", 1))
        self.assertEqual(ca.t2i_prompt("schulkind", "quer", 11), ca.t2i_prompt("schulkind", "quer", 3))

    def test_poses_and_expressions_complete(self):
        for g, d in ca.GUESTS.items():
            self.assertEqual(len(d["poses"]), 8, g)
            self.assertEqual(len(set(d["poses"])), 8, g)
        self.assertEqual(len(set(ca._EXPRESSIONS)), 8)

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

    def test_load_overrides_rejects_unknown_key(self):
        with self.assertRaisesRegex(ValueError, "wirtin_zufriden_2_quer"):
            ca.load_overrides(self.write("wirtin_zufriden_2_quer seed=5"))

    def test_load_overrides_rejects_other_fields(self):
        with self.assertRaises(ValueError):
            ca.load_overrides(self.write("wirtin_zufrieden_2_quer denoise=0.5"))


class FakeRun(unittest.TestCase):
    """Basis ohne eigene Tests: Fake-Run statt ComfyUI."""

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
        self.encoded = []
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
            self.encoded.append(text)  # roh, wie ins Modell kodiert
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

class Render(FakeRun):
    """Render-Stufen mit Fake-Run: kein ComfyUI nötig."""

    def test_render_fragend_prefixes_and_sizes(self):
        ca.render_fragend(["wirtin"], ["quer", "hoch"], [911], out=self.out)
        self.assertEqual(self.prefixes, ["wirtin_fragend_quer_s911", "wirtin_fragend_hoch_s911"])
        self.assertEqual([(g["w"], g["h"]) for g in self.sizes], [(1664, 928), (928, 1664)])

    def test_render_fragend_single_trigger_word(self):
        ca.render_fragend(["wirtin"], ["quer"], [911], out=self.out)
        self.assertEqual(self.encoded[0].count("shotengai_style"), 1)
        self.assertTrue(self.encoded[0].startswith("shotengai_style, waist-up portrait photo"))

    def test_render_fragend_variant_per_seed(self):
        ca.render_fragend(["wirtin"], ["quer"], (1, 2), out=self.out)
        self.assertEqual(len(self.positives), 2)
        self.assertNotEqual(self.positives[0], self.positives[1])
        self.assertIn(ca.GUESTS["wirtin"]["poses"][1], self.positives[1])

    def test_render_edits_changed_source_rerenders(self):
        other = os.path.join(self.d, "anders.png")
        with open(other, "wb") as f:
            f.write(b"png2")
        pick = "wirtin_quer_2"
        ca.render_edits({pick: self.img}, out=self.out)
        ca.render_edits({pick: self.img}, out=self.out)
        self.assertEqual(len(self.prefixes), 2)  # gleiche Quelle: übersprungen
        ca.render_edits({pick: other}, out=self.out)
        self.assertEqual(self.prefixes[2:], ["wirtin_zufrieden_2_quer", "wirtin_abwinkend_2_quer"])
        with open(self.out / "_sources.json", encoding="utf-8") as f:
            rec = json.load(f)
        self.assertEqual(rec, {"wirtin_zufrieden_2_quer": other, "wirtin_abwinkend_2_quer": other})
        ca.render_edits({pick: other}, out=self.out)
        self.assertEqual(len(self.prefixes), 4)

    def test_render_manga_changed_source_rerenders(self):
        other = os.path.join(self.d, "anders.png")
        with open(other, "wb") as f:
            f.write(b"png2")
        name = "wirtin_fragend_2_quer"
        ca.render_manga({name: self.img}, out=self.out)
        ca.render_manga({name: self.img}, out=self.out)
        self.assertEqual(len(self.prefixes), 1)
        ca.render_manga({name: other}, out=self.out)
        self.assertEqual(len(self.prefixes), 2)
        self.assertEqual(ca._load_sources(self.out)[name], other)

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

    def test_prompts_and_default_seeds(self):
        ca.render_fragend(["wirtin"], ["quer"], [911], out=self.out)
        ca.render_edits({"wirtin_quer_2": self.img}, out=self.out)
        ca.render_manga({"wirtin_fragend_2_quer": self.img}, out=self.out)
        self.assertEqual(self.positives[0], ca.t2i_prompt("wirtin", "quer")[0])
        self.assertEqual(self.positives[1], ca.edit_prompt("wirtin", "zufrieden"))
        self.assertEqual(self.positives[2], ca.edit_prompt("wirtin", "abwinkend"))
        self.assertEqual(self.seeds, [911, 21, 21, 831])

    def test_extra_in_prompts(self):
        ca.render_edits({"wirtin_quer_2": self.img}, out=self.out,
                        overrides={"wirtin_zufrieden_2_quer": {"extra": "eyes open"}})
        self.assertEqual(self.positives[0], ca.edit_prompt("wirtin", "zufrieden") + ", eyes open")
        self.assertEqual(self.positives[1], ca.edit_prompt("wirtin", "abwinkend"))
        ca.render_manga({"wirtin_fragend_2_quer": self.img}, out=self.out,
                        overrides={"wirtin_fragend_2_quer": {"extra": "soft light"}})
        self.assertEqual(self.positives[2], ca.manga_prompt("wirtin")[0] + ", soft light")

    def test_manga_seed_override_and_force(self):
        src = {"wirtin_fragend_2_quer": self.img}
        ca.render_manga(src, out=self.out)
        ca.render_manga(src, out=self.out)
        self.assertEqual(len(self.prefixes), 1)
        ca.render_manga(src, out=self.out, overrides={"wirtin_fragend_2_quer": {"seed": 7, "force": True}})
        self.assertEqual(len(self.prefixes), 2)
        self.assertEqual(self.seeds[-1], 7)

    def test_bad_keys_log_err_and_continue(self):
        picks = {"wirtin_quer_6": self.img, "wirtin_hoch_1": self.img}
        ca.render_edits(picks, out=self.out)
        self.assertEqual(self.prefixes, ["wirtin_zufrieden_1_hoch", "wirtin_abwinkend_1_hoch"])
        self.assertEqual(self.log.getvalue().count("ERR wirtin_quer_6"), 1)
        self.assertEqual(ca.fragend_sources(picks), {"wirtin_fragend_1_hoch": self.img})
        self.assertEqual(self.log.getvalue().count("ERR wirtin_quer_6"), 2)
        del self.prefixes[:]
        ca.render_manga({"unbekannt_fragend_1_quer": self.img, "wirtin_fragend_1_quer": self.img}, out=self.out)
        self.assertEqual(self.prefixes, ["wirtin_fragend_1_quer"])
        self.assertIn("ERR unbekannt_fragend_1_quer", self.log.getvalue())

    def test_edit_outputs_newest_and_tie_break(self):
        self.out.mkdir(parents=True, exist_ok=True)
        a, b, c = (self.out / n for n in ("wirtin_zufrieden_2_quer_a_00001_.png",
                                          "wirtin_zufrieden_2_quer_b_00001_.png",
                                          "wirtin_zufrieden_2_quer_c_00001_.png"))
        for f, t in ((a, 200), (b, 100), (c, 100)):
            f.write_bytes(b"x")
            os.utime(f, (t, t))
        self.assertEqual(ca.edit_outputs(self.out), {"wirtin_zufrieden_2_quer": str(a)})
        os.utime(a, (100, 100))
        self.assertEqual(ca.edit_outputs(self.out), {"wirtin_zufrieden_2_quer": str(c)})


class Stages(FakeRun):
    """Stufen gate/runde1/runde2 mit Fake-Run und Fake-Bogen."""

    def setUp(self):
        super().setUp()
        self.sheet_items = {}
        self._saved_stage = (ca.ROOT, ca.make_sheet)
        self._real_make_sheet = ca.make_sheet
        ca.ROOT = Path(self.d) / "root"

        self.sheet_out = {}

        def fake_sheet(name, items, cols, out=None):
            self.sheet_items[name] = items
            self.sheet_out[name] = out
            return Path(self.d) / (name + ".png")
        ca.make_sheet = fake_sheet
        self.picks_two_guests = os.path.join(self.d, "picks.txt")
        with open(self.picks_two_guests, "w", encoding="utf-8") as f:
            for g in ("wirtin", "schulkind"):
                for fmt in ca.FORMATS:
                    for n in range(1, 6):
                        f.write(f"{g}_{fmt}_{n}={self.img}\n")

    def tearDown(self):
        ca.ROOT, ca.make_sheet = self._saved_stage
        super().tearDown()

    def test_gate_sheet_rows(self):
        ca.gate(seeds=(1, 2))
        labels = [l for l, _ in self.sheet_items["gate"]]
        self.assertEqual(len(labels), 12)
        self.assertEqual(labels, [f"{f} s{s} {m}" for f in ("quer", "hoch") for s in (1, 2)
                                  for m in ("fragend", "zufrieden", "abwinkend")])
        base = ca.ROOT / "gate"
        self.assertTrue(all(str(p).startswith(str(base / "manga")) for _, p in self.sheet_items["gate"]))
        self.assertEqual(self.sheet_out["gate"], base / "sheets")
        for sub in ("foto", "edit", "manga", "sheets"):
            self.assertFalse((ca.ROOT / sub).exists())

    def test_missing_image_placeholder(self):
        real_run = cc.run

        def skipping(graph, prefix, out_dir, client_id="x"):
            if prefix == "wirtin_zufrieden_1_quer":
                return []
            return real_run(graph, prefix, out_dir, client_id)
        cc.run = skipping
        ca.gate(seeds=(1, 2))
        items = self.sheet_items["gate"]
        self.assertEqual(len(items), 12)
        self.assertEqual(items[1][0], "quer s1 zufrieden")
        self.assertEqual(items[1][1].name, "_placeholder.png")
        self.assertTrue(items[1][1].exists())
        self.assertIn("WARN fehlt: quer s1 zufrieden", self.log.getvalue())

    def test_make_sheet_failure_raises(self):
        import subprocess
        saved = subprocess.run
        subprocess.run = lambda cmd, **kw: subprocess.CompletedProcess(cmd, 1) if not kw.get("check") \
            else (_ for _ in ()).throw(subprocess.CalledProcessError(1, cmd))
        try:
            with self.assertRaises(subprocess.CalledProcessError):
                self._real_make_sheet("x", [("a", "b")], 3, out=Path(self.d) / "sh")
        finally:
            subprocess.run = saved

    def test_runde1_sheets_per_cell(self):
        ca.runde1(seeds=(1, 2, 3))
        self.assertEqual(sorted(self.sheet_items),
                         sorted(f"r1_{g}_{f}" for g in ca.GUESTS for f in ca.FORMATS))
        self.assertEqual(len(self.sheet_items["r1_wirtin_quer"]), 3)
        self.assertEqual([l for l, _ in self.sheet_items["r1_wirtin_quer"]], ["s1", "s2", "s3"])
        self.assertIn("foto", str(self.sheet_items["r1_wirtin_quer"][0][1]))

    def test_runde1_explicit_seeds_sheet_names(self):
        ca.runde1(seeds=(931, 932), suffixed=True)
        self.assertIn("r1_wirtin_quer_s931-932", self.sheet_items)
        self.assertNotIn("r1_wirtin_quer", self.sheet_items)

    def test_main_runde1_seeds_option(self):
        calls = []
        saved = ca.runde1
        ca.runde1 = lambda seeds=None, suffixed=False: calls.append((seeds, suffixed))
        self.addCleanup(setattr, ca, "runde1", saved)
        ca.main(["runde1", "--seeds", "931,932"])
        self.assertEqual(calls, [((931, 932), True)])

    def test_runde2_sheet_per_guest(self):
        ca.runde2(self.picks_two_guests)
        self.assertEqual(sorted(self.sheet_items), ["r2_schulkind", "r2_wirtin"])
        items = self.sheet_items["r2_wirtin"]
        self.assertEqual([l for l, _ in items],
                         [f"{m} {n} {f}" for n in range(1, 6) for f in ("quer", "hoch")
                          for m in ("fragend", "zufrieden", "abwinkend")])
        self.assertIn("manga", str(items[0][1]))

    def test_runde2_overrides_reach_edits(self):
        ov = os.path.join(self.d, "ov.txt")
        with open(ov, "w", encoding="utf-8") as f:
            f.write("wirtin_zufrieden_1_quer seed=77\n")
        ca.runde2(self.picks_two_guests, ov)
        i = self.prefixes.index("wirtin_zufrieden_1_quer")
        self.assertEqual(self.seeds[i], 77)
        j = self.prefixes.index("wirtin_abwinkend_1_quer")
        self.assertEqual(self.seeds[j], 21)

    def test_cli_failure_marker(self):
        with self.assertRaises(SystemExit) as cm_:
            ca.main(["runde2", "/nonexistent/picks.txt"])
        self.assertEqual(cm_.exception.code, 1)
        out = self.log.getvalue()
        self.assertIn("ANSPRACHE_FAILED:", out)
        self.assertNotIn("ANSPRACHE_DONE", out)

    def test_cli_unknown_stage(self):
        with self.assertRaises(SystemExit):
            ca.main(["nix"])

    def test_cli_marker(self):
        ca.main(["gate"])
        self.assertIn("ANSPRACHE_DONE", self.log.getvalue())


class Finish(FakeRun):
    """Finish und Auswahl der Manga-Ausgaben; Fake-Run liefert PNGs in (falscher) Größe."""

    def setUp(self):
        super().setUp()
        self.src = Path(self.img)

    def _png_run(self, size):
        from PIL import Image

        def run(graph, prefix, out_dir, client_id="x"):
            os.makedirs(out_dir, exist_ok=True)
            dest = os.path.join(out_dir, "%s_00001_.png" % prefix)
            with Image.new("RGB", size, (200, 100, 50)) as im:
                im.save(dest)
            self.prefixes.append(prefix)
            return [dest]
        return run

    def test_finish_names_and_quality(self):
        from PIL import Image
        cc.run = self._png_run((1080, 1936))
        paths = ca.finish({"wirtin_fragend_1_hoch": self.src}, out=self.out)
        self.assertEqual(paths[0].name, "wirtin_fragend_1_hoch.jpg")
        with Image.open(paths[0]) as im:
            self.assertEqual(im.size, (1080, 1936))
            self.assertEqual(im.format, "JPEG")
        self.assertEqual(self.prefixes, ["fin_wirtin_fragend_1_hoch"])
        self.assertTrue(os.path.exists(os.path.join(cc.COMFY_INPUT, "ansf_wirtin_fragend_1_hoch.png")))

    def test_finish_skips_up_to_date(self):
        cc.run = self._png_run((1920, 1072))
        ca.finish({"wirtin_fragend_1_quer": self.src}, out=self.out)
        dest = self.out / "wirtin_fragend_1_quer.jpg"
        os.utime(dest, (os.path.getmtime(self.src) + 100,) * 2)
        ca.finish({"wirtin_fragend_1_quer": self.src}, out=self.out)
        self.assertEqual(len(self.prefixes), 1)

    def test_finish_wrong_size_raises(self):
        cc.run = self._png_run((1000, 1000))
        with self.assertRaisesRegex(AssertionError, "wirtin_fragend_1_hoch.*1080"):
            ca.finish({"wirtin_fragend_1_hoch": self.src}, out=self.out)

    def test_final_picks_missing_lists_names(self):
        manga = Path(self.d) / "manga"
        manga.mkdir()
        (manga / "wirtin_fragend_1_quer_00001_.png").write_bytes(b"x")
        with self.assertRaisesRegex(ValueError, "schulkind_abwinkend_5_hoch"):
            ca.final_picks(manga)
        got = ca.final_picks(manga, allow_missing=True)
        self.assertEqual(list(got), ["wirtin_fragend_1_quer"])

    def test_final_picks_complete_takes_newest(self):
        manga = Path(self.d) / "manga"
        manga.mkdir()
        for name in ca.all_names():
            (manga / (name + "_00001_.png")).write_bytes(b"x")
        newer = manga / "wirtin_fragend_1_quer_00002_.png"
        newer.write_bytes(b"y")
        os.utime(newer, (4e9, 4e9))
        got = ca.final_picks(manga)
        self.assertEqual(len(got), 120)
        self.assertEqual(Path(got["wirtin_fragend_1_quer"]).name, newer.name)


if __name__ == "__main__":
    unittest.main()
