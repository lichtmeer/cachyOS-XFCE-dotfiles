#!/bin/bash
# Smooth wallpaper change: crossfades from the current wallpaper to the new one.
# Usage: wallpaper-fade.sh /full/path/to/new-wallpaper
# Blend frames are rendered small (half HD, JPG) for speed - the eye can't
# tell during a sub-second fade, and the final wallpaper is set full-size.

NEW="$1"
[ -n "$NEW" ] && [ -f "$NEW" ] || exit 1

FRAMES=10
STEP=0.07
CACHE="$HOME/.cache/wallpaper-fade"
mkdir -p "$CACHE"

# Only one fade at a time
exec 9>"$CACHE/lock"
flock 9

props() { xfconf-query -c xfce4-desktop -l 2>/dev/null | grep 'last-image'; }

set_wall() {
    local p
    for p in $(props); do
        xfconf-query -c xfce4-desktop -p "$p" -s "$1"
    done
}

first_prop=$(props | head -1)
OLD=""
[ -n "$first_prop" ] && OLD=$(xfconf-query -c xfce4-desktop -p "$first_prop" 2>/dev/null)

# No fade possible or needed: switch instantly.
if [ -z "$OLD" ] || [ ! -f "$OLD" ] || [ "$OLD" = "$NEW" ]; then
    set_wall "$NEW"
    exit 0
fi

# Pre-render blend frames (half HD, JPG): frame 1 = mostly OLD ... frame 9 = almost NEW.
render_ok=true
for (( i=1; i<FRAMES; i++ )); do
    pct=$(( 100 * (FRAMES - i) / FRAMES ))
    composite -blend "$pct" \
        \( "$OLD" -resize 960x540 \) \
        \( "$NEW" -resize 960x540 \) \
        "$CACHE/frame-$i.jpg" 2>/dev/null
    [ -s "$CACHE/frame-$i.jpg" ] || render_ok=false
done

# Play the fade.
if [ "$render_ok" = true ]; then
    for (( i=1; i<FRAMES; i++ )); do
        set_wall "$CACHE/frame-$i.jpg"
        sleep "$STEP"
    done
fi

# Finish on the real new wallpaper and clean up.
set_wall "$NEW"
rm -f "$CACHE"/frame-*.jpg
