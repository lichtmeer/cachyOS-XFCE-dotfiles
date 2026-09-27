#!/bin/bash
exec rofi -show power -modi "power:$HOME/.config/rofi/power-menu.sh" -theme "$HOME/.config/rofi/power-buttons.rasi"
