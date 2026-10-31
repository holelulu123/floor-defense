#!/usr/bin/env python3
"""Synthesises the melee sounds (whoosh per swing, hit thud) as 16-bit mono wavs in build/sounds/, so nothing
third-party is needed. Upload with `scripts/roblox/import-models.py --audio build/sounds/*.wav` (keys Sound_<Name>).
Usage: python3 scripts/roblox/make-sounds.py"""
import math
import os
import random
import struct
import wave

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "build", "sounds")
RATE = 44100


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.9 * 32767)) for s in samples))
    print(path)


def whoosh(seconds=0.28):
    # Noise through a resonant low-pass whose cutoff sweeps up then down, under a sine envelope: air past a blade.
    rnd = random.Random(7)
    n = int(RATE * seconds)
    out, low, band = [], 0.0, 0.0
    for i in range(n):
        t = i / n
        cutoff = 300 + 2200 * math.sin(math.pi * t) ** 2
        f = 2 * math.sin(math.pi * cutoff / RATE)
        x = rnd.uniform(-1, 1)
        low += f * band
        high = x - low - 0.5 * band
        band += f * high
        out.append(band * math.sin(math.pi * t) ** 1.5)
    return out


def hit(seconds=0.12):
    # A short thud: falling-pitch sine plus a click of noise, fast decay.
    rnd = random.Random(3)
    n = int(RATE * seconds)
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        phase += 2 * math.pi * (220 - 900 * t) / RATE
        env = math.exp(-t * 40)
        out.append(env * (math.sin(phase) + 0.6 * rnd.uniform(-1, 1) * math.exp(-t * 120)))
    return out


if __name__ == "__main__":
    write("Whoosh", whoosh())
    write("MeleeHit", hit())
