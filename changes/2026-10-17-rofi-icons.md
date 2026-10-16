# 2026-10: Rofi icons follow system icon theme

- Removed the hardcoded "YAMIS" icon-theme from all 5 rofi theme files (config, grid, power, power-buttons, window).
- Rofi now uses whatever icon theme is set in XFCE Appearance (currently Mignon); switching themes in the future needs no rofi changes.
- Power menu still references icon names (system-log-out etc.), which resolve inside whatever theme is active.
