#!/bin/bash
# CachyOS updates module for polybar
# v3: checks at login, then every hour (retries every 30s while the network is not up yet).
# White icon when calm, pulses white<->blue with the count while updates are available.
# Left-click: run cachy-update in a terminal. Right-click: re-check now.
# Test mode: echo 7 > ~/.cache/polybar-cachyos-updates.force  (rm the file to end test)
CACHE="$HOME/.cache/polybar-cachyos-updates.state"
STAMP="$HOME/.cache/polybar-cachyos-updates.stamp"
FORCE="$HOME/.cache/polybar-cachyos-updates.force"
IDLE="#E6E1E5"
PULSE_A="#E6E1E5"
PULSE_B="#A4C3FF"
ICON=""

check() {
    local out n
    if out=$(checkupdates 2>/dev/null); then
        if [ -z "$out" ]; then
            n=0
        else
            n=$(printf '%s\n' "$out" | grep -c .)
        fi
        printf '%s' "$n" > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
    fi
}

rm -f "$CACHE"
(
    first=true
    while true; do
        if [ "$first" = true ] && [ ! -f "$CACHE" ]; then
            check
            [ -f "$CACHE" ] || sleep 30
        else
            first=false
            sleep 3600
            check
        fi
    done
) &
retry_pid=$!

cleanup() { kill "$retry_pid" 2>/dev/null; }
trap cleanup EXIT
trap 'cleanup; exit' TERM INT

toggle=0
last=""
while true; do
    pending=false
    n=""
    if [ -f "$FORCE" ]; then
        n=$(cat "$FORCE" 2>/dev/null)
        pending=true
    elif [ -f "$CACHE" ]; then
        n=$(cat "$CACHE" 2>/dev/null)
        pending=true
    fi

    if [ "$pending" = true ] && [ "$n" -gt 0 ] 2>/dev/null; then
        toggle=$(( 1 - toggle ))
        if [ "$toggle" -eq 1 ]; then color=$PULSE_A; else color=$PULSE_B; fi
        line="%{F${color}}${ICON} ${n}"
    else
        line="%{F${IDLE}}${ICON}"
    fi

    if [ "$line" != "$last" ]; then
        printf '%s\n' "$line"
        last="$line"
    fi

    if [ -f "$STAMP" ]; then
        rm -f "$STAMP"
        check &
    fi

    sleep 0.5
done
