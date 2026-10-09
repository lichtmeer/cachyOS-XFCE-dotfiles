# Report 2026-10-09: cava music spectrum inside the conky-glance widget

## What we built today

The glance widget now shows a live music spectrum (cava bars) between the
artist line and the progress bar while Spotify is playing.

## How it works, in one paragraph

cava cannot draw inside conky, so it runs invisibly in the background
(pinned to the default audio sink's .monitor) and constantly writes its
bar values (24 numbers, 0-100, semicolon-separated) to
~/.cache/conky-glance/cava.raw. glance.lua reads that file on every
redraw and paints rounded bars with cairo, in the widget's own palette
(accent blue above 60, muted white below). The spectrum only shows while
Spotify reports status "Playing".

## Files

| File | What it is |
|---|---|
| conky/conky.conf | update_interval 1 -> 0.05, card height 440 -> 480 |
| conky/glance.lua | adds cava_read/cava_draw; weather/Spotify caches; layout shift |
| conky/cava.conf | cava config: raw ascii output, 24 bars, 30 fps, [input] pinned to default sink |
| conky/cava-spectrum.sh | bridge: cava -> awk (FS=";") -> cava.raw |
| conky/weather.sh | weather fetcher with 30 min cache (unchanged) |
| conky/spotify-status.sh | Spotify reader via playerctl (unchanged) |
| autostart/Conky glance.desktop | also starts the cava bridge; still waits for picom first |

## Bugs hit during the build (and their fixes)

1. **cava raw output is binary by default** — the bridge expected text.
   Fix: data_format = ascii in the [output] section.
2. **awk did not split on semicolons** — only one bar survived.
   Fix: BEGIN { FS = ";" } in the bridge.
3. **Weather went "unavailable"** — two stacked causes:
   - the new weather cache remembered FAILED lookups for 60s (wttr.in
     hiccup -> a minute of "unavailable"); fix: retry failures after
     10s, cache only successes for 60s.
   - the cache used os.clock() (CPU time), which barely advances in a
     fast-redrawing conky, so the retry never fired; fix: os.time().
   Personal location stays in ~/.config/conky/location, never committed.

## Layout shift

Artist line to progress bar gained 40 px for the spectrum:
CAVA_Y = 316, height 28, PROG_Y = 354, BTN_Y = 416, card height 480.

## Restart

killall conky; pkill -f "cava -p"; then the autostart .desktop does:
wait for picom -> start cava-spectrum.sh -> start conky.
