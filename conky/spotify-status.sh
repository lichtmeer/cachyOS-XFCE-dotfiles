#!/bin/bash
# Spotify status reader for the conky-glance widget.
# Output: "STATUS|title|artist|position|length(sec)" or "NONE"
# Uses playerctl against the Spotify MPRIS player.

PC="playerctl -p spotify"
export LD_PRELOAD=

if ! $PC status >/dev/null 2>&1; then
    echo "NONE"
    exit 0
fi

STATUS=$($PC status 2>/dev/null)
TITLE=$($PC metadata title 2>/dev/null)
ARTIST=$($PC metadata artist 2>/dev/null)
POS=$(timeout 2 $PC position 2>/dev/null)
LEN_US=$($PC metadata mpris:length 2>/dev/null)

LEN=$(( ${LEN_US:-0} / 1000000 ))

if [ -z "$TITLE" ] || [ -z "$STATUS" ]; then
    echo "NONE"
    exit 0
fi

TITLE=$(echo "$TITLE" | tr '|' ' ')
ARTIST=$(echo "$ARTIST" | tr '|' ' ')
POS=${POS:-0}

echo "$STATUS|$TITLE|$ARTIST|$POS|$LEN"
