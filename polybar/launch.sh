#!/bin/bash
killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 0.2; done
polybar --reload google-top &
polybar struthelper &
