#!/usr/bin/env python3
"""Vergleichsseite für Ulis Picks: review_page.py OUT.html "Titel" rows.json
rows.json = [{"label": "p01 · Bahnsteig", "note": "Prüfliste …", "items": [{"label": "quer s701", "path": "/…/x.png"}, …]}, …]
Bilder werden auf 900 px Breite verkleinert und als data-URIs eingebettet (max ~16 MB)."""
import base64
import io
import json
import sys

from PIL import Image

CSS = """<style>
:root{--bg:#eef1ef;--ink:#1b2220;--muted:#5f6f6b;--line:#c9d3d0;--card:#f7f9f8;--accent:#3f6f68;color-scheme:light}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){--bg:#14191a;--ink:#e3e8e6;--muted:#93a39f;--line:#2c3736;--card:#1c2324;--accent:#7fb5ac;color-scheme:dark}}
:root[data-theme="dark"]{--bg:#14191a;--ink:#e3e8e6;--muted:#93a39f;--line:#2c3736;--card:#1c2324;--accent:#7fb5ac;color-scheme:dark}
body{background:var(--bg);color:var(--ink);font-family:"IBM Plex Sans","Segoe UI",system-ui,sans-serif;padding-inline:16px;padding-block:24px 48px;max-width:1400px;margin:0 auto;line-height:1.45}
h1{font-size:clamp(24px,4vw,34px);margin:0 0 14px}h2{font-size:17px;margin:26px 0 6px}
p.note{color:var(--muted);margin:0 0 8px;max-width:70ch}
.strip{display:flex;gap:8px;overflow-x:auto;padding-bottom:8px}
.strip figure{flex:0 0 auto;width:min(420px,84vw);margin:0}
.strip img{width:100%;height:auto;display:block;border:1px solid var(--line);background:#fff;cursor:zoom-in}
.strip figcaption{font-size:12px;color:var(--muted);margin-top:4px;text-transform:uppercase;letter-spacing:.05em}
.missing{display:flex;align-items:center;justify-content:center;aspect-ratio:16/9;border:1px dashed #c33;color:#c33;font-size:13px}
#lb{position:fixed;inset:0;background:rgba(0,0,0,.92);display:none;align-items:center;justify-content:center;z-index:9;cursor:zoom-out;padding:12px}
#lb img{max-width:100%;max-height:100%;object-fit:contain}#lb.on{display:flex}
</style>"""
JS = """<div id="lb"><img alt=""></div><script>
(function(){var lb=document.getElementById('lb'),im=lb.querySelector('img');
document.querySelectorAll('.strip img').forEach(function(el){el.addEventListener('click',function(){im.src=el.src;lb.classList.add('on');});});
lb.addEventListener('click',function(){lb.classList.remove('on');im.src='';});})();</script>"""


def uri(path):
    try:
        im = Image.open(path).convert("RGB")
    except OSError:
        return None
    w = 900
    im = im.resize((w, int(im.height * w / im.width)), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=82, optimize=True)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def main(out, title, rows_path):
    rows = json.load(open(rows_path, encoding="utf-8"))
    parts = ["<title>%s</title>" % title, CSS, "<h1>%s</h1>" % title]
    for row in rows:
        parts.append("<h2>%s</h2>" % row["label"])
        if row.get("note"):
            parts.append("<p class=\"note\">%s</p>" % row["note"])
        parts.append("<div class=\"strip\">")
        for item in row["items"]:
            u = uri(item["path"])
            body = "<img alt=\"%s\" src=\"%s\">" % (item["label"], u) if u else "<div class=\"missing\">fehlt</div>"
            parts.append("<figure>%s<figcaption>%s</figcaption></figure>" % (body, item["label"]))
        parts.append("</div>")
    parts.append(JS)
    html = "\n".join(parts)
    open(out, "w", encoding="utf-8").write(html)
    print(out, "%.1f MB" % (len(html.encode()) / 1e6))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
