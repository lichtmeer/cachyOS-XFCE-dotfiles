# Report 2026-10-09: installer sandbox-tested before the bare-metal move

## What we did

The one-command installer (install.sh + conky/install.sh) was tested
end-to-end in a sandbox before relying on it for a fresh machine. The
sandbox simulated CachyOS/XFCE machines with stubbed system tools
(pacman, xfconf-query, pactl, checkupdates) and empty home
directories — first as a fully fresh machine, then as partially
installed, fully installed, and re-run scenarios.

The test ran twice; the second run applied the exact patch blocks from
the release script to a fresh clone of the repo, proving the script
produces exactly what was tested.

## Bugs found (and fixed)

### Bug 1: personal path still in the autostart step
An earlier audit claimed to remove the `sed s|/home/userfolder|$HOME|g` line
from install.sh, but its own sed command failed silently — the
delimiter (|) collided with the | characters inside the pattern, so
the line survived while the script reported success. Replaced with a
plain `cp`; the .desktop files have been portable ($HOME-based) for
a while, so the sed was a no-op that only leaked a personal path.

### Bug 2: the weather question never existed
README and INSTALL promise the installer asks for a weather location
"only if ~/.config/conky/location is missing" — but conky/install.sh
contained no such question at all. Fresh installs silently fell back
to wttr.in IP auto-detection and never saved the location. Added the
question before the cava pinning step: asked once, saved to
~/.config/conky/location (private, never committed), empty answer =
IP auto-detect, and never asked again once the file exists.

## What the test verified

| Scenario | Result |
|---|---|
| Fresh machine, zip given | exit 0; location saved privately; 8/8 files verified; 12 xfconf settings; packages installed with --needed --noconfirm |
| Re-run on the same machine | exit 0; location kept; no question re-asked |
| Empty weather answer | no location file; IP auto-detect message shown |
| City name with spaces/umlauts ("Berlin Mitte", "Würzburg") | saved byte-perfect |
| Partially installed machine (polybar/rofi/conky present) | only the 13 missing packages installed; present ones skipped |
| Everything already installed | zero pacman calls; "nothing to do" |
| Personal-path scan across all installed configs | zero matches |
| Keybindings set | Alt+Tab, Super+Tab, Super+Space, Super+< (wallpaper) all recorded correctly |

## Known limits

- The sandbox stubs system tools, so the test proves script flow,
  prompts, file handling, and binding commands — not pacman's actual
  package resolution or a live X session. The real first run on bare
  metal is the final confirmation.
