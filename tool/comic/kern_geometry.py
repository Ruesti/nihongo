#!/usr/bin/env python3
"""Geometrie „Hochbild aus dem Querbild" (Spec §12). Reine Funktionen, laufen auf NUC und Box.

Kern = [x0, x1] als Anteile der Querbreite. Hochfenster = volle Höhe, Breite im Hochformat-Verhältnis.
Passt der Kern ins Fenster → "crop" (Fenster mittig über dem Kern, an den Rand geklemmt).
Sonst → "extend": Kernstreifen (volle Höhe) auf HOCH-Breite skaliert, unten BOTTOM px, oben der Rest in
Schritten ≤ STEP_MAX. Alle Maße Vielfache von MULT (Qwen-VAE)."""

QUER = (1664, 928)
HOCH = (928, 1664)
MULT = 16
BOTTOM = 128
STEP_MAX = 480


def _mult(v):
    return int(round(v / MULT)) * MULT


def window_width(img_w, img_h):
    """Breite des Hochfensters bei voller Höhe des Querbilds."""
    return int(round(img_h * HOCH[0] / HOCH[1]))


def top_steps(total):
    """Teilt `total` (Vielfaches von MULT) in möglichst wenige Schritte ≤ STEP_MAX, alle Vielfache von MULT."""
    if total % MULT:
        raise ValueError("top muss Vielfaches von %d sein, nicht %d" % (MULT, total))
    if total <= 0:
        return []
    n = -(-total // STEP_MAX)            # aufrunden
    base = _mult(total / n)
    steps = [base] * n
    steps[-1] = total - base * (n - 1)
    return steps


def plan_for(kern, img_w=QUER[0], img_h=QUER[1]):
    x0f, x1f = kern
    if not (0 <= x0f < x1f <= 1):
        raise ValueError("kern muss 0 <= x0 < x1 <= 1 sein, nicht %r" % (kern,))
    kx0, kx1 = int(round(x0f * img_w)), int(round(x1f * img_w))
    win = window_width(img_w, img_h)
    if kx1 - kx0 <= win:
        cx = (kx0 + kx1) / 2
        x0 = int(round(cx - win / 2))
        x0 = max(0, min(img_w - win, x0))
        return {"mode": "crop", "x0": x0, "x1": x0 + win}
    sh = min(_mult(img_h * HOCH[0] / (kx1 - kx0)), HOCH[1])
    bottom = min(BOTTOM, HOCH[1] - sh)
    top = HOCH[1] - sh - bottom
    return {"mode": "extend", "x0": kx0, "x1": kx1, "strip_h": sh, "bottom": bottom,
            "top": top, "top_steps": top_steps(top)}


def map_rect(rect, plan, img_w=QUER[0], img_h=QUER[1]):
    """Rechteck [x, y, w, h] (normiert im Querbild) → normiert im Hochbild (ohne Beschnitt)."""
    x, y, w, h = rect
    kw = plan["x1"] - plan["x0"]
    nx = (x * img_w - plan["x0"]) / kw
    nw = w * img_w / kw
    if plan["mode"] == "crop":
        ny, nh = y, h
    else:
        ny = (plan["top"] + y * plan["strip_h"]) / HOCH[1]
        nh = h * plan["strip_h"] / HOCH[1]
    return [round(v, 4) for v in (nx, ny, nw, nh)]


def clip_rect(rect):
    """Auf 0..1 beschneiden; None, wenn nichts übrig bleibt."""
    x, y, w, h = rect
    x0, y0, x1, y1 = max(0.0, x), max(0.0, y), min(1.0, x + w), min(1.0, y + h)
    if x1 <= x0 or y1 <= y0:
        return None
    return [round(v, 4) for v in (x0, y0, x1 - x0, y1 - y0)]


def hoch_faces(faces, plan, img_w=QUER[0], img_h=QUER[1]):
    out = []
    for f in faces:
        c = clip_rect(map_rect(f, plan, img_w, img_h))
        if c:
            out.append(c)
    return out
