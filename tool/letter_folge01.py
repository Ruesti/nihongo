#!/usr/bin/env python3
"""Prototyp-Lettering fuer Folge 01 (Spec Reader-Erleben §4).

Komponiert Sprechblasen + japanischen Text auf die Original-Renders und
erzeugt getoente Reaktions-Varianten. Haesslich ist erlaubt — beurteilt
wird das Erlebnis, nicht das Artwork. Idempotent: liest immer die
Originale aus SRC, schreibt nach DST.
"""
from PIL import Image, ImageDraw, ImageEnhance, ImageFont

SRC = '/home/uli/.claude/jobs/df1342e0/tmp/final'
DST = 'assets/story'
FONT = '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf'
WIDTH = 1080

# Panel -> Liste von (text, (x, y, w, h)) — MUSS mit den hitAreas in
# lib/features/story/episodes/folge_01_regen.dart uebereinstimmen.
BUBBLES = {
    7:  [('すみません', (0.52, 0.05, 0.42, 0.14))],
    8:  [('はい？', (0.06, 0.05, 0.36, 0.13))],
    11: [('あめ', (0.32, 0.36, 0.30, 0.14))],
    17: [('これ、こわれた', (0.06, 0.05, 0.46, 0.14))],
    18: [('これ… こわれた…？', (0.48, 0.05, 0.46, 0.14))],
    19: [('はい', (0.06, 0.05, 0.30, 0.12))],
    20: [('ありがとう', (0.52, 0.05, 0.42, 0.13))],
    21: [('はい。かさ。どうぞ', (0.06, 0.05, 0.50, 0.14))],
    22: [('ありがとう… すみません', (0.44, 0.05, 0.50, 0.14))],
    23: [('かさ…', (0.56, 0.05, 0.38, 0.12))],
    24: [('あめ', (0.30, 0.34, 0.32, 0.14))],
}
REACTIONS = [7, 22, 24]


def load(n):
    img = Image.open(f'{SRC}/P{n:02d}.png').convert('RGB')
    w, h = img.size
    return img.resize((WIDTH, int(h * WIDTH / w)), Image.LANCZOS)


def fit_font(draw, text, box_w, box_h):
    size = int(box_h * 0.55)
    while size > 10:
        font = ImageFont.truetype(FONT, size)
        l, t, r, b = draw.textbbox((0, 0), text, font=font)
        if r - l <= box_w * 0.86 and b - t <= box_h * 0.7:
            return font
        size -= 2
    return ImageFont.truetype(FONT, 10)


def letter(img, bubbles):
    draw = ImageDraw.Draw(img)
    W, H = img.size
    for text, (x, y, w, h) in bubbles:
        box = (x * W, y * H, (x + w) * W, (y + h) * H)
        draw.ellipse(box, fill='white', outline='black', width=4)
        font = fit_font(draw, text, (box[2] - box[0]), (box[3] - box[1]))
        l, t, r, b = draw.textbbox((0, 0), text, font=font)
        cx = (box[0] + box[2]) / 2 - (r - l) / 2 - l
        cy = (box[1] + box[3]) / 2 - (b - t) / 2 - t
        draw.text((cx, cy), text, fill='black', font=font)
    return img


def main():
    for n in range(1, 25):
        img = load(n)
        if n in BUBBLES:
            img = letter(img, BUBBLES[n])
        img.save(f'{DST}/p{n:02d}.jpg', quality=85, optimize=True)
        if n in REACTIONS:
            warm = ImageEnhance.Color(
                ImageEnhance.Brightness(img).enhance(1.12)).enhance(1.25)
            warm.save(f'{DST}/p{n:02d}_reaction.jpg', quality=85,
                      optimize=True)
    print('OK: 24 Panels geletttert/kopiert, '
          f'{len(REACTIONS)} Reaktions-Varianten erzeugt.')


if __name__ == '__main__':
    main()
