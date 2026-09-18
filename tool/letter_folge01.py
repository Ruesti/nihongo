#!/usr/bin/env python3
"""Lettering fuer Folge 01 V2 auf den FINALEN Renders (PR #46).

Quelle der Wahrheit fuer die Bilder ist der Branch comic/folge01-panels;
SRC neu befuellen mit:
  git fetch origin comic/folge01-panels
  git archive origin/comic/folge01-panels assets/comic/folge01 \
    | tar -x --strip-components=2 -C <SRC-Elternverzeichnis>

Komponiert Sprechblasen + japanischen Text und erzeugt getoente
Reaktions-Varianten fuer die 10 dichten V2-Panels. Das Blasen-Lettering
bleibt Skript-Provisorium, bis echtes Lettering Teil der Bild-Produktion
ist. Idempotent: liest immer die Originale aus SRC, schreibt nach DST.
"""
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

SRC = os.environ.get(
    'LETTER_SRC',
    '/home/uli/.claude/jobs/c9abf868/tmp/final_renders/folge01')
EXT = 'jpg'
DST = 'assets/story'
FONT = '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf'
WIDTH = 1080

# Neue Panel-Nr. -> Quell-Render P## (Panel-Bauplan, Spalte "Quell-Render").
MAPPING = {1: 1, 2: 2, 3: 4, 4: 5, 5: 7, 6: 17, 7: 21, 8: 22, 9: 11, 10: 3}

# Slots (normierte Rechtecke x, y, w, h) aus dem Panel-Bauplan.
S1 = (0.52, 0.05, 0.42, 0.13)   # oben rechts
S2 = (0.06, 0.05, 0.42, 0.13)   # oben links
S2B = (0.06, 0.20, 0.43, 0.11)  # links darunter
S1B = (0.56, 0.20, 0.36, 0.11)  # rechts darunter
S2C = (0.06, 0.33, 0.43, 0.10)  # links dritte Zeile
M = (0.30, 0.36, 0.40, 0.13)    # mittig

# Panel (neu) -> Liste von (text, slot) — MUSS mit den hitAreas in
# lib/features/story/episodes/folge_01_regen.dart uebereinstimmen.
# P2 und P10 tragen bewusst kein Lettering (keine Bubbles im Bauplan).
BUBBLES = {
    1: [('みなみまち駅', S2, ('駅', 'えき'))],   # S2 statt M: M lag auf Miras Gesicht
    3: [('あめ！あめ！', S2), ('あめ、あめ… さむい、さむい', S1)],
    4: [('傘', M, ('傘', 'かさ')), ('…あめ', S1)],
    5: [('あめ、あめ！', S2), ('これ？かさ？みせ！', S2B),
        ('ひとり？', (0.06, 0.31, 0.43, 0.09)),   # flacher: Unterkante 0.40 bleibt ueber W's Haaransatz (0.42)
        ('…はい。ひとり', S1)],
    # p06: Kopf des Mannes sitzt oben-mittig zwischen den Spalten -> links
    # schmaler (bis x 0.41), rechts spaeter (ab 0.56), damit keine Ellipse ihn streift.
    6: [('これ、こわれた', (0.04, 0.05, 0.35, 0.13)),
        ('はい、こわれた、こわれた。だめ、だめ', (0.04, 0.20, 0.37, 0.11)),
        ('…こわれた…？', (0.56, 0.05, 0.40, 0.13))],
    # p07: rechte 2. Zeile hoeher (Miras Haaransatz bei y 0.26), linke 3. Zeile
    # hoeher (Kopf des Mannes bei y 0.40); Zeilen dafuer etwas enger gestapelt.
    7: [('はい。かさ。どうぞ', S2), ('え？いくら？いくら？', (0.52, 0.04, 0.42, 0.12)),
        ('いいえ、いいえ。どうぞ、どうぞ。かさ！', (0.06, 0.19, 0.43, 0.10)),
        ('…ほんとう？', (0.56, 0.17, 0.36, 0.08)),
        ('ほんとう。だいじょうぶ、だいじょうぶ', (0.06, 0.30, 0.43, 0.09))],
    8: [('はいはい', S2),
        ('ありがとう… すみません… あめ… かさ… いいえ… だいじょうぶ… えき… みせ…', S1)],
    9: [('あめやどり', M), ('ここ…？あめ…やどり？', S1)],
    10: [('ここ…', S1)],
}
REACTIONS = [2, 5, 8]

# Gesichter (normierte Rechtecke x, y, w, h) — kein Blasen-Slot darf eines
# ueberlappen. Uli: "In einem Bild ueberdeckt die Sprechblase das Gesicht von
# Mira. Das muessen wir ausschliessen." Zonen aus den Renders abgelesen.
FACES = {
    1: [(0.58, 0.20, 0.10, 0.12)],                          # Mira
    5: [(0.62, 0.18, 0.10, 0.14), (0.30, 0.42, 0.10, 0.10)],  # Mira, W
    6: [(0.44, 0.12, 0.09, 0.13)],                          # alter Mann
    7: [(0.15, 0.40, 0.11, 0.12), (0.64, 0.26, 0.10, 0.14)],  # Mann, Mira
    8: [(0.54, 0.20, 0.14, 0.18)],                          # Mira
    9: [(0.38, 0.20, 0.12, 0.14)],                          # Mira
    10: [(0.54, 0.30, 0.16, 0.20)],                         # Mira
}


def _overlaps(slot, face):
    """Blase = Ellipse im Slot-Rechteck. Trifft die Ellipse das Gesichts-Rechteck?
    Naechster Punkt des Rechtecks zum Ellipsen-Mittelpunkt, normiert auf die Radien."""
    sx, sy, sw, sh = slot
    fx, fy, fw, fh = face
    cx, cy, rx, ry = sx + sw / 2, sy + sh / 2, sw / 2, sh / 2
    px = min(max(cx, fx), fx + fw)
    py = min(max(cy, fy), fy + fh)
    return ((px - cx) / rx) ** 2 + ((py - cy) / ry) ** 2 <= 1.0


def check_faces():
    """Bricht ab, wenn ein Blasen-Slot ein Gesicht ueberlappt."""
    bad = []
    for n, bubbles in BUBBLES.items():
        for entry in bubbles:
            slot = entry[1]
            for face in FACES.get(n, []):
                if _overlaps(slot, face):
                    bad.append((n, entry[0], slot, face))
    if bad:
        for n, text, slot, face in bad:
            print(f'GESICHT VERDECKT: p{n:02d} "{text}" slot={slot} face={face}')
        raise SystemExit('Lettering abgebrochen: Blase ueber Gesicht.')


def load(n):
    img = Image.open(f'{SRC}/P{n:02d}.{EXT}').convert('RGB')
    w, h = img.size
    return img.resize((WIDTH, int(h * WIDTH / w)), Image.LANCZOS)


def wrap(text):
    """Lange Blasen auf zwei Zeilen: an Leerzeichen, sonst nach dem ersten
    Satzpunkt in der Mitte. Kurze Texte bleiben einzeilig."""
    if len(text) <= 9:
        return text
    if ' ' in text:
        parts = text.split(' ')
        n = 3 if len(parts) >= 6 else 2  # sehr lange Zeilen (Uebungs-Murmeln) dreizeilig
        per = -(-len(parts) // n)
        return '\n'.join(' '.join(parts[i:i + per]) for i in range(0, len(parts), per))
    dots = [i for i, c in enumerate(text[:-1]) if c == '。']
    if dots:
        i = min(dots, key=lambda d: abs(d - len(text) / 2))  # mittigster Satzpunkt
        return text[:i + 1] + '\n' + text[i + 1:]
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
    for entry in bubbles:
        text, (x, y, w, h) = entry[0], entry[1]
        furi = entry[2] if len(entry) > 2 else None  # (kanji, lesung)
        box = (x * W, y * H, (x + w) * W, (y + h) * H)
        draw.ellipse(box, fill='white', outline='black', width=4)
        # Font hat weder U+2026 noch den ASCII-Punkt — nur ・ existiert (Manga-Konvention).
        shown = wrap(text.replace('…', '・・・'))
        reserve = (box[3] - box[1]) * 0.22 if furi else 0
        font = fit_font(draw, shown, (box[2] - box[0]), (box[3] - box[1]), reserve)
        l, t, r, b = draw.multiline_textbbox((0, 0), shown, font=font)
        cx = (box[0] + box[2]) / 2 - (r - l) / 2 - l
        cy = (box[1] + box[3]) / 2 - (b - t) / 2 - t + reserve / 2
        draw.multiline_text((cx, cy), shown, fill='black', font=font, align='center')
        if furi:
            # Furigana: kleine Lesung ueber dem Kanji (Anfaenger-Manga-Konvention).
            kanji, reading = furi
            small = ImageFont.truetype(FONT, max(10, font.size // 2))
            pre = shown[:shown.index(kanji)]
            kx = cx + draw.textlength(pre, font=font)
            kw = draw.textlength(kanji, font=font)
            rw = draw.textlength(reading, font=small)
            draw.text((kx + kw / 2 - rw / 2, cy + t - small.size - 2), reading,
                      fill='black', font=small)
    return img


def main():
    check_faces()
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
