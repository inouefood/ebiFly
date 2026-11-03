#!/usr/bin/env python3
"""Clean up the sound effects and copy them into ebiFly/Resources/Sounds.

usage: python3 Design/tools/prepare_sounds.py <se-pack folder>

For every 16-bit mono WAV:
- removes any DC offset
- fades in over 3 ms / out over 8 ms, so sounds that start or end mid-waveform don't click
- *_loop.wav: crossfades the last 300 ms into the start instead, so the loop has no seam or level dip
Levels are left as they are; per-sound playback volume is set in Sound.swift.
Pure standard library (no numpy).
"""
import pathlib
import struct
import sys
import wave

OUT = pathlib.Path(__file__).resolve().parents[2] / "ebiFly" / "Resources" / "Sounds"
SKIP = {"preview_all.wav"}  # a demo reel of the whole pack, not used in the game


def read(p):
    with wave.open(str(p)) as w:
        assert w.getnchannels() == 1 and w.getsampwidth() == 2, f"{p.name}: expected 16-bit mono"
        sr, n = w.getframerate(), w.getnframes()
        return [v / 32768 for v in struct.unpack(f"<{n}h", w.readframes(n))], sr


def write(p, x, sr):
    with wave.open(str(p), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(struct.pack(f"<{len(x)}h", *(max(-32768, min(32767, round(v * 32767))) for v in x)))


def process(x, sr, loop):
    dc = sum(x) / len(x)
    x = [v - dc for v in x]
    if loop:
        k = int(sr * 0.3)
        head, body, tail = x[:k], x[k:-k], x[-k:]
        # the loop becomes body + (tail fading out over head fading in); its end then runs straight into body's start
        mixed = [t * (1 - i / k) + h * (i / k) for i, (t, h) in enumerate(zip(tail, head))]
        return body + mixed
    fi, fo = int(sr * 0.003), int(sr * 0.008)
    for i in range(min(fi, len(x))):
        x[i] *= i / fi
    for i in range(min(fo, len(x))):
        x[-1 - i] *= i / fo
    return x


def main():
    src = pathlib.Path(sys.argv[1]).expanduser()
    OUT.mkdir(parents=True, exist_ok=True)
    for p in sorted(src.glob("*.wav")):
        if p.name in SKIP:
            continue
        x, sr = read(p)
        write(OUT / p.name, process(x, sr, p.stem.endswith("_loop")), sr)
        print("ok", p.name)


if __name__ == "__main__":
    main()
