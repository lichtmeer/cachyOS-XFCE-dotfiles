# 2026-10-17: Brightness device auto-detected

- brightness.sh no longer hardcodes amdgpu_bl1: it uses the first valid device under /sys/class/backlight (works on Intel/NVIDIA/whatever a future machine has).
- Machines without a backlight (desktops) show a sun with -- instead of erroring.
- The installer udev rule was already device-agnostic; only the script was hardcoded.
- Revert: ~/.config/polybar/brightness.sh.pre-detect
