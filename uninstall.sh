#!/bin/bash
# uninstall.sh — puts your machine back to how it was before install.sh.
# Works from the backup install.sh made on its FIRST run:
#   ~/.local/share/cachyos-dotfiles-backup
# Run from the repo root:  bash uninstall.sh
# Never run with sudo — it asks for your sudo password only where needed.

set -e
REPO="$(pwd)"
[ -f "$REPO/install.sh" ] || { echo "Run from the repo root."; exit 1; }

if [ "$(id -u)" = "0" ]; then
    echo "ERROR: do not run this with sudo or as root."
    echo "Run it as your normal user:  bash uninstall.sh"
    exit 1
fi

BK="$HOME/.local/share/cachyos-dotfiles-backup"
if [ ! -f "$BK/.done" ]; then
    echo "No backup found at: $BK"
    echo "Nothing to revert (this machine never ran install.sh with the"
    echo "backup step, or the backup was already removed)."
    exit 0
fi

echo "=========================================="
echo " Uninstall — reverting the CachyOS + XFCE desktop"
echo " user: $(whoami)   host: $(uname -n)"
echo "=========================================="
read -r -p "Continue? [y/N] " ANS
[ "$ANS" = "y" ] || [ "$ANS" = "Y" ] || { echo "aborted"; exit 0; }

echo "==> [1/6] Stopping the desktop apps this setup starts ..."
killall -q polybar picom plank conky 2>/dev/null || true
echo "    done"

echo "==> [2/6] Restoring your files (replaced ones) and removing ours ..."
# 1. remove files that did NOT exist before install.sh created them
if [ -s "$BK/new.list" ]; then
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        rm -rf -- "$f" && echo "    removed (was new): $f"
    done < "$BK/new.list"
fi
# 2. put back every file that existed before
if [ -s "$BK/restored.list" ]; then
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        case "$f" in
            "$HOME/.icons/YAMIS")
                # icons were backed up as one tar (see install.sh)
                if [ -f "$BK/files/yamis-icons.tar" ]; then
                    # tar was created inside ~/.icons, paths start at YAMIS/
                    rm -rf -- "$f"
                    mkdir -p -- "$(dirname "$f")"
                    (cd "$(dirname "$f")" && tar -xf "$BK/files/yamis-icons.tar") \
                        && echo "    restored: $f (from tar)" \
                        || echo "    WARNING: could not restore $f"
                else
                    rm -rf -- "$f"
                    echo "    removed (no backup copy existed): $f"
                fi
                ;;
            *)
                if [ -e "$BK/files/$f" ]; then
                    rm -rf -- "$f"
                    cp -a -- "$BK/files/$f" "$f" && echo "    restored: $f"
                else
                    echo "    WARNING: no backup copy for $f - left in place"
                fi
                ;;
        esac
    done < "$BK/restored.list"
fi
echo "    done"

echo "==> [3/6] Restoring your XFCE settings ..."
# restore each saved xfconf value; settings that had NO value before
# (not in the saved list) get reset to factory default instead
if [ -s "$BK/xfconf-before.tsv" ]; then
    while IFS='|' read -r chan prop val; do
        [ -n "$chan" ] || continue
        if xfconf-query -c "$chan" -p "$prop" >/dev/null 2>&1; then
            if xfconf-query -c "$chan" -p "$prop" -s "$val" 2>/dev/null; then
                echo "    restored: $chan $prop"
            else
                xfconf-query -c "$chan" -p "$prop" -r -R 2>/dev/null || true
                echo "    reset:    $chan $prop (value could not be restored)"
            fi
        else
            xfconf-query -c "$chan" -p "$prop" -n -t string -s "$val" 2>/dev/null \
                && echo "    restored: $chan $prop" \
                || echo "    skip:     $chan $prop"
        fi
    done < "$BK/xfconf-before.tsv"
fi
# everything the installer touches that had no saved value: remove the
# property so XFCE falls back to its factory default
for prop in "/xfwm4/custom/<Alt>Tab" "/xfwm4/custom/<Super>Tab" \
            "/xfwm4/custom/<Alt><Shift>Tab" "/xfwm4/switch_window_key" \
            "/xfwm4/cycle_windows_key" "/commands/custom/<Alt>Tab" \
            "/commands/custom/<Super>Tab" "/commands/custom/<Super>space" \
            "/commands/custom/<Super>t" "/commands/custom/<Super>less"; do
    if ! grep -q "^xfce4-keyboard-shortcuts|$prop|" "$BK/xfconf-before.tsv" 2>/dev/null; then
        xfconf-query -c xfce4-keyboard-shortcuts -p "$prop" -r 2>/dev/null || true
        echo "    reset:    $prop (factory default)"
    fi
done
for chanprop in "xfce4-session|/sessions/Failsafe/Client2_Command" \
                "xfce4-panel|/panels" \
                "xfwm4|/general/use_compositing" \
                "xfwm4|/general/margin_top" \
                "xfwm4|/general/margin_left" \
                "xfwm4|/general/margin_right" \
                "xfwm4|/general/margin_bottom" \
                "xfwm4|/general/theme" \
                "xsettings|/Net/ThemeName" \
                "xsettings|/Net/IconThemeName"; do
    chan="${chanprop%%|*}"; prop="${chanprop#*|}"
    if ! grep -q "^$chan|$prop|" "$BK/xfconf-before.tsv" 2>/dev/null; then
        xfconf-query -c "$chan" -p "$prop" -r 2>/dev/null || true
        echo "    reset:    $chan $prop (factory default)"
    fi
done
# wallpaper per-monitor/per-workspace last-image settings created by the
# installer: remove them (desktop shows the default background again)
while read -r prop; do
    [ -n "$prop" ] || continue
    if ! grep -q "^xfce4-desktop|$prop|" "$BK/xfconf-before.tsv" 2>/dev/null; then
        xfconf-query -c xfce4-desktop -p "$prop" -r 2>/dev/null || true
        echo "    reset:    $prop"
    fi
done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep 'last-image' || true)
# bring back the stock panel and xfwm4's own compositor now
xfconf-query -c xfce4-panel -p /panels -n -t int -s 1 2>/dev/null || \
    xfconf-query -c xfce4-panel -p /panels -t int -s 1 2>/dev/null || true
xfdesktop --reload 2>/dev/null || true
echo "    done"

echo "==> [4/6] System-level changes (udev rule, login screen, video group) ..."
read -r -p "    Revert these too? (asks for your sudo password) [Y/n] " SUDOANS
if [ "${SUDOANS:-y}" != "n" ]; then
    # backlight udev rule written by install.sh
    if [ -f /etc/udev/rules.d/99-backlight.rules ]; then
        sudo rm /etc/udev/rules.d/99-backlight.rules \
            && echo "    removed: /etc/udev/rules.d/99-backlight.rules"
    fi
    # login screen theme lines written by install.sh
    GREETER_CONF="/etc/lightdm/lightdm-gtk-greeter.conf"
    if [ -f "$GREETER_CONF" ] && grep -q '^theme-name=Orchis-Dark' "$GREETER_CONF"; then
        sudo sed -i '/^theme-name=Orchis-Dark$/d;/^icon-theme-name=YAMIS$/d' "$GREETER_CONF" \
            && echo "    login screen: theme lines removed (back to default)"
    fi
    # video group membership
    if id -nG "$USER" | tr ' ' '\n' | grep -qx video; then
        sudo gpasswd -d "$USER" video \
            && echo "    removed $USER from the video group (active after next login)"
    fi
else
    echo "    skipped (system-level changes kept)"
fi
echo "    done"

echo "==> [5/6] Packages (optional — keeps anything you installed yourself) ..."
read -r -p "    Remove the desktop's packages too? (NOT recommended if other programs need them) [y/N] " PKGANS
if [ "$PKGANS" = "y" ] || [ "$PKGANS" = "Y" ]; then
    echo "    NOTE: the next prompt is your SUDO PASSWORD (for pacman)."
    sudo pacman -Rns --noconfirm polybar picom rofi plank xdotool xorg-xrandr \
        xorg-xinput wmctrl mpv imagemagick pacman-contrib cachy-update \
        alacritty fastfetch conky playerctl 2>/dev/null \
        && echo "    packages removed" \
        || echo "    some packages kept (still needed by something else - that is fine)"
else
    echo "    skipped (packages stay installed)"
fi

echo "==> [6/6] Cleanup ..."
read -r -p "    Delete the backup folder $BK too? [y/N] " BKANS
if [ "$BKANS" = "y" ] || [ "$BKANS" = "Y" ]; then
    rm -rf "$BK" && echo "    backup deleted"
else
    echo "    backup kept at: $BK"
fi

cat <<'BANNER'

==========================================
 UNINSTALL COMPLETE — log out and back in.
==========================================
 The stock XFCE panel and compositor are
 back; your old configs, keybindings and
 theme settings are restored.

 Your wallpapers in ~/Pictures/wallpapers
 and your weather location in
 ~/.config/conky/location were NOT touched
 (they are your personal files).
BANNER
read -r -p "Log out NOW to apply everything? [y/N] " LOGOUT
if [ "$LOGOUT" = "y" ] || [ "$LOGOUT" = "Y" ]; then
    echo "    logging out in 3 seconds ..."
    sleep 3
    xfce4-session-logout --logout
else
    echo "    not logging out — everything applies after your next login"
fi
