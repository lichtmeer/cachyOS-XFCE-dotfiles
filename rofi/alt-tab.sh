#!/bin/bash
# alt-tab.sh — hold-and-release window switcher.
# Opens the rofi window switcher; a watcher commits the highlighted
# entry when the user releases the Alt key (like Windows Alt+Tab).

# start rofi windowed, remember its pid
rofi -show window -theme "$HOME/.config/rofi/window.rasi" &
ROFI_PID=$!

# wait until rofi is actually up
for i in $(seq 1 40); do
    kill -0 "$ROFI_PID" 2>/dev/null || exit 0
    xdotool search --name "Switch" 2>/dev/null | grep -q . && break
    sleep 0.01
done

# watch the Alt modifier; when it is fully released, send Enter to rofi
while kill -0 "$ROFI_PID" 2>/dev/null; do
    STATE=$(xdotool getmodifierstate 2>/dev/null)
    if ! echo "$STATE" | grep -q "alt"; then
        # small debounce: make sure Alt is really gone, not mid-repeat
        sleep 0.006
        STATE2=$(xdotool getmodifierstate 2>/dev/null)
        if ! echo "$STATE2" | grep -q "alt"; then
            xdotool key --window "$(xdotool search --name 'Switch' | head -1)" Return
            exit 0
        fi
    fi
    sleep 0.006
done
