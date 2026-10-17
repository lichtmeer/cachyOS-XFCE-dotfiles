#!/bin/bash
# Auto-detect the backlight device: first one under /sys/class/backlight/.
# Works on AMD (amdgpu_bl*), Intel (intel_backlight), etc.
DEV=""
for d in /sys/class/backlight/*; do
    [ -e "$d/brightness" ] && [ -e "$d/max_brightness" ] && { DEV="$d"; break; }
done
# no backlight found (desktop PC?): show a dimmed sun, do nothing else
[ -n "$DEV" ] || { printf '\uf185 --\n'; exit 0; }
B="$DEV/brightness"
M="$DEV/max_brightness"
case "$1" in
  up)
    new=$(( $(<$B) + $(<$M) / 20 ))
    [ $new -gt $(<$M) ] && new=$(<$M)
    echo $new > $B ;;
  down)
    new=$(( $(<$B) - $(<$M) / 20 ))
    [ $new -lt 0 ] && new=0
    echo $new > $B ;;
  *)
    printf '\uf185 %d%%' $(( 100 * $(<$B) / $(<$M) )) ;;
esac
