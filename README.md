# cachyOS-XFCE-dotfiles

My CachyOS (Arch-based) + XFCE desktop, rebuilt as a complete desktop
shell replacement: floating Material You pill bar, rofi launcher / power
menu / wallpaper picker / hold-and-release Alt+Tab switcher, plank dock,
picom compositor, and a transparent glance widget with a live cava music
spectrum and weather.

## Install — one command

    git clone https://github.com/lichtmeer/cachyOS-XFCE-dotfiles
    cd cachyOS-XFCE-dotfiles && bash install.sh

The installer checks packages (installs only missing, reports outdated,
never upgrades silently), copies all configs, applies every xfconf
setting (keybindings, stock panel off, margins), pins cava to your audio
output, and asks questions only when needed — your weather location
(kept in `~/.config/conky/location` on your machine, never committed)
and optional extras (wallpapers, YAMIS icons + Orchis-Dark theme).

Safe to re-run. Details, manual remainders (theme clicks, one session
cleanup, LightDM greeter), verification checklist and rollback: see
[INSTALL.md](INSTALL.md).

## Layout

| Folder | Contents | Install to |
|---|---|---|
| `install.sh` | one-command installer | run from repo root |
| `polybar/` | `config.ini`, `launch.sh`, `hide-when-overlapped.sh`, `cachyos-updates.sh` | `~/.config/polybar/` |
| `rofi/` | `config.rasi`, `grid.rasi`, `power.rasi`, `power-buttons.rasi`, `window.rasi`, `power-menu.sh`, `power.sh`, `wallpaper.sh`, `wallpaper-fade.sh`, `alt-tab.sh` | `~/.config/rofi/` |
| `picom/` | `picom.conf` | `~/.config/picom/` |
| `conky/` | `conky.conf`, `glance.lua`, `cava.conf`, `cava-spectrum.sh`, `weather.sh`, `spotify-status.sh`, `install.sh` | `~/.config/conky/` |
| `plank/` | `dock.theme` (MaterialPill) | `~/.local/share/plank/themes/MaterialPill/` |
| `autostart/` | `Polybar.desktop`, `Polybar overlap watcher.desktop`, `picom.desktop`, `plank.desktop`, `Conky glance.desktop` | `~/.config/autostart/` |
| `wallpapers/` | wallpaper collection, used by `rofi/wallpaper.sh` | `~/Pictures/wallpapers/` |
| `changes/` | dated change reports (the repo's changelog) | - |

## What it looks like

- **Pill bar (google-top)**: floating rounded pill, 95% width, Material
  You dark tonal palette (#1C1B1F surface, #A4C3FF accent). Left: power
  button opening the rofi power menu, GNOME-style workspace dots.
  Center: clock. Right: disk, volume, RAM, CPU, update checker, tray.
- **Invisible reserve bar (struthelper)**: full-width bar that reserves
  the top row so no window ever sits beside the pill.
- **Fullscreen watcher (v3)**: hides the pill only while a window is
  truly fullscreen (`_NET_WM_STATE_FULLSCREEN`, F11 or in-game); returns
  when it ends. Windows touching the top strip — dragged or floating —
  do NOT trigger the hide.
- **Alt+Tab switcher** (`rofi/alt-tab.sh`): Windows-style. Hold Alt,
  tap Tab to cycle the switcher, release Alt to focus the highlighted
  window (~20ms commit, no Enter). Super+Tab opens the same switcher
  with classic confirm-on-Enter.
- **Rofi launcher**: compact centered list below the bar, recolored to
  the polybar palette, YAMIS icons, Super+Space toggles it.
- **Rofi power menu**: five Android-style buttons (Log out, Restart,
  Shutdown, Suspend, Switch User); destructive actions confirm first.
- **Wallpaper picker**: thumbnails + crossfade on switch.
- **Update checker**: white CachyOS icon when up to date; pulses
  white/blue with a count when updates are pending. Checks at login,
  then hourly; left-click runs the guided updater.
- **conky-glance widget**: transparent "At a Glance" card on the right
  edge — date headline, weather (wttr.in, private location file), and
  Spotify: title, artist, clickable prev/play/pause/next buttons,
  progress bar, and a live 24-bar cava music spectrum while music
  plays. Bars render accent blue on peaks, soft white otherwise.
  Shadow-free (picom excludes it), starts after picom is up.
- **picom**: GLX compositor, 12px rounded window corners.
- **Plank dock**: bottom dock, MaterialPill theme.

## Dependencies

Installed automatically by `install.sh`: polybar, picom, rofi, plank,
xdotool, imagemagick, pacman-contrib, cachy-update, alacritty, conky,
cava, playerctl, curl, noto-fonts, noto-fonts-cjk,
ttf-nerd-fonts-symbols.

The glance widget deliberately uses no icon-font glyphs — its music
buttons are drawn as geometric shapes, so nothing can render as a
placeholder box.

## Known caveats

- Geometry is tuned for 1920x1080; other resolutions need bar offsets
  and rofi width/position adjusted.
- Polybar `pseudo-transparency` must stay `false` (picom is running).
- Games that go "fullscreen" without the X11 fullscreen state (some
  Wine/older titles) do not trigger the bar hide.
- Switch User depends on LightDM's `dm-tool`.

## History

Every change is documented in `changes/` — dated reports with symptoms,
root causes and fixes (boot races, wttr.in localization, cava raw
output, the weather timer, the Alt+Tab keybinding lesson, portability
fixes). Start with the oldest and read up.

> **No GitHub account needed.** Plain `git clone` works anonymously on
> this public repo. Do not use `gh repo clone` on a fresh machine — the
> GitHub CLI demands a login even for public repos. And never run the
> installer with `sudo` — the only elevated part is the internal
> `sudo pacman` call, which asks for your sudo password once.
