# Report 2026-10-09: cava music spectrum inside the conky-glance widget

## What we built

Live music spectrum (cava bars) between artist line and progress bar while
Spotify plays. cava runs headless, pinned to the default sink's .monitor,
and writes 24 bar values (0-100, ';'-separated) to
~/.cache/conky-glance/cava.raw; glance.lua reads it every redraw and paints
rounded bars in cairo (accent blue above 60, muted white below).

## Files

| File | What it is |
|---|---|
| conky/conky.conf | update_interval 1 -> 0.05, card height 440 -> 480 |
| conky/glance.lua | cava_read/cava_draw, weather/Spotify caches, layout shift |
| conky/cava.conf | raw ascii output, 24 bars, 30 fps, [input] pinned to default sink |
| conky/cava-spectrum.sh | bridge: cava -> awk (FS=";") -> cava.raw |
| conky/install.sh | one-command installer; pins [input] to the local default sink |
| conky/weather.sh, conky/spotify-status.sh | unchanged helpers |
| autostart/Conky glance.desktop | also starts the bridge; waits for picom first |

## Bugs hit during the build (and fixes)

1. cava raw output is binary by default -> data_format = ascii.
2. awk did not split on ';' -> BEGIN { FS = ";" }; only 1 of 24 bars survived.
3. Weather went "unavailable", two stacked causes:
   - cache remembered FAILED lookups for 60s -> retry failures after 10s,
     cache only successes for 60s;
   - cache used os.clock() (CPU time, barely advances in a fast conky)
     -> os.time().
   Personal location stays in ~/.config/conky/location, never committed.

## Layout

CAVA_Y = 316 (height 28), PROG_Y = 354, BTN_Y = 416, card height 480.

## Addendum: weather icon removed

### Symptom
The weather line showed an empty box "[]" before the text. The icon came
from Symbols Nerd Font; when the glyph is not available on a system, it
renders as a placeholder box instead of failing visibly.

### Fix
Removed the icon from the weather line entirely. The weather info itself
("+11°C  Light drizzle") is enough; it is now plain centered Noto Sans
text, same font as the rest of the widget, so nothing can render as a
box on any system. The unused weather_icon() helper stays in glance.lua
(harmless); the drawing code no longer calls it.

### Note
The first patch attempt anchored on section comments that no longer
existed in the rewritten file; it failed safely with no changes. The
working patch anchors on code lines that exist in every version:
the get_weather() call and the get_spotify() call after it.

## Addendum: design polish pass

Kept the transparent Google "At a Glance" look, refined the details:

- Dividers now fade out at both ends (linear alpha gradient, peak 0.35)
  instead of hard full-width lines.
- Hover highlight on the music buttons is a soft wash (white at 12%
  alpha) instead of the harder 25% pill.
- Weather text bumped to 14.5pt to hold the line without its icon.
- Section spacing evened out a few pixels (DIV1_Y 170->172, WX_Y
  200->204, DIV2_Y 228->230, and the music block shifted down ~2px).
- Removed the nerd-font music-note placeholder from the "Nothing
  playing" state (same [] risk as the weather icon had).

The cava spectrum, palette, fonts, and all behavior are unchanged.

## Addendum: shadow around the widget removed

### Symptom
A dark halo framed the transparent conky-glance widget, looking like an
unwanted border.

### Cause
picom draws soft shadows around all windows; on a fully transparent
window the shadow reads as a dark rim. Conky itself draws no border.

### Fix
Added "class_g = 'conky-glance'" to shadow-exclude in picom.conf. Only
the widget loses its shadow; polybar and every other window keep theirs.

## Addendum: overlap watcher rewritten (v3, fullscreen-only)

### Symptom
Dragging a floating window to the top of the screen — onto the invisible
struthelper strip — made the polybar pill vanish, even though nothing
covered it.

### Root cause
The watcher (v2) detected "bar hidden" by pixel geometry: any NORMAL
window rectangle intersecting the bar rectangle triggered the hide. A
floating window resting on the reserved strip intersects that rectangle
the same way a covering window does, so it falsely triggered the hide.
The fullscreen case it was built for worked only by coincidence
(fullscreen windows also intersect the rectangle).

### Fix
v3 asks the window manager directly instead of doing pixel math: the bar
now hides only while some window carries the _NET_WM_STATE_FULLSCREEN
state (checked via xprop per visible normal window). Window positions
are irrelevant now; F11-style fullscreen hides the bar, anything else —
including windows touching the invisible reserve strip — does not.

### Testing
Simulated in a sandbox with stubbed xdotool/xprop/polybar-msg before
shipping:

- windowed game at the top edge -> bar stays visible
- window enters fullscreen -> bar hides once
- fullscreen ends mid-run -> bar returns
- windowed game + maximized windows -> bar stays visible

(The first sandbox runs "failed" due to bugs in the stub tools — wrong
arg order, lowercase atom names — not in the watcher logic.)

### Known limitation
Games that render "fullscreen" as a plain screen-sized window without
the X11 fullscreen state (some Wine titles, older native games) will
not trigger the hide. If one shows up, a hybrid check (fullscreen flag
OR window covering the whole screen) is the follow-up.
