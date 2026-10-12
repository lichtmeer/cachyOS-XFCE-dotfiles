#!/bin/bash
# cava-spectrum.sh v5: cava is broken on this system (all input methods
# return silence on PipeWire). pyspectrum.py replaces it: parecord feeds
# it raw audio, it writes bar values to cava.raw for the widget.
PY="$HOME/.config/conky/pyspectrum.py"
RAW="$HOME/.cache/conky-glance/cava.raw"
mkdir -p "$(dirname "$RAW")"

while true; do
    MON="$(pactl get-default-sink 2>/dev/null).monitor"
    [ -z "$MON" ] || [ "$MON" = ".monitor" ] && MON="auto"
    parecord -d "$MON" --file-format=raw --format=s16le --rate=44100 --channels=2 /dev/stdout 2>/dev/null \
    | python3 "$PY"
    sleep 2   # pipe broke (device switch?) -> re-resolve and restart
done
