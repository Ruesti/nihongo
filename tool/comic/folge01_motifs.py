#!/usr/bin/env python3
"""Feste Prompt-Bausteine für Folge 01 (Spec Manga-Vollbild §2.2/§4.1).
Quelle der Panel-Prompts: folge01_A.py / folge01_fix.py (Look A, 12.9.),
Zuordnung Reader-Panel → Quell-Render aus tool/letter_folge01.py (MAPPING)."""

FIG = {
    "P": ("a young woman in her early twenties, short straight black bob haircut, pale skin, "
          "slender, dark navy jacket over a pale blouse, dark skirt"),
    "M": ("an elderly man in his seventies, thin grey hair, wire-rim glasses, grey cardigan, "
          "gentle weathered face"),
    "W": "an older woman in her sixties, short greying hair, beige cardigan, holding a shopping bag",
}
P, M, W = FIG["P"], FIG["M"], FIG["W"]

# Foto-Pass (Look A): LoRA 0,3 + Foto-Zusatz + Anti-Anime-Negativ.
LORA_PHOTO = 0.3
PHOTO = (", muted desaturated cool grey-green 1990s palette, deep shadows, melancholic, "
         "cinematic, photorealistic film still, realistic detailed human faces, "
         "natural skin texture, 35mm photograph, sharp focus")
NEG_PHOTO = ("anime, manga, cartoon, cel shading, illustration, comic, drawing, flat colors, "
             "stylized, big anime eyes, 2d, painting, text, watermark, letters, oversaturated, "
             "bright, cute, kawaii, blurry, deformed hands, extra fingers, empty, no people, faceless")
NEG_PHOTO_DET = NEG_PHOTO.replace(", empty, no people, faceless", "")

# Manga-Pass: Stil-Prompt + Panel-Inhalt; Negativ OHNE Anti-Anime.
STY = ("muted painterly 1990s manga illustration, hand-drawn linework, deep shadows, "
       "melancholic, atmospheric")
NEG_MANGA = ("photo, photorealistic, text, watermark, oversaturated, bright, cute, kawaii, "
             "blurry, deformed hands, extra fingers, distorted face")
UMBRELLA_FIX = ", clean transparent umbrella without stains"

FORMATS = {"quer": (1664, 928), "hoch": (928, 1664)}
FORMAT_HINT = {"quer": ", wide cinematic framing", "hoch": ", vertical framing, tall composition"}
SEEDS = (701, 702)

PANELS = {
    "p01": {"src": "P01", "kind": "fig", "core":
            "a small rural train platform at night in the rain, rain slanting through a neon light, "
            "wet platform, distant hills, a station sign, " + P + ", standing small and alone with a "
            "travel bag, head lowered, wide establishing shot"},
    "p02": {"src": "P02", "kind": "det", "core":
            "close-up of a hand holding a handwritten paper note, ink bleeding and running in the rain, "
            "no face, shallow focus"},
    "p03": {"src": "P04", "kind": "fig", "core":
            P + ", wearing her dark navy jacket, seen from behind walking away down an empty wet "
            "residential street at night, old wooden houses, utility poles and wires against a grey sky, "
            "small in the wide scene"},
    "p04": {"src": "P05", "kind": "det", "core":
            "the arched entrance of a covered shopping arcade seen from outside at dusk, rain on the roof, "
            "hanging signs, warm light inside, no people, establishing wide shot"},
    "p05": {"src": "P07", "kind": "fig", "core":
            "in a covered shopping arcade, in the foreground " + P + " raises her hand to get attention, "
            "and " + W + " walks toward her; two people clearly visible"},
    "p06": {"src": "P17", "kind": "fig", "core":
            M + ", stands in a small repair workshop, turned around, pointing at a broken umbrella lying "
            "on the workbench, full upper body, tools and workbench around him"},
    "p07": {"src": "P21", "kind": "fig", "core":
            "at a small shop doorway, " + M + " holds out a repaired open transparent umbrella toward " + P +
            " who reaches to take it, two people clearly visible, emotional moment"},
    "p08": {"src": "P22", "kind": "fig", "core":
            P + ", at a shop doorway holds a transparent umbrella in both hands and bows slightly in thanks"},
    "p09": {"src": "P11", "kind": "fig", "core":
            "low angle view of " + P + " standing outside in the street looking up into the falling rain, "
            "wet face, a weather notice board on the wall behind her"},
    "p10": {"src": "P03", "kind": "fig", "core":
            "a close-up portrait of " + P + ", rain in her hair, eyes lowered, melancholic and thoughtful"},
}

# Titelbild-Motive (Spec §6): ruhige Fläche oben (quer) bzw. unten (hoch) für den Titel.
COVERS = {
    "titel_a": ("a small rural train platform at night in the rain, " + P + " seen from behind, standing "
                "still with a travel bag as a local train pulls away, red tail lights, far away the faint "
                "lights of a small town, large calm empty sky above, wide establishing shot"),
    "titel_b": ("a small rural train platform at night, " + P + " small under the platform roof, a suitcase "
                "beside her, a curtain of heavy rain in front, dim neon, large calm empty area in the "
                "composition, wide shot"),
    "titel_c": ("close-up of a young woman's hand holding a handwritten paper note with three lines of "
                "running ink in the rain, no face, shallow focus, dark calm background with empty space"),
}


def motifs():
    """Alle 13 Motive → Prompt-Kern (Panels + Titelbilder)."""
    out = {pid: p["core"] for pid, p in PANELS.items()}
    out.update(COVERS)
    return out


def negative_for(motif):
    kind = PANELS.get(motif, {}).get("kind")
    if kind == "det" or motif == "titel_c":
        return NEG_PHOTO_DET
    return NEG_PHOTO
