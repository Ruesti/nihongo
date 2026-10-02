#!/usr/bin/env python3
"""Leitet die Hoch-Gesichter aus den Quer-Gesichtern und dem Kern ab (Spec §12.3).
Aufruf im Repo-Wurzelverzeichnis: python3 tool/comic/kern_faces.py
Druckt je Panel eine Zeile `pid faces=[…]` zum Einsetzen unter panels.<pid>.hoch.faces (die Layout-Datei
ist von Hand formatiert und wird nicht automatisch umgeschrieben)."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kern_geometry as kg  # noqa: E402

LAYOUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "folge01_layout.json")


def derive(layout):
    out = {}
    for pid, formats in layout["panels"].items():
        plan = kg.plan_for(layout["kern"][pid])
        out[pid] = kg.hoch_faces(formats["quer"].get("faces", []), plan)
    return out


def main():
    with open(LAYOUT, encoding="utf-8") as f:
        layout = json.load(f)
    for pid, faces in derive(layout).items():
        print("%s faces=%s" % (pid, json.dumps(faces)))


if __name__ == "__main__":
    main()
