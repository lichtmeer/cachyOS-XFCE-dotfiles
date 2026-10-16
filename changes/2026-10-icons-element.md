# 2026-10: Icons everywhere + Element icon

- New custom YAMIS-style Element icon (icons/element-desktop.svg, currentColor monochrome from the official logo). YAMIS ships none; installed under element, element-desktop, io.element.Element (the last is what the Element desktop package requests).
- rofi window switcher now shows theme icons for ALL windows: window.rasi sets window { prefer-icon-theme: true; } (verified in rofi source: skips the X11 window icon, looks up the window class in the icon theme) + alt-tab.sh passes the current Xfce icon theme to rofi.
- Super+Tab (installer) now uses the theme-aware wrapper like Super+Space.
- Known limits: the polybar tray icons are app-provided by design (Element stays green there).
