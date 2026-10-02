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

# Hochbild aus dem Querbild (Spec §12.4): was oben und unten an Umgebung dazukommt, wenn der Kern breiter
# als das Hochfenster ist. Nur Umgebung, keine Figuren — die Figuren sind maskiert und bleiben.
HOCH_UMGEBUNG = {
    "p01": "the station platform roof and a grey rainy night sky above, wet platform surface below",
    "p02": "rain-streaked grey air above, wet ground below",
    "p03": "grey evening sky with utility poles and wires above, wet asphalt with reflections below",
    "p04": "grey dusk sky above the arcade roof, wet street with reflections below",
    "p05": "the arcade's glass roof and hanging signs above, wet tiled arcade floor below",
    "p06": "the workshop's ceiling with a bare fluorescent lamp and shelves above, "
           "the workbench legs and the workshop floor below",
    "p07": "the shop's upper facade with windows and a sign above the doorway, wet pavement with reflections below",
    "p08": "the shop's awning and facade above, wet pavement below",
    "p09": "the building's wall and eaves in the rain above, wet pavement below",
    "p10": "grey rain-filled sky above, wet ground below",
    "titel": "a wide open grey rainy night sky above, no roof overhead, wet platform edge below",
}
# Unten (kleiner Rand mit Figuren-Prompt): Beine/Füße laufen weiter, sonst nichts.
HOCH_HINT_UNTEN = (", the figures' legs and feet continue naturally down to the floor, nothing else added "
                   "below them, vertical framing")
NEG_HOCH_UNTEN = (", black bars, letterbox, frame, border, seam, visible edge, duplicate person, second body, "
                  "extra body, doubled figure, cloned figure, extra legs, extra arms, floating torso")
# Oben (großer Rand mit Umgebungs-Prompt): zusätzlich keine Personen — der Kern ist maskiert.
NEG_HOCH_OBEN = NEG_HOCH_UNTEN + ", people, person, human figure, face, character, portrait"

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


# Nachrender der Foto-Runde 1 im Hochformat (28./29.9., Rulings R7/R11), wortgleich mit den damals
# gelaufenen Skripten foto_nachrender{,2,3}.py. Positiv = core + Format-Zusatz + extra + PHOTO,
# Negativ = negative_for(motif) + ", " + neg. format_hint=False: FORMAT_HINT fällt weg (Nachrender 2/3
# liefen ohne ihn). Genutzt über overrides_foto.txt (core=@HOCH_FIX:<name>).
_LETTERBOX_NEG = "black bars, letterbox, letterboxing, black borders, frame, border, empty black areas"
HOCH_FIX = {
    # Nachrender 1, Seeds 703/704 → gepickt s704 (Mira wirklich von hinten).
    "p03": {"core": ("view from directly behind " + P + ", her back to the camera, we see only the back of her "
                     "navy jacket and the back of her black bob haircut, no face visible, she walks away from the "
                     "viewer down an empty wet residential street at night, old wooden houses, utility poles and "
                     "wires against a grey sky, small in the wide scene")},
    # Nachrender 1, Seeds 703/704 → gepickt s703 (Kopf zum abfahrenden Zug gedreht).
    "titel_a": {"core": ("a small rural train platform at night in the rain, " + P + " seen from behind at a "
                         "three-quarter angle, standing still with a travel bag, her head turned to watch a local "
                         "train pulling away, red tail lights, far away the faint lights of a small town, large "
                         "calm empty sky above, wide establishing shot")},
    # Nachrender 2, Seeds 705/706 → gepickt s705 (bildfüllend statt Querbild mit schwarzen Balken).
    # Mit demselben Rezept lief auch p07 hoch (s705/706) — landete im Flur statt an der Ladentür, verworfen.
    "p06": {"core": PANELS["p06"]["core"], "format_hint": False,
            "extra": ("vertical portrait composition filling the entire tall frame from top edge to bottom edge, "
                      "camera close to the figures, ceiling and floor of the room visible"),
            "neg": _LETTERBOX_NEG},
    # Nachrender 3, Seeds 707/708 → gepickt s707 (Ladenfront mit Schild).
    "p07": {"core": ("outside on a wet shopping street at dusk, in the open doorway of a small old shop, " + M +
                     " stands on the threshold and holds out a repaired open transparent umbrella toward " + P +
                     " who stands on the street and reaches to take it, two people clearly visible, emotional "
                     "moment, the tall doorframe and the lit shop interior fill the vertical frame from top to "
                     "bottom, wet pavement in the foreground, shop sign above the door"),
            "format_hint": False, "neg": _LETTERBOX_NEG + ", corridor, hallway"},
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
