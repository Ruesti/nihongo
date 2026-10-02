#!/bin/sh
# Auslieferung (Spec §4.3): wartet, bis ComfyUI antwortet, dann folge01_finish.py über picks_manga.txt.
# Läuft AUF DER BOX in ~/f01tool (dorthin vorher tool/comic/*.py, *.sh und *.txt kopieren).
# Start vom NUC (Details in tool/comic/README.md):
#   ssh pc 'setsid nohup sh ~/f01tool/run_finish.sh > ~/f01tool/finish.log 2>&1 </dev/null &'
# Log-Marken: "--- finish", je Key OK/SKIP/ERR, FINISH_DONE, RUN_FINISH_DONE.
cd ~/f01tool || exit 1
until curl -s -m 3 localhost:8188/system_stats > /dev/null; do sleep 5; done
echo "--- finish $(date +%H:%M:%S)"
python3 folge01_finish.py picks_manga.txt
echo "RUN_FINISH_DONE"
