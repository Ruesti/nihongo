#!/usr/bin/env python3
"""Prototyp-Lettering fuer Folge 01 V2 (Spec Reader-Erleben,
docs/superpowers/plans/2026-09-13-folge01-v2.md, Panel-Bauplan).

Komponiert Sprechblasen + japanischen Text auf die Original-Renders und
erzeugt getoente Reaktions-Varianten fuer die 10 dichten V2-Panels.
Haesslich ist erlaubt — beurteilt wird das Erlebnis, nicht das Artwork.
Idempotent: liest immer die Originale aus SRC, schreibt nach DST.
"""
from PIL import Image, ImageDraw, ImageEnhance, ImageFont

SRC = '/home/uli/.claude/jobs/df1342e0/tmp/final'
DST = 'assets/story'
FONT = '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf'
WIDTH = 1080

# Neue Panel-Nr. -> Quell-Render P## (Panel-Bauplan, Spalte "Quell-Render").
MAPPING = {1: 1, 2: 2, 3: 4, 4: 5, 5: 7, 6: 17, 7: 21, 8: 22, 9: 11, 10: 3}

# Slots (normierte Rechtecke x, y, w, h) aus dem Panel-Bauplan.
S1 = (0.52, 0.05, 0.42, 0.13)   # oben rechts
S2 = (0.06, 0.05, 0.42, 0.13)   # oben links
S2B = (0.06, 0.20, 0.36, 0.11)  # links darunter
M = (0.30, 0.36, 0.40, 0.13)    # mittig

# Panel (neu) -> Liste von (text, slot) — MUSS mit den hitAreas in
# lib/features/story/episodes/folge_01_regen.dart uebereinstimmen.
# P2 und P10 tragen bewusst kein Lettering (keine Bubbles im Bauplan).
BUBBLES = {
    1: [('みなみまち', M)],
    3: [('あめ！', S2), ('あめ、あめ…', S1)],
    4: [('かさ', M)],
    5: [('あめ、あめ！', S2), ('これ？', S2B)],
    6: [('これ、こわれた', S2), ('こわれた、こわれた', S2B),
        ('…こわれた…？', S1)],
    7: [('はい。かさ。どうぞ', S2), ('え？', S1),
        ('どうぞ、どうぞ。かさ！', S2B)],
    8: [('はいはい', S2), ('ありがとう… すみません… あめ… かさ…', S1)],
    9: [('あめやどり', M)],
}
REACTIONS = [2, 5, 8]


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
    for n in range(1, 11):
        img = load(MAPPING[n])
        if n in BUBBLES:
            img = letter(img, BUBBLES[n])
        img.save(f'{DST}/p{n:02d}.jpg', quality=85, optimize=True)
        if n in REACTIONS:
            warm = ImageEnhance.Color(
                ImageEnhance.Brightness(img).enhance(1.12)).enhance(1.25)
            warm.save(f'{DST}/p{n:02d}_reaction.jpg', quality=85,
                      optimize=True)
    print('OK: 10 Panels geletttert/kopiert, '
          f'{len(REACTIONS)} Reaktions-Varianten erzeugt.')


if __name__ == '__main__':
    main()
