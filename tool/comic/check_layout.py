#!/usr/bin/env python3
"""Prueft tool/comic/folge01_layout.json gegen die Folge-01-Texte (Task 5b-1): Checker-Ausgabe muss [] sein.
Aufruf im Repo-Wurzelverzeichnis: python3 tool/comic/check_layout.py"""
import ast
import json
import subprocess
import sys

sys.path.insert(0, "tool/comic")
import letter_folge01  # noqa: E402

with open("tool/comic/folge01_layout.json", encoding="utf-8") as f:
    layout = json.load(f)

print(letter_folge01.check_layout(layout))

# Drehbuch V3 (Mira schweigt, docs/story/DREHBUCH_FOLGE_01_V3.md): Mira hat keine Blase, ihr Schweigen
# steht im Erzaehltext (Aenderung 5.10.).
EXPECTED = {
    "p01": ["みなみまち駅"],
    "p02": [],
    "p03": ["すみません！あめ！あめ！", "ありがとう！あめ、あめ… さむい、さむい"],
    "p04": ["傘"],
    "p05": ["ここ、ここ！", "あめ、あめ！", "これ？かさ？みせ！みせ！", "えき？ひとり？ひとり…"],
    "p06": ["これ、こわれた", "はい、こわれた、こわれた。だめ、だめ"],
    "p07": ["はい。かさ。どうぞ", "いくら？いいえ、いいえ。どうぞ、どうぞ。かさ！",
            "ほんとう、ほんとう。だいじょうぶ、だいじょうぶ"],
    "p08": ["はいはい"],
    "p09": ["あめやどり"],
    "p10": [],
}
# Panels, deren Texte seit V2 unveraendert sind — nur die werden noch gegen die Git-Quelle geprueft.
UNCHANGED_SINCE_V2 = ["p01", "p02"]
FURI = {"p01": [["駅", "えき"]], "p04": [["傘", "かさ"]]}
# Schilder (Spec Mira schweigt §4, Aenderung 5.10.): als Kasten gelettert.
SCHILD = {"p01": ["みなみまち駅"], "p04": ["傘"], "p09": ["あめやどり"]}

# Gegenprobe gegen die Git-Quelle (BUBBLES im alten Lettering-Skript).
src = subprocess.run(["git", "show", "f49e164:tool/letter_folge01.py"],
                     capture_output=True, text=True, check=True).stdout
tree = ast.parse(src)
git_texts = {}
for node in tree.body:
    if isinstance(node, ast.Assign) and getattr(node.targets[0], "id", "") == "BUBBLES":
        for k, v in zip(node.value.keys, node.value.values):
            git_texts["p%02d" % k.value] = [e.elts[0].value for e in v.elts]
for pid in UNCHANGED_SINCE_V2:
    assert git_texts.get(pid, []) == EXPECTED[pid], ("Git-Abweichung", pid, git_texts.get(pid))

assert layout["reactions"] == ["p02", "p05", "p08"], layout["reactions"]
assert layout["safe"] == 0.8
MOTIFS = sorted(EXPECTED) + ["titel"]
assert sorted(layout["kern"]) == sorted(MOTIFS), sorted(layout["kern"])
for m, (kx0, kx1) in layout["kern"].items():
    assert 0 <= kx0 < kx1 <= 1, ("kern", m, kx0, kx1)
assert sorted(layout["panels"]) == sorted(EXPECTED), sorted(layout["panels"])
for pid, texts in EXPECTED.items():
    for fmt in ("quer", "hoch"):
        spec = layout["panels"][pid][fmt]
        got = [b["text"] for b in spec["bubbles"]]
        assert got == texts, (pid, fmt, got)
        for b in spec["bubbles"]:
            assert len(b["rect"]) == 4 and all(0 <= v <= 1 for v in b["rect"]), (pid, fmt, b)
            x, y, w, h = b["rect"]
            assert x + w <= 1 and y + h <= 1, (pid, fmt, b)
        if pid in FURI:
            assert [b.get("furigana") for b in spec["bubbles"]] == FURI[pid], (pid, fmt)
        else:
            assert all("furigana" not in b for b in spec["bubbles"]), (pid, fmt)
        schilder = [b["text"] for b in spec["bubbles"] if b.get("form") == "schild"]
        assert schilder == SCHILD.get(pid, []), (pid, fmt, "schild", schilder)
        assert all("off" not in b for b in spec["bubbles"]), (pid, fmt, "keine Zeiger mehr")
        for face in spec["faces"]:
            assert len(face) == 4, (pid, fmt, face)
print("OK: 10 Panels x 2 Formate, Texte = Drehbuch V3 (p01/p02 = Git-Quelle), reactions ok, kern 11/11, Schilder 3")
