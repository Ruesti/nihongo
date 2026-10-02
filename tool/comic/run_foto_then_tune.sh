#!/bin/sh
# Foto-Nachrender (nur die genannten Keys, mit overrides_foto.txt) und danach Manga-Feinschliff.
# Läuft AUF DER BOX in ~/f01tool. Aufruf mit den Keys der Nachrender, z. B.:
#   sh run_foto_then_tune.sh p03_hoch titel_a_hoch
# Ohne Keys: nur der Feinschliff. Vorher picks_foto.txt auf der Box aktualisieren (tune liest p10_quer/p07_quer).
# Log-Marken: FOTO_DONE (Nachrender), "--- tune", TUNE_DONE, RUN_DONE.
cd ~/f01tool || exit 1
if [ "$#" -gt 0 ]; then
  python3 folge01_foto.py "$@" overrides_foto.txt
fi
echo "--- tune $(date +%H:%M:%S)"
python3 folge01_manga.py tune picks_foto.txt
echo "RUN_DONE"
