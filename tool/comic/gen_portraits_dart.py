#!/usr/bin/env python3
"""Erzeugt lib/features/cafe/cafe_portrait_library.g.dart aus den Ansprache-JPEGs.
Liest assets/comic/cafe/ansprache/*.jpg (Name `{gast}_{stimmung}_{n}_{fmt}.jpg`) und schreibt die
Tabelle `cafePortraitFiles`: '{gast}_{stimmung}' -> Format -> Nummern.
Aufruf: python3 tool/comic/gen_portraits_dart.py (Standardpfade hängen am Repo, nicht am Arbeitsordner)."""
import sys
from pathlib import Path

import cafe_ansprache as ca

REPO = Path(__file__).resolve().parents[2]
ASSET_DIR = REPO / "assets/comic/cafe/ansprache"
OUT = REPO / "lib/features/cafe/cafe_portrait_library.g.dart"

HEADER = ("// GENERIERT von tool/comic/gen_portraits_dart.py — nicht von Hand ändern.\n"
          "/// Vorhandene Ansprache-Bilder: '{gast}_{stimmung}' → Format → Nummern.\n"
          "const Map<String, Map<String, List<int>>> cafePortraitFiles = ")


def _parse(filename):
    """`wirtin_fragend_1_quer.jpg` -> (gast, stimmung, n, fmt); SystemExit bei unbekanntem Namen."""
    stem = filename[:-len(".jpg")]
    parts = stem.split("_")
    try:
        if len(parts) != 4 or not parts[2].isdigit():
            raise ValueError(stem)
        gast, mood, n, fmt = parts[0], parts[1], int(parts[2]), parts[3]
        if ca.name_for(gast, mood, n, fmt) != stem:  # z. B. führende Nullen
            raise ValueError(stem)
    except ValueError:
        raise SystemExit("Unbekannter Dateiname im Ansprache-Ordner: %s" % filename)
    return gast, mood, n, fmt


def main(asset_dir=ASSET_DIR, out=OUT):
    table = {}
    for p in sorted(Path(asset_dir).iterdir()):
        if p.name.startswith("."):
            continue
        if p.suffix != ".jpg":
            raise SystemExit("Fremde Datei im Ansprache-Ordner (nur .jpg erlaubt): %s" % p.name)
        gast, mood, n, fmt = _parse(p.name)
        table.setdefault("%s_%s" % (gast, mood), {}).setdefault(fmt, []).append(n)
    if not table:
        body = "{};\n"
    else:
        lines = []
        for key in sorted(table):
            cells = ", ".join("'%s': [%s]" % (fmt, ", ".join(str(n) for n in sorted(table[key][fmt])))
                              for fmt in sorted(table[key]))
            lines.append("  '%s': {%s}," % (key, cells))
        body = "{\n" + "\n".join(lines) + "\n};\n"
    src = HEADER + body
    out = Path(out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(src, encoding="utf-8")
    return src


if __name__ == "__main__":
    main()
    print(OUT)
