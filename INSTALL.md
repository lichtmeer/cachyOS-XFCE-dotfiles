# Install guide — CachyOS + XFCE desktop shell

Rebuilds the complete desktop on a fresh CachyOS (XFCE, X11 session)
install: polybar pill bar with fullscreen-aware hiding, rofi launcher +
power menu + wallpaper picker + hold-and-release Alt+Tab switcher,
plank dock, picom compositor, and the conky-glance widget with a live
cava music spectrum and weather.

## Quick start (the short version)

    git clone https://github.com/lichtmeer/cachyOS-XFCE-dotfiles
    cd cachyOS-XFCE-dotfiles && bash install.sh

Never with sudo — the installer refuses root runs. The only elevated
parts are the internal `sudo pacman` / greeter-config calls, each
explained in the output right before the password prompt.

## What the installer does, step by step

1. **System packages** — checks every package, one line per package
   (ok / MISSING / outdated). Installs only missing ones with
   `pacman -S --needed` (its normal output shows); reports outdated
   ones without touching them. The full list and each package's
   purpose: see Dependencies in [README.md](README.md).
2. **Spotify question** — asked on every run, even when installed
   (the glance widget's music section needs a Spotify player via
   playerctl; without it that section stays empty). Yes is always
   safe — `--needed` never reinstalls.
3. **Polybar / Rofi / Picom / Conky / Plank** — copies all configs,
   fixes paths for the current user, pins cava to your default audio
   output (defers gracefully if no audio server is running yet).
4. **XFCE settings** — applies all xfconf settings:
   - keybindings: Alt+Tab (hold-and-release wrapper), Super+Tab
     (rofi window switcher), Super+Space (launcher), Super+T
     (alacritty), Super+< (wallpaper picker)
   - xfwm4's own Tab key mappings unbound (so rofi receives the keys)
   - stock panel off (killed first, no restart popup)
   - xfwm4 compositor off — picom owns the screen
   - workspace margins: top 0, left/right 55, bottom 15
5. **Wallpapers** — asks, copies to ~/Pictures/wallpapers, then sets
   one at random so the Super+< switcher works from the first login.
6. **Icons + theme** — asks; when yes: downloads YAMIS (original
   author's Bitbucket source) and Orchis-Dark, installs them, then
   applies GTK theme + window style + icons via xfconf automatically,
   and writes the same theme into the LightDM GTK greeter config
   (sudo, explained; skipped with a note if not present).
7. **Logout offer** — explains why (session settings and autostart
   entries apply on the next login) and asks; yes logs out after a
   3-second warning.

Weather location is asked once (only if not already saved) and kept
in `~/.config/conky/location` on your machine — never committed.

Re-running the installer is safe: installed packages are skipped,
private files are kept, configs are overwritten with the repo versions.

## What remains manual (and why)

1. **Once: Settings > Session and Startup > Sessions > clear saved
   sessions.** Old sessions can double-start the watchers. (Deliberate:
   wiping session state automatically is riskier than one click.)

## Verification — log out and back in, then check

- [ ] Pill bar at the top (workspaces, clock, system info); stock panel gone
- [ ] Windows stop below the bar; F11 hides the bar, leaving fullscreen
      brings it back; windows on the top strip do NOT hide it
- [ ] Maximized windows keep 55px from the left/right screen edges
- [ ] Plank dock at the bottom (pick MaterialPill theme once)
- [ ] Super+Space opens the launcher; pressing again closes it
- [ ] Alt+Tab: hold Alt, tap Tab, release Alt -> window switches
- [ ] Super+Tab opens the rofi window switcher (Enter confirms)
- [ ] Super+T opens alacritty
- [ ] Super+< opens the wallpaper picker; previews and crossfade work
- [ ] Power button in the bar opens the rofi power menu
- [ ] Update icon: white = up to date, pulsing blue + count = updates
- [ ] Glance widget on the right: date, weather, Spotify with clickable
      buttons, cava spectrum while music plays
- [ ] Theme is Orchis-Dark with YAMIS icons everywhere (applied
      automatically — nothing to click); after a reboot the login
      screen matches

## How the pieces work (reference)

| Piece | Where | Notes |
|---|---|---|
| Polybar pill + invisible reserve bar | `polybar/` | `struthelper` reserves the top row so nothing sits beside the pill |
| Fullscreen watcher v3 | `polybar/hide-when-overlapped.sh` | hides the pill only on `_NET_WM_STATE_FULLSCREEN`; window positions are irrelevant |
| Alt+Tab switcher | `rofi/alt-tab.sh` | watches for Alt release (~10ms), sends Return to rofi; binding lives in xfconf |
| Glance widget | `conky/` | `glance.lua` draws with cairo; `cava-spectrum.sh` bridges cava -> `~/.cache/conky-glance/cava.raw` |
| Weather | `conky/weather.sh` | wttr.in, 30 min cache; location from `~/.config/conky/location` (private) or IP |
| Shadows | `picom/picom.conf` | `conky-glance` is excluded from shadows (no dark rim on the transparent widget) |

## Known caveats

- Geometry is tuned for 1920x1080; other resolutions need the bar
  offsets (polybar config) and rofi width/position adjusted.
- Polybar `pseudo-transparency` must stay `false` (picom is running;
  `true` causes black corner artifacts).
- Games that go "fullscreen" without the X11 fullscreen state (some
  Wine/older titles) do not trigger the bar hide.
- The keybindings are stored in xfconf (machine-side, not files);
  `install.sh` applies them, this doc records them.

## Rollback pointers

- XFCE panel: delete the failsafe override
  (`xfconf-query -c xfce4-session -p /sessions/Failsafe/Client2_Command -r`)
  and re-add a panel in xfconf.
- Greeter: remove the `theme-name` / `icon-theme-name` lines the
  installer added to `/etc/lightdm/lightdm-gtk-greeter.conf`.
- Everything else: delete the copied files from `~/.config` — all
  user-side changes are just files in `~/.config` and `~/.local`.
