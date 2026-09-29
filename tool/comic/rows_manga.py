#!/usr/bin/env python3
"""rows.json für die Vergleichsseite der Runde 2 (Manga): je Motiv eine Zeile
Foto quer | Manga quer | Foto hoch | Manga hoch.
Aufruf im Repo-Wurzelverzeichnis (nach dem Abholen der Manga-Bilder nach build/f01_manga):
  python3 tool/comic/rows_manga.py [picks_foto.txt] [foto_ordner] [manga_ordner]
Voreinstellung: tool/comic/picks_foto.txt build/f01_foto build/f01_manga → build/f01_manga/rows.json.
Danach: python3 tool/comic/review_page.py build/f01_manga/runde2.html "Folge 01 · Runde 2" build/f01_manga/rows.json"""
import glob
import json
import os
import sys

LABELS = {"p01": "Bahnsteig", "p02": "Zettel", "p03": "Straße, von hinten", "p04": "Arkade", "p05": "Arkade, Frau",
          "p06": "Werkstatt", "p07": "Schirm-Übergabe", "p08": "Verbeugung", "p09": "Anschlagtafel", "p10": "Mira nah",
          "titel": "Titelbild"}
NOTE = {m: "Mira nachdenklich statt traurig? Schirm ohne Flecken?" for m in ("p07", "p08", "p10")}


def read_picks(path, local):
    picks = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                k, v = line.split("=", 1)
                picks[k.strip()] = os.path.join(local, os.path.basename(v.strip()))
    return picks


def main(picks_path="tool/comic/picks_foto.txt", foto="build/f01_foto", manga="build/f01_manga"):
    picks = read_picks(picks_path, foto)
    rows = []
    for motif in ["p%02d" % i for i in range(1, 11)] + ["titel"]:
        items = []
        for fmt in ("quer", "hoch"):
            key = "%s_%s" % (motif, fmt)
            hits = sorted(glob.glob(os.path.join(manga, "%s_*.png" % key)))
            items.append({"label": "Foto %s" % fmt, "path": picks.get(key, "fehlt")})
            items.append({"label": "Manga %s" % fmt, "path": hits[-1] if hits else "fehlt"})
        rows.append({"label": "%s · %s" % (motif, LABELS[motif]), "items": items, "note": NOTE.get(motif, "")})
    out = os.path.join(manga, "rows.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(rows, f, ensure_ascii=False, indent=1)
    print(out, len(rows), "Zeilen")


if __name__ == "__main__":
    main(*sys.argv[1:])
