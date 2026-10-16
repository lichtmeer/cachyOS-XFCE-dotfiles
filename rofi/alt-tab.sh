#!/bin/bash
# alt-tab.sh — hold-and-release window switcher (v3, keycode-based).
# xinput test reports raw keycodes, not names: Alt_L = keycode 64.
# Commit happens on keycode 64's release.

THEME=$(xfconf-query -c xsettings -p /Net/IconThemeName 2>/dev/null)
ICON_ARGS=()
if [ -n "$THEME" ]; then
    ICON_ARGS=(-icon-theme "$THEME")
fi

rofi -show window -theme "$HOME/.config/rofi/window.rasi" "${ICON_ARGS[@]}" &
ROFI_PID=$!

KID=$(xinput list 2>/dev/null | sed -n 's/.*AT Translated Set 2 keyboard.*id=\([0-9]*\).*/\1/p' | head -1)
[ -z "$KID" ] && KID=$(xinput list 2>/dev/null | sed -n '/keyboard/!d; /Virtual/d; s/.*id=\([0-9]*\).*/\1/p' | head -1)

KEYS=/tmp/alt-tab-keys.$$
rm -f "$KEYS"
xinput test "$KID" > "$KEYS" 2>/dev/null &
XINPUT_PID=$!
trap 'kill $XINPUT_PID 2>/dev/null; rm -f "$KEYS"' EXIT

# commit as soon as Alt_L (keycode 64) is released
while kill -0 "$ROFI_PID" 2>/dev/null && kill -0 "$XINPUT_PID" 2>/dev/null; do
    if grep -q "key release 64" "$KEYS" 2>/dev/null; then
        xdotool key Return
        exit 0
    fi
    sleep 0.01
done
