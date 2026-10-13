#!/bin/bash
# install.sh: apply the conky-glance widget (with pyspectrum) to this system.
# Run from the repo:  bash conky/install.sh   (safe to re-run)

set -e
SRC="$(cd "$(dirname "$0")" && pwd)"
CFG="$HOME/.config/conky"

# Never run as root: the widget belongs to the user session.
if [ "$(id -u)" = "0" ]; then
    echo "ERROR: do not run this with sudo or as root."
    echo "Run it as your normal user:  bash conky/install.sh"
    exit 1
fi

echo "==> Checking packages..."
command -v parecord >/dev/null 2>&1 || { echo "    parecord missing: sudo pacman -S pulseaudio-utils"; exit 1; }
command -v conky >/dev/null 2>&1 || { echo "    conky missing: sudo pacman -S conky"; exit 1; }

echo "==> Checking conky version (1.25.x has a mouse regression) ..."
if command -v conky >/dev/null 2>&1; then
    VER=$(conky --version 2>/dev/null | grep -oPm1 "(?<=conky )\d+\.\d+(\.\d+)?")
    case "$VER" in
        1.25*)
            echo "    WARNING: conky $VER has a mouse-event regression:"
            echo "             the widget's transport buttons will NOT work."
            echo "             Fix: install 1.24.2 and pin it:"
            echo "               sudo pacman -U /var/cache/pacman/pkg/conky-1.24.2-*.pkg.tar.zst"
            echo "               then add 'IgnorePkg = conky' to /etc/pacman.conf"
            echo "             (see changes/2026-10-13-conky-1.25-mouse-regression.md)"
            ;;
        "")
            echo "    (could not read conky version - continuing)"
            ;;
        *)
            echo "    ok: conky $VER"
            ;;
    esac
fi

echo "==> Backing up existing conky config..."
[ -d "$CFG" ] && cp -r "$CFG" "$CFG.bak-$(date +%Y%m%d-%H%M%S)"

echo "==> Installing files to $CFG ..."
mkdir -p "$CFG"
cp "$SRC/conky.conf"         "$CFG/"
cp "$SRC/glance.lua"         "$CFG/"
cp "$SRC/weather.sh"         "$CFG/"
cp "$SRC/spotify-status.sh"  "$CFG/"
cp "$SRC/pyspectrum.py"       "$CFG/"
cp "$SRC/cava-spectrum.sh"   "$CFG/"
chmod +x "$CFG/weather.sh" "$CFG/spotify-status.sh" "$CFG/cava-spectrum.sh"

echo "==> Weather location ..."
if [ -f "$CFG/location" ]; then
    echo "    keeping existing location (private, never committed)"
else
    read -r -p "    Your weather location for wttr.in (e.g. city name or zip code; empty = auto-detect): " LOC
    if [ -n "$LOC" ]; then
        printf '%s' "$LOC" > "$CFG/location"
        echo "    saved to $CFG/location (private; this file is never committed)"
    else
        echo "    no location given — wttr.in will auto-detect by IP"
    fi
fi

echo "==> Installing autostart entry ..."
mkdir -p "$HOME/.config/autostart"
cp "$SRC/../autostart/Conky glance.desktop" "$HOME/.config/autostart/"
rm -f "$HOME/.config/autostart/conky.desktop" 2>/dev/null || true

echo "==> Starting the widget ..."
mkdir -p "$HOME/.cache/conky-glance"
killall -q conky 2>/dev/null || true
pkill -f "cava-spectrum.sh" 2>/dev/null || true
sleep 0.5
nohup bash "$CFG/cava-spectrum.sh" >/dev/null 2>&1 &
nohup conky -c "$CFG/conky.conf" >/dev/null 2>&1 &

echo "Done. Play something in Spotify — the spectrum appears"
echo "between the artist line and the progress bar."
