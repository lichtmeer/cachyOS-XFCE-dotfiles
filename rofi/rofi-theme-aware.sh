#!/bin/bash
# rofi wrapper: always pass the CURRENT Xfce icon theme to rofi.
# rofi cannot reliably detect it on its own outside GNOME.
THEME=$(xfconf-query -c xsettings -p /Net/IconThemeName 2>/dev/null)
if [ -n "$THEME" ]; then
    exec rofi -icon-theme "$THEME" "$@"
else
    exec rofi "$@"
fi
