#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_check_bars"""
import contextlib
import io
import os
import tempfile
import unittest

from PIL import Image, ImageDraw

import check_bars as cb


def quer_with_bars(left, right, w=200, h=100):
    im = Image.new("RGB", (w, h), (120, 120, 120))
    d = ImageDraw.Draw(im)
    if left:
        d.rectangle((0, 0, left - 1, h - 1), fill=(0, 0, 0))
    if right:
        d.rectangle((w - right, 0, w - 1, h - 1), fill=(0, 0, 0))
    return im


class Bars(unittest.TestCase):
    def test_clean_image(self):
        self.assertEqual(cb.bar_percent(quer_with_bars(0, 0)), 0.0)

    def test_quer_counts_left_and_right_columns(self):
        self.assertAlmostEqual(cb.bar_percent(quer_with_bars(20, 10)), 15.0)

    def test_hoch_counts_top_and_bottom_rows(self):
        im = quer_with_bars(30, 0).rotate(90, expand=True)  # 100×200, Balken jetzt unten
        self.assertEqual(im.size, (100, 200))
        self.assertAlmostEqual(cb.bar_percent(im), 15.0)

    def test_dark_but_not_black_is_no_bar(self):
        im = Image.new("RGB", (100, 50), (20, 20, 20))
        self.assertEqual(cb.bar_percent(im), 0.0)

    def test_only_edge_runs_count(self):
        im = quer_with_bars(0, 0)
        ImageDraw.Draw(im).rectangle((90, 0, 109, 99), fill=(0, 0, 0))  # Schwarz in der Mitte
        self.assertEqual(cb.bar_percent(im), 0.0)

    def test_bright_fringe_before_bar_counts(self):
        im = quer_with_bars(20, 0)
        ImageDraw.Draw(im).rectangle((0, 0, 1, 99), fill=(40, 40, 40))  # 2 px Saum vor dem Balken
        self.assertAlmostEqual(cb.bar_percent(im), 10.0)

    def test_fringe_without_bar_is_nothing(self):
        im = quer_with_bars(0, 0)
        ImageDraw.Draw(im).rectangle((0, 0, 1, 99), fill=(40, 40, 40))  # dunkler Saum, dahinter Bild
        self.assertEqual(cb.bar_percent(im), 0.0)
        ImageDraw.Draw(im).rectangle((10, 0, 19, 99), fill=(0, 0, 0))  # Schwarz jenseits des Saums
        self.assertEqual(cb.bar_percent(im), 0.0)

    def test_all_black(self):
        self.assertEqual(cb.bar_percent(Image.new("RGB", (40, 20))), 100.0)

    def test_main_folder_and_exit_code(self):
        d = tempfile.mkdtemp()
        quer_with_bars(0, 0).save(os.path.join(d, "p01.jpg"))
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            self.assertEqual(cb.main([d]), 0)
        self.assertIn("p01 0.0", buf.getvalue())
        quer_with_bars(8, 0).save(os.path.join(d, "p04.png"))  # 4 % → noch ok
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(cb.main([d]), 0)
        quer_with_bars(12, 0).save(os.path.join(d, "p04.png"))  # 6 % → Fehler
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            self.assertEqual(cb.main([d]), 1)
        self.assertIn("p04 6.0", buf.getvalue())

    def test_picks_file_with_local_folder(self):
        d = tempfile.mkdtemp()
        quer_with_bars(20, 0).save(os.path.join(d, "p04_quer_s701_00001_.png"))
        p = os.path.join(d, "picks.txt")
        with open(p, "w", encoding="utf-8") as f:
            f.write("# Kommentar\np04_quer=/home/box/comfy_f01/foto/p04_quer_s701_00001_.png\n")
        self.assertEqual(cb.items_from(p, d), [("p04_quer", os.path.join(d, "p04_quer_s701_00001_.png"))])
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            self.assertEqual(cb.main([p, d]), 1)
        self.assertIn("p04_quer 10.0", buf.getvalue())


if __name__ == "__main__":
    unittest.main()
