# 2026-10: Alacritty maximized + installer coverage

- Alacritty opens every new window maximized (alacritty/alacritty.toml, [window] startup_mode = "Maximized").
- install.sh audit: fastfetch (package + config + logo) and alacritty were missing from the installer - both added, steps renumbered to 11, verify step extended.
- install.sh sandbox-tested: fresh install + two re-runs, all files land correctly, idempotent.
