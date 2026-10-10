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
echo "    This step makes sure every tool the desktop needs is installed:"
echo "    the bar (polybar), compositor (picom), menus (rofi), dock (plank),"
echo "    terminal (alacritty), widget (conky), spectrum (cava), and helpers."
# check each package: installed+current = skip, installed+outdated = report,
# missing = install
PKGS="polybar picom rofi plank xdotool xorg-xrandr imagemagick pacman-contrib cachy-update alacritty conky cava playerctl curl noto-fonts noto-fonts-cjk ttf-nerd-fonts-symbols"
echo "    checking every package — watching me work:"
MISSING=""; OUTDATED=""
for p in $PKGS; do
    if ! pacman -Qi "$p" >/dev/null 2>&1; then
        MISSING="$MISSING $p"
        echo "        MISSING : $p"
    elif [ -n "$(checkupdates 2>/dev/null | grep -F " $p " )" ] || \
         [ -n "$(checkupdates 2>/dev/null | grep -F "/$p ")" ]; then
        OUTDATED="$OUTDATED $p"
        echo "        outdated: $p (installed, not touched)"
    else
        echo "        ok      : $p"
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
    sudo pacman -S --needed --noconfirm --color=always $MISSING
else
    echo "    all packages already installed — nothing to do"
fi
echo "    done"

echo "==> Spotify (optional — needed for the widget's music section) ..."
# ALWAYS ask — even if already installed (the user decides every run;
# --needed makes a redundant install a no-op, never a reinstall)
if pacman -Qi spotify-launcher >/dev/null 2>&1; then
    echo "    spotify-launcher is already installed."
fi
echo "    The glance widget shows track info + spectrum by talking to a"
echo "    Spotify player via playerctl. Without any Spotify installed,"
echo "    that section stays empty (everything else works)."
read -r -p "    Install spotify-launcher from the official repos now? [y/N] " SP
if [ "$SP" = "y" ] || [ "$SP" = "Y" ]; then
    echo ""
    echo "    NOTE: the next prompt is your SUDO PASSWORD (for pacman)."
    echo "    It is NOT a login of any kind."
    echo ""
    sudo pacman -S --needed --noconfirm spotify-launcher \
        && echo "    spotify-launcher ready" \
        || echo "    install failed — continue anyway (widget works otherwise)"
else
    echo "    skipped — install later with: sudo pacman -S spotify-launcher"
fi

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
# take Alt+Tab and Super+Tab away from xfwm4: its key->action MAPPINGS
# under /xfwm4/custom/ must be overwritten with 'empty' (= unbound).
# Setting the action value alone is not enough; deleting the mapping
# would fall back to the factory default (which grabs the key).
for prop in "/xfwm4/custom/<Alt>Tab" "/xfwm4/custom/<Super>Tab" "/xfwm4/custom/<Alt><Shift>Tab"; do
    xfconf-query -c xfce4-keyboard-shortcuts -p "$prop" -n -t string -s empty 2>/dev/null || true
    xfconf-query -c xfce4-keyboard-shortcuts -p "$prop" -s empty -t string 2>/dev/null || true
done
xfconf-query -c xfce4-keyboard-shortcuts -p /xfwm4/switch_window_key -n -t string -s empty 2>/dev/null || true
xfconf-query -c xfce4-keyboard-shortcuts -p /xfwm4/cycle_windows_key -n -t string -s empty 2>/dev/null || true
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
# picom replaces xfwm4's own compositor — turn it off
xfconf-query -c xfwm4 -p /general/use_compositing -n -t bool -s false 2>/dev/null || \
    xfconf-query -c xfwm4 -p /general/use_compositing -t bool -s false
# workspace margins: keep windows off the dock and the invisible bar strip.
# top=0 (the bar watcher handles fullscreen itself), left/right=55
# (dock space), bottom=15
xfconf-query -c xfwm4 -p /general/margin_top -n -t int -s 0 2>/dev/null || \
    xfconf-query -c xfwm4 -p /general/margin_top -t int -s 0
for side in left right; do
    xfconf-query -c xfwm4 -p /general/margin_$side -n -t int -s 55 2>/dev/null || \
        xfconf-query -c xfwm4 -p /general/margin_$side -t int -s 55
done
xfconf-query -c xfwm4 -p /general/margin_bottom -n -t int -s 15 2>/dev/null || \
    xfconf-query -c xfwm4 -p /general/margin_bottom -t int -s 15
echo "    workspace margins set: top 0, left/right 55, bottom 15"
# Super+Space opens the app launcher
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>space" -n -t string -s "rofi -show drun" 2>/dev/null || \
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>space" -t string -s "rofi -show drun"
# Super+t opens the terminal
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>t" -n -t string -s "alacritty" 2>/dev/null || \
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>t" -t string -s "alacritty"
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
        # set a random wallpaper so the switcher has a starting point
        RAND=$(find "$HOME/Pictures/wallpapers" -maxdepth 1 -type f \
            \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n1)
        if [ -n "$RAND" ]; then
            echo "    setting a random wallpaper as the starting point ..."
            SETCOUNT=0
            # machines that already had a wallpaper: update the existing
            # per-workspace settings
            while read -r prop; do
                [ -n "$prop" ] || continue
                if xfconf-query -c xfce4-desktop -p "$prop" -s "$RAND"; then
                    SETCOUNT=$((SETCOUNT+1))
                fi
            done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep 'last-image' || true)
            # The property path contains the MONITOR NAME, which is not
            # fixed: it comes from the hardware/driver (monitor0,
            # monitorVirtual-1, monitorDP-1, ...). Hardcoding any name
            # writes to a monitor that may not exist — the setting lands
            # in xfconf but xfdesktop never reads it. So ASK THE SYSTEM:
            # xrandr names the connected outputs; xfce4-desktop uses
            # "monitor<NAME>".
            MONITOR=$(xrandr --query 2>/dev/null | awk '/ connected/ {print $1; exit}')
            if [ -z "$MONITOR" ]; then
                # xrandr unavailable (should not happen — it is in the
                # package list): look for monitor names the desktop or
                # the settings GUI already used in backdrop props.
                # Real output names are never bare "0", so prefer a
                # non-"0" name.
                MONITOR=$(xfconf-query -c xfce4-desktop -l 2>/dev/null \
                    | sed -n 's|^/backdrop/screen0/monitor\([^/]*\)/.*|\1|p' \
                    | sort -u | grep -v '^0$' | head -1)
                if [ -n "$MONITOR" ]; then
                    echo "    (xrandr missing — monitor name from existing settings)"
                fi
            fi
            if [ -z "$MONITOR" ]; then
                MONITOR="0"
            fi
            BASE="/backdrop/screen0/monitor$MONITOR"
            echo "    monitor detected: $MONITOR"
            # ensure the display-style props exist (xfdesktop will not
            # paint an image without them; the GUI creates them on first
            # manual set — the installer must create them itself)
            if ! xfconf-query -c xfce4-desktop -p "$BASE/image-show" >/dev/null 2>&1; then
                xfconf-query -c xfce4-desktop -p "$BASE/image-show" -n -t bool -s true 2>/dev/null || true
            fi
            if ! xfconf-query -c xfce4-desktop -p "$BASE/image-style" >/dev/null 2>&1; then
                xfconf-query -c xfce4-desktop -p "$BASE/image-style" -n -t int -s 5 2>/dev/null || true
            fi
            # set the image on the REAL monitor path (create if missing)
            if xfconf-query -c xfce4-desktop -p "$BASE/last-image" >/dev/null 2>&1; then
                if xfconf-query -c xfce4-desktop -p "$BASE/last-image" -s "$RAND"; then
                    SETCOUNT=$((SETCOUNT+1))
                fi
            else
                if xfconf-query -c xfce4-desktop -p "$BASE/last-image" \
                    -n -t string -s "$RAND"; then
                    SETCOUNT=$((SETCOUNT+1))
                fi
            fi
            # also update any existing per-workspace settings (used when
            # per-workspace wallpapers are ON)
            while read -r prop; do
                [ -n "$prop" ] || continue
                if xfconf-query -c xfce4-desktop -p "$prop" -s "$RAND"; then
                    SETCOUNT=$((SETCOUNT+1))
                fi
            done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep 'last-image' || true)
            # verify for real: read the value back — trust nothing
            STORED=$(xfconf-query -c xfce4-desktop -p "$BASE/last-image" 2>/dev/null)
            if [ "$STORED" = "$RAND" ]; then
                xfdesktop --reload 2>/dev/null || true
                echo "    set: $RAND"
                echo "    (Super+< now works — the switcher needs a current wallpaper)"
            else
                echo "    WARNING: could not set the wallpaper automatically"
                echo "    (read-back check failed). After logging in, press"
                echo "    Super+< and pick one — the switcher works from then on."
            fi
        fi
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
        rm -rf ~/.icons/YAMIS
        mkdir -p ~/.icons/YAMIS
        # copy WITHOUT the .git folder: git's read-only pack files make
        # re-runs of cp fail with "Permission denied" (and shipping .git
        # inside an icon theme is wrong anyway)
        if (cd "$TMP/yamis" && tar --exclude=.git -cf - .) | tar -xf - -C ~/.icons/YAMIS/; then
            echo "    YAMIS icons installed to ~/.icons/YAMIS/"
        else
            echo "    YAMIS copy failed (skipped)"
        fi
    else
        echo "    YAMIS download failed (offline? skipped)"
    fi
    rm -rf "$TMP"
    echo "==> Applying YAMIS icons + Orchis-Dark theme to your desktop ..."
    xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "Orchis-Dark" 2>/dev/null || \
        xfconf-query -c xsettings -p /Net/ThemeName -t string -s "Orchis-Dark"
    if [ -d ~/.icons/YAMIS ]; then
        xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "YAMIS" 2>/dev/null || \
            xfconf-query -c xsettings -p /Net/IconThemeName -t string -s "YAMIS"
    fi
    xfconf-query -c xfwm4 -p /general/theme -n -t string -s "Orchis-Dark" 2>/dev/null || \
        xfconf-query -c xfwm4 -p /general/theme -t string -s "Orchis-Dark"
    echo "    applied to your session: GTK theme Orchis-Dark, window theme"
    echo "    Orchis-Dark, icons YAMIS (fully visible after the next log-in)"

    echo "==> Applying the theme to the login screen (LightDM greeter) ..."
    GREETER_CONF="/etc/lightdm/lightdm-gtk-greeter.conf"
    if [ -f "$GREETER_CONF" ]; then
        echo "    LightDM GTK greeter found — giving it the same look."
        echo "    NOTE: the next prompt is your SUDO PASSWORD (to edit the"
        echo "    greeter config in /etc). It is NOT a login of any kind."
        sudo sed -i '/^theme-name=/d;/^icon-theme-name=/d' "$GREETER_CONF"
        if grep -q '^\[greeter\]' "$GREETER_CONF" 2>/dev/null; then
            sudo sed -i '/^\[greeter\]/a theme-name=Orchis-Dark\nicon-theme-name=YAMIS' "$GREETER_CONF"
        else
            printf '[greeter]\ntheme-name=Orchis-Dark\nicon-theme-name=YAMIS\n' | sudo tee -a "$GREETER_CONF" >/dev/null
        fi
        echo "    done: login screen now uses Orchis-Dark + YAMIS too"
    else
        echo "    no LightDM GTK greeter config found — skipped"
        echo "    (if your login screen is a different greeter, set it manually)"
    fi
    echo ""
    echo "    Nothing left to click: theme, window style and icons are"
    echo "    applied automatically (login screen too, when found)."
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


 Private files kept on this machine:
  ~/.config/conky/location (weather)
==========================================
BANNER

# WHY LOGOUT: the autostart entries (picom, polybar, plank, the
# glance widget) only START in a fresh session; keybindings, the
# disabled stock panel, the compositor switch and the theme/icon
# settings are session settings that apply fully only when the
# session restarts. Logging out and back in applies everything at once.
read -r -p "Log out NOW to apply everything? [y/N] " LOGOUT
if [ "$LOGOUT" = "y" ] || [ "$LOGOUT" = "Y" ]; then
    echo "    logging out in 3 seconds ..."
    sleep 3
    xfce4-session-logout --logout
else
    echo "    not logging out — everything is applied after your next login"
fi
