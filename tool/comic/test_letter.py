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

    def test_nogo_overlap(self):
        lay = layout([0.2, 0.2, 0.3, 0.1])
        lay["panels"]["p01"]["quer"]["nogo"] = [[0.0, 0.0, 0.72, 0.26]]
        msgs = lf.check_layout(lay)
        self.assertEqual(len(msgs), 1)
        self.assertTrue(msgs[0].startswith("ÜBERLAGERUNG p01 quer"), msgs)

    def test_nogo_clear_and_corner_miss(self):
        lay = layout([0.2, 0.3, 0.3, 0.1])
        # Rechteck-Ecke beruehrt nur die Bounding-Box, nicht die Ellipse → kein Treffer
        lay["panels"]["p01"]["quer"]["nogo"] = [[0.0, 0.0, 0.72, 0.26], [0.0, 0.0, 0.21, 0.305]]
        self.assertEqual(lf.check_layout(lay), [])

    def test_small_font_aborts(self):
        lay = layout([0.2, 0.3, 0.06, 0.04])
        lay["panels"]["p01"]["quer"]["bubbles"][0]["text"] = "いいえ、いいえ。どうぞ、どうぞ。かさ！"
        msgs = lf.check_layout(lay)
        self.assertTrue(any(m.startswith("KLEINSCHRIFT p01 quer いいえ、いいえ。どうぞ、どうぞ。かさ！ ")
                            and m.endswith("px") for m in msgs), msgs)

    def test_small_font_threshold_per_format(self):
        # dieselbe Blase: quer (1920 breit) zu klein, erst eine groessere Ellipse besteht
        big = layout([0.2, 0.3, 0.40, 0.16])
        big["panels"]["p01"]["quer"]["bubbles"][0]["text"] = "いいえ、いいえ。どうぞ、どうぞ。かさ！"
        self.assertEqual(lf.check_layout(big), [])

    def test_validate_collects_small_font_with_other_problems(self):
        lay = layout([0.2, 0.05, 0.06, 0.04])
        lay["panels"]["p01"]["quer"]["bubbles"][0]["text"] = "いいえ、いいえ。どうぞ、どうぞ。かさ！"
        msgs = lf.validate(lay, tempfile.mkdtemp())
        kinds = {m.split(" ")[0] for m in msgs}
        self.assertTrue({"KLEINSCHRIFT", "SICHERE", "QUELLE"} <= kinds, msgs)

    def test_output_names(self):
        self.assertEqual(lf.out_name("p01", "quer"), "p01.jpg")
        self.assertEqual(lf.out_name("p01", "hoch"), "p01_hoch.jpg")
        self.assertEqual(lf.out_name("p02", "quer", reaction=True), "p02_reaction.jpg")
        self.assertEqual(lf.out_name("p02", "hoch", reaction=True), "p02_reaction_hoch.jpg")


class Schild(unittest.TestCase):
    """Schilder ("form": "schild"): rechteckiges Etikett, Pruefung gegen das volle Rechteck."""

    def schild_layout(self, rect, face=None, fmt="quer", form="schild"):
        lay = layout(rect, face=face, fmt=fmt)
        lay["panels"]["p01"][fmt]["bubbles"][0]["form"] = form
        return lay

    def test_schild_clear_is_ok(self):
        self.assertEqual(lf.check_layout(self.schild_layout([0.2, 0.2, 0.3, 0.1])), [])

    def test_corner_hit_counts_for_schild_not_for_oval(self):
        # Gesicht nur in der Rechteck-Ecke: das Oval laesst es frei, das Schild verdeckt es
        rect, face = [0.2, 0.2, 0.3, 0.1], [0.48, 0.28, 0.05, 0.05]
        self.assertEqual(lf.check_layout(layout(rect, face=face)), [])
        msgs = lf.check_layout(self.schild_layout(rect, face=face))
        self.assertEqual(len(msgs), 1, msgs)
        self.assertTrue(msgs[0].startswith("GESICHT VERDECKT p01 quer"), msgs)

    def test_corner_hit_on_nogo(self):
        lay = self.schild_layout([0.2, 0.3, 0.3, 0.1])
        lay["panels"]["p01"]["quer"]["nogo"] = [[0.0, 0.0, 0.21, 0.305]]
        self.assertTrue(any(m.startswith("ÜBERLAGERUNG") for m in lf.check_layout(lay)))
        lay["panels"]["p01"]["quer"]["bubbles"][0].pop("form")
        self.assertEqual(lf.check_layout(lay), [])

    def test_bad_form(self):
        msgs = lf.check_layout(self.schild_layout([0.2, 0.2, 0.3, 0.1], form="wolke"))
        self.assertTrue(msgs and msgs[0].startswith("FORM p01 quer"), msgs)

    def test_schild_drawn_as_rectangle(self):
        from PIL import Image
        rect = [0.2, 0.3, 0.3, 0.2]   # x 320–800, y 240–400
        oval = lf.letter(Image.new("RGB", (1600, 800), (90, 90, 90)), [{"text": "あ", "rect": rect}])
        schild = lf.letter(Image.new("RGB", (1600, 800), (90, 90, 90)),
                           [{"text": "あ", "rect": rect, "form": "schild"}])
        # nahe der Ecke: Oval laesst den Hintergrund, das Schild ist gefuellt
        self.assertEqual(oval.getpixel((340, 260)), (90, 90, 90))
        self.assertEqual(schild.getpixel((340, 260)), lf.SCHILD_FILL)
        # gerade Kontur an der Oberkante
        self.assertEqual(schild.getpixel((560, 241)), lf.SCHILD_LINE)

    def test_no_off_tails_anymore(self):
        self.assertFalse(hasattr(lf, "tail_points"))
        self.assertFalse(hasattr(lf, "OFF_DIRS"))


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

    def test_explicit_line_count(self):
        murmur = "ありがとう… すみません… あめ… かさ… いいえ… だいじょうぶ… えき… みせ…"
        self.assertEqual(lf.wrap(murmur).count("\n"), 2)
        four = lf.shown_text(murmur, 4)
        self.assertEqual(four.split("\n"), ["ありがとう・・・ すみません・・・", "あめ・・・ かさ・・・",
                                            "いいえ・・・ だいじょうぶ・・・", "えき・・・ みせ・・・"])

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
