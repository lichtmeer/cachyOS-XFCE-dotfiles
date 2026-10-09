# Install guide — CachyOS + XFCE desktop shell

Rebuilds the complete desktop on a fresh CachyOS (XFCE, X11 session)
install: polybar pill bar with fullscreen-aware hiding, rofi launcher +
power menu + wallpaper picker + hold-and-release Alt+Tab switcher,
plank dock, picom compositor, and the conky-glance widget with a live
cava music spectrum and weather.

## Quick start (the short version)

    git clone https://github.com/lichtmeer/cachyOS-XFCE-dotfiles
    cd cachyOS-XFCE-dotfiles && bash install.sh

That is the whole install. It:

- checks every package (installs only missing ones, reports outdated,
  never upgrades without asking)
- copies all configs (polybar, rofi, picom, conky, plank theme,
  autostart) and fixes paths for the current user
- applies all xfconf settings (Alt+Tab wrapper, Super+Tab, Super+Space,
  stock panel off, screen margins)
- pins cava to your default audio output
- asks questions only when needed: weather location (once, stays in
  `~/.config/conky/location`, never committed) and optional extras
  (wallpapers, YAMIS icons + Orchis-Dark theme from GitHub)

Re-running it is safe: installed packages are skipped, existing private
files are kept, configs are just overwritten with the repo versions.

## What remains manual (and why)

1. **Set the theme after the optional theme step**: Settings > Appearance
   > Style: Orchis-Dark, Icons: YAMIS; Window Manager > Style: Orchis-Dark.
   An installer should put files on disk, not silently switch your theme.
2. **Once: Settings > Session and Startup > Sessions > clear saved
   sessions.** Old sessions can double-start the watchers.
3. **Login screen (LightDM, system-side, sudo)** — deliberate, it edits
   system files:
       sudo cp -r ~/.themes/Orchis-Dark /usr/share/themes/
   In `/etc/lightdm/lightdm-gtk-greeter.conf`, `[greeter]` section:
       theme-name = Orchis-Dark
       icon-theme-name = Adwaita
       font-name = Noto Sans 11
       background = #1C1B1F

## Verification — log out and back in, then check

- [ ] Pill bar at the top (workspaces, clock, system info); stock panel gone
- [ ] Windows stop below the bar; F11 hides the bar, leaving fullscreen
      brings it back; windows on the top strip do NOT hide it
- [ ] Plank dock at the bottom (pick MaterialPill theme once)
- [ ] Super+Space opens the launcher; pressing again closes it
- [ ] Alt+Tab: hold Alt, tap Tab, release Alt -> window switches
- [ ] Power button in the bar opens the rofi power menu
- [ ] Wallpaper picker shows previews and crossfades on switch
- [ ] Update icon: white = up to date, pulsing blue + count = updates
- [ ] Glance widget on the right: date, weather, Spotify with clickable
      buttons, cava spectrum while music plays

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
- The Alt+Tab binding is stored in xfconf (machine-side, not files);
  `install.sh` applies it, this doc records it.

## Rollback pointers

- Greeter: remove the added lines from
  `/etc/lightdm/lightdm-gtk-greeter.conf`, optionally
  `sudo rm -r /usr/share/themes/Orchis-Dark`.
- XFCE panel: delete the failsafe override
  (`xfconf-query -c xfce4-session -p /sessions/Failsafe/Client2_Command -r`)
  and re-add a panel in xfconf.
- Everything else: delete the copied files from `~/.config` — all
  user-side changes are just files in `~/.config` and `~/.local`.
