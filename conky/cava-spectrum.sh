#!/bin/bash
# cava-spectrum.sh: feeds cava's bar values to the conky-glance widget.
# cava prints one line per frame: "v1;v2;...;v24;" (0-255 each).
# We split on ';', scale to 0-100, and write to cava.raw for glance.lua.

CACHE_DIR="$HOME/.cache/conky-glance"
RAW="$CACHE_DIR/cava.raw"
CONF="$HOME/.config/conky/cava.conf"

mkdir -p "$CACHE_DIR"

cava -p "$CONF" | awk -v RAWF="$RAW" '
    BEGIN { FS = ";" }
    NF == 0 { next }
    {
        out = ""
        for (i = 1; i <= NF; i++) {
            v = $i + 0
            if (v > 255) v = 255
            if (v < 0) v = 0
            n = int(v * 100 / 255)
            out = (out == "") ? n : out ";" n
        }
        print out > RAWF
        close(RAWF)
    }
'
