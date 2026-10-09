#!/bin/bash
# install.sh — one-command install for the whole desktop.
#   git clone https://github.com/lichtmeer/cachyOS-XFCE-dotfiles
#   cd cachyOS-XFCE-dotfiles && bash install.sh
# Asks questions only when needed (weather location, wallpapers, theme).
# Safe to re-run; existing private files are kept.

set -e
REPO="$(pwd)"
[ -f "$REPO/polybar/config.ini" ] || { echo "Run from the repo root."; exit 1; }

# Never run as root: configs must go to YOUR home, not /root,
# and the desktop settings tools need your user session.
if [ "$(id -u)" = "0" ]; then
    echo "ERROR: do not run this with sudo or as root."
    echo "Run it as your normal user:  bash install.sh"
    echo "(It asks for your sudo password only for the pacman step.)"
    exit 1
fi

echo "=========================================="
echo " CachyOS + XFCE desktop — one-command setup"
echo " user: $(whoami)   host: $(uname -n)"
echo "=========================================="

echo "==> [1/9] System packages ..."
# check each package: installed+current = skip, installed+outdated = report,
# missing = install
PKGS="polybar picom rofi plank xdotool imagemagick pacman-contrib cachy-update alacritty conky cava playerctl curl noto-fonts noto-fonts-cjk ttf-nerd-fonts-symbols spotify-launcher"
MISSING=""; OUTDATED=""
for p in $PKGS; do
    if ! pacman -Qi "$p" >/dev/null 2>&1; then
        MISSING="$MISSING $p"
    elif [ -n "$(checkupdates 2>/dev/null | grep -F " $p " )" ] || \
         [ -n "$(checkupdates 2>/dev/null | grep -F "/$p ")" ]; then
        OUTDATED="$OUTDATED $p"
    fi
done
if [ -n "$OUTDATED" ]; then
    echo "    outdated (will NOT be touched):$OUTDATED"
    echo "    (run 'sudo pacman -Syu' yourself whenever you like)"
fi
if [ -n "$MISSING" ]; then
    echo "    installing missing:$MISSING"
    echo ""
    echo "    NOTE: the next prompt is your SUDO PASSWORD (for pacman)."
    echo "    It is NOT a login of any kind and this script never talks"
    echo "    to GitHub. Do not run the whole script with sudo instead."
    echo ""
    sudo pacman -S --needed --noconfirm $MISSING
else
    echo "    all packages already installed — nothing to do"
fi
echo "    done"

echo "==> [2/9] Polybar ..."
mkdir -p ~/.config/polybar
cp polybar/* ~/.config/polybar/
chmod +x ~/.config/polybar/*.sh
echo "    done (bar, watcher v3, update checker)"

echo "==> [3/9] Rofi ..."
mkdir -p ~/.config/rofi
cp rofi/* ~/.config/rofi/
chmod +x ~/.config/rofi/*.sh
echo "    done (launcher, power menu, wallpaper picker, alt-tab)"

echo "==> [4/9] Picom ..."
mkdir -p ~/.config/picom
cp picom/picom.conf ~/.config/picom/
echo "    done (shadow exclusion for the widget included)"

echo "==> [5/9] Conky glance widget ..."
bash conky/install.sh
echo "    done (may have asked for your weather location)"

echo "==> [6/9] Plank ..."
mkdir -p ~/.local/share/plank/themes/MaterialPill
cp plank/dock.theme ~/.local/share/plank/themes/MaterialPill/
echo "    done (pick 'MaterialPill' in plank's preferences once)"

echo "==> [7/9] Autostart + keybindings ..."
mkdir -p ~/.config/autostart
for f in autostart/*.desktop; do
    cp "$f" ~/.config/autostart/"$(basename "$f")"
done
xfconf-query -c xfce4-keyboard-shortcuts -p /xfwm4/switch_window_key -t string -s "" 2>/dev/null || \
    xfconf-query -c xfce4-keyboard-shortcuts -p /xfwm4/switch_window_key -n -t string -s ""
xfconf-query -c xfce4-keyboard-shortcuts -p /xfwm4/cycle_windows_key -t string -s "" 2>/dev/null || \
    xfconf-query -c xfce4-keyboard-shortcuts -p /xfwm4/cycle_windows_key -n -t string -s ""
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Alt>Tab" -n -t string -s "$HOME/.config/rofi/alt-tab.sh" 2>/dev/null || \
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Alt>Tab" -t string -s "$HOME/.config/rofi/alt-tab.sh"
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>Tab" -n -t string -s "rofi -show window -theme $HOME/.config/rofi/window.rasi" 2>/dev/null || \
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>Tab" -t string -s "rofi -show window -theme $HOME/.config/rofi/window.rasi"
echo "    done (Alt+Tab hold-and-release, Super+Tab classic)"

echo "==> XFCE settings (stock panel off, screen margins, launcher key) ..."
# stop the stock XFCE panel from starting (failsafe session)
xfconf-query -c xfce4-session -p /sessions/Failsafe/Client2_Command -n -t string -s /bin/true 2>/dev/null || \
    xfconf-query -c xfce4-session -p /sessions/Failsafe/Client2_Command -t string -s /bin/true
# remove existing panels
killall -q xfce4-panel 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels -n -t int -s 0 2>/dev/null || true
# screen-edge margins: 8px left/right/bottom, 0 top
for side in left right bottom; do
    xfconf-query -c xfwm4 -p /general/margin_$side -n -t int -s 8 2>/dev/null || \
        xfconf-query -c xfwm4 -p /general/margin_$side -t int -s 8
done
xfconf-query -c xfwm4 -p /general/margin_top -n -t int -s 0 2>/dev/null || \
    xfconf-query -c xfwm4 -p /general/margin_top -t int -s 0
# Super+Space opens the app launcher
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>space" -n -t string -s "rofi -show drun" 2>/dev/null || \
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>space" -t string -s "rofi -show drun"
# Super+less opens the wallpaper switcher
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>less" -n -t string -s "$HOME/.config/rofi/wallpaper.sh" 2>/dev/null || \
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>less" -t string -s "$HOME/.config/rofi/wallpaper.sh"

echo "    done (re-login shows the pill bar instead of the stock panel)"
echo "    NOTE: once, in Settings > Session and Startup > Sessions:"
echo "    clear saved sessions (prevents double-starting watchers)."

echo "==> [8/9] Wallpapers ..."
if [ -d "$REPO/wallpapers" ] && ls "$REPO"/wallpapers/* >/dev/null 2>&1; then
    read -r -p "    Copy the repo's wallpapers to ~/Pictures/wallpapers? [Y/n] " ANS
    if [ "${ANS:-y}" != "n" ] && [ "${ANS:-Y}" != "n" ]; then
        mkdir -p ~/Pictures/wallpapers
        cp wallpapers/* ~/Pictures/wallpapers/
        echo "    copied"
    else
        echo "    skipped"
    fi
fi

echo "==> [9/9] Icon pack + GTK theme (optional, from GitHub) ..."
read -r -p "    Install YAMIS icons + Orchis-Dark theme? (needs internet; ~1 min) [y/N] " THEME
if [ "$THEME" = "y" ] || [ "$THEME" = "Y" ]; then
    TMP=$(mktemp -d)
    echo "    downloading Orchis theme ..."
    if git clone --depth 1 https://github.com/vinceliuice/Orchis-theme.git "$TMP/Orchis" 2>/dev/null; then
        (cd "$TMP/Orchis" && bash install.sh --theme default --color dark >/dev/null 2>&1) \
            && echo "    Orchis-Dark installed" || echo "    Orchis install FAILED (continue; set theme manually later)"
    else
        echo "    Orchis download failed (offline? skipped)"
    fi
    echo "    downloading YAMIS icon set ..."
    if git clone --depth 1 https://bitbucket.org/dirn-typo/yet-another-monochrome-icon-set.git "$TMP/yamis" 2>/dev/null; then
        mkdir -p ~/.icons/YAMIS
        if cp -r "$TMP"/yamis/. ~/.icons/YAMIS/ 2>/dev/null; then
            echo "    YAMIS icons installed to ~/.icons/YAMIS/"
        else
            echo "    YAMIS copy failed (skipped)"
        fi
    else
        echo "    YAMIS download failed (offline? skipped)"
    fi
    rm -rf "$TMP"
    echo ""
    echo "    ONE MANUAL STEP LEFT (settings are yours to click):"
    echo "      Settings > Appearance  > Style: Orchis-Dark"
    echo "      Settings > Appearance  > Icons:  Yet-Another-Monochrome-Icon-Set"
    echo "      Settings > Window Manager > Style: Orchis-Dark"
else
    echo "    skipped (see INSTALL.md section 3 for the manual route)"
fi

echo "==> Verifying ..."
FAIL=0
for f in ~/.config/polybar/config.ini ~/.config/polybar/hide-when-overlapped.sh \
         ~/.config/rofi/alt-tab.sh ~/.config/picom/picom.conf \
         ~/.config/conky/glance.lua ~/.config/conky/cava.conf \
         ~/.local/share/plank/themes/MaterialPill/dock.theme \
         ~/.config/autostart/"Conky glance.desktop"; do
    [ -e "$f" ] && echo "    ok   $f" || { echo "    MISS $f"; FAIL=1; }
done
[ "$FAIL" = 1 ] && { echo "Some files missing — see the MISS lines."; exit 1; }

cat <<'BANNER'

==========================================
 INSTALL COMPLETE — log out and back in.
==========================================
 Then check: pill bar + dock + glance
 widget (weather, Spotify, spectrum),
 Alt+Tab hold-and-release, Super+Space
 launcher, F11 hides the bar.

 If you took the theme step:
  Settings > Appearance > Style: Orchis-Dark
  Settings > Appearance > Icons:  YAMIS
  Settings > Window Manager > Style: Orchis-Dark

 Private files kept on this machine:
  ~/.config/conky/location (weather)
==========================================
BANNER
