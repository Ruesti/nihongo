#!/usr/bin/env python3
"""rows.json für die Vergleichsseite der Foto-Runde 1 (Spec §6 Runde 1) aus einem Ordner
mit den abgeholten Renders bauen:  rows_foto.py build/f01_foto build/f01_foto/rows.json
Je Motiv eine Zeile: quer s701 | quer s702 | hoch s701 | hoch s702, dazu die Prüfliste."""
import glob
import json
import os
import sys

from folge01_motifs import COVERS, PANELS, SEEDS

LABELS = {
    "p01": "Bahnsteig, Mira allein im Regen", "p02": "Hand mit dem verlaufenen Zettel",
    "p03": "Mira von hinten, nasse Straße", "p04": "Eingang der Arkade (ohne Menschen)",
    "p05": "Arkade: Mira hebt die Hand, ältere Frau kommt", "p06": "Der alte Mann in der Werkstatt",
    "p07": "Schirm-Übergabe an der Ladentür", "p08": "Mira verbeugt sich mit Schirm",
    "p09": "Mira blickt in den Regen, Anschlagtafel", "p10": "Mira nah, Regen im Haar",
    "titel_a": "Titelbild a: Zug fährt ab, Lichter fern", "titel_b": "Titelbild b: klein unterm Dach, Regenvorhang",
    "titel_c": "Titelbild c: Hand mit Zettel, drei Zeilen",
}
CHECK = {
    "p03": "Prüfliste: trägt Mira die dunkle Jacke?", "p06": "Prüfliste: liegt der kaputte Schirm auf der Werkbank?",
    "p09": "Prüfliste: steht Mira draußen im Regen?",
}


def main(folder, out):
    rows = []
    for motif in list(PANELS) + list(COVERS):
        items = []
        for fmt in ("quer", "hoch"):
            for seed in SEEDS:
                hits = sorted(glob.glob(os.path.join(folder, "%s_%s_s%d_*.png" % (motif, fmt, seed))))
                items.append({"label": "%s s%d" % (fmt, seed), "path": hits[0] if hits else os.path.join(folder, "fehlt.png")})
        note = CHECK.get(motif, "Keine Schrift im Bild? Gesicht und Kleidung wie beschrieben?")
        rows.append({"label": "%s · %s" % (motif, LABELS.get(motif, motif)), "note": note, "items": items})
    json.dump(rows, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(out, len(rows), "Zeilen")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
