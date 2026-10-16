# 2026-10-17: Wallpaper switch = true 60fps crossfade

- wallpaper-fade.sh rewritten: renders a 0.8s 60fps crossfade video (ffmpeg xfade) and plays it with mpv in a borderless fullscreen window pushed BELOW all normal windows (wmctrl) - the fade happens on the desktop layer, behind windows, bar and dock, while the real wallpaper switches underneath. Replaces the old 9-frame image-stepping method, which looked choppy because each wallpaper repaint by xfdesktop arrived unevenly.
- Falls back to an instant switch if mpv/wmctrl/ffmpeg are missing or the video render fails; a watchdog kills the video window if its window id cannot be found (never leaves a stuck window on top).
- New packages: mpv, wmctrl (added to install.sh; ffmpeg ships with the base install).
- Revert: ~/.config/rofi/wallpaper-fade.sh.pre-video
