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
