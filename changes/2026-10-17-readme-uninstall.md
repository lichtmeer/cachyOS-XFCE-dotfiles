# 2026-10-17: README gets its uninstall section

- Install section now ends with "Uninstall — one command": bash uninstall.sh reverts the first-run backup (old configs, keybindings, XFCE settings), with the system-level bits (udev rule, greeter theme, video group, packages) offered as options and personal files never touched.
- Layout table: install.sh row notes the first-run backup; new uninstall.sh row.
- Docs only — no code changes.
