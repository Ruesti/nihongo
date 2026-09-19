"""Feste Beschreibungen und Prompts der Café-Bibliothek (Spec Café-Szenen-und-Stimmen
§3.2/§5.6). Die Figurenbeschreibungen werden zwischen Motiven NIE verändert — sie sind
der einzige Identitätsanker im Look A (kein Referenzbild)."""

LORA_STRENGTH = 0.3

CAFE = ("the interior of a small old 1990s cafe, wooden counter, green vinyl booths, "
        "formica tables, net curtains, warm pendant bulbs")
LAND = ("an older landlady in her sixties, grey hair tied back in a low bun, "
        "black short-sleeved dress and a beige apron")
GIRL = ("a small elementary-school girl with a short black bob with bangs, navy sailor "
        "uniform with white stripes and a grey neckerchief, white socks")
MAN = ("a middle-aged man in his forties, short black hair, stubble, "
       "a worn olive-brown work jacket over a dark sweater")
YW = "a young woman with a chin-length black bob, an oversized cream knit sweater"

PHOTO = (", muted desaturated cool grey-green 1990s palette, deep shadows, melancholic, "
         "cinematic, photorealistic film still, realistic detailed human faces, "
         "natural skin texture, 35mm photograph, sharp focus")
NEG = ("anime, manga, cartoon, cel shading, illustration, comic, drawing, flat colors, "
       "stylized, big anime eyes, 2d, painting, text, watermark, letters, oversaturated, "
       "bright, cute, kawaii, blurry, deformed hands, extra fingers, empty, no people, faceless")
NEG_EMPTY = NEG.replace(", empty, no people, faceless", "")

# Neue Tag-Motive (Task 7). Schlüssel = Dateistamm.
TAG_MOTIFS = {
    "wirtin_tisch": CAFE + ", " + LAND + ", sits at a formica table directly across from the viewer, "
                    "a teapot and two cups on the table, looking at the viewer kindly, medium shot",
    "wirtin_tee": CAFE + ", " + LAND + ", stands behind the wooden counter pouring tea from a teapot "
                  "into a cup, seen across the room",
    "schulkind_hausaufgaben": CAFE + ", " + GIRL + ", sits low in a green booth bent over an open "
                              "exercise book, pencil in hand, small in correct perspective",
    "schulkind_kakao": CAFE + ", " + GIRL + ", sits low in a green booth holding a cup of cocoa with "
                       "both hands, looking toward the viewer, small in correct perspective",
    "vielredner_gefaltet": CAFE + ", " + MAN + ", sits in a green booth, a folded newspaper on the "
                           "table, gesturing with one hand mid-sentence, seen across the room",
    "vielredner_fenster": CAFE + ", " + MAN + ", sits in a green booth by the window holding a coffee "
                          "cup, looking out of the window, seen across the room",
    "gleichaltrige_haende": CAFE + ", " + YW + ", sits at a formica table holding a coffee cup in both "
                            "hands, a slight smile toward the viewer",
    "gleichaltrige_fenster": CAFE + ", " + YW + ", sits at a table by the window looking out at the "
                             "rain, a coffee cup on the table",
}

# Die fünf vorhandenen Tag-Bilder (PR #46) — nur für Weg T (Text-zu-Bild je Licht) nötig.
EXISTING_TAG = {
    "leer": CAFE + ", a coffee siphon and an old radio on the counter, empty, quiet, wide interior view",
    "wirtin_tresen": CAFE + ", " + LAND + ", stands behind the counter wiping it with a cloth, clearly visible",
    "schulkind_nische": CAFE + ", " + GIRL + ", sits low in a green booth at a table on the right, "
                        "small in correct perspective",
    "vielredner_zeitung": CAFE + ", " + MAN + ", sits in a green booth reading an open newspaper",
    "gleichaltrige_kaffee": CAFE + ", " + YW + ", sits at a table with a cup of coffee",
}

# Weg R: Umleuchten (Trigger der Relight-LoRA am Anfang).
KEEP = " Keep the same room, same furniture, same people, same poses, same faces."
RELIGHT = {
    "regen": "重新照明, relight this scene as a grey rainy day: dim overcast daylight through the "
             "windows, rain streaks and drops on the window glass, slightly cooler and darker, "
             "the pendant bulbs glowing warm. Rain only outside the windows, no rain inside "
             "the room." + KEEP,
    "abend": "重新照明, relight this scene at evening golden hour: low warm amber sunlight through "
             "the windows, long soft shadows, the pendant bulbs on." + KEEP,
    "nacht": "重新照明, relight this scene at night: dark blue outside the windows, the room lit only "
             "by the warm pendant bulbs, deep shadows, cozy." + KEEP,
}

# Weg T: Licht als Prompt-Zusatz (Rückfall, falls das Gate durchfällt).
T2I_LIGHT = {
    "regen": ", on a grey rainy day, rain streaks on the windows, dim overcast light",
    "abend": ", in the evening, warm amber golden-hour light through the windows, long soft shadows",
    "nacht": ", at night, dark windows, the room lit only by warm pendant bulbs",
}

# Licht-Matrix (Spec §3.2): Raum, Stammplätze und Wirtin am Tisch in allen vier
# Lichtern; Momente nur Tag + Abend.
FULL = ["leer", "wirtin_tresen", "wirtin_tisch", "schulkind_nische",
        "vielredner_zeitung", "gleichaltrige_kaffee"]
MOMENTS = ["wirtin_tee", "schulkind_hausaufgaben", "schulkind_kakao", "vielredner_gefaltet",
           "vielredner_fenster", "gleichaltrige_haende", "gleichaltrige_fenster"]


def lights_for(motif):
    if motif in FULL:
        return ["regen", "abend", "nacht"]
    if motif in MOMENTS:
        return ["abend"]
    raise KeyError(motif)


def negative_for(motif):
    return NEG_EMPTY if motif == "leer" else NEG
