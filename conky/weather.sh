#!/bin/bash
# Weather fetcher for the conky-glance widget.
# Output: "<temp>|<description>"  e.g. "+12°C|Light rain"
# Caches for 30 minutes in ~/.cache/conky-glance/weather.txt.
# Location priority: $1 argument > ~/.config/conky/location > wttr.in IP auto-detect.

CACHE_DIR="$HOME/.cache/conky-glance"
CACHE="$CACHE_DIR/weather.txt"
TTL=1800

mkdir -p "$CACHE_DIR"

if [ -f "$CACHE" ]; then
    AGE=$(( $(date +%s) - $(stat -c %Y "$CACHE") ))
    if [ "$AGE" -lt "$TTL" ]; then
        cat "$CACHE_DIR/weather.txt"
        exit 0
    fi
fi

LOC="$1"
[ -z "$LOC" ] && [ -f "$HOME/.config/conky/location" ] && LOC=$(cat "$HOME/.config/conky/location")

LINE=$(curl -sf --max-time 5 "https://wttr.in/${LOC}?format=%t|%C" 2>/dev/null)

if [ -n "$LINE" ] && [[ "$LINE" == *"|"* ]]; then
    echo "$LINE" | tee "$CACHE"
    exit 0
fi

# stale cache beats no data
if [ -f "$CACHE" ]; then
    cat "$CACHE"
    exit 0
fi

echo "--|--"
