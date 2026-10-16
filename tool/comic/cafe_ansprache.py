#!/usr/bin/env python3
"""Café-Ansprache-Bilder: Prompt-Tabelle, Stimmungen und Dateinamen.

Datenschicht für die 60 Gästeporträts (4 Gäste x 3 Stimmungen x 5 Varianten,
je in zwei Formaten). Kein ComfyUI-Aufruf, nur Texte und Namen.
Spec: docs/superpowers/specs/2026-10-15-cafe-ansprache-design.md §2.
"""
import glob
import os
import shutil
from pathlib import Path

import comfy_client as cc
import folge01_manga
from cafe_motifs import CAFE, GIRL, LAND, LORA_STRENGTH, MAN, NEG, PHOTO, YW  # noqa: F401
from folge01_motifs import NEG_MANGA, STY

ROOT = Path("~/comfy_cafe_ansprache").expanduser()  # Unterordner foto, edit, manga, final, sheets
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


def load_picks(path):
    """Liest die Picks (Runde 1): Zeilen `{gast}_{fmt}_{n}=/pfad/foto.png`, n = 1..VARIANTS.
    `#` und Leerzeilen zählen nicht, `~` wird aufgelöst. Gibt Schlüssel → Pfad zurück.
    ValueError (mit der Zeile) bei falschem Schlüssel, doppelter Nummer oder fehlender Datei."""
    picks = {}
    with open(os.path.expanduser(path), encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            key, _, value = line.partition("=")
            key, value = key.strip(), os.path.expanduser(value.strip())
            parts = key.split("_")
            if (len(parts) != 3 or parts[0] not in GUESTS or parts[1] not in FORMATS
                    or not parts[2].isdigit() or not 1 <= int(parts[2]) <= VARIANTS):
                raise ValueError("Schlüssel ungültig (erwartet {gast}_{fmt}_{n}): %s" % line)
            if key in picks:
                raise ValueError("Nummer doppelt in derselben Zelle: %s" % line)
            if not os.path.isfile(value):
                raise ValueError("Datei fehlt: %s (Zeile: %s)" % (value, line))
            picks[key] = value
    return picks


def cells_missing(picks):
    """Zellen `{gast}_{fmt}` mit weniger als VARIANTS Picks, in Reihenfolge Gast, Format."""
    return [f"{g}_{fmt}" for g in GUESTS for fmt in FORMATS
            if sum(1 for n in range(1, VARIANTS + 1) if f"{g}_{fmt}_{n}" in picks) < VARIANTS]


def load_overrides(path):
    """Nachbesserungen je Bild; Schlüssel = voller Name `{gast}_{stimmung}_{n}_{fmt}`."""
    return folge01_manga.load_overrides(path, allowed={"seed", "extra", "force"})


def _skip_existing(prefix, out):
    return bool(glob.glob(os.path.join(glob.escape(str(out)), glob.escape(prefix) + "_*")))


def _with_extra(text, opts):
    return text + ", " + opts["extra"] if opts.get("extra") else text


def _run_all(jobs):
    """jobs: (prefix, Funktion) -> alle erzeugten Pfade; ein Fehler bricht den Lauf nicht ab."""
    done = []
    for prefix, job in jobs:
        try:
            done += [Path(p) for p in job()]
            print("OK", prefix, flush=True)
        except Exception as e:  # noqa: BLE001
            print("ERR %s: %r" % (prefix, e), flush=True)
    return done


def _parse_key(key):
    """`{gast}_{fmt}_{n}` -> (gast, fmt, n); ValueError bei ungültigem Schlüssel."""
    parts = key.split("_")
    if len(parts) != 3 or not parts[2].isdigit():
        raise ValueError("Schlüssel ungültig (erwartet {gast}_{fmt}_{n}): %r" % key)
    gast, fmt, n = parts[0], parts[1], int(parts[2])
    name_for(gast, "fragend", n, fmt)  # prüft Gast, Format und Nummer
    return gast, fmt, n


def render_fragend(guests, fmts, seeds, out=ROOT / "foto"):
    """Runde 1: Text-zu-Bild je Gast/Format/Seed; vorhandene Ausgaben werden übersprungen."""
    def make(gast, fmt, seed, prefix):
        pos, neg = t2i_prompt(gast, fmt)
        w, h = FORMATS[fmt]
        return lambda: cc.run(cc.t2i_graph(pos, neg, seed, prefix, LORA_STRENGTH, w, h), prefix, out)
    jobs = []
    for gast in guests:
        for fmt in fmts:
            for seed in seeds:
                prefix = "%s_fragend_%s_s%d" % (gast, fmt, seed)
                if _skip_existing(prefix, out):
                    print("SKIP", prefix, flush=True)
                    continue
                jobs.append((prefix, make(gast, fmt, seed, prefix)))
    return _run_all(jobs)


def render_edits(picks, seed=21, out=ROOT / "edit", overrides=None):
    """Runde 2: je Pick zwei Edits (zufrieden, abwinkend) aus dem Foto der Stimmung fragend."""
    overrides = overrides or {}

    def make(key, src, gast, mood, prefix, opts):
        def job():
            input_name = "ans_%s.png" % key
            shutil.copy(src, os.path.join(cc.COMFY_INPUT, input_name))
            graph = cc.edit_graph(input_name, _with_extra(edit_prompt(gast, mood), opts),
                                  opts.get("seed", seed), prefix, negative=NEG)
            return cc.run(graph, prefix, out)
        return job
    jobs = []
    for key, src in picks.items():
        try:
            gast, fmt, n = _parse_key(key)
        except ValueError as e:
            print("ERR %s: %r" % (key, e), flush=True)
            continue
        for mood in ("zufrieden", "abwinkend"):
            prefix = name_for(gast, mood, int(n), fmt)
            opts = overrides.get(prefix, {})
            if folge01_manga.should_skip(prefix, str(out), opts):
                print("SKIP", prefix, flush=True)
                continue
            jobs.append((prefix, make(key, src, gast, mood, prefix, opts)))
    return _run_all(jobs)


def render_manga(sources, out=ROOT / "manga", overrides=None):
    """Runde 3: Manga-Durchgang je Foto; sources = Name `{gast}_{stimmung}_{n}_{fmt}` -> Pfad."""
    overrides = overrides or {}

    def make(name, src, gast, opts):
        def job():
            input_name = "ansm_%s.png" % name
            shutil.copy(src, os.path.join(cc.COMFY_INPUT, input_name))
            pos, neg = manga_prompt(gast)
            graph = cc.manga_graph(input_name, _with_extra(pos, opts), neg, opts.get("seed", 831), name)
            return cc.run(graph, name, out)
        return job
    jobs = []
    for name, src in sources.items():
        if name.split("_")[0] not in GUESTS:
            print("ERR %s: %r" % (name, ValueError("unbekannter Gast")), flush=True)
            continue
        opts = overrides.get(name, {})
        if folge01_manga.should_skip(name, str(out), opts):
            print("SKIP", name, flush=True)
            continue
        jobs.append((name, make(name, src, name.split("_")[0], opts)))
    return _run_all(jobs)


def edit_outputs(out=ROOT / "edit"):
    """Name -> neueste Datei je Prefix `{gast}_{stimmung}_{n}_{fmt}` im Edit-Ordner."""
    best = {}
    for p in Path(out).glob("*.png"):
        for name in all_names():
            if p.name.startswith(name + "_"):
                # neueste mtime gewinnt, bei Gleichstand der lexikalisch größere Name
                if name not in best or (p.stat().st_mtime, p.name) > (best[name].stat().st_mtime, best[name].name):
                    best[name] = p
    return {k: str(v) for k, v in sorted(best.items())}


def fragend_sources(picks):
    """Picks `{gast}_{fmt}_{n}` -> Manga-Quellen mit Schlüssel `name_for(gast, "fragend", n, fmt)`."""
    out = {}
    for key, path in picks.items():
        try:
            gast, fmt, n = _parse_key(key)
        except ValueError as e:
            print("ERR %s: %r" % (key, e), flush=True)
            continue
        out[name_for(gast, "fragend", n, fmt)] = path
    return out
