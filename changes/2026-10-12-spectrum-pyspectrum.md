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
