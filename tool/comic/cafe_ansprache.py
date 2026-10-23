#!/usr/bin/env python3
"""Café-Ansprache-Bilder: 60 Gästeporträts (4 Gäste x 3 Stimmungen x 5 Varianten, je in zwei Formaten).

Inhalt: Datenschicht (Gäste, Stimmungen, Dateinamen, Prompts), Picks- und Override-Dateien,
Render-Stufen über ComfyUI (Foto fragend, Edits zufrieden/abwinkend, Manga-Durchgang), Kontaktbögen,
die Stufen gate/runde1/runde2, finish (Vergrößern + JPEG) und die Kommandozeile `main`.
Spec: docs/superpowers/specs/2026-10-15-cafe-ansprache-design.md §2.
Aufruf: python3 cafe_ansprache.py gate | runde1 [--seeds ..] [--gast ..] [--fmt ..] | runde2 PICKS [OVERRIDES] [--denoise 0.6] | finish MANGA_DIR OUT
"""
import glob
import hashlib
import json
import os
import shutil
import subprocess
import sys
import traceback
from pathlib import Path

import comfy_client as cc
import folge01_manga
from cafe_motifs import CAFE, GIRL, LAND, LORA_STRENGTH, MAN, NEG, PHOTO, YW  # noqa: F401
from folge01_motifs import NEG_MANGA, STY

HERE = Path(__file__).resolve().parent
ROOT = Path("~/comfy_cafe_ansprache").expanduser()  # Unterordner foto, edit, manga, final, sheets
MOODS = ("fragend", "zufrieden", "abwinkend")
FORMATS = {"quer": (1664, 928), "hoch": (928, 1664)}
TARGET = {"quer": (1920, 1072), "hoch": (1080, 1936)}
VARIANTS = 5

# Fester Schluss jeder Edit-Anweisung
_KEEP = ", keep the same person, clothes, lighting, background and framing"  # ohne "pose": Gesten ändern die Haltung

# Stimmungsbeschreibung für den Manga-Durchgang (sonst löscht er den Ausdruck aus dem Foto)
MANGA_MOODS = {
    "fragend": "asking expression, eyebrows raised, mouth slightly open, looking at the viewer",
    "zufrieden": "beaming happy smile showing teeth, eyes crinkled with joy",
    "abwinkend": "displeased frown, eyebrows drawn together, mouth corners turned down, head slightly turned away",
}

# Kinderproportionen, sonst wirkt das Schulmädchen im Manga-Durchgang erwachsen
_CHILD = ("a little nine-year-old child, childlike round face with chubby cheeks, head large in proportion to her small body, "
          "tiny narrow shoulders, short arms and small hands, sitting low so the table reaches her chest")
_GIRL_CHILD = GIRL + ", " + _CHILD

GUESTS = {
    "wirtin": {
        "figure": LAND,
        "place": "behind the wooden counter of the cafe",
        "note": "warm",
        "poses": [
            "wiping the counter with a cloth and looking up",
            "both hands on the counter, leaning forward",
            "holding a small tray with a cup",
            "arms folded over the apron",
            "pouring tea from a pot into a cup",
            "standing beside a booth with a notepad in hand",
            "one hand on her hip, the other on the counter",
            "sitting on a stool at the end of the counter, turned to the camera",
        ],
        "moods": {
            "zufrieden": "change her expression to a warm broad smile showing teeth, eyes crinkled with joy, nodding, hands clasped in front of the apron" + _KEEP,
            "abwinkend": "change her expression to a disappointed frown, mouth corners down, eyebrows drawn together, head tilted and slightly turned away, one hand flat on the counter pushing an imaginary thing away" + _KEEP,
        },
        # Gesten je Stimmung für den Manga-Durchgang (fragend hat keine)
        "gestures": {
            "zufrieden": "nodding, hands clasped in front of the apron",
            "abwinkend": "one hand flat on the counter, pushing an imaginary thing away",
        },
    },
    "schulkind": {
        "figure": _GIRL_CHILD,
        "place": "in a green vinyl booth with school notebooks on the table",
        "note": "cheeky, chin forward",
        # Zusatz-Negativ: das Fotomodell macht sonst eine Teenagerin daraus
        "neg": "teenager, high school student, young woman, adult, mature face, long legs, tall",
        "poses": [
            "chin resting on both hands over an open notebook",
            "holding up a pencil, mid-thought",
            "kneeling on the bench with her arms on the backrest",
            "standing next to the table with her hands behind her back",
            "both hands wrapped around a mug of cocoa",
            "leaning back with her arms crossed",
            "waving an open notebook",
            "head tilted, one hand raised like asking in class",
        ],
        "moods": {
            "zufrieden": "change her expression to a big open-mouthed grin with eyes squeezed shut in delight, one fist pumped up in triumph" + _KEEP,
            "abwinkend": "change her expression to a sulky pout with the lower lip pushed out, eyebrows drawn together, arms crossed tightly, head turned away" + _KEEP,
        },
        # Gesten je Stimmung für den Manga-Durchgang (fragend hat keine)
        "gestures": {
            "zufrieden": "one fist pumped up in triumph",
            "abwinkend": "arms crossed tightly, sulky pout with the lower lip pushed out",
        },
    },
    "vielredner": {
        "figure": MAN,
        "place": "at the window table with a folded newspaper",
        "note": "grumpy, glancing over the newspaper",
        "poses": [
            "newspaper lowered to the table, glasses in one hand",
            "standing by the table with the folded newspaper under his arm",
            "leaning back with the newspaper open",
            "elbows on the table, hands clasped",
            "pointing at an article in the newspaper",
            "holding a cup of coffee",
            "sitting sideways with one arm over the chair back",
            "standing at the window with the newspaper rolled in one hand",
        ],
        "moods": {
            "zufrieden": "change his expression to a broad satisfied grin, eyes narrowed, chin lifted, giving a thumbs-up" + _KEEP,
            "abwinkend": "change his expression to a deep frown with eyebrows drawn together and mouth corners down, the newspaper lowered flat on the table, shaking his head" + _KEEP,
        },
        # Gesten je Stimmung für den Manga-Durchgang (fragend hat keine)
        "gestures": {
            "zufrieden": "chin lifted, giving a thumbs-up",
            "abwinkend": "newspaper lowered flat on the table, shaking his head",
        },
    },
    "gleichaltrige": {
        "figure": YW,
        "place": "at a formica table with a cup of coffee",
        "note": "friendly but indifferent",
        "poses": [
            "both hands around the coffee cup",
            "stirring the coffee and looking up",
            "chin on one hand, elbow on the table",
            "leaning back with one arm over the backrest",
            "standing with the cup in her hand",
            "phone face-down on the table, hands folded",
            "turned sideways on the bench with one knee up",
            "leaning in with both forearms on the table",
        ],
        "moods": {
            "zufrieden": "change her expression to a genuine wide smile showing teeth, eyes warm, giving a small thumbs-up" + _KEEP,
            "abwinkend": "change her expression to an unimpressed look with a raised eyebrow and flat mouth, shrugging with both shoulders up and palms turned upward" + _KEEP,
        },
        # Gesten je Stimmung für den Manga-Durchgang (fragend hat keine)
        "gestures": {
            "zufrieden": "giving a small thumbs-up",
            "abwinkend": "shrugging with both shoulders up and palms turned upward",
        },
    },
}

# Gemeinsamer Kern der Stimmung "fragend"
_KERN = ("waist-up portrait photo, close medium shot, the figure fills the frame, "
         "direct eye contact, looks straight into the camera lens and speaks to the viewer, "
         "mouth slightly open, eyebrows raised in a question, face sharp and large, alone")
# Acht Varianten des fragenden Ausdrucks; Variante v nimmt _EXPRESSIONS[v] und poses[v]
_EXPRESSIONS = (
    "eyebrows raised, waiting for an answer",
    "head tilted, curious",
    "a slight puzzled frown",
    "mouth open mid-sentence",
    "attentive, with a slight smile",
    "one eyebrow raised, skeptical",
    "mildly surprised, eyes wide",
    "patient, chin lifted",
)
_FORMAT_SATZ = {
    "quer": ", horizontal composition, the figure in the left third of the frame close to the camera, the counter and booths blurred to the right",
    "hoch": ", vertical portrait orientation filling the whole frame, the face in the upper third, the counter edge at the bottom",
}
_NEG_EXTRA = ", two people, looking away, profile view, closed eyes, back turned, wide shot, full body, distant figure, small figure, far away, black bars, letterbox, empty room"


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


def _guest_neg(g):
    """Gastspezifisches Zusatz-Negativ als ', ...' oder leer."""
    return ", " + g["neg"] if g.get("neg") else ""


def t2i_prompt(gast, fmt, variant=0):
    """Positiv- und Negativ-Prompt für die Stimmung fragend; variant (modulo 8) wählt Haltung und Ausdruck."""
    if gast not in GUESTS:
        raise ValueError(f"unbekannter Gast: {gast!r}")
    if fmt not in FORMATS:
        raise ValueError(f"unbekanntes Format: {fmt!r}")
    g = GUESTS[gast]
    # der Auslöser "shotengai_style, " kommt von cc.t2i_graph selbst
    v = variant % len(_EXPRESSIONS)
    pos = (_KERN + ", " + g["figure"] + ", " + _EXPRESSIONS[v] + ", " + g["poses"][v]
           + ", " + g["note"] + ", " + g["place"]
           + ", in " + CAFE + _FORMAT_SATZ[fmt] + PHOTO)
    return pos, NEG + _NEG_EXTRA + _guest_neg(g)


def edit_prompt(gast, stimmung):
    """Edit-Anweisung für zufrieden/abwinkend (fragend ist das Ausgangsbild)."""
    if gast not in GUESTS:
        raise ValueError(f"unbekannter Gast: {gast!r}")
    if stimmung not in GUESTS[gast]["moods"]:
        raise ValueError(f"keine Edit-Anweisung für Stimmung: {stimmung!r}")
    return GUESTS[gast]["moods"][stimmung]


def manga_prompt(gast, stimmung="fragend"):
    """Manga-Prompt mit Stimmung und Geste; ohne Stimmung = fragend (wie bisher)."""
    if gast not in GUESTS:
        raise ValueError(f"unbekannter Gast: {gast!r}")
    if stimmung not in MANGA_MOODS:
        raise ValueError(f"unbekannte Stimmung: {stimmung!r}")
    g = GUESTS[gast]
    gesture = g["gestures"].get(stimmung)
    return (STY + ", " + g["figure"] + ", " + MANGA_MOODS[stimmung]
            + (", " + gesture if gesture else "") + ", " + g["place"], NEG_MANGA + _guest_neg(g))


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
    ov = folge01_manga.load_overrides(path, allowed={"seed", "extra", "force"})
    valid = set(all_names())
    for key in ov:
        if key not in valid:
            raise ValueError("Override-Schlüssel unbekannt: %r" % key)
    return ov


def _skip_existing(prefix, out):
    return bool(glob.glob(os.path.join(glob.escape(str(out)), glob.escape(prefix) + "_*")))


def _sources_path(out):
    return Path(out) / "_sources.json"


def _load_sources(out):
    try:
        with open(_sources_path(out), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def _fingerprint(*parts):
    """SHA1 über die Bestandteile eines Auftrags (Prompt, Denoise, Seed ...)."""
    return hashlib.sha1("|".join(str(p) for p in parts).encode("utf-8")).hexdigest()


def _record_source(out, name, src, fp=None):
    """Merkt sich je Ausgabename Quellpfad und Fingerprint (Wechsel erzwingt Neurender)."""
    data = _load_sources(out)
    data[name] = {"src": os.path.abspath(str(src)), "fp": fp}
    Path(out).mkdir(parents=True, exist_ok=True)
    _sources_path(out).write_text(json.dumps(data, indent=1, sort_keys=True), encoding="utf-8")


def _source_changed(out, name, src, fp=None):
    """True bei anderer Quelle oder anderem Fingerprint; alter Klartext-Eintrag = Fingerprint unbekannt."""
    old = _load_sources(out).get(name)
    if old is None:
        return False
    if isinstance(old, str):  # alter Eintrag: nur Quellpfad, Fingerprint unbekannt -> einmal neu
        return old != os.path.abspath(str(src)) or fp is not None
    if old.get("src") != os.path.abspath(str(src)):
        return True
    return fp is not None and old.get("fp") != fp


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
    def make(gast, fmt, seed, prefix, variant):
        pos, neg = t2i_prompt(gast, fmt, variant)
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
                jobs.append((prefix, make(gast, fmt, seed, prefix, seeds.index(seed))))
    return _run_all(jobs)


def _edit_fp(gast, mood, opts, seed):
    """Fingerprint eines Edits: Anweisung + Zusatz + wirksamer Seed (Override oder Standard), wie beim Manga-Fp."""
    return _fingerprint(_with_extra(edit_prompt(gast, mood), opts), opts.get("seed", seed))


def render_edits(picks, seed=21, out=ROOT / "edit", overrides=None):
    """Runde 2: je Pick zwei Edits (zufrieden, abwinkend) aus dem Foto der Stimmung fragend."""
    overrides = overrides or {}

    def make(key, src, gast, mood, prefix, opts):
        def job():
            input_name = "ans_%s.png" % key
            shutil.copy(src, os.path.join(cc.COMFY_INPUT, input_name))
            graph = cc.edit_graph(input_name, _with_extra(edit_prompt(gast, mood), opts),
                                  opts.get("seed", seed), prefix, negative=NEG)
            got = cc.run(graph, prefix, out)
            if got:
                _record_source(out, prefix, src, _edit_fp(gast, mood, opts, seed))
            return got
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
            if _source_changed(out, prefix, src, _edit_fp(gast, mood, opts, seed)):
                opts = {**opts, "force": True}
            if folge01_manga.should_skip(prefix, str(out), opts):
                print("SKIP", prefix, flush=True)
                continue
            jobs.append((prefix, make(key, src, gast, mood, prefix, opts)))
    return _run_all(jobs)


_MOOD_SEED = {"fragend": 0, "zufrieden": 1, "abwinkend": 2}


def _manga_job(name, opts, denoise, seed_base):
    """(Positiv, Negativ, Seed, Fingerprint) für einen Manga-Namen; ValueError bei ungültigem Namen."""
    parts = name.split("_")
    if len(parts) != 4 or parts[0] not in GUESTS or parts[1] not in MANGA_MOODS:
        raise ValueError("unbekannter Gast oder Stimmung")
    pos, neg = manga_prompt(parts[0], parts[1])
    pos = _with_extra(pos, opts)
    seed = opts.get("seed", seed_base + _MOOD_SEED[parts[1]])
    return pos, neg, seed, _fingerprint(pos, denoise, seed)


def render_manga(sources, out=ROOT / "manga", overrides=None, denoise=0.7, seed_base=831):
    """Runde 3: Manga-Durchgang je Foto; sources = Name `{gast}_{stimmung}_{n}_{fmt}` -> Pfad.
    Prompt kennt die Stimmung, Seed = seed_base + Stimmungsversatz (fragend 0, zufrieden 1, abwinkend 2)."""
    overrides = overrides or {}

    def make(name, src, pos, neg, seed, fp):
        def job():
            input_name = "ansm_%s.png" % name
            shutil.copy(src, os.path.join(cc.COMFY_INPUT, input_name))
            graph = cc.manga_graph(input_name, pos, neg, seed, name, denoise=denoise)
            got = cc.run(graph, name, out)
            if got:
                _record_source(out, name, src, fp)
            return got
        return job
    jobs = []
    for name, src in sources.items():
        opts = overrides.get(name, {})
        try:
            pos, neg, seed, fp = _manga_job(name, opts, denoise, seed_base)
        except ValueError as e:
            print("ERR %s: %r" % (name, e), flush=True)
            continue
        if _source_changed(out, name, src, fp):
            opts = {**opts, "force": True}
        if folge01_manga.should_skip(name, str(out), opts):
            print("SKIP", name, flush=True)
            continue
        jobs.append((name, make(name, src, pos, neg, seed, fp)))
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


# --- Bögen und Stufen -------------------------------------------------------

MOODS_ORDER = ("fragend", "zufrieden", "abwinkend")


def make_sheet(name, items, cols, out=None):
    """Kontaktbogen `name.png` aus (Label, Pfad)-Paaren über sheet.py; Rückgabe = Bogenpfad."""
    out = Path(out) if out else ROOT / "sheets"
    out.mkdir(parents=True, exist_ok=True)
    target = out / (name + ".png")
    subprocess.run([sys.executable, str(HERE / "sheet.py"), str(target), str(cols)]
                   + ["%s=%s" % (label, path) for label, path in items], check=True)
    return target


def _newest(prefix, folder):
    """Neueste Datei `prefix_*` im Ordner oder None."""
    found = glob.glob(os.path.join(glob.escape(str(folder)), glob.escape(prefix) + "_*"))
    return max(found, key=lambda f: (os.path.getmtime(f), f)) if found else None


def _placeholder(folder):
    """Kleines dunkles Ersatzbild `_placeholder.png`, einmal erzeugt; hält das Raster ausgerichtet."""
    from PIL import Image
    folder = Path(folder)
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / "_placeholder.png"
    if not path.exists():
        Image.new("RGB", (256, 256), (30, 30, 30)).save(path)
    return path


def _cells(labelled, lookup, sheets_dir):
    """(Label, Schlüssel) -> (Label, Pfad); fehlendes Bild = WARN + Platzhalter statt Lücke."""
    items = []
    for label, key in labelled:
        path = lookup(key)
        if not path:
            print("WARN fehlt: %s" % label, flush=True)
            path = _placeholder(sheets_dir)
        items.append((label, path))
    return items


def _manga_sheet(name, labelled, manga_dir, sheets_dir):
    """Bogen mit 3 Spalten aus den Manga-Ausgaben; (Label, Name)-Paare."""
    manga = edit_outputs(manga_dir)
    return make_sheet(name, _cells(labelled, manga.get, sheets_dir), 3, out=sheets_dir)


def gate(seeds=(911, 912)):
    """Gate: Wirtin quer/hoch, je Seed fragend -> Edits -> Manga; Bogen gate/sheets/gate.png.
    Eigener Unterbaum ROOT/gate, damit Runde 2 keine Gate-Bilder wiederverwendet."""
    base = ROOT / "gate"
    foto, edit, manga, sheets = (base / d for d in ("foto", "edit", "manga", "sheets"))
    render_fragend(["wirtin"], list(FORMATS), seeds, out=foto)
    picks = {}
    for fmt in FORMATS:
        for i, seed in enumerate(seeds, 1):
            f = _newest("wirtin_fragend_%s_s%d" % (fmt, seed), foto)
            if f:
                picks["wirtin_%s_%d" % (fmt, i)] = f
    render_edits(picks, out=edit)
    render_manga({**fragend_sources(picks), **edit_outputs(edit)}, out=manga)
    labelled = [("%s s%d %s" % (fmt, seed, mood), name_for("wirtin", mood, i, fmt))
                for fmt in FORMATS for i, seed in enumerate(seeds, 1) for mood in MOODS_ORDER]
    return _manga_sheet("gate", labelled, manga, sheets)


def runde1(seeds=tuple(range(921, 929)), suffixed=False, gaeste=None, formate=None):
    """Runde 1: alle Gäste/Formate/Seeds als Foto; ein Bogen je Zelle (4 Spalten).
    suffixed (bei --seeds): Bogenname bekommt _s{erster}-{letzter}, damit die Standardbögen bleiben.
    gaeste / formate (bei --gast / --fmt): nur diese Gäste bzw. Formate rendern und als Bogen ausgeben."""
    seeds = tuple(seeds)
    gaeste = list(gaeste) if gaeste else list(GUESTS)
    formate = list(formate) if formate else list(FORMATS)
    for g in gaeste:
        if g not in GUESTS:
            raise ValueError(f"unbekannter Gast: {g!r}")
    for f in formate:
        if f not in FORMATS:
            raise ValueError(f"unbekanntes Format: {f!r}")
    suffix = "_s%d-%d" % (seeds[0], seeds[-1]) if suffixed else ""
    foto, sheets_dir = ROOT / "foto", ROOT / "sheets"
    render_fragend(gaeste, formate, seeds, out=foto)
    sheets = []
    for gast in gaeste:
        for fmt in formate:
            labelled = [("s%d" % seed, "%s_fragend_%s_s%d" % (gast, fmt, seed)) for seed in seeds]
            items = _cells(labelled, lambda pre: _newest(pre, foto), sheets_dir)
            sheets.append(make_sheet("r1_%s_%s%s" % (gast, fmt, suffix), items, 4, out=sheets_dir))
    return sheets


def runde2(picks_path, overrides_path=None, denoise=0.7):
    """Runde 2: Edits + Manga aus den Picks; ein Bogen je Gast (3 Spalten)."""
    picks = load_picks(picks_path)
    overrides = load_overrides(overrides_path) if overrides_path else None
    edit, manga, sheets_dir = ROOT / "edit", ROOT / "manga", ROOT / "sheets"
    render_edits(picks, out=edit, overrides=overrides)
    render_manga({**fragend_sources(picks), **edit_outputs(edit)}, out=manga, overrides=overrides, denoise=denoise)
    guests = {k.split("_")[0] for k in picks}
    sheets = []
    for gast in GUESTS:
        if gast not in guests:
            continue
        labelled = [("%s %d %s" % (mood, n, fmt), name_for(gast, mood, n, fmt))
                    for n in range(1, VARIANTS + 1) for fmt in FORMATS for mood in MOODS_ORDER]
        sheets.append(_manga_sheet("r2_" + gast, labelled, manga, sheets_dir))
    return sheets


# --- Finish ------------------------------------------------------------------

def final_picks(manga_dir=ROOT / "manga", allow_missing=False):
    """Alle 120 Namen -> neueste Manga-Datei; ValueError mit den fehlenden Namen, außer allow_missing."""
    found, missing = {}, []
    for name in all_names():
        path = _newest(name, manga_dir)
        if path:
            found[name] = Path(path)
        else:
            missing.append(name)
    if missing and not allow_missing:
        raise ValueError("Manga-Bilder fehlen (%d): %s" % (len(missing), ", ".join(missing)))
    return found


def _up_to_date(dest, src):
    return os.path.exists(dest) and os.path.getmtime(dest) > os.path.getmtime(src)


def finish(sources, out=ROOT / "final"):
    """Vergrößert je Name (4x-UltraSharp, dann Zielgröße) und speichert JPEG q88; gibt die JPEG-Pfade zurück.
    Falsche Größe = AssertionError mit Name; aktuelle JPEGs werden übersprungen."""
    from PIL import Image
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    done = []
    for name, src in sources.items():
        fmt = name.rsplit("_", 1)[-1]
        if fmt not in TARGET:
            raise ValueError("%s: Format muss quer oder hoch sein" % name)
        w, h = TARGET[fmt]
        dest = out / (name + ".jpg")
        if _up_to_date(dest, src):
            print("SKIP", name, flush=True)
            done.append(dest)
            continue
        input_name = "ansf_%s.png" % name
        shutil.copy(src, os.path.join(cc.COMFY_INPUT, input_name))
        got = cc.run(cc.upscale_graph(input_name, "fin_" + name, w, h), "fin_" + name, out.parent / "final_png")
        with Image.open(got[0]) as im:
            if im.size != (w, h):
                raise AssertionError("%s: %s statt %s" % (name, im.size, (w, h)))
            tmp = dest.with_suffix(".tmp")  # erst ganz schreiben, dann ersetzen
            im.convert("RGB").save(tmp, "JPEG", quality=88, optimize=True)
            os.replace(tmp, dest)
        print("OK", name, (w, h), flush=True)
        done.append(dest)
    return done


def _parse_seeds(args):
    """`--seeds 931,932` -> (931, 932)."""
    seeds = tuple(int(x) for x in args[1].split(",") if x.strip())
    if not seeds:
        raise SystemExit("--seeds braucht mindestens eine Zahl")
    return seeds


def _parse_list_opt(args, flag):
    """Entfernt `flag a,b` aus args; Rückgabe (Tupel oder None, Rest)."""
    if flag not in args:
        return None, args
    i = args.index(flag)
    vals = tuple(x.strip() for x in args[i + 1].split(",") if x.strip()) if i + 1 < len(args) else ()
    if not vals:
        raise SystemExit("%s braucht mindestens einen Wert" % flag)
    return vals, args[:i] + args[i + 2:]


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    stage, args = (argv[0] if argv else ""), argv[1:]
    denoise = 0.7
    if stage == "runde2" and "--denoise" in args:  # --denoise X an beliebiger Stelle nach der Stufe
        i = args.index("--denoise")
        try:
            denoise = float(args[i + 1])
        except (IndexError, ValueError):
            raise SystemExit("--denoise braucht eine Zahl")
        args = args[:i] + args[i + 2:]
    gaeste = formate = None
    if stage == "runde1":  # --gast / --fmt an beliebiger Stelle nach der Stufe
        gaeste, args = _parse_list_opt(args, "--gast")
        formate, args = _parse_list_opt(args, "--fmt")
        for flag, vals, known in (("--gast", gaeste, GUESTS), ("--fmt", formate, FORMATS)):
            for v in vals or ():  # vor dem ersten Render prüfen, nicht erst in runde1
                if v not in known:
                    raise SystemExit("%s: unbekannter Wert %r (erlaubt: %s)" % (flag, v, ", ".join(known)))
    if stage not in ("gate", "runde1", "runde2", "finish") or (
            stage == "runde1" and args and (len(args) != 2 or args[0] != "--seeds")) or (
            stage == "runde2" and not 1 <= len(args) <= 2) or (stage == "finish" and len(args) != 2):
        raise SystemExit("Aufruf: cafe_ansprache.py gate | runde1 [--seeds 931,932,...] [--gast schulkind[,wirtin]] [--fmt quer[,hoch]] | runde2 PICKS [OVERRIDES] [--denoise 0.6] | finish MANGA_DIR OUT")
    try:
        if stage == "gate":
            gate()
        elif stage == "runde1":
            kw = {}
            if gaeste:
                kw["gaeste"] = gaeste
            if formate:
                kw["formate"] = formate
            if args:
                runde1(_parse_seeds(args), suffixed=True, **kw)
            else:
                runde1(**kw)
        elif stage == "runde2":
            runde2(*args, denoise=denoise)
        else:
            finish(final_picks(Path(args[0]).expanduser()), out=Path(args[1]).expanduser())
    except Exception as e:  # noqa: BLE001
        print("ANSPRACHE_FAILED: %s: %s" % (type(e).__name__, e), flush=True)
        traceback.print_exc()
        raise SystemExit(1)
    print("ANSPRACHE_DONE", flush=True)


if __name__ == "__main__":
    main()
