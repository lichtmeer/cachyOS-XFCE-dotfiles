#!/bin/bash
B=/sys/class/backlight/amdgpu_bl1/brightness
M=/sys/class/backlight/amdgpu_bl1/max_brightness
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
