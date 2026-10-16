#!/bin/bash
killall -q polybar
for i in $(seq 1 20); do pgrep -x polybar >/dev/null || break; sleep 0.2; done
killall -q -9 polybar 2>/dev/null
polybar --reload google-top >/dev/null 2>&1 &
polybar struthelper >/dev/null 2>&1 &
exit 0
