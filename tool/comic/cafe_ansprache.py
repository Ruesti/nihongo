#!/usr/bin/env python3
"""Café-Ansprache-Bilder: Prompt-Tabelle, Stimmungen und Dateinamen.

Datenschicht für die 60 Gästeporträts (4 Gäste x 3 Stimmungen x 5 Varianten,
je in zwei Formaten). Kein ComfyUI-Aufruf, nur Texte und Namen.
Spec: docs/superpowers/specs/2026-10-15-cafe-ansprache-design.md §2.
"""
from cafe_motifs import CAFE, GIRL, LAND, LORA_STRENGTH, MAN, NEG, PHOTO, YW  # noqa: F401
from folge01_motifs import NEG_MANGA, STY

MOODS = ("fragend", "zufrieden", "abwinkend")
FORMATS = {"quer": (1664, 928), "hoch": (928, 1664)}
TARGET = {"quer": (1920, 1072), "hoch": (1080, 1936)}
VARIANTS = 5

# Fester Schluss jeder Edit-Anweisung
_KEEP = ", keep the same person, clothes, pose, lighting, background and framing"

GUESTS = {
    "wirtin": {
        "figure": LAND,
        "place": "behind the wooden counter of the cafe",
        "note": "warm",
        "moods": {
            "zufrieden": "change her expression to a warm satisfied smile with a slight nod" + _KEEP,
            "abwinkend": "change her expression to a kind but disappointed look, head slightly tilted, "
                         "one hand raised in a small dismissive wave" + _KEEP,
        },
    },
    "schulkind": {
        "figure": GIRL,
        "place": "in a green vinyl booth with school notebooks on the table",
        "note": "cheeky, chin forward",
        "moods": {
            "zufrieden": "change her expression to a big cheeky grin, one fist raised in triumph" + _KEEP,
            "abwinkend": "change her expression to rolled eyes and a flat mouth, "
                         "one hand waving the idea away" + _KEEP,
        },
    },
    "vielredner": {
        "figure": MAN,
        "place": "at the window table with a folded newspaper",
        "note": "grumpy, glancing over the newspaper",
        "moods": {
            "zufrieden": "change his expression to a satisfied grunt, a small nod, eyes a little softer" + _KEEP,
            "abwinkend": "change his expression to a frown with furrowed brow, the newspaper lowered" + _KEEP,
        },
    },
    "gleichaltrige": {
        "figure": YW,
        "place": "at a formica table with a cup of coffee",
        "note": "friendly but indifferent",
        "moods": {
            "zufrieden": "change her expression to a brief genuine smile" + _KEEP,
            "abwinkend": "change her expression to a shrug with raised shoulders and a flat mouth" + _KEEP,
        },
    },
}

# Gemeinsamer Kern der Stimmung "fragend"
_KERN = ("looks straight into the camera and speaks to the viewer, mouth slightly open, "
         "eyebrows raised in a question, medium shot from head to hips, alone")
_FORMAT_SATZ = {
    "quer": ", the figure in the left half of the frame, the room continues to the right, wide framing",
    "hoch": ", the face in the upper half of the frame, table or counter in the lower half, vertical framing",
}
_NEG_EXTRA = ", two people, looking away, profile view, closed eyes, back turned"


def _check(gast, stimmung, n, fmt):
    if gast not in GUESTS:
        raise ValueError(f"unbekannter Gast: {gast!r}")
    if stimmung not in MOODS:
        raise ValueError(f"unbekannte Stimmung: {stimmung!r}")
    if fmt not in FORMATS:
        raise ValueError(f"unbekanntes Format: {fmt!r}")
    if not 1 <= n <= VARIANTS:
        raise ValueError(f"Variante außerhalb 1-{VARIANTS}: {n!r}")


def name_for(gast, stimmung, n, fmt):
    _check(gast, stimmung, n, fmt)
    return f"{gast}_{stimmung}_{n}_{fmt}"


def all_names():
    return [name_for(g, m, n, f) for g in GUESTS for m in MOODS
            for n in range(1, VARIANTS + 1) for f in FORMATS]


def t2i_prompt(gast, fmt):
    """Positiv- und Negativ-Prompt für die Stimmung fragend."""
    if gast not in GUESTS:
        raise ValueError(f"unbekannter Gast: {gast!r}")
    if fmt not in FORMATS:
        raise ValueError(f"unbekanntes Format: {fmt!r}")
    g = GUESTS[gast]
    pos = ("shotengai_style, " + CAFE + ", " + g["figure"] + ", " + g["place"] + ", "
           + _KERN + ", " + g["note"] + _FORMAT_SATZ[fmt] + PHOTO)
    return pos, NEG + _NEG_EXTRA


def edit_prompt(gast, stimmung):
    """Edit-Anweisung für zufrieden/abwinkend (fragend ist das Ausgangsbild)."""
    if gast not in GUESTS:
        raise ValueError(f"unbekannter Gast: {gast!r}")
    if stimmung not in GUESTS[gast]["moods"]:
        raise ValueError(f"keine Edit-Anweisung für Stimmung: {stimmung!r}")
    return GUESTS[gast]["moods"][stimmung]


def manga_prompt(gast):
    if gast not in GUESTS:
        raise ValueError(f"unbekannter Gast: {gast!r}")
    g = GUESTS[gast]
    return STY + ", " + g["figure"] + ", " + g["place"], NEG_MANGA
