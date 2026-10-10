"""Synthesize Act 1 chase audio. Pure stdlib, no numpy needed.
Outputs land in game/assets/audio/ (git-ignored build output, like the rest).
Run:  python3 art-source/audio/synth_chase.py
"""
import math
import struct
import wave
from pathlib import Path

SR = 22050
OUT = Path(__file__).resolve().parents[2] / "game" / "assets" / "audio"


def write_wav(name, samples):
    peak = max(1e-6, max(abs(s) for s in samples))
    gain = 0.72 / peak
    path = OUT / name
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s * gain)) * 32767))
            for s in samples
        )
        w.writeframes(frames)
    print(f"{name}: {len(samples) / SR:.1f}s -> {path}")


def chase_loop(dur=12.0):
    """Eerie chase loop, seamless over `dur` (all LFOs complete integer cycles).
    Minor-2nd shimmer + heartbeat + low beating drone + detuned plucks.
    """
    n = int(SR * dur)
    out = [0.0] * n
    # deterministic pseudo-noise (no random module state to seed; LCG inline)
    seed = 0xC0FFEE

    def rnd():
        nonlocal seed
        seed = (1103515245 * seed + 12345) & 0x7FFFFFFF
        return seed / 0x7FFFFFFF * 2.0 - 1.0

    noise_hist = [0.0] * 8
    for i in range(n):
        t = i / SR
        s = 0.0
        # low beating drone: 73 Hz vs 74.5 Hz (1.5 beats/s, exactly 18 cycles)
        s += 0.30 * (math.sin(2 * math.pi * 73.0 * t) + math.sin(2 * math.pi * 74.5 * t))
        # minor-2nd shimmer, slow tremolo (2 cycles per loop)
        trem = 0.6 + 0.4 * math.sin(2 * math.pi * 2.0 * t / dur)
        s += 0.10 * trem * (math.sin(2 * math.pi * 1174.7 * t) + math.sin(2 * math.pi * 1244.5 * t))
        # heartbeat 100 bpm: exactly 20 beats per 12 s loop
        beat_t = (t * 100.0 / 60.0) % 1.0
        thump = math.exp(-beat_t * 22.0) * math.sin(2 * math.pi * 55.0 * t)
        s += 0.55 * thump
        # noise wash swelling every 4 s (3 swells per loop)
        raw = rnd()
        noise_hist.append(raw)
        noise_hist.pop(0)
        smooth = sum(noise_hist) / len(noise_hist)
        swell = 0.5 + 0.5 * math.sin(2 * math.pi * 3.0 * t / dur)
        s += 0.16 * swell * smooth
        # sparse detuned plucks, pentatonic-ish, slightly flat (the 30th's motif, wrong)
        for k, f in enumerate((659.3, 739.9, 880.0, 987.8)):
            pt = (t + k * 1.7) % 3.0
            s += 0.12 * math.exp(-pt * 6.0) * math.sin(2 * math.pi * f * 0.997 * t)
        # loop-wide dread LFO (1 cycle): quiet middle, loud edges
        lfo = 0.75 + 0.25 * math.cos(2 * math.pi * t / dur)
        out[i] = s * lfo
    return out


def caught_sting(dur=1.4):
    """Catch sting: downward sweep + noise burst + low boom. One shot."""
    n = int(SR * dur)
    out = []
    seed = 1234

    def rnd():
        nonlocal seed
        seed = (1103515245 * seed + 12345) & 0x7FFFFFFF
        return seed / 0x7FFFFFFF * 2.0 - 1.0

    phase = 0.0
    for i in range(n):
        t = i / SR
        f = 800.0 * math.exp(-t * 2.2) + 90.0  # sweep down to the floor
        phase += 2 * math.pi * f / SR
        env = math.exp(-t * 2.6)
        s = env * (0.6 * math.sin(phase) + 0.3 * math.sin(phase * 2.01))
        s += math.exp(-t * 9.0) * 0.5 * rnd()  # initial burst
        s += math.exp(-t * 4.0) * 0.5 * math.sin(2 * math.pi * 48.0 * t)  # boom
        out.append(s)
    return out


if __name__ == "__main__":
    write_wav("chase_loop.wav", chase_loop())
    write_wav("caught_sting.wav", caught_sting())
