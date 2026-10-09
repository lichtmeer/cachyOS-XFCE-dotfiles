# Full install guide — CachyOS + XFCE desktop shell

This guide rebuilds the complete desktop from a fresh CachyOS (XFCE, X11
session) install: polybar pill bar, rofi launcher + power menu + wallpaper
picker, plank dock, picom, update checker, themed login screen.

Two ways to use it:
- Follow it top to bottom on a fresh install (~30-45 min), or
- Use it as a reference to check/repair individual parts.

The repo is the source of truth for all config files. Everything the repo
does NOT contain is listed with its own step.

---

## 1. Packages

    sudo pacman -S --needed polybar picom rofi plank xdotool \
      imagemagick pacman-contrib cachy-update alacritty conky cava \
      noto-fonts noto-fonts-cjk ttf-nerd-fonts-symbols

What each is for:
- `polybar` — the bar itself
- `picom` — compositor (rounded corners, no black bar-corner artifacts)
- `rofi` — app launcher, power menu, wallpaper picker
- `plank` — the dock
- `xdotool` — used by the hide-when-overlapped watcher
- `imagemagick` — wallpaper thumbnails + crossfade frames
- `pacman-contrib` — `checkupdates` for the update module
- `cachy-update` — guided updater (opens on left-click of the update icon)
- `alacritty` — terminal the update module opens the updater in
- fonts — Noto Sans (text), Symbols Nerd Font (icons/glyphs),
  Noto Sans CJK (workspace dots)

## 2. Files from this repo

Copy everything to its destination, keeping file names:

| Repo file | Destination |
|---|---|
| `polybar/config.ini` | `~/.config/polybar/config.ini` |
| `polybar/launch.sh` | `~/.config/polybar/launch.sh` (chmod +x) |
| `polybar/hide-when-overlapped.sh` | `~/.config/polybar/hide-when-overlapped.sh` (chmod +x) |
| `polybar/cachyos-updates.sh` | `~/.config/polybar/cachyos-updates.sh` (chmod +x) |
| `rofi/config.rasi` | `~/.config/rofi/config.rasi` |
| `rofi/power-buttons.rasi` | `~/.config/rofi/power-buttons.rasi` |
| `rofi/power-menu.sh` | `~/.config/rofi/power-menu.sh` (chmod +x) |
| `rofi/power.sh` | `~/.config/rofi/power.sh` (chmod +x) |
| `rofi/wallpaper.sh` | `~/.config/rofi/wallpaper.sh` (chmod +x) |
| `rofi/wallpaper-fade.sh` | `~/.config/rofi/wallpaper-fade.sh` (chmod +x) |
| `rofi/alt-tab.sh` | `~/.config/rofi/alt-tab.sh` (chmod +x) — hold-Alt-tap-Tab-release Alt window switching |
| `picom/picom.conf` | `~/.config/picom/picom.conf` |
| `plank/dock.theme` | `~/.local/share/plank/themes/MaterialPill/dock.theme` |
| `autostart/Polybar.desktop` | `~/.config/autostart/Polybar.desktop` |
| `autostart/Polybar overlap watcher.desktop` | `~/.config/autostart/Polybar overlap watcher.desktop` |
| `autostart/picom.desktop` | `~/.config/autostart/picom.desktop` |
| `autostart/plank.desktop` | `~/.config/autostart/plank.desktop` |
| `autostart/xfce4-panel.desktop` | `~/.config/autostart/xfce4-panel.desktop` (must contain `Hidden=true`) |

Quick block that does all of it from the repo root:

    mkdir -p ~/.config/polybar ~/.config/rofi ~/.config/picom \
             ~/.config/autostart ~/.local/share/plank/themes/MaterialPill
    cp polybar/* ~/.config/polybar/
    cp rofi/* ~/.config/rofi/
    cp picom/picom.conf ~/.config/picom/
    cp plank/dock.theme ~/.local/share/plank/themes/MaterialPill/
    cp autostart/* ~/.config/autostart/
    chmod +x ~/.config/polybar/*.sh ~/.config/rofi/*.sh
    bash conky/install.sh

## 3. GTK theme and icon set (NOT in this repo)

The desktop look needs Orchis-Dark and the YAMIS icon set; both are
re-downloadable:

    git clone https://github.com/vinceliuice/Orchis-theme.git ~/Orchis-theme
    ~/Orchis-theme/install.sh --theme default --color dark

Then set manually:
- Settings -> Appearance -> Style: **Orchis-Dark**
- Settings -> Window Manager -> Style: **Orchis-Dark**
- Icon theme "Yet Another Monochrome Icon Set" (YAMIS) goes into `~/.icons/`

## 4. XFCE settings (stored inside xfconf, not in files)

Run once:

    # Stop the stock XFCE panel from starting (failsafe session)
    xfconf-query -c xfce4-session -p /sessions/Failsafe/Client2_Command -n \
      -t string -s /bin/true

    # Remove existing panels
    xfconf-query -c xfce4-panel -p /panels -n -t int -s 0

    # Screen-edge margins: 8px left/right/bottom, 0 top
    for side in left right bottom; do
      xfconf-query -c xfwm4 -p /general/margin_$side -n -t int -s 8
    done
    xfconf-query -c xfwm4 -p /general/margin_top -n -t int -s 0

Then once, manually: Settings -> Session and Startup -> Sessions ->
**clear saved sessions** (otherwise the watcher may start twice).

## 5. Keyboard shortcut

Settings -> Keyboard -> Application Shortcuts:
- `Super+Space` -> `rofi -show drun`

(Pressing Super+Space while rofi is open closes it again — that toggle is
part of `rofi/config.rasi`.)

## 6. Login screen (LightDM GTK greeter, system-side, sudo)

The greeter runs before login as a system user, so it cannot see
`~/.themes`. Make the theme system-wide:

    sudo cp -r ~/.themes/Orchis-Dark /usr/share/themes/

In `/etc/lightdm/lightdm-gtk-greeter.conf`, `[greeter]` section:

    theme-name = Orchis-Dark
    icon-theme-name = Adwaita
    font-name = Noto Sans 11
    background = #1C1B1F

## 7. Wallpapers

The wallpaper picker expects images in `~/Pictures/wallpapers/`
(png/jpg/jpeg/webp). Create it and put your wallpapers there. Thumbnails
and crossfade frames are cached in `~/.cache/` — throwaway data, safe to
delete anytime.

## 8. Final verification — log out and back in

After re-login, check:
- [ ] Polybar pill bar at the top (workspaces, clock, system info)
- [ ] Windows stop below the bar; none of them touch left/right/bottom
      screen edges
- [ ] Plank dock at the bottom, Material You style
- [ ] Super+Space opens rofi; pressing again closes it
- [ ] Power button in the bar opens the rofi power menu
- [ ] Wallpaper picker shows previews and crossfades on switch
- [ ] CachyOS update icon in the bar: white = up to date,
      pulsing blue + count = updates available
- [ ] Login screen is dark (Orchis)
- [ ] Stock XFCE panel does NOT appear

## Known caveats

- Geometry is tuned for 1920x1080. Other resolutions require adjusting
  bar offsets, the watcher's bar rectangle, and rofi width/position.
- The hide-when-overlapped watcher and the bar rectangle values live in
  `polybar/hide-when-overlapped.sh` — keep them in sync with any bar
  geometry change in `config.ini`.
- Polybar `pseudo-transparency` must stay `false` (picom is running;
  `true` causes black corner artifacts).
- Fade smoothness is limited on a VM's virtual GPU; on real hardware it
  renders cleaner.

## Rollback pointers

- Greeter: remove the added lines from
  `/etc/lightdm/lightdm-gtk-greeter.conf`, optionally
  `sudo rm -r /usr/share/themes/Orchis-Dark`.
- XFCE panel: restore it by deleting the Hidden=true autostart entry and
  re-adding a panel in xfconf.
- Everything else: delete the copied files from `~/.config` — all
  user-side changes are just files in `~/.config` and `~/.local`.
