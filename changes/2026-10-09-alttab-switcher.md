# Report 2026-10-09: hold-and-release Alt+Tab window switcher

## What we built

Windows-style Alt+Tab: hold Alt, tap Tab to cycle through the rofi
window switcher, release Alt to focus the highlighted window. No Enter
needed. Super+Tab still opens the switcher with the old confirm-on-Enter
behavior.

## How it works

rofi/alt-tab.sh opens the rofi window switcher, then polls the physical
modifier state (~10ms) via xdotool getmodifierstate. When Alt is fully
released (with a 6ms re-verify to ignore key-repeat flicker), it sends
Return into the switcher, committing the highlighted entry. Total
worst-case commit delay ~20ms — imperceptible.

## Files

| File | What it is |
|---|---|
| rofi/alt-tab.sh | wrapper: opens switcher + watches for Alt release |
| window.rasi | unchanged theme; Alt+Tab cycles entries inside the switcher (kb-row-down: "Down,Alt+Tab") |

## The keybinding (done on the machine, not in files)

Alt+Tab must be taken away from xfwm4 and given to the wrapper:

    xfconf-query -c xfce4-keyboard-shortcuts -p /xfwm4/switch_window_key -t string -s ""
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/<Alt>Tab -n -t string -s "~/.config/rofi/alt-tab.sh"

XFCE stores command shortcuts under /commands/custom/<Alt>Tab — the
first attempt used a wrong path (/custom/...) and XFCE silently ignored
it, briefly leaving no working switcher shortcut at all. Second lesson
in this repo about verifying settings paths: check with
xfconf-query -l before trusting a write.

## Timing notes

Initial timings (50ms poll / 30ms debounce) felt sluggish; tightened to
10ms / 6ms via sed passes after user testing. Faster than that risks
false commits from key bounce.

## Addendum: launcher and wallpaper shortcuts on pre-existing machines

### Symptom
After the v1.0 release, Super+Space did not open the rofi launcher on
the VM. (Same class of issue applies to the rofi wallpaper switcher
bound to a Super combo.)

### Root cause
The keybinding steps (/commands/custom/<Super>space -> "rofi -show
drun", and the wallpaper switcher binding) were added to install.sh
only in the final rewrite. The VM's xfconf state predated those steps,
and the installer was never re-run there. Fresh installs get every
binding automatically; the VM simply never received the newer ones.

### Fix
Re-applied the bindings via xfconf-query on the VM — the same commands
install.sh uses. Verified working: Super+Space opens the launcher, and
Super+Space closes it again while open (kb-cancel in rofi/config.rasi),
so the toggle is intact.

### Note for other pre-existing machines
If a machine was set up before the installer existed and a shortcut
does nothing, either re-run install.sh (idempotent) or apply the
single xfconf-query commands from install.sh step 7.
