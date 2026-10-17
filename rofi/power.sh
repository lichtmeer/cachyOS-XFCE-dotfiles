#!/bin/bash
exec rofi -icon-theme "YAMIS" -show power -modi "power:$HOME/.config/rofi/power-menu.sh" -theme "$HOME/.config/rofi/power-buttons.rasi"
