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
