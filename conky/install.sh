#!/bin/bash
# install.sh: apply the conky-glance widget (with cava spectrum) to this system.
# Run from the repo:  bash conky/install.sh   (safe to re-run)

set -e
SRC="$(cd "$(dirname "$0")" && pwd)"
CFG="$HOME/.config/conky"

echo "==> Checking packages..."
command -v cava  >/dev/null 2>&1 || { echo "    cava missing:  sudo pacman -S cava";  exit 1; }
command -v conky >/dev/null 2>&1 || { echo "    conky missing: sudo pacman -S conky"; exit 1; }

echo "==> Backing up existing conky config..."
[ -d "$CFG" ] && cp -r "$CFG" "$CFG.bak-$(date +%Y%m%d-%H%M%S)"

echo "==> Installing files to $CFG ..."
mkdir -p "$CFG"
cp "$SRC/conky.conf"         "$CFG/"
cp "$SRC/glance.lua"         "$CFG/"
cp "$SRC/weather.sh"         "$CFG/"
cp "$SRC/spotify-status.sh"  "$CFG/"
cp "$SRC/cava.conf"          "$CFG/"
cp "$SRC/cava-spectrum.sh"   "$CFG/"
chmod +x "$CFG/weather.sh" "$CFG/spotify-status.sh" "$CFG/cava-spectrum.sh"

echo "==> Pinning cava to your default audio output ..."
SINK=$(pactl info | grep 'Default Sink' | awk '{print $3}')
if [ -n "$SINK" ]; then
    sed -i "s|^source *=.*|source = ${SINK}.monitor|" "$CFG/cava.conf"
    echo "    source = ${SINK}.monitor"
fi

echo "==> Installing autostart entry ..."
mkdir -p "$HOME/.config/autostart"
cp "$SRC/../autostart/Conky glance.desktop" "$HOME/.config/autostart/"
rm -f "$HOME/.config/autostart/conky.desktop" 2>/dev/null || true

echo "==> Starting the widget ..."
mkdir -p "$HOME/.cache/conky-glance"
killall -q conky 2>/dev/null || true
pkill -f "cava.*$CFG/cava.conf" 2>/dev/null || true
sleep 0.5
nohup bash "$CFG/cava-spectrum.sh" >/dev/null 2>&1 &
nohup conky -c "$CFG/conky.conf" >/dev/null 2>&1 &

echo "Done. Play something in Spotify — the spectrum appears"
echo "between the artist line and the progress bar."
