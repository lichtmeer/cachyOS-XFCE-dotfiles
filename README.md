# cachyOS-XFCE-dotfiles

My CachyOS (Arch-based) + XFCE desktop, rebuilt around Polybar as a complete
desktop shell replacement. Material You dark design, floating pill bar,
Rofi launcher, picom compositor.

## Layout

| Folder | Contents | Install to |
|---|---|---|
| `polybar/` | `config.ini`, `launch.sh`, `hide-when-overlapped.sh` | `~/.config/polybar/` |
| `rofi/` | `config.rasi` | `~/.config/rofi/` |
| `picom/` | `picom.conf` | `~/.config/picom/` |
| `autostart/` | `polybar-watcher.desktop` | `~/.config/autostart/` |
| `changes/` | dated change reports | - |

## What it looks like

- **google-top bar**: floating rounded pill, 66% width, centered top,
  Material You dark tonal palette (#1C1B1F surface, #A4C3FF accent).
  Left: power button (IEC power symbol, runs xfce4-session-logout) and
  GNOME-style workspace dots. Center: clock. Right: disk, volume, RAM,
  CPU, tray.
- **struthelper**: invisible full-width bar that reserves the entire top
  row so no window ever sits beside the pill.
- **hide-when-overlapped.sh**: watcher that hides the pill when a window
  is dragged over it or a window goes fullscreen (F11).
- **Rofi launcher**: Ribbon Top Round layout, recolored to match the bar,
  pixel-aligned with the pill, toggled with Super+Space.
- **picom**: GLX backend compositor; polybar `pseudo-transparency` must
  stay `false` (with a compositor, `true` causes black corner artifacts).

## XFCE settings not stored in files

These live in xfconf / session settings and are NOT captured by this repo.
On a fresh install, re-apply:

    # Block the XFCE panel from starting (failsafe session)
    xfconf-query -c xfce4-session -p /sessions/Failsafe/Client2_Command -n \
      -t string -s /bin/true

    # Remove existing panels
    xfconf-query -c xfce4-panel -p /panels -n -t int -s 0

    # Screen-edge margins: 8px left/right/bottom, 0 top
    for side in left right bottom; do
      xfconf-query -c xfwm4 -p /general/margin_$side -n -t int -s 8
    done
    xfconf-query -c xfwm4 -p /general/margin_top -n -t int -s 0

Manual steps:

- Keyboard shortcut Super+Space -> `rofi -show drun`
  (Settings -> Keyboard -> Application Shortcuts)
- Autostart entries (Settings -> Session and Startup):
  - polybar: `~/.config/polybar/launch.sh`
  - picom: `picom -b`
  - watcher: `~/.config/polybar/hide-when-overlapped.sh`
- Clear saved sessions once after setup (Session and Startup -> Sessions),
  so the watcher does not start twice.

## Dependencies

    sudo pacman -S polybar picom rofi xdotool \
      ttf-nerd-fonts-symbols noto-fonts noto-fonts-cjk

Icon theme: "Yet Another Monochrome Icon Set" (YAMIS) for tray icons
(nm-applet). Fonts used: Noto Sans, Symbols Nerd Font, Noto Sans CJK TC
(the CJK font provides the workspace dots).

## Known caveats

- Geometry is hard-coded for 1920x1080 (VirtualBox "Virtual-1").
  Changing the screen resolution requires recalculating bar offsets,
  the watcher's bar rectangle, and rofi width/position.
- Network module is disabled (wired ethernet handled by nm-applet tray icon).
- Manually dragged windows can still touch the screen edges; margins only
  affect maximized windows. The watcher hides the pill if a window is
  dragged over it.

## GTK theme

Orchis (Material Design) dark variant by vinceliuice. Not stored in this
repo (re-downloadable). Restore with:

    git clone https://github.com/vinceliuice/Orchis-theme.git ~/Orchis-theme
    ~/Orchis-theme/install.sh --theme default --color dark

Then set it in Settings -> Appearance (Style: Orchis-Dark) AND
Settings -> Window Manager (Style: Orchis-Dark).
See changes/2026-09-27-gtk-theme.md for details.

## Update checker module — extra notes

The polybar update module (`polybar/cachyos-updates.sh`) needs two packages
that are not part of the dotfiles themselves:

    sudo pacman -S cachy-update pacman-contrib

- `pacman-contrib` provides `checkupdates`, which the module uses to count
  pending updates. Without it, the icon stays white and quiet.
- `cachy-update` is the guided updater that opens when you left-click the icon
  (runs in alacritty: `alacritty -e cachy-update`).

Behavior summary:

- Checks at login, then once every hour. Right-click the icon to re-check
  immediately; left-click to run the updater.
- White CachyOS icon = up to date. Pulsing white/blue icon with a count =
  updates available.

The files `~/.cache/polybar-cachyos-updates.*` (`.state`, `.stamp`, `.force`)
are throwaway runtime data created by the module. They are safe to delete at
any time and must never be committed to this repo.
