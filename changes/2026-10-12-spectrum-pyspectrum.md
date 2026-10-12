# Spectrum: replaced broken cava with pyspectrum (the saga)

## Symptom
After the no-date redesign (tall spectrum), bars were maxing out, then
went completely silent. Diagnosis showed cava 1.0.0 returning silence
through ALL its input methods (pulse, pipewire, fifo, raw stdin) on
CachyOS PipeWire - while parecord captured the monitor perfectly
(80%+ non-zero audio verified directly).

## Root causes found along the way
1. cava.conf still pointed at the old VM sound card (worked never, on ThinkPad)
2. cava's own capture broken on PipeWire (the real blocker)
3. Several of my config attempts had real bugs the sandbox tests caught:
   invalid input method, wrong parecord flag, trailing-';' phantom value

## The solution
- `pyspectrum.py`: pure-Python spectrum analyzer (Goertzel per band),
  reads s16le stereo audio on stdin, writes 36 bar values (0-100) to
  ~/.cache/conky-glance/cava.raw - same file/format the widget always used.
- `cava-spectrum.sh` v5: parecord (default-sink monitor) -> pyspectrum,
  with a self-healing loop that re-resolves the sink after device switches.
- Smoothing stack (the "realistic + fluid" feel):
  2048-sample windows; dB mapping (-60..-6 dB -> 0..100); temporal glide
  (blend 0.45); neighbor blending (0.6/0.2/0.2, like cava's monstercat);
  widget gravity: instant rise, fall *0.92 per frame.
- CPU cost: ~6% of one core. cava.conf retired - cava no longer used.

## Revert
Restore cava.conf + old cava-spectrum.sh from git history and reinstall
cava (only works on systems where cava's capture actually functions).

## Update (same day): tuning + installer cleanup

### Smoothing stack - final tuned values
Getting from "working" to "feels like cava" took four iterations:
1. FRAG 1024 (43fps) - faster, but exposed frame-to-frame jitter
2. temporal low-pass blend: `nv = prev + (v - prev) * 0.45`
3. back to FRAG 2048 (21.5fps, naturally syncs with the widget's
   20fps redraw - kills the beat-frequency stutter) + neighbor
   blending (0.6 self / 0.2 left / 0.2 right, like cava's monstercat)
   - fixed frequency-leakage flicker between adjacent bands
4. widget gravity softened by hand: fall `prev * 0.94` in glance.lua
   (tuned live on the machine)

### Installer cleanup (e9eabb5)
- install.sh: cava removed from package list, pulseaudio-utils
  (parecord) added - the new pipeline's only real dependency
- conky/install.sh: copies pyspectrum.py, checks parecord, obsolete
  "pin cava to sink" block removed (the pipeline self-resolves the
  default sink at runtime and re-resolves on device switches)
- autostart comment updated; Exec unchanged (still cava-spectrum.sh)
- verification list checks pyspectrum.py instead of cava.conf
