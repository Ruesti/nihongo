#!/bin/sh
# Hochbild aus dem Querbild (Spec §12). Läuft auf der Box in ~/f01tool, Log ~/comfy_f01/hoch.log.
cd ~/f01tool
until curl -s -m 3 localhost:8188/system_stats > /dev/null; do sleep 5; done
echo "--- hoch $(date +%H:%M:%S)"
python3 folge01_hoch.py picks_manga.txt overrides_hoch.txt
echo "RUN_HOCH_DONE"
