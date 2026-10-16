# 2026-10: Custom YAMIS-style Element icon

- icons/element-desktop.svg: the Element messenger logo (four corner brackets) redrawn as a YAMIS-style monochrome SVG (currentColor, themes with the system).
- YAMIS ships no Element icon; installed into ~/.icons/YAMIS/apps/scalable under three names apps request: element, element-desktop, io.element.Element (the Element desktop package uses the last one).
- install.sh copies the aliases into YAMIS right after installing it, then refreshes the icon cache.
- Note: tray icons (polybar tray) are provided by the apps themselves and ignore the icon theme; Element in the tray stays its own green icon by design.
