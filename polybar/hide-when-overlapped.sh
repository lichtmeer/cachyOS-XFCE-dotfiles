#!/bin/bash
# Hides polybar while any normal window overlaps its area
# v2: bar position computed from config values, not from the bar window

LOG=/tmp/polybar-hide-debug.log
hidden=false

# --- Bar rectangle, matching your config.ini (edit here if you change the bar) ---
read -r screen_w screen_h <<< "$(xdotool getdisplaygeometry)"
BAR_WIDTH_PCT=95
BAR_OFFSET_X_PCT=2.5
PAD=8                    # 6pt borders = 8px
bar_y=16                 # offset-y = 12pt = 16px
bar_h=40                 # height 24pt = 32px + 8px bottom border
bar_x=$(awk -v w="$screen_w" -v p="$BAR_OFFSET_X_PCT" -v pad="$PAD" 'BEGIN{printf "%d", w * p / 100 - pad}')
bar_w=$(( screen_w * BAR_WIDTH_PCT / 100 + 2 * PAD ))

log() { echo "$(date +%H:%M:%S) $*" >> "$LOG"; }
: > "$LOG"
log "=== started (screen ${screen_w}x${screen_h}, bar rect ${bar_x},${bar_y} ${bar_w}x${bar_h}) ==="

while true; do
    overlap=false

    n_bars=$(xdotool search --name "polybar" 2>/dev/null | wc -l)
    if (( n_bars > 4 )); then
        log "WARNING: $n_bars windows match the name 'polybar'"
    fi

    for id in $(xdotool search --onlyvisible ".*" 2>/dev/null); do
        wtype=$(xprop -id "$id" _NET_WM_WINDOW_TYPE 2>/dev/null)
        [[ "$wtype" != *_NET_WM_WINDOW_TYPE_NORMAL* ]] && continue
        eval "$(xdotool getwindowgeometry --shell "$id")"
        if (( X < bar_x + bar_w && X + WIDTH > bar_x && Y < bar_y + bar_h && Y + HEIGHT > bar_y )); then
            log "OVERLAP: '$(xdotool getwindowname "$id" 2>/dev/null)' at ${X},${Y} ${WIDTH}x${HEIGHT}"
            overlap=true
            break
        fi
    done

    if [[ "$overlap" = true && "$hidden" = false ]]; then
        polybar-msg -p "$(pgrep -f -- "polybar --reload google-top" | head -1)" cmd hide
        hidden=true
        log "DECISION: hide"
    elif [[ "$overlap" = false && "$hidden" = true ]]; then
        polybar-msg -p "$(pgrep -f -- "polybar --reload google-top" | head -1)" cmd show
        hidden=false
        log "DECISION: show"
    fi

    sleep 0.5
done
