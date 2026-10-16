# 2026-10: Brightness module

- Sun icon + percentage between volume and RAM, styled like the volume module.
- Scroll up/down on it changes brightness in 5% steps (script module writing to the amdgpu_bl1 backlight).
- Number refreshes every second.

## Install script
- install.sh gained step [10/10]: video group + udev rule + chgrp so brightness writing works on any fresh install (needs one re-login).
- launch.sh now always exits cleanly (force-kills leftover polybar after ~4s, silences output).
- Revert backups kept locally: config.ini.pre-backlight etc., install.sh.old
