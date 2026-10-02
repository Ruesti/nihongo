#!/usr/bin/env python3
"""Balken-Check: findet schwarze Balken am Bildrand (Querkomposition in hoher Leinwand o. ä.).
  python3 tool/comic/check_bars.py assets/story/folge01           → alle Bilder im Ordner
  python3 tool/comic/check_bars.py tool/comic/picks_foto.txt build/f01_foto
      → je Key der Picks-Datei; mit zweitem Argument wird der Dateiname dort gesucht (Box-Pfade)
Gemessen wird je Bild: quer (breiter als hoch) → ganz schwarze Spalten (Mittel < 8) am linken und
rechten Rand; hoch → ganz schwarze Zeilen oben und unten. Gezählt wird nur zusammenhängend vom
Rand her; ein schmaler heller Saum (≤ 1 %) direkt am Rand vor dem Balken zählt mit. Ausgabe je Zeile
`key <prozent>`; Exit 1, wenn ein Bild über 5 % liegt.
Am besten VOR dem Lettering prüfen (Foto-Picks, build/f01_raw): Blasen, die in einem Balken sitzen,
unterbrechen den Balken und drücken den Wert bei gelettertem Material nach unten."""
import os
import sys

from PIL import Image

BLACK = 8        # Mittelwert (0..255) einer Spalte/Zeile, unter dem sie als schwarz gilt
LIMIT = 5.0      # Prozent der Breite (quer) bzw. Höhe (hoch)
EXTS = (".jpg", ".jpeg", ".png")


FRINGE = 0.01    # bis 1 % nicht ganz schwarzer Saum direkt am Rand (Hochskalier-Überschwinger) wird
                 # übersprungen und mitgezählt, wenn dahinter der Balken beginnt


def _edge_run(means, fringe):
    start = 0
    while start < min(fringe, len(means)) and means[start] >= BLACK:
        start += 1
    if start and (start == len(means) or means[start] >= BLACK):
        start = 0  # kein Balken hinter dem Saum → Saum zählt nicht
    n = start
    for m in means[start:]:
        if m >= BLACK:
            break
        n += 1
    return 0 if n == start else n


def bar_percent(img):
    """Anteil schwarzer Rand-Spalten (quer) bzw. -Zeilen (hoch) in Prozent."""
    g = img.convert("L")
    w, h = g.size
    if w >= h:
        means = list(g.resize((w, 1), Image.BOX).getdata())
    else:
        means = list(g.resize((1, h), Image.BOX).getdata())
    fringe = max(2, int(len(means) * FRINGE))
    lead = _edge_run(means, fringe)
    if lead >= len(means):
        return 100.0
    return min(100.0, 100.0 * (lead + _edge_run(means[::-1], fringe)) / len(means))


def items_from(arg, local=None):
    """[(key, pfad)] aus einem Ordner oder einer Picks-Datei (key=pfad je Zeile)."""
    if os.path.isdir(arg):
        return [(os.path.splitext(f)[0], os.path.join(arg, f)) for f in sorted(os.listdir(arg))
                if f.lower().endswith(EXTS)]
    out = []
    with open(arg, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            key, src = line.split("=", 1)
            src = os.path.expanduser(src.strip())
            if local:
                src = os.path.join(local, os.path.basename(src))
            out.append((key.strip(), src))
    return out


def main(argv):
    if not argv:
        raise SystemExit(__doc__)
    bad = []
    for key, path in items_from(argv[0], argv[1] if len(argv) > 1 else None):
        with Image.open(path) as img:
            pct = bar_percent(img)
        print("%s %.1f" % (key, pct))
        if pct > LIMIT:
            bad.append(key)
    if bad:
        print("BALKEN > %.0f %%: %s" % (LIMIT, ", ".join(bad)))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
