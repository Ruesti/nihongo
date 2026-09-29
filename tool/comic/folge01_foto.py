#!/usr/bin/env python3
"""Runde 1: Foto-Pass (Look A) für alle 13 Motive × 2 Formate × 2 Seeds. Läuft auf der Box.
  folge01_foto.py                                   → alles
  folge01_foto.py p03 titel_a                       → nur diese Motive (beide Formate)
  folge01_foto.py p03_hoch titel_a_hoch overrides_foto.txt → nur diese Keys, mit Overrides (Nachrender)
Ein Argument, das auf .txt endet, ist die Override-Datei. Grammatik wie overrides_manga.txt:
  <motif>_<fmt> [seed=N] [force] [core=<Text>|core=@HOCH_FIX:<name>;] [extra=<Text>;] [neg=<Text>]
core= ersetzt den Motiv-Kern (@HOCH_FIX:<name> holt Kern, Zusätze und Negativ aus
folge01_motifs.HOCH_FIX), extra= hängt an den Positiv-, neg= an den Negativ-Prompt an.
Hat ein Key einen seed=, wird NUR dieser Seed gerendert statt SEEDS.
Schreibt ~/comfy_f01/foto/, überspringt vorhandene Ausgaben (außer mit force), endet mit FOTO_DONE."""
import os
import subprocess
import sys

import comfy_client as cc
from folge01_manga import load_overrides as _load_overrides
from folge01_motifs import FORMATS, FORMAT_HINT, HOCH_FIX, LORA_PHOTO, PHOTO, SEEDS, motifs, negative_for

OUT = os.path.expanduser("~/comfy_f01/foto")
HERE = os.path.dirname(os.path.abspath(__file__))
FOTO_KEYS = frozenset({"seed", "extra", "neg", "core", "force"})
HOCH_FIX_REF = "@HOCH_FIX:"


def load_overrides(path):
    return _load_overrides(path, allowed=FOTO_KEYS)


def resolve_core(motif, opts):
    """Kern + Zusätze eines Motivs nach Override: {core, format_hint, extra, neg}."""
    ref = opts.get("core")
    if not ref:
        base = {"core": motifs()[motif]}
    elif ref.startswith(HOCH_FIX_REF):
        name = ref[len(HOCH_FIX_REF):].strip()
        if name not in HOCH_FIX:
            raise ValueError("%s: unbekannter HOCH_FIX-Eintrag %r" % (motif, name))
        base = dict(HOCH_FIX[name])
    else:
        base = {"core": ref}
    extra = ", ".join(x for x in (base.get("extra"), opts.get("extra")) if x)
    neg = ", ".join(x for x in (base.get("neg"), opts.get("neg")) if x)
    return {"core": base["core"], "format_hint": base.get("format_hint", True), "extra": extra, "neg": neg}


def prompts(motif, fmt, opts):
    """(Positiv, Negativ) für ein Motiv in einem Format mit den Overrides des Keys."""
    r = resolve_core(motif, opts)
    pos = r["core"] + (FORMAT_HINT[fmt] if r["format_hint"] else "") + \
        ((", " + r["extra"]) if r["extra"] else "") + PHOTO
    neg = negative_for(motif) + ((", " + r["neg"]) if r["neg"] else "")
    return pos, neg


def seeds_for(opts):
    return (opts["seed"],) if "seed" in opts else SEEDS


def selected(motif, fmt, only):
    return not only or motif in only or "%s_%s" % (motif, fmt) in only


def already(prefix):
    return any(f.startswith(prefix + "_") for f in os.listdir(OUT)) if os.path.isdir(OUT) else False


def main(only, overrides_path=None):
    overrides = load_overrides(overrides_path) if overrides_path else {}
    os.makedirs(OUT, exist_ok=True)
    tiles = {fmt: [] for fmt in FORMATS}
    for motif in motifs():
        for fmt, (w, h) in FORMATS.items():
            if not selected(motif, fmt, only):
                continue
            opts = overrides.get("%s_%s" % (motif, fmt), {})
            pos, neg = prompts(motif, fmt, opts)
            for seed in seeds_for(opts):
                prefix = "%s_%s_s%d" % (motif, fmt, seed)
                if already(prefix) and not opts.get("force", False):
                    print("SKIP", prefix, flush=True)
                    got = [os.path.join(OUT, f) for f in sorted(os.listdir(OUT)) if f.startswith(prefix + "_")]
                    tiles[fmt] += ["%s=%s" % (prefix, p) for p in got[:1]]
                    continue
                try:
                    got = cc.run(cc.t2i_graph(pos, neg, seed, prefix, LORA_PHOTO, w, h), prefix, OUT, "f01foto")
                    tiles[fmt] += ["%s=%s" % (prefix, p) for p in got]
                    print("OK", prefix, flush=True)
                except Exception as e:  # noqa: BLE001
                    print("ERR", prefix, repr(e), flush=True)
    for fmt, items in tiles.items():
        if items:
            subprocess.run(["python3", os.path.join(HERE, "sheet.py"),
                            os.path.join(OUT, "foto_%s.png" % fmt), "4" if fmt == "quer" else "6"] + items,
                           check=False)
    print("FOTO_DONE", flush=True)


def parse_args(argv):
    txt = [a for a in argv if a.endswith(".txt")]
    if len(txt) > 1:
        raise SystemExit("höchstens eine Override-Datei")
    return set(a for a in argv if not a.endswith(".txt")), (txt[0] if txt else None)


if __name__ == "__main__":
    main(*parse_args(sys.argv[1:]))
