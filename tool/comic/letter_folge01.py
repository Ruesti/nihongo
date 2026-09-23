#!/usr/bin/env python3
"""Lettering fuer Folge 01 aus EINER Layout-Datei (Spec Manga-Vollbild §4.4, INV-14/15).
Quelle: build/f01_raw/<pid>_<fmt>.jpg (Task 4). Ziel: assets/story/folge01/.
Idempotent; bricht bei Gesichts- oder Zonen-Verstoss ab, ohne etwas zu schreiben.
Aufruf im Repo-Wurzelverzeichnis: python3 tool/comic/letter_folge01.py"""
import json
import os
import shutil

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
LAYOUT = os.path.join(HERE, "folge01_layout.json")
SRC = os.environ.get("LETTER_SRC", "build/f01_raw")
DST = "assets/story/folge01"
FONT = "/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf"


def out_name(pid, fmt, reaction=False):
    return pid + ("_reaction" if reaction else "") + ("_hoch" if fmt == "hoch" else "") + ".jpg"


def _overlaps(slot, face):
    sx, sy, sw, sh = slot
    fx, fy, fw, fh = face
    cx, cy, rx, ry = sx + sw / 2, sy + sh / 2, sw / 2, sh / 2
    px = min(max(cx, fx), fx + fw)
    py = min(max(cy, fy), fy + fh)
    return ((px - cx) / rx) ** 2 + ((py - cy) / ry) ** 2 <= 1.0


def _in_safe_zone(rect, fmt, safe):
    lo, hi = (1 - safe) / 2, 1 - (1 - safe) / 2
    x, y, w, h = rect
    if fmt == "quer":      # oben/unten beschnitten
        return lo <= y and y + h <= hi
    return lo <= x and x + w <= hi  # hoch: links/rechts beschnitten


def check_layout(layout):
    msgs = []
    safe = layout.get("safe", 0.8)
    for pid, formats in layout["panels"].items():
        for fmt, spec in formats.items():
            for b in spec.get("bubbles", []):
                for face in spec.get("faces", []):
                    if _overlaps(b["rect"], face):
                        msgs.append("GESICHT VERDECKT %s %s %r rect=%s face=%s" % (pid, fmt, b["text"], b["rect"], face))
                if not _in_safe_zone(b["rect"], fmt, safe):
                    msgs.append("SICHERE ZONE %s %s %r rect=%s" % (pid, fmt, b["text"], b["rect"]))
    return msgs


def wrap(text):
    if len(text) <= 9:
        return text
    if " " in text:
        parts = text.split(" ")
        n = 3 if len(parts) >= 6 else 2
        per = -(-len(parts) // n)
        return "\n".join(" ".join(parts[i:i + per]) for i in range(0, len(parts), per))
    dots = [i for i, c in enumerate(text[:-1]) if c == "。"]
    if dots:
        i = min(dots, key=lambda d: abs(d - len(text) / 2))
        return text[:i + 1] + "\n" + text[i + 1:]
    return text


def fit_font(draw, text, box_w, box_h, reserve_top=0):
    size = int(box_h * 0.55)
    while size > 10:
        font = ImageFont.truetype(FONT, size)
        l, t, r, b = draw.multiline_textbbox((0, 0), text, font=font)
        if r - l <= box_w * 0.86 and b - t <= box_h * 0.72 - reserve_top:
            return font
        size -= 2
    return ImageFont.truetype(FONT, 10)


def letter(img, bubbles):
    draw = ImageDraw.Draw(img)
    W, H = img.size
    for b in bubbles:
        x, y, w, h = b["rect"]
        furi = b.get("furigana")
        box = (x * W, y * H, (x + w) * W, (y + h) * H)
        draw.ellipse(box, fill="white", outline="black", width=4)
        shown = wrap(b["text"].replace("…", "・・・"))
        reserve = (box[3] - box[1]) * 0.22 if furi else 0
        font = fit_font(draw, shown, box[2] - box[0], box[3] - box[1], reserve)
        l, t, r, bb = draw.multiline_textbbox((0, 0), shown, font=font)
        cx = (box[0] + box[2]) / 2 - (r - l) / 2 - l
        cy = (box[1] + box[3]) / 2 - (bb - t) / 2 - t + reserve / 2
        draw.multiline_text((cx, cy), shown, fill="black", font=font, align="center")
        if furi:
            kanji, reading = furi
            small = ImageFont.truetype(FONT, max(10, font.size // 2))
            pre = shown[:shown.index(kanji)]
            kx = cx + draw.textlength(pre, font=font)
            kw = draw.textlength(kanji, font=font)
            rw = draw.textlength(reading, font=small)
            draw.text((kx + kw / 2 - rw / 2, cy + t - small.size - 2), reading, fill="black", font=small)
    return img


def main():
    with open(LAYOUT, encoding="utf-8") as f:
        layout = json.load(f)
    problems = check_layout(layout)
    if problems:
        print("\n".join(problems))
        raise SystemExit("Lettering abgebrochen (%d Verstösse)." % len(problems))
    os.makedirs(DST, exist_ok=True)
    n = 0
    for pid, formats in layout["panels"].items():
        for fmt, spec in formats.items():
            img = Image.open(os.path.join(SRC, "%s_%s.jpg" % (pid, fmt))).convert("RGB")
            img = letter(img, spec.get("bubbles", []))
            img.save(os.path.join(DST, out_name(pid, fmt)), quality=88, optimize=True)
            n += 1
            if pid in layout.get("reactions", []):
                warm = ImageEnhance.Color(ImageEnhance.Brightness(img).enhance(1.12)).enhance(1.25)
                warm.save(os.path.join(DST, out_name(pid, fmt, reaction=True)), quality=88, optimize=True)
                n += 1
    for fmt in ("quer", "hoch"):
        shutil.copy(os.path.join(SRC, "titel_%s.jpg" % fmt), os.path.join(DST, out_name("titel", fmt)))
        n += 1
    print("OK: %d Dateien nach %s" % (n, DST))


if __name__ == "__main__":
    main()
