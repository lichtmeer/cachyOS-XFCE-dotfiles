#!/bin/bash
# Hides polybar ONLY while a window is truly fullscreen.
# v3: a floating window touching the reserved top strip (struthelper)
# no longer triggers the hide. Only _NET_WM_STATE_FULLSCREEN does,
# so the pill vanishes in fullscreen and returns when it ends.

LOG=/tmp/polybar-hide-debug.log
hidden=false

read -r screen_w screen_h <<< "$(xdotool getdisplaygeometry)"

log() { echo "$(date +%H:%M:%S) $*" >> "$LOG"; }
: > "$LOG"
log "=== started v3 (screen ${screen_w}x${screen_h}, fullscreen-only) ==="

while true; do
    fullscreen=false
    for id in $(xdotool search --onlyvisible ".*" 2>/dev/null); do
        wtype=$(xprop -id "$id" _NET_WM_WINDOW_TYPE 2>/dev/null)
        [[ "$wtype" != *_NET_WM_WINDOW_TYPE_NORMAL* ]] && continue
        state=$(xprop -id "$id" _NET_WM_STATE 2>/dev/null)
        if [[ "$state" == *_NET_WM_STATE_FULLSCREEN* ]]; then
            log "FULLSCREEN: '$(xdotool getwindowname "$id" 2>/dev/null)'"
            fullscreen=true
            break
        fi
    done

    if [[ "$fullscreen" = true && "$hidden" = false ]]; then
        polybar-msg -p "$(pgrep -f -- "polybar --reload google-top" | head -1)" cmd hide
        hidden=true
        log "DECISION: hide"
    elif [[ "$fullscreen" = false && "$hidden" = true ]]; then
        polybar-msg -p "$(pgrep -f -- "polybar --reload google-top" | head -1)" cmd show
        hidden=false
        log "DECISION: show"
    fi
    sleep 0.5
done
