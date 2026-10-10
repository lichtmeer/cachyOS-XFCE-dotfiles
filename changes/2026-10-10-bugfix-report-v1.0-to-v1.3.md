# Bug-Fix Report: v1.0-metal-ready → v1.3-metal-ready

Everything fixed after the initial v1.0 release, in the order the
issues surfaced. Each fix follows the same discipline: reproduce in
the sandbox, fix the root cause, verify on the test VM, then commit.
All commits listed are on main between the two tags.

---

## 1. Sudo password mistaken for a login (root guard)
**Commit 064fc17-era fix, refined through the campaign**

### Symptom
On the fresh test VM, the first `bash install.sh` run was cancelled at
the package step because the sudo password prompt was mistaken for a
GitHub login. The re-run as `sudo ./install.sh` then broke everything:
configs landed in /root, xfconf died without a user D-Bus session
("Failed to init libxfconf"), pactl couldn't reach the audio server.

### Root cause
Two misunderstandings, both unhandled by the installer: (1) the sudo
prompt appeared with no explanation, (2) nothing stopped the user from
running the whole script as root.

### Fix
- Root guard in both installers: `id -u` check, aborts with a plain
  explanation if run as root/sudo
- Explanatory note printed BEFORE every sudo password prompt: "the
  next prompt is your SUDO PASSWORD (for pacman). It is NOT a login of
  any kind."
- README documents: plain `git clone` is anonymous, `gh repo clone`
  demands a login even for public repos, never run the installer with
  sudo

### Testing
Sandbox with stubbed id: root run aborts with exit 1 and the message;
normal run proceeds. Verified live on the VM afterwards.

---

## 2. "Failed to restart the panel" popup during install
**Commit 9fdcb6a (part 1)**

### Symptom
At the XFCE settings step, a GDBus popup appeared: "Failed to restart
the panel — ServiceUnknown: The name is not activatable."

### Root cause
Writing `panels=0` while the stock panel was still running made it
notice its config change, try to restart itself, and fail — nothing was
left to activate.

### Fix
`killall -q xfce4-panel` runs BEFORE the setting is written. The panel
stops gracefully and never attempts its confused restart.

### Testing
Verified on the VM: no popup, panel gone, setting stuck at 0.

---

## 3. YAMIS icon download failed (dead repos)
**Commit 9fdcb6a (part 2)**

### Symptom
Step 9 failed to download the YAMIS icon set on the VM.

### Root cause
Both original GitHub repos (yeyushengfanw/yamis-icon-theme and
daniruixin/yamis-icon-theme) are gone — the accounts were deleted.

### Fix
Install from the original author's source instead: Dirn's
yet-another-monochrome-icon-set on Bitbucket
(dirn-typo/yet-another-monochrome-icon-set). Verified with a real
clone: index.theme present, ~6280 icons.

### Testing
Real clone verified; VM run afterwards installed the icons cleanly.

---

## 4. YAMIS copy failed on EVERY re-run (the .git poison)
**Commit 21ad586**

### Symptom
From the second install onward, step 9 always reported "YAMIS copy
failed (skipped)" — even though the first run had worked.

### Root cause
The copy command took the clone's hidden `.git` folder along into
`~/.icons/YAMIS`. Git marks its internal pack files read-only. Every
later run tried to overwrite those files with cp, got "Permission
denied", and declared the copy failed. The `2>/dev/null` on the copy
hid the real error for three VM runs.

### Fix
The installer now wipes the old `~/.icons/YAMIS` first and copies the
set WITHOUT `.git` (tar --exclude=.git pipe). Re-runs are clean, and
the icon theme no longer ships a stray git repository.

### Testing
Live test against the real Bitbucket clone: fresh copy OK, immediate
re-copy OK (the previously failing case), no `.git` in the target,
index.theme present. Confirmed on the VM: "YAMIS icons installed".

---

## 5. Super+Tab opened the XFCE switcher, not rofi
**Commit 3ec8ead (the /xfwm4/custom/ mapping fix)**

### Symptom
Super+Tab kept opening xfwm4's own window switcher instead of the rofi
one — even after both switcher keys printed as empty, even after
`xfwm4 --replace`, even after setting the values to the word 'empty'.
rofi itself worked when launched directly.

### Root cause
A hidden second layer: xfwm4 keeps key->action MAPPING entries under
`/xfwm4/custom/` — `/xfwm4/custom/<Super>Tab = switch_window_key`
(and the Alt+Tab/Alt+Shift+Tab equivalents). As long as those entries
exist, xfwm4 grabs the keys before any /commands/custom shortcut can
run. Emptying the action VALUES did nothing about the mappings, and
deleting them outright would fall back to the factory defaults under
`/xfwm4/default/` (which bind the same keys).

### Fix
The installer overwrites all three mapping entries
(<Alt>Tab, <Super>Tab, <Alt><Shift>Tab) with the literal 'empty'
(= unbound) and sets both action values to 'empty' as well.

### Testing
Full channel scan on the VM pinpointed the mappings; the three xfconf
writes fixed it live; sandbox run confirms the installer writes all
three. Confirmed working on the VM after a fresh login.

---

## 6. Compositor conflict (picom vs xfwm4)
**Commit 3ec8ead**

### Symptom
Potential (preemptive): two compositors — xfwm4's built-in and picom —
fighting over the screen is one crash away from breakage.

### Fix
The installer sets `/general/use_compositing = false` so picom owns the
screen alone.

### Testing
Sandbox: xfconf write logged. VM: shadows/transparency via picom,
no glitches.

---

## 7. Super+T had no keybinding
**Commit 3ec8ead**

### Symptom
Alacritty was in the package list but no shortcut opened it.

### Fix
`/commands/custom/<Super>t → alacritty`, bound in the installer
alongside the other shortcuts.

### Testing
Sandbox: binding written in order with the other five. VM: Super+T
opens alacritty.

---

## 8. spotify-launcher installed silently
**Commits 13c9494 + 84d6d15**

### Symptom
The installer pulled spotify-launcher as part of the package list —
no question, no explanation. Against the repo's own ask-first rule
(the user had explicitly scolded an earlier silent install).

### Root cause
It sat in the silent PKGS list, predating the permission rule.

### Fix
Two-step fix, driven by the user's decisions:
1. Moved out of PKGS into its own question that explains WHY the
   glance widget wants it (music section talks to a Spotify player
   via playerctl; without it that section stays empty)
2. After VM testing showed the question never appearing (because
   Spotify was already installed), the user's rule was sharpened:
   **ask on EVERY run**. Already-installed now prints a note and asks
   anyway; `--needed` makes a yes a harmless no-op.

### Testing
Sandbox, stubbed pacman: installed+yes → note + harmless install;
not-installed+yes → installs; no → skip with the later-command hint.
Question appears in all cases. VM confirmed.

---

## 9. Theme/icons needed manual clicking
**Commit 3ec8ead (auto-apply) + 62e3376 (stale text)**

### Symptom
The installer downloaded and installed Orchis-Dark + YAMIS, then told
the user to open Settings and click three things to actually apply
them. Worse: after auto-apply was added, the installer STILL printed
the "ONE MANUAL STEP LEFT" instructions — stale text telling users to
do work that was already done.

### Root cause
The manual instructions predated the auto-apply feature; nobody
removed them when the feature landed.

### Fix
- Auto-apply via xfconf: GTK theme, window theme, icon theme — set
  directly, no clicking (plus the LightDM greeter, see #10)
- Stale manual-step block and banner lines removed, replaced by:
  "Nothing left to click: theme, window style and icons are applied
  automatically (login screen too, when found)."

### Testing
Sandbox: xfconf writes logged, stale text gone from output. VM:
theme applied, no manual clicking needed.

---

## 10. Login screen (LightDM greeter) not themed
**Commit 45d6bb7**

### Symptom
Desktop themed, login screen still stock — inconsistent look.

### Fix
If /etc/lightdm/lightdm-gtk-greeter.conf exists, the installer writes
`theme-name=Orchis-Dark` and `icon-theme-name=YAMIS` into it (sudo,
with the explanatory note). Other greeter = clean skip with a note.

### Testing
VM: config shows both lines active; login screen themed after
reboot. (Note: sudo may skip its password prompt when the password
was entered minutes earlier — that's normal sudo caching, not a bug.)

---

## 11. Wallpaper switcher dead on fresh install
**Commit 45d6bb7**

### Symptom
The Super+< wallpaper switcher needs a currently-set wallpaper to
work; a fresh install had none, so the switcher did nothing.

### Fix
After copying the repo's wallpapers, the installer picks one at
random and sets it as the desktop wallpaper (same xfconf path the
switcher uses).

### Testing
Sandbox: wallpaper picked and set. VM: "set: wallhaven-yjk6ml.jpg",
switcher works from first login.

---

## 12. Step 1 was silent
**Commit 45d6bb7**

### Symptom
The package step grinded silently through 16 packages, then jumped to
step 2 — no indication what happened.

### Fix
- Intro text explaining what the step does
- One line per package while checking: `ok / MISSING / outdated`
- pacman runs with --color=always so its normal output shows
  (--noconfirm stays — no babysitting Enter, but nothing hidden)

### Testing
Sandbox: verdict lines print in order, colored install fires. VM:
full visible check of all 16 packages.

---

## 13. Workspace margins
**Commit 45d6bb7**

Change (not a bug): margins set to top 0 (the invisible bar rule —
the watcher handles fullscreen), left/right 55 (dock space), bottom 15.

---

## 14. Logout needed to apply, but nothing said so
**Commit 3ec8ead**

### Symptom
Autostart entries, keybindings, compositor and theme settings only
apply fully in a fresh session — but the installer just ended,
leaving the user to discover the re-login requirement by confusion.

### Fix
The installer ends with the reason written out (WHY LOGOUT comment
in the script + prompt) and asks "Log out NOW to apply everything?
[y/N]". Yes = clean logout after a 3-second warning.

### Testing
Sandbox: y calls xfce4-session-logout, n continues gracefully. VM:
confirmed.

---

## Meta-lessons from this campaign

- **Hidden state layers:** XFCE settings have more than one layer
  (values, mappings, defaults). Fixing the visible layer isn't always
  enough — scan the whole channel.
- **Silent error suppression hides bugs:** the `2>/dev/null` on the
  YAMIS copy kept the real error ("Permission denied" on read-only
  git files) invisible for three test runs.
- **Stale documentation lies:** text that was true when written
  ("click these settings") became false when the code improved — and
  kept lying until someone questioned it.
- **Test the re-run, not just the first run:** idempotency bugs
  (the .git poison) only appear the second time.
- **The user's machine is the source of truth:** sandbox first, VM
  second, push only after both agree.

## Addendum: README.md + INSTALL.md rewritten to match the installer

### Symptom
The docs predated the v1.2/v1.3 installer work: they still told the
user to click the theme into Settings > Appearance manually, to set up
the LightDM greeter by hand (with a wrong icon-theme value), and knew
nothing about the Spotify permission gate, the confirmed logout
offer, Super+T, Super+Tab, the workspace margins or the visible
step 1.

### Fix
Both files rewritten to document what the installer actually does:
- README: install command + a plain list of installer behavior
  (visible package check, Spotify every-run question, xfconf
  settings incl. margins 0/55/55/15, compositor handover, random
  wallpaper, auto theme + login screen theming, logout offer),
  layout table, look section, dependencies, caveats, history.
- INSTALL: 7-step "what the installer does, step by step", the ONE
  remaining manual item (clear saved sessions, with why), expanded
  verification checklist (margins, Super+Tab, Super+T, Super+<,
  auto-applied theme + login screen), how-the-pieces-work table,
  rollback pointers matching what the installer really writes.
Stale manual-theme and manual-greeter instructions removed.
Docs-only change: install.sh untouched.

### Testing
Consistency checks: Spotify gate in both files, Super+T in both,
margins 55 present, "remains manual" = 1 item, zero stale claims
(manual theme clicks, Adwaita greeter value, old quotes all gone).

## Addendum: random wallpaper never applied on a fresh machine

### Symptom
On a clean CachyOS install the installer printed "set: <wallpaper>"
but the desktop wallpaper never changed. On the test VM the same
step worked every time.

### Root cause
The block only UPDATED existing per-workspace wallpaper settings
(xfconf last-image properties). A fresh machine has none of those
properties yet — the grep found nothing, the update loop never ran,
and the script still printed "set:". xfconf-query needs -n -t string
to CREATE a property; without it, writing to a non-existent property
just fails (silently, thanks to 2>/dev/null). The VM worked only
because a wallpaper had been set there before.

### Fix
After trying the existing properties, if none were updated the
installer now CREATES the standard settings for workspaces 0-3
(/backdrop/screen0/monitor0/workspaceN/last-image, -n -t string).
Success is counted for real: "set:" only prints when at least one
write succeeded; otherwise an honest WARNING with the one-click
fallback (press Super+< and pick one) is printed instead.

### Testing
Sandbox with a faithful fake xfconf-query (missing property without
-n fails, like the real one): fresh machine -> "no wallpaper settings
exist yet — creating them ...", 4 settings actually written,
"set:" printed; machine with an existing wallpaper -> updated as
before; failure path prints the WARNING instead of a false "set:".
bash -n clean.

## Addendum: wallpaper bug — second fix (wrong xfconf path on fresh machines)

### Symptom
The first fix (creating workspace0-3 wallpaper settings) still did
not change the wallpaper on a fresh VM.

### Root cause
On a fresh install, "different wallpaper for each workspace" is OFF.
In that mode xfdesktop reads /backdrop/screen0/monitor0/last-image —
WITHOUT any workspaceN segment. The first fix only wrote the
workspaceN variants, so the property xfdesktop actually reads was
never created. The sandbox test could not catch this: it ran
against a faithful-in-shape fake xfconf-query, not real xfdesktop,
so it confirmed the code path but not the property name reality.

### Fix
The installer now creates BOTH variants when no settings exist:
/backdrop/screen0/monitor0/last-image (single-wallpaper mode) and
the four workspaceN variants (per-workspace mode). Each mode ignores
the other's properties, so writing both is safe. After a successful
write, xfdesktop --reload forces the running desktop to re-read the
settings, so the wallpaper changes immediately, not just next login.

### Testing
Placement verified: the block runs only after the wallpapers are
copied from the repo (inside step 8, directly after the cp). Syntax
clean; both paths present; success counting unchanged (honest "set:"
or WARNING). Final visual proof: fresh-VM run.

## Addendum: wallpaper bug — third fix (update loop masked the missing property)

### Symptom
Even after the second fix, a fresh VM did not change its wallpaper.
The installer printed the copy question and "copied" but the random
wallpaper never appeared.

### Root cause
Ordering. The "update existing settings" loop ran first; the previous
install had already created the workspace0-3 last-image settings, so
that loop succeeded and SETCOUNT was non-zero — the code that creates
the single-wallpaper property (/backdrop/screen0/monitor0/last-image,
the one xfdesktop actually reads with per-workspace wallpapers OFF)
never ran. The success path short-circuited the fix.

### Fix
The single-wallpaper property is now ALWAYS ensured, regardless of
what the update loop found: if it does not exist, it is created
before anything else. The workspace0-3 variants are only created when
no standard settings exist at all. xfdesktop --reload afterwards
forces the running desktop to re-read.

### Testing
Full sandbox trace against the exact repo block, simulating the VM
state (workspace0-3 settings pre-created, single property missing):
log shows 4 UPDATEs, then CREATE of the missing property, then
XFDESKTOP RELOAD CALLED, then an honest "set:". Final store contains
the single-wallpaper property with the random file. Fresh-machine
and had-wallpaper paths unchanged.

## Addendum: wallpaper bug — the real root cause (monitor name in the property path)

### Symptom
Across three fixes, a fresh VM never showed the random wallpaper
even though the installer reported success and the setting could be
found in xfconf.

### Root cause
The wallpaper property path contains the MONITOR NAME, which is
hardware/driver-specific: /backdrop/screen0/monitor<NAME>/last-image.
The installer hardcoded "monitor0". The fresh VM's monitor is named
"Virtual-1" — so the setting was written to a monitor that does not
exist, and xfdesktop (which only reads the real monitor's path)
ignored it. The settings dialog on the same VM wrote to
monitorVirtual-1, which revealed the mismatch. Additionally, setting
an image also requires the image-show and image-style properties to
exist — the GUI creates them implicitly on a first manual set; the
installer did not.

### Fix
The installer now asks the system for the monitor name (xrandr
--query, first connected output) and writes the full property set to
the real path: last-image, plus image-show=true and image-style
(zoom/fit) created when missing, plus updating any existing
per-workspace variants. Success is verified by reading the value
back — "set:" only prints when the stored value matches the chosen
wallpaper. xfdesktop --reload afterwards applies it immediately.

### Testing
Sandbox with a faithful fake xfconf-query/xrandr (Virtual-1 as the
connected output, faithful create/update/read semantics):
fresh machine — creates image-show, image-style, last-image on the
monitorVirtual-1 path, read-back matches, reload called;
second run — updates the existing settings, read-back matches.
bash -n clean; stale duplicate success-block removed in testing.

## Addendum: wallpaper bug — xrandr was missing (detection depended on an uninstalled tool)

### Symptom
After the monitor-detection fix, a fresh VM still printed
"monitor detected: 0" and no wallpaper appeared.

### Root cause
The detection runs `xrandr --query`, but xorg-xrandr was never in
the installer's package list. On the fresh VM xrandr was simply not
installed ("command not found"), the detection got an empty result,
fell back to the generic "monitor0" — a monitor that does not exist
on that machine — and the settings were again written to a path
xfdesktop never reads.

### Fix
1. xorg-xrandr added to the package list, so the tool the fix
   depends on is guaranteed to be installed before step 8.
2. Safety net: if xrandr is still unavailable, the monitor name is
   taken from the backdrop properties already present in the
   settings store (the names the desktop/GUI itself used; real
   output names are never bare "0", so a non-"0" name is preferred
   over the generic fallback).

### Testing
Sandbox, xrandr absent, store pre-populated with monitorVirtual-1
props: the fallback prints "(xrandr missing — monitor name from
existing settings)" and detects "Virtual-1"; image-show/image-style
are created, last-image written to the real path, read-back
matches, reload called. Direct xrandr path unchanged (Virtual-1 via
xrandr). bash -n clean.

## Addendum: wallpaper bug — the actual 4.20 behavior (per-workspace path on the real monitor)

### Symptom
After the xrandr fix, the correct monitor was detected and the
settings were verifiably stored — yet the desktop still showed the
default wallpaper after a re-login.

### Root cause (from a live-VM diagnosis)
xfdesktop 4.20.2 paints the wallpaper from the PER-WORKSPACE path
on the real monitor:
/backdrop/screen0/monitorVirtual-1/workspace0/last-image
The installer wrote only the base path (.../monitorVirtual-1/
last-image). The settings dialog on the same machine wrote the
workspace path — and its wallpaper appeared instantly, proving
which path is authoritative. Setting a wallpaper via the GUI right
after the installer showed both: installer value on the base path,
GUI value on the workspace path, only the workspace one painted.

### Fix
After detecting the monitor (xrandr, with the settings-store
fallback), the installer now creates or updates the workspace0-3
paths on that monitor: last-image (the painted value) and
image-style (created when missing). The base path is still written
for older xfdesktop versions, other existing last-image settings
are updated, and the read-back check now verifies the workspace
path — the one 4.20 actually paints.

### Testing
Sandbox, faithful fakes (Virtual-1 via xrandr, create/update/read
semantics): fresh machine creates base + 4 workspace paths, the
painted path holds the random wallpaper; re-run updates them;
read-back matches; bash -n clean. The GUI-diff method (comparing
xfconf state before/after a manual wallpaper set) located the
authoritative path — that goes into the toolbox.

## Addendum: complete dependency documentation

### Symptom
The README listed the step-1 packages but was missing xorg-xrandr
(added when the wallpaper fix started detecting the monitor name),
and gave no reasons for any package.

### Fix
The README's Dependencies section is now a table of all 16 packages
with a one-line purpose each, followed by the permission-gated
spotify-launcher (with its every-run question and --needed note)
and the download-time-only git dependency. INSTALL.md's step 1
references the table instead of duplicating it. Docs are now a 1:1
match with what the installer installs.

### Testing
Script-checked: every PKGS entry from install.sh is present in the
README table; INSTALL pointer present; no stale claims.
