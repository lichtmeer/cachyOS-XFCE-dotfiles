#!/bin/bash
# CachyOS updates module for polybar
# Checks for updates once at login (retries every 30s until the first check succeeds).
# Blue when updates are available, calm grey when the system is up to date.
# Right-click: re-check now. Click: run cachy-update in a terminal.
# Force-mode for testing: echo 7 > ~/.cache/polybar-cachyos-updates.force
CACHE="$HOME/.cache/polybar-cachyos-updates.state"
STAMP="$HOME/.cache/polybar-cachyos-updates.stamp"
FORCE="$HOME/.cache/polybar-cachyos-updates.force"
IDLE="#C3C7CF"
BLUE="#A4C3FF"
ICON=""

check() {
    local out
    if out=$(checkupdates 2>/dev/null); then
        printf '%s\n' "$out" | wc -l > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
    fi
}

rm -f "$CACHE"
(
    while [ ! -f "$CACHE" ]; do
        check
        [ -f "$CACHE" ] || sleep 30
    done
) &
retry_pid=$!

cleanup() { kill "$retry_pid" 2>/dev/null; }
trap cleanup EXIT
trap 'cleanup; exit' TERM INT

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
        line="%{F${BLUE}}${ICON} ${n}"
    elif [ "$pending" = true ]; then
        line="%{F${IDLE}}${ICON}"
    else
        line="%{F${IDLE}}${ICON} ..."
    fi

    if [ "$line" != "$last" ]; then
        printf '%s\n' "$line"
        last="$line"
    fi

    if [ -f "$STAMP" ]; then
        rm -f "$STAMP"
        check &
    fi

    sleep 1
done
