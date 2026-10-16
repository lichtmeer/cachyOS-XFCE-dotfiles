#!/bin/bash
# Smooth wallpaper change: true 60fps crossfade, played as a video
# on the DESKTOP LAYER - behind windows, behind the bar and dock.
# Usage: wallpaper-fade.sh /full/path/to/new-wallpaper
#
# How: renders a short crossfade video (old -> new) with ffmpeg, plays
# it with mpv in a borderless fullscreen window, and pushes that window
# BELOW all normal windows with wmctrl. The real wallpaper switch
# happens underneath while the video covers only the wallpaper area.
# Falls back to an instant switch if mpv/wmctrl/ffmpeg are missing.

NEW="$1"
[ -n "$NEW" ] && [ -f "$NEW" ] || exit 1

DUR=0.8        # fade length in seconds
CACHE="$HOME/.cache/wallpaper-fade"
mkdir -p "$CACHE"

# Only one fade at a time.
exec 9>"$CACHE/lock"
flock 9

# --- check tools; fall back to instant switch if anything is missing ---
for tool in mpv wmctrl ffmpeg; do
    command -v "$tool" >/dev/null 2>&1 || { echo "wallpaper-fade: $tool missing - instant switch" >&2; set_wall_instant=1; }
done

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
if [ -z "$set_wall_instant" ] && { [ -z "$OLD" ] || [ ! -f "$OLD" ] || [ "$OLD" = "$NEW" ]; }; then
    set_wall "$NEW"; exit 0
fi
[ -n "$set_wall_instant" ] && { set_wall "$NEW"; exit 0; }

# --- render the crossfade video once (sub-second, before playback) ---
VID="$CACHE/fade.mp4"
ffmpeg -y -loglevel error \
    -loop 1 -t "$DUR" -i "$OLD" \
    -loop 1 -t "$DUR" -i "$NEW" \
    -filter_complex "[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080[o];[1:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080[n];[o][n]xfade=transition=fade:duration=${DUR}:offset=0" \
    -r 60 -pix_fmt yuv420p -an "$VID" 2>/dev/null

if [ ! -s "$VID" ]; then
    # render failed: plain switch, never leave the desktop broken
    set_wall "$NEW"; exit 0
fi

# --- play it on the desktop layer, hidden behind everything ---
mpv --really-quiet --no-config \
    --fullscreen --keep-open=no --loop=no \
    --force-window=yes --cursor-autohide=always \
    "$VID" &
MPV_PID=$!

# find mpv's window and push it below all normal windows
WMID=""
for i in $(seq 1 20); do
    WMID=$(xdotool search --pid "$MPV_PID" 2>/dev/null | head -1)
    [ -n "$WMID" ] && break
    kill -0 "$MPV_PID" 2>/dev/null || break
    sleep 0.05
done
if [ -n "$WMID" ]; then
    wmctrl -i -r "$WMID" -b add,below
    wmctrl -i -r "$WMID" -b add,skip_taskbar,skip_pager
else
    # no window id found: too risky to leave it on top - kill and switch
    kill "$MPV_PID" 2>/dev/null
    set_wall "$NEW"; rm -f "$VID"; exit 0
fi

# switch the real wallpaper underneath while the video plays
sleep 0.2
set_wall "$NEW"

# wait for playback to end, then clean up
wait "$MPV_PID" 2>/dev/null
rm -f "$VID"
