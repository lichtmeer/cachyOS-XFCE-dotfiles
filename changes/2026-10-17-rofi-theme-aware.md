# 2026-10: Rofi follows the icon theme, reliably

- New rofi wrapper (rofi/rofi-theme-aware.sh): reads the current Xfce icon theme at every launch and passes it to rofi with -icon-theme. Rofi cannot reliably detect the icon theme on its own outside GNOME (it kept showing a stale Mignon icon).
- Super+Space now launches the wrapper instead of raw rofi (xfconf binding; install.sh sets the same).
- Nothing hardcoded: switching the icon theme in Appearance changes rofi icons immediately.
- Fix for stale icons in general: rm -rf ~/.cache/rofi* (plank similarly caches; restart plank).
