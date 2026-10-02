#!/usr/bin/env python3
"""Nach dem Manga-Vollrender (und allen Nachzügen): Kontaktbogen der 22 Manga-Bilder und
tool/comic/picks_manga.txt (neueste Datei je Key, als Box-Pfad) für folge01_finish.py.
Aufruf im Repo-Wurzelverzeichnis, nachdem ~/comfy_f01/manga/*.png nach build/f01_manga abgeholt ist:
  python3 tool/comic/finish_prep.py ["Kommentarzeile für picks_manga.txt"]
Achtung: „neueste Datei" = höchster Zähler (_00002_ vor _00001_). Liegt ein verworfener Nachzug
noch im Ordner, vorher löschen oder die Zeile in picks_manga.txt von Hand korrigieren."""
import glob
import os
import subprocess
import sys

MANGA = "build/f01_manga"
BOX = "/home/uli/comfy_f01/manga"
KEYS = ["%s_%s" % (m, f) for m in ["p%02d" % i for i in range(1, 11)] + ["titel"] for f in ("quer", "hoch")]


def main(comment="Manga-Picks (neueste Datei je Key)."):
    items, lines, missing = [], ["# " + comment], []
    for key in KEYS:
        hits = sorted(glob.glob(os.path.join(MANGA, "%s_*.png" % key)))
        if not hits:
            missing.append(key)
            continue
        latest = hits[-1]
        items.append("%s=%s" % (key, latest))
        lines.append("%s=%s/%s" % (key, BOX, os.path.basename(latest)))
    if missing:
        raise SystemExit("FEHLT: " + ", ".join(missing))
    subprocess.run(["python3", "tool/comic/sheet.py", os.path.join(MANGA, "sheet_manga.png"), "4"] + items, check=True)
    with open("tool/comic/picks_manga.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(len(lines) - 1, "Picks → tool/comic/picks_manga.txt")


if __name__ == "__main__":
    main(*sys.argv[1:])
