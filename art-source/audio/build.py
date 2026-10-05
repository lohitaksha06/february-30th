"""
FEBRUARY 30th — audio synthesis.

Pure Python standard library. No numpy, no scipy, no sample libraries.
This is not a purity stunt: it is the entire reason there is no licensing
question in this project (docs/distribution.md) and it is the correct sound
for the reference register -- degraded synthetic audio is what the PS1 and
analog-horror lineage is built from.

    python art-source/audio/build.py
    -> game/assets/audio/*.wav

Godot imports .wav natively. 16-bit mono 22050 Hz, which is a fifth of CD
quality and is the correct period-correct choice as well as the cheap one.
"""

import math
import os
import struct
import wave
import random

SR = 22050          # sample rate
BITS = 16
CHANNELS = 1
TAU = 2.0 * math.pi

# ---------------------------------------------------------------- output


def write_wav(path, samples):
    """Clamp to 16-bit and write a mono wav."""
    frames = bytearray()
    for s in samples:
        v = int(max(-1.0, min(1.0, s)) * 32767)
        frames += struct.pack('<h', v)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'wb') as w:
        w.setnchannels(CHANNELS)
        w.setsampwidth(BITS // 8)
        w.setframerate(SR)
        w.writeframes(bytes(frames))
    return path


def blank(seconds):
    return [0.0] * int(SR * seconds)


def mix(dest, src, at=0.0, gain=1.0):
    """Add src into dest at sample offset `at`, scaled by gain."""
    off = int(at * SR)
    for i, s in enumerate(src):
        j = off + i
        if 0 <= j < len(dest):
            dest[j] += s * gain
    return dest


# ---------------------------------------------------------------- oscillators


def sine(freq, seconds, amp=1.0, phase=0.0):
    n = int(SR * seconds)
    return [amp * math.sin(TAU * freq * i / SR + phase) for i in range(n)]


def triangle(freq, seconds, amp=1.0):
    """Warmer than sine, cheaper than a real synth."""
    n = int(SR * seconds)
    out = []
    for i in range(n):
        t = (freq * i / SR) % 1.0
        out.append(amp * (4.0 * abs(t - 0.5) - 1.0))
    return out


def noise(seconds, amp=1.0, seed=0):
    rng = random.Random(seed)
    n = int(SR * seconds)
    return [amp * (rng.random() * 2.0 - 1.0) for i in range(n)]


# ---------------------------------------------------------------- filters


def one_pole_lowpass(sig, cutoff):
    """Cheap, stable, and exactly as good as this sound needs."""
    x = math.exp(-TAU * cutoff / SR)
    out = []
    z = 0.0
    for s in sig:
        z = (1.0 - x) * s + x * z
        out.append(z)
    return out


def one_pole_highpass(sig, cutoff):
    lp = one_pole_lowpass(sig, cutoff)
    return [s - l for s, l in zip(sig, lp)]


def resonance(sig, freq, q=0.9):
    """Two-pole resonator. Gives us the 'wrong' ringing the ghouls need."""
    w = TAU * freq / SR
    r = 1.0 - q * 0.02
    a1 = 2.0 * r * math.cos(w)
    a2 = -r * r
    out = []
    y1 = y2 = 0.0
    for s in sig:
        y = s + a1 * y1 + a2 * y2
        out.append(y)
        y2, y1 = y1, y
    return out


def convolve(sig, impulse, taps=192):
    """Direct convolution, but only over the taps that actually matter.

    A naive n*m loop over a 30s signal and a 1.5s IR is ~2e10 operations
    in pure Python -- it does not finish. The perceptual difference between
    1.5s of noise tail and the first 512 significant taps is nil, so we
    threshold the IR down to its strongest taps and iterate only those.

    This is the whole reason the pipeline has no numpy dependency and still
    builds in under a second: be cheap in the right places.
    """
    # keep the strongest `taps` IR coefficients
    order = sorted(range(len(impulse)), key=lambda j: -abs(impulse[j]))[:taps]
    order.sort()
    active = [(j, impulse[j]) for j in order if abs(impulse[j]) > 1e-4]

    out = [0.0] * len(sig)
    n = len(out)
    for j, imp in active:
        # out[i+j] += sig[i]*imp  ->  slide the impulse over the signal
        for i in range(n - j):
            out[i + j] += sig[i] * imp
    return out


def normalise(sig, peak=0.9):
    m = max((abs(s) for s in sig), default=0.0)
    if m < 1e-9:
        return sig
    return [s * (peak / m) for s in sig]


def fade(sig, in_s=0.01, out_s=0.05):
    """Every cue must not click. Always call this."""
    n = len(sig)
    fi, fo = int(SR * in_s), int(SR * out_s)
    out = list(sig)
    for i in range(min(fi, n)):
        out[i] *= i / max(1, fi)
    for i in range(min(fo, n)):
        out[n - 1 - i] *= i / max(1, fo)
    return out


def envelope(n, attack=0.01, decay=0.3, curve=3.0):
    a = max(1, int(SR * attack))
    out = []
    for i in range(n):
        if i < a:
            out.append(i / a)
        else:
            t = (i - a) / max(1, (n - a))
            out.append(math.exp(-curve * t) * (1.0 - t * 0.2))
    return out


# ---------------------------------------------------------------- spaces


def hallway_ir(seconds=1.5, seed=7):
    """A 1.5s room tail, generated rather than recorded.

    Early reflections then exponential decay. This is the reason the knock
    sounds like it is in a house instead of on a table.
    """
    rng = random.Random(seed)
    n = int(SR * seconds)
    ir = [0.0] * n
    ir[0] = 1.0
    for tap_ms, gain in ((7, 0.5), (11, -0.35), (19, 0.3), (27, -0.22), (41, 0.18)):
        i = int(SR * tap_ms / 1000.0)
        if i < n:
            ir[i] += gain
    for i in range(n):
        ir[i] += rng.uniform(-1, 1) * math.exp(-4.0 * i / n) * 0.25
    return normalise(ir, 0.85)


# ---------------------------------------------------------------- the cues

# 24 notes. The motif. One semitone flat, slowing per loop.
# D minor, sparse, unresolved -- it should sound like it never quite finishes.
MOTIF = [
    ('D4', 1.0), ('A4', 1.0), ('F4', 0.5), ('G4', 0.5),
    ('A4', 1.5), (None, 0.5),
    ('C5', 1.0), ('A4', 1.0), ('D4', 1.0),
    ('E4', 1.5), ('D4', 1.5),
    ('F4', 1.0), ('E4', 1.0), ('C4', 1.0),
    ('A3', 2.0), (None, 1.0),
    ('D4', 1.0), ('F4', 1.0), ('A4', 1.0),
    ('G4', 1.5), ('F4', 1.5),
    ('E4', 1.0), ('D4', 1.0), ('C4', 1.0),
    ('D4', 3.0), (None, 2.0),
]

NOTES = {'A3': 220.00, 'C4': 261.63, 'D4': 293.66, 'E4': 329.63,
         'F4': 349.23, 'G4': 392.00, 'A4': 440.00, 'C5': 523.25}


def celesta(freq, seconds, amp=1.0, detune=0.4):
    """Two slightly detuned partials plus a struck transient.

    The detune is what makes it sound like a real music box rather than a
    sine wave. It is the single most important 3 lines in this file.
    """
    a = triangle(freq, seconds, amp * 0.6)
    b = triangle(freq * (1.0 + detune / 100.0), seconds, amp * 0.4)
    partial = sine(freq * 4.02, seconds * 0.35, amp * 0.12)
    env = envelope(len(a), attack=0.004, decay=0.30, curve=2.2)

    n = len(a)
    out = []
    for i in range(n):
        v = a[i] + b[i]
        out.append(v * env[i])
    return mix(out, partial, gain=1.0)


def music_box(detune_semitones=-1.0, tempo_scale=1.0, seed=3):
    """The motif. Flat by a semitone and slowing -- the 30th's theme.

    In the prologue this runs at tempo 1.0 and in tune. Everywhere else it
    is this. Docs/prologue.md beats 4-5.
    """
    rng = random.Random(seed)
    out = blank(30.0 * tempo_scale + 2.0)
    at = 0.0
    for name, beats in MOTIF:
        dur = beats * 0.42 * tempo_scale
        if name:
            f = NOTES[name] * math.pow(2.0, detune_semitones / 12.0)
            # ±0.3% pitch drift per note: an old box is never in tune
            f *= 1.0 + rng.uniform(-0.003, 0.003)
            note = celesta(f, dur * 2.2, amp=0.5, detune=0.5)
            # a music box is tinny -- band-limit it
            note = resonance(note, f * 2.1, q=1.4)
            mix(out, note, at, gain=0.9)
        at += dur
    return fade(normalise(out, 0.62), in_s=0.05, out_s=1.2)


def knock(seed=11, pitch_scale=0.5):
    """Three knocks. The inciting incident. ~200 bytes of feeling.

    Filtered noise burst -> 1.5s hallway tail, pitched down 12 semitones.
    """
    ir = hallway_ir(1.5, seed=seed)
    out = blank(3.4)
    rng = random.Random(seed)

    for k, start in enumerate((0.0, 0.42, 0.96)):
        body = noise(0.16, seed=seed * 31 + k)
        body = one_pole_lowpass(body, 900 * pitch_scale * 2.0)
        body = resonance(body, 160 * pitch_scale, q=1.2)
        body = [s * e for s, e in zip(body, envelope(len(body), 0.001, 0.12, 4.0))]

        # wood resonance: the difference between a cupboard and a wall
        thud = sine(74 * pitch_scale, 0.20, 0.55)
        thud = [s * e for s, e in zip(thud, envelope(len(thud), 0.001, 0.14, 5.0))]

        hit = [b + t for b, t in zip(body, thud)]
        hit = convolve(hit, ir)
        mix(out, hit, start, gain=0.85 - k * 0.12)

    return fade(normalise(out, 0.85), in_s=0.002, out_s=0.6)


def door_lock():
    """A key in a lock, one floor down. The most ordinary sound in the game.

    Deliberately under-designed. It should sound like a house, not a horror
    game -- that is why the mother unlock works.
    """
    out = blank(2.2)
    # key entering the lock
    jitter = noise(0.18, 1.0, seed=41)
    jitter = resonance(one_pole_highpass(jitter, 2500), 3800, q=1.8)
    jitter = [s * e for s, e in zip(jitter, envelope(len(jitter), 0.002, 0.09, 3.0))]
    mix(out, jitter, 0.0, 0.5)
    # the turn
    turn = noise(0.26, 1.0, seed=42)
    turn = one_pole_lowpass(turn, 1200)
    turn = resonance(turn, 900, q=1.6)
    turn = [s * e for s, e in zip(turn, envelope(len(turn), 0.004, 0.16, 2.6))]
    mix(out, turn, 0.22, 0.6)
    # the latch
    latch = noise(0.05, 1.0, seed=43)
    latch = one_pole_lowpass(latch, 3000)
    mix(out, latch, 0.46, 0.7)
    mix(out, convolve([s for s in out], hallway_ir(1.0, seed=9)), 0.0, 0.25)
    return fade(normalise(out, 0.7), in_s=0.003, out_s=0.4)


def bad_cheer(durations=1.0, voices=6, seed=17):
    """THE GHOUL SOUND. The most important cue in the game.

    Not a roar. A party noise played slightly wrong: children cheering and
    clapping, degraded until it is out of time with itself, and stacked so
    it doubles 1 -> 4 -> 6 voices.

    You are hunted by something that is nearly a birthday party. That gap
    is the whole horror and it is all in this function.
    """
    out = blank(durations + 0.5)
    rng = random.Random(seed)

    for v in range(voices):
        gain = 0.85 / (1.0 + v * 0.55)
        # each "voice" is a band of formant-ish resonances around a
        # child's vocal range, ring-modulated at a slightly wrong rate
        base = 340 + v * 46 + rng.uniform(-25, 25)
        carrier = sine(base, durations, 1.0)
        shaper = [math.tanh(4.0 * math.sin(TAU * base * 1.6 * i / SR)) * 0.5
                  for i in range(int(SR * durations))]

        voice = [c * s for c, s in zip(carrier, shaper)]

        # clapping: a rhythmic gate at a rate slightly off from the others,
        # so the crowd never quite lines up
        claps = noise(durations, 1.0, seed=seed * 7 + v)
        claps = one_pole_highpass(claps, 900 + v * 120)
        # each voice claps at a slightly different rate, so the crowd never
        # quite lines up with itself
        rate = 7.5 + v * 0.37
        n_claps = len(claps)
        gate = [math.exp(-26.0 * ((i / SR * rate) % 1.0))
                if ((i / SR * rate) % 1.0) < 0.5 else 0.0
                for i in range(n_claps)]
        claps = [c * g for c, g in zip(claps, gate)]

        voice = [v0 + c * 0.30 for v0, c in zip(voice, claps)]

        # each voice arrives slightly late
        offset = v * 0.085
        mix(out, voice, offset, gain=gain)

    # 40 Hz ring modulation is what makes it read as *broken* rather than loud
    lfo = sine(40.0, len(out), 0.35)
    out = [(s + l * math.sin(TAU * 40.0 * i / SR) * 0.5) for i, s in enumerate(out)]

    out = convolve(out, hallway_ir(1.2, seed=5))
    return fade(normalise(out, 0.8), in_s=0.01, out_s=0.35)


def static_voice(seconds=2.0, seed=23):
    """Corrupted speech. No text-to-speech is used anywhere in this game.

    A pitched noise source ring-modulated by a 40 Hz LFO, granular-stuttered
    so it has syllables without having words.
    """
    rng = random.Random(seed)
    n = int(SR * seconds)
    out = [0.0] * n

    grain = int(SR * 0.09)
    pos = 0
    while pos < n:
        f = 180 + rng.uniform(-60, 140)
        g = sine(f, grain / SR, 1.0)
        g = resonance(g, 700, q=1.5)
        env = envelope(len(g), 0.01, 0.05, 2.0)
        g = [s * e for s, e in zip(g, env)]
        for i, s in enumerate(g):
            if pos + i < n:
                out[pos + i] = s
        pos += grain + rng.randint(-int(SR * 0.012), int(SR * 0.022))

    lfo = sine(40.0, seconds, 1.0)
    out = [s * (0.55 + 0.45 * l) for s, l in zip(out, lfo)]

    out = convolve(out, hallway_ir(0.9, seed=13))
    return fade(normalise(out, 0.6), in_s=0.02, out_s=0.3)


def bedroom_ambience(seconds=20.0, seed=29):
    """Room tone with one band removed. The absence is the part you notice.

    A fridge, something settling, and a gap where the street should be.
    """
    out = blank(seconds)
    rng = random.Random(seed)

    base = noise(seconds, 0.10, seed=seed)
    base = one_pole_lowpass(base, 900)
    out = mix(out, base, 0.0, 1.0)

    # the fridge: a steady hum two octaves down, with a slow wobble
    hum = sine(49, seconds, 0.09)
    wobble = sine(0.09, seconds, 0.02)
    hum = [h + w for h, w in zip(hum, wobble)]
    mix(out, hum, 0.0, 1.0)

    # a car passing, far off, every ~14s
    t = 3.0
    while t < seconds - 3:
        pass_by = blank(2.6)
        n = noise(2.6, 1.0, seed=seed + int(t))
        for i in range(len(n)):
            d = abs(i - len(n) / 2) / (len(n) / 2)
            n[i] *= math.exp(-3.0 * d)
        n = one_pole_lowpass(n, 700 + 400 * math.sin(math.pi * i / len(n)))
        mix(pass_by, n, 0.0, 0.5)
        mix(out, pass_by, t, 0.30)
        t += 14.0 + rng.uniform(-3, 3)

    # THE GAP: a band-pass notch around 2-4k where street sound would live.
    lp = one_pole_lowpass(out, 1800)
    hp = one_pole_highpass(out, 3800)
    out = [0.6 * s - 0.25 * (l + h) for s, l, h in zip(out, lp, hp)]

    return fade(normalise(out, 0.34), in_s=1.0, out_s=2.0)


def footsteps(count=6, seed=61):
    """Small feet on a hallway floor. The companion following you."""
    ir = hallway_ir(0.7, seed=seed)
    out = blank(count * 0.42 + 0.4)
    for k in range(count):
        step = noise(0.09, 1.0, seed=seed + k)
        step = one_pole_lowpass(step, 1100)
        step = resonance(step, 210, q=1.3)
        step = [s * e for s, e in zip(step, envelope(len(step), 0.002, 0.07, 4.5))]
        mix(out, convolve(step, ir), k * 0.42, 0.7 - k * 0.03)
    return fade(normalise(out, 0.5), in_s=0.002, out_s=0.25)


# ---------------------------------------------------------------- main

CUES = [
    ('music_box_realmotif', lambda: music_box(0.0, 1.0, seed=3)),
    ('music_box_30th', lambda: music_box(-1.0, 1.0, seed=3)),
    ('music_box_slow', lambda: music_box(-1.0, 1.22, seed=4)),
    ('knock', lambda: knock()),
    ('door_lock', lambda: door_lock()),
    ('bad_cheer_near', lambda: bad_cheer(1.1, 3, seed=17)),
    ('bad_cheer_far', lambda: bad_cheer(1.0, 6, seed=18)),
    ('static_voice', lambda: static_voice()),
    ('bedroom_ambience', lambda: bedroom_ambience()),
    ('footsteps', lambda: footsteps()),
]


def build(out_dir):
    print(f'building audio -> {out_dir}\n')
    total = 0
    for name, fn in CUES:
        samples = fn()
        path = os.path.join(out_dir, name + '.wav')
        write_wav(path, samples)
        kb = os.path.getsize(path) / 1024.0
        total += kb
        print(f'  {name:<22} {len(samples)/SR:>5.1f}s  {kb:>7.1f} KB')
    print(f'\n  total {total:.1f} KB   (budget: 12000 KB)')
    return total


if __name__ == '__main__':
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       '..', '..', 'game', 'assets', 'audio')
    total = build(os.path.normpath(root))
    raise SystemExit(0 if total < 12000 else 1)