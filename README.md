# cachyOS-XFCE-dotfiles

My CachyOS (Arch-based) + XFCE desktop, rebuilt as a complete desktop
shell replacement: floating Material You pill bar, rofi launcher /
power menu / wallpaper picker / hold-and-release Alt+Tab switcher,
plank dock, picom compositor, and a transparent glance widget with a
live cava music spectrum and weather.

## Install — one command

    git clone https://github.com/lichtmeer/cachyOS-XFCE-dotfiles
    cd cachyOS-XFCE-dotfiles && bash install.sh

The installer:

- checks every package, one line per package (installs only missing
  ones, reports outdated, never upgrades silently; pacman shows its
  normal output during install)
- asks the Spotify question (every run, even when installed — the
  glance widget's music section needs a Spotify player; yes is always
  safe, `--needed` never reinstalls)
- copies all configs, fixes paths for the current user
- applies every xfconf setting: keybindings (Alt+Tab wrapper,
  Super+Tab, Super+Space, Super+T, Super+<), stock panel off,
  workspace margins (top 0, left/right 55, bottom 15)
- switches xfwm4's compositor off so picom owns the screen
- pins cava to your audio output (defers gracefully if no server yet)
- asks your weather location once (kept in `~/.config/conky/location`
  on your machine, never committed)
- asks before copying wallpapers, then sets a random one so the
  Super+< switcher works from the first login
- asks before installing YAMIS icons + Orchis-Dark theme — then
  applies theme, window style and icons automatically, and themes the
  LightDM login screen too (when its config exists)
- offers a confirmed logout at the end (session settings and autostart
  entries apply on the next login)

Safe to re-run: installed packages are skipped, private files are kept,
configs are overwritten with the repo versions.

Details, the one remaining manual step, verification checklist and
rollback: see [INSTALL.md](INSTALL.md).

> **No GitHub account needed.** Plain `git clone` works anonymously on
> this public repo. Do not use `gh repo clone` on a fresh machine — the
> GitHub CLI demands a login even for public repos. And never run the
> installer with `sudo` — it refuses root runs anyway; the only
> elevated parts are the internal `sudo pacman` / greeter-config calls,
> each explained before the password prompt.

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
- **Wallpaper picker**: thumbnails + crossfade on switch (Super+<).
- **Update checker**: white CachyOS icon when up to date; pulses
  white/blue with a count when updates are pending. Checks at login,
  then hourly; left-click runs the guided updater.
- **conky-glance widget**: transparent "At a Glance" card on the right
  edge — date headline, weather (wttr.in, private location file), and
  Spotify: title, artist, clickable prev/play/pause/next buttons,
  progress bar, and a live 24-bar cava music spectrum while music
  plays. Bars render accent blue on peaks, soft white otherwise.
  Shadow-free (picom excludes it), starts after picom is up.
- **picom**: GLX compositor, 12px rounded window corners (xfwm4's own
  compositor is switched off).
- **Plank dock**: bottom dock, MaterialPill theme.

## Dependencies

Installed automatically by `install.sh` (step 1, official repos only —
no AUR anywhere):

| Package | Why |
|---|---|
| `polybar` | the pill bar (and the invisible reserve bar) |
| `picom` | compositor: rounded corners, no shadows on the widget |
| `rofi` | launcher, power menu, wallpaper picker, Alt+Tab switcher |
| `plank` | the dock |
| `xdotool` | Alt+Tab key-state polling, fullscreen watcher |
| `xorg-xrandr` | monitor detection for the wallpaper step (the property path contains the monitor name) |
| `imagemagick` | wallpaper thumbnails and the switcher crossfade |
| `pacman-contrib` | update checker (`checkupdates`) |
| `cachy-update` | CachyOS update tool the bar's updater launches |
| `alacritty` | terminal (Super+T) |
| `conky` | the glance widget |
| `cava` | the music spectrum |
| `playerctl` | track info + playback buttons (talks to Spotify) |
| `curl` | weather fetch (wttr.in) |
| `noto-fonts`, `noto-fonts-cjk` | text rendering, full unicode coverage |
| `ttf-nerd-fonts-symbols` | icons in the bar |

Asked about separately (permission gate, asked on EVERY run — answering
yes is always safe, `--needed` never reinstalls):

- `spotify-launcher` — the glance widget's music section talks to a
  Spotify player via playerctl; without it that section stays empty.

Needed at download time only (already on any Arch/CachyOS base
install): `git` — step 9 fetches YAMIS + Orchis-Dark from their
repositories (only when you answer yes).

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
- Theme/icons and the login screen theme apply automatically; if your
  machine uses a greeter other than LightDM's GTK greeter, that one is
  skipped with a note.

## History

Every change is documented in `changes/` — dated reports with symptoms,
root causes and fixes, plus the full bug-fix report for v1.0 → v1.3.
Start with the oldest and read up.
