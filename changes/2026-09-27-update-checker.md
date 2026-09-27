# 2026-09-27 — CachyOS update checker

## Summary

Added a system update checker to the polybar right side, between the CPU
module and the tray. White CachyOS logo (Nerd Font `nf-linux-cachyos`,
U+F385) when the system is up to date; pulses white/blue with the pending
count when updates are available. Checks at login, then once every hour.

## New files

- `polybar/cachyos-updates.sh` — the module script. Runs `checkupdates`
  (from pacman-contrib) in the background, never blocks the bar.
  - Left-click: opens `alacritty -e cachy-update` (guided updater);
    re-checks when the terminal closes.
  - Right-click: re-check immediately.
  - Test mode: `echo 7 > ~/.cache/polybar-cachyos-updates.force` forces a
    pulsing "7"; `rm ~/.cache/polybar-cachyos-updates.force` ends the test.
  - Runtime state lives in `~/.cache/polybar-cachyos-updates.*` — throwaway
    files, not part of this repo.

## Changed files

- `polybar/config.ini`
  - `modules-right` now: `filesystem pulseaudio memory cpu cachyos-updates tray`
  - New `[module/cachy-updates]` block (custom/script, tail mode).

## New package dependency

    sudo pacman -S cachy-update pacman-contrib

- `cachy-update`: official CachyOS update notifier & applier; we use its
  guided terminal updater as the click action. Its tray applet is NOT used
  (polybar's tray is XEmbed-only and cannot show it).
- `pacman-contrib`: provides `checkupdates`.

## Issues hit and fixed during the build

1. Module did not load after first config patch: the modules list said
   `cachyos-updates` but the section header was `[module/cachy-updates]`
   (missing "os"). Polybar silently disabled the module. Fixed by making
   both names identical.
2. Zero-updates counting bug: `checkupdates` outputs nothing when the
   system is current; counting empty output with `wc -l` produces a wrong
   "1". Fixed with explicit empty-output handling.
3. Endless pulsing after updates were installed: by design the module only
   checked at login, so its answer went stale. Fixed by adding the hourly
   re-check cycle (with 30s retry while the network is not up at boot).
4. Display tweaks: removed the "..." placeholder shown while checking;
   idle color changed from grey (#C3C7CF) to white (#E6E1E5); pulse changed
   from red/blue to white/blue.

## Also today

- `README.md` resynced with the current setup: file lists completed
  (rofi power menu files, update module, autostart entries), bar geometry
  corrected to 95% / 24pt / 2.5% offset, power button now opens the Rofi
  power menu, launcher described as the compact centered list, picom
  rounded corners documented, `alacritty` added to dependencies,
  update-checker notes section added.
- Duplicate overlap-watcher processes (found twice via `pgrep -fa polybar`)
  were cleaned up by the standard restart procedure.

## Verification

- Pulse verified by pixel analysis of sandbox screenshots (alternating
  #E6E1E5 / #A4C3FF).
- Hourly refresh verified in sandbox with a shortened 3s interval: state
  went 2 -> 0 on its own after the interval elapsed.
- Glyph safety verified: script written by Python, U+F385 checked before
  and after every write; the glyph never passed through chat/clipboard.
- End-to-end on target: icon loads (9 modules in bar log), force-test
  pulses, rm of the force file returns it to calm white.
