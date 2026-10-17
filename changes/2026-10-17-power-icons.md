# 2026-10-17: Power menu icons fixed (YAMIS)

- The power menu (bar power button) launched raw rofi and missed the theme-aware wrapper treatment from the icon rework, so its icons fell back to non-theme icons after icon-theme was removed from the .rasi files.
- power.sh now passes -icon-theme YAMIS explicitly. Deliberate exception to the theme-following rule: this menu keeps YAMIS even if the system icon theme changes (everything else still follows Appearance).
- Revert: ~/.config/rofi/power.sh.pre-yamis
