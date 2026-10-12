# Plank: floating pill redesign + move to left edge

## Summary (backfilled - the theme was pushed earlier without a report)
- MaterialPill theme rebuilt to match the polybar pill: #1C1B1F body,
  #2A2930 outline, near-full pill corner roundness, slim padding
  (TopPadding/BottomPadding 1 = 10% of icon size).
- Icon size 36 (default 48), dock moved to the left screen edge.
- Asymmetric corners kept deliberately after an accidental finding:
  TopRoundness=5 (near-square) + BottomRoundness=28 (full pill curve).

## Root cause found during this work
The theme file existed but plank was still running its built-in
"Default" theme - activation is a gsettings value the installer can't
guess. install.sh now activates it on install:
  gsettings set net.launchpad.plank.dock.settings:\
/net/launchpad/plank/docks/dock1/ theme "MaterialPill"

## Settings pinned (live-tuned during the session)
- theme = MaterialPill, icon-size = 36, position = left

## Revert
gsettings ... theme 'Default', icon-size 48, position 'bottom';
restore dock.theme from git history.
