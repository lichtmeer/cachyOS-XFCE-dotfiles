# Conky glance widget: date removed, tall cava spectrum

## Summary
- Removed the date headline (day + date) from the top of the widget.
- Freed space given to the cava spectrum: 28px tall/24 bars ->
  150px tall/36 bars - the spectrum is now the visual centerpiece.
- New layout: weather on top, then Spotify title/artist, big spectrum,
  progress bar and buttons. Widget keeps its 480px height.
- Weather and Spotify remain the only text content.

## Revert
Restore glance.lua from git history (or the .backup-no-date file).
