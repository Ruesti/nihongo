#!/usr/bin/env python3
"""Kontaktbögen der Foto-Runde 1 aus dem abgeholten Ordner (je Format ein Bogen, Seeds aus SEEDS).
Nötig, weil ein Nachlauf auf der Box die dortigen Bögen überschreibt.
Aufruf im Repo-Wurzelverzeichnis: python3 tool/comic/make_sheets.py [build/f01_foto]
→ <ordner>/sheet_quer.png (4 Spalten), <ordner>/sheet_hoch.png (6 Spalten)."""
import glob
import os
import subprocess
import sys

sys.path.insert(0, "tool/comic")
from folge01_motifs import COVERS, PANELS, SEEDS  # noqa: E402


def main(folder="build/f01_foto"):
    for fmt, cols in (("quer", 4), ("hoch", 6)):
        items = []
        for motif in list(PANELS) + list(COVERS):
            for seed in SEEDS:
                hits = sorted(glob.glob(os.path.join(folder, "%s_%s_s%d_*.png" % (motif, fmt, seed))))
                if hits:
                    items.append("%s_s%d=%s" % (motif, seed, hits[0]))
        subprocess.run(["python3", "tool/comic/sheet.py", os.path.join(folder, "sheet_%s.png" % fmt), str(cols)] + items,
                       check=True)
        print(fmt, len(items))


if __name__ == "__main__":
    main(*sys.argv[1:])
