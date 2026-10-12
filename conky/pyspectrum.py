#!/usr/bin/env python3
# pyspectrum: cava replacement for the conky-glance widget.
# Reads raw s16le stereo audio on stdin, writes bar values 0-100 to a file.
# Pure Python (Goertzel per band) - no numpy, no cava.
import sys, struct, math, os

RAW_PATH = os.path.expanduser('~/.cache/conky-glance/cava.raw')
BANDS    = 36
FRAG     = 2048
RATE     = 44100
F_MIN, F_MAX = 50, 10000

def band_freqs():
    lo, hi = math.log(F_MIN), math.log(F_MAX)
    step = (hi - lo) / (BANDS - 1)
    return [math.exp(lo + i * step) for i in range(BANDS)]
FREQS = band_freqs()

COEFS = []
for f in FREQS:
    k = 2.0 * math.pi * f / RATE
    COEFS.append(2.0 * math.cos(k))

smooth = [0.0] * BANDS

def process(energies):
    global smooth
    out = []
    for i, e in enumerate(energies):
        if e <= 1e-12:
            db = -120.0
        else:
            db = 20.0 * math.log10(e)
        v = (db + 60.0) / 54.0
        v = max(0.0, min(1.0, v))
        prev = smooth[i]
        nv = prev + (v - prev) * 0.45
        smooth[i] = nv
        out.append(nv)
    # neighbor blending: adjacent bands move together (like cava's monstercat)
    blended = []
    for i in range(BANDS):
        left  = out[i - 1] if i > 0 else out[i]
        right = out[i + 1] if i < BANDS - 1 else out[i]
        blended.append(0.6 * out[i] + 0.2 * left + 0.2 * right)
    return [int(b * 100) for b in blended]

def main():
    buf = b''
    target = FRAG * 4
    while True:
        chunk = sys.stdin.buffer.read(4096)
        if not chunk:
            break
        buf += chunk
        while len(buf) >= target:
            frame_bytes, buf = buf[:target], buf[target:]
            samples = struct.unpack('<%dh' % (FRAG * 2), frame_bytes)
            mono = [(samples[2*i] + samples[2*i+1]) / 2.0 / 32768.0
                    for i in range(FRAG)]
            energies = []
            for i in range(BANDS):
                coef = COEFS[i]
                s1 = s2 = 0.0
                for x in mono:
                    s0 = x + coef * s1 - s2
                    s2, s1 = s1, s0
                power = (s1*s1 + s2*s2 - coef*s1*s2)
                energies.append(math.sqrt(max(0.0, power)) / FRAG * 2.0)
            vals = process(energies)
            with open(RAW_PATH, 'w') as f:
                f.write(';'.join(str(v) for v in vals))

if __name__ == '__main__':
    main()
