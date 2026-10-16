#!/bin/sh
# Café-Ansprache: wartet, bis ComfyUI antwortet, dann die gewünschte Stufe von cafe_ansprache.py.
# Läuft AUF DER BOX in ~/f01tool (dorthin vorher tool/comic/*.py und *.sh kopieren).
# Aufruf: sh run_ansprache.sh gate | runde1 | runde2 PICKS [OVERRIDES] | finish PICKS OUT
#   ssh pc 'setsid nohup sh ~/f01tool/run_ansprache.sh gate > ~/f01tool/ansprache.log 2>&1 </dev/null &'
# Log-Marken: je Bild OK/SKIP/ERR, ANSPRACHE_DONE (Stufe fertig), RUN_ANSPRACHE_DONE.
cd ~/f01tool || exit 1
until curl -s -m 3 localhost:8188/system_stats > /dev/null; do sleep 5; done
echo "--- ansprache $1 $(date +%H:%M:%S)"
python3 cafe_ansprache.py "$@"
echo "RUN_ANSPRACHE_DONE"
