#!/usr/bin/env python3
"""Aufruf: cd tool/comic && python3 -m unittest test_letter"""
import os
import tempfile
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


class Wrap(unittest.TestCase):
    def test_short_stays_one_line(self):
        self.assertEqual(lf.wrap("みなみまち駅"), "みなみまち駅")

    def test_breaks_after_question_and_exclamation(self):
        self.assertEqual(lf.wrap("これ？かさ？みせ！"), "これ？かさ？\nみせ！")
        self.assertEqual(lf.wrap("ここ…？あめ…やどり？"), "ここ…？\nあめ…やどり？")
        self.assertEqual(lf.shown_text("ここ…？あめ…やどり？").count("\n"), 1)

    def test_sentence_end_before_comma(self):
        # 。 bleibt vor 、 (bestehende Regel), auch wenn ein 、 naeher an der Mitte liegt.
        self.assertEqual(lf.wrap("いいえ、いいえ。どうぞ、どうぞ。かさ！"), "いいえ、いいえ。\nどうぞ、どうぞ。かさ！")

    def test_comma_as_fallback(self):
        self.assertEqual(lf.wrap("あめ、あめ、さむい、さむい"), "あめ、あめ、\nさむい、さむい")

    def test_spaces_rule_unchanged(self):
        self.assertEqual(lf.wrap("あめ、あめ… さむい、さむい"), "あめ、あめ…\nさむい、さむい")


class FitFont(unittest.TestCase):
    def test_text_fits_inscribed_rectangle(self):
        from PIL import Image, ImageDraw
        draw = ImageDraw.Draw(Image.new("RGB", (10, 10)))
        w, h, reserve = 500.0, 140.0, 30.0
        font = lf.fit_font(draw, "これ？かさ？\nみせ！", w, h, reserve)
        l, t, r, b = draw.multiline_textbbox((0, 0), "これ？かさ？\nみせ！", font=font)
        self.assertLessEqual(r - l, w / 2 ** 0.5)
        self.assertLessEqual(b - t, h / 2 ** 0.5 - reserve)


class Validate(unittest.TestCase):
    def setUp(self):
        from PIL import Image
        self.src = tempfile.mkdtemp()
        for name in ("p01_quer", "titel_quer", "titel_hoch"):
            Image.new("RGB", (64, 36), (90, 90, 90)).save(os.path.join(self.src, name + ".jpg"))

    def lay(self, text="みなみまち駅", furi=("駅", "えき")):
        b = {"text": text, "rect": [0.2, 0.2, 0.5, 0.3]}
        if furi:
            b["furigana"] = list(furi)
        return {"safe": 0.8, "reactions": [], "panels": {"p01": {"quer": {"faces": [], "bubbles": [b]}}}}

    def test_ok(self):
        self.assertEqual(lf.validate(self.lay(), self.src), [])

    def test_missing_source(self):
        os.remove(os.path.join(self.src, "p01_quer.jpg"))
        self.assertTrue(any(m.startswith("QUELLE FEHLT") for m in lf.validate(self.lay(), self.src)))
        os.remove(os.path.join(self.src, "titel_hoch.jpg"))
        self.assertEqual(sum(m.startswith("QUELLE FEHLT") for m in lf.validate(self.lay(), self.src)), 2)

    def test_furigana_kanji_missing(self):
        msgs = lf.validate(self.lay(furi=("傘", "かさ")), self.src)
        self.assertTrue(any(m.startswith("FURIGANA p01 quer") for m in msgs))

    def test_furigana_kanji_on_second_line(self):
        msgs = lf.validate(self.lay(text="はい。かさ。どうぞ駅", furi=("駅", "えき")), self.src)
        self.assertTrue(any(m.startswith("FURIGANA") for m in msgs))

    def test_nothing_written_before_everything_rendered(self):
        dst = os.path.join(tempfile.mkdtemp(), "out")
        outputs = lf.render_all(self.lay(), self.src)
        self.assertFalse(os.path.exists(dst))
        self.assertEqual([n for n, _ in outputs], ["p01.jpg", "titel.jpg", "titel_hoch.jpg"])
        lf.write_all(outputs, dst)
        self.assertEqual(sorted(os.listdir(dst)), ["p01.jpg", "titel.jpg", "titel_hoch.jpg"])


if __name__ == "__main__":
    unittest.main()
