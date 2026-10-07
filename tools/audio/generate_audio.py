"""Generates the game's retro sound effects and chiptune music.

Run from the project root:  python tools/audio/generate_audio.py
Needs numpy, and ffmpeg on PATH for the music (.ogg).

Output:
  assets/sound/generated/*.wav   short effects (brick, paddle, wall, crack, explosion)
  assets/music/*.ogg             looping chiptune tracks (menu, level_a, level_b)

Everything is synthesized from square, triangle and noise waves, like old consoles.
Seeds are fixed, so running it again gives the same files.
"""

import os
import subprocess
import wave

import numpy as np

RATE = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SFX_DIR = os.path.join(ROOT, "assets", "sound", "generated")
MUSIC_DIR = os.path.join(ROOT, "assets", "music")


# --- oscillators -----------------------------------------------------------

def square(freq, length, duty=0.5):
    t = np.arange(int(length * RATE)) / RATE
    phase = (t * freq) % 1.0
    return np.where(phase < duty, 1.0, -1.0)


def square_sweep(f0, f1, length, duty=0.5):
    n = int(length * RATE)
    freqs = np.linspace(f0, f1, n)
    phase = np.cumsum(freqs / RATE) % 1.0
    return np.where(phase < duty, 1.0, -1.0)


def triangle(freq, length):
    t = np.arange(int(length * RATE)) / RATE
    phase = (t * freq) % 1.0
    return 4.0 * np.abs(phase - 0.5) - 1.0


def noise(length, seed=0, step=1):
    """White noise; `step` > 1 holds each value for several samples (lower, grittier noise)."""
    rng = np.random.default_rng(seed)
    n = int(length * RATE)
    values = rng.uniform(-1.0, 1.0, n // step + 1)
    return np.repeat(values, step)[:n]


def envelope(n, attack=0.002, decay=0.1, sustain=0.0, release=0.0, length=None):
    """Attack-decay(-sustain) envelope over n samples."""
    env = np.ones(n)
    a = max(1, int(attack * RATE))
    env[:a] = np.linspace(0.0, 1.0, a)
    d = max(1, int(decay * RATE))
    end = min(n, a + d)
    env[a:end] = np.linspace(1.0, sustain, end - a)
    env[end:] = sustain
    if release > 0:
        r = min(n, int(release * RATE))
        env[n - r:] *= np.linspace(1.0, 0.0, r)
    return env


def lowpass(signal, amount):
    """Simple one-pole low-pass filter (0 = none, close to 1 = very muffled)."""
    out = np.empty_like(signal)
    acc = 0.0
    for i, s in enumerate(signal):
        acc = acc * amount + s * (1.0 - amount)
        out[i] = acc
    return out


def write_wav(path, signal, volume=0.8):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    peak = np.max(np.abs(signal)) or 1.0
    data = (signal / peak * volume * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


# --- sound effects ---------------------------------------------------------

def make_sfx():
    # Brick break: bright blip with a quick upward chirp. Played at higher pitch as combo grows.
    n = int(0.12 * RATE)
    s = square_sweep(660, 990, 0.12, duty=0.25) * envelope(n, decay=0.11)
    write_wav(os.path.join(SFX_DIR, "brick_break.wav"), s, 0.55)

    # Paddle: rounder, lower "bop".
    n = int(0.09 * RATE)
    s = (square(330, 0.09, 0.5) * 0.6 + triangle(165, 0.09) * 0.4) * envelope(n, decay=0.085)
    write_wav(os.path.join(SFX_DIR, "paddle_hit.wav"), s, 0.55)

    # Wall: tiny tick.
    n = int(0.04 * RATE)
    s = square(880, 0.04, 0.125) * envelope(n, decay=0.035)
    write_wav(os.path.join(SFX_DIR, "wall_hit.wav"), s, 0.3)

    # Hard brick crack (hit without breaking): noise click + low square.
    n = int(0.1 * RATE)
    s = (noise(0.1, seed=3, step=4) * 0.6 + square(220, 0.1, 0.25) * 0.4) * envelope(n, decay=0.09)
    write_wav(os.path.join(SFX_DIR, "brick_crack.wav"), s, 0.55)

    # Explosion: low gritty noise with a long decay, muffled at the end.
    n = int(0.7 * RATE)
    raw = noise(0.7, seed=7, step=12) * envelope(n, attack=0.003, decay=0.65)
    s = lowpass(raw, 0.55) + noise(0.7, seed=8, step=3) * envelope(n, decay=0.08) * 0.4
    write_wav(os.path.join(SFX_DIR, "explosion.wav"), s, 0.85)

    # Fire ball burning through a brick: short noisy "fshh".
    n = int(0.08 * RATE)
    s = noise(0.08, seed=11, step=2) * envelope(n, decay=0.075)
    write_wav(os.path.join(SFX_DIR, "burn.wav"), s, 0.4)


# --- music -----------------------------------------------------------------

NOTE_NAMES = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8,
              "A": 9, "A#": 10, "B": 11}


def midi_to_freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def note(name, octave):
    return 12 * (octave + 1) + NOTE_NAMES[name]


MINOR = [0, 2, 3, 5, 7, 8, 10]


def render_track(cfg):
    """A loop of `bars` bars: bass, arpeggio, lead melody and noise drums.

    cfg keys: tempo, key (midi of the tonic), progression (list of (degree, quality)), bars,
    seed, lead_duty, arp_duty, and optional style keys:
      drums: "rock" (kick 1+3, snare 2+4), "four" (four on the floor), "break" (syncopated),
             "half" (half-time, snare on 3)
      arp:   "up", "down", "updown", "broken"
      bass:  "octave" (root + octave jumps), "eighths" (driving eighth notes), "walk"
      progression_b: second chord progression; with it the second half of the track is a
             "B section" with its own melody, so a 32-bar track repeats much less.
    """
    rng = np.random.default_rng(cfg["seed"])
    beat = 60.0 / cfg["tempo"]
    step = beat / 4  # sixteenth notes
    steps_per_bar = 16
    total_steps = cfg["bars"] * steps_per_bar
    n = int(total_steps * step * RATE)
    mix = np.zeros(n)

    def place(sig, start_step, gain):
        start = int(start_step * step * RATE)
        end = min(n, start + len(sig))
        mix[start:end] += sig[: end - start] * gain

    key = cfg["key"]
    scale = [key + i for i in MINOR]

    def degree_root(deg):
        return key + MINOR[deg % 7] + 12 * (deg // 7)

    def triad(deg, quality):
        r = degree_root(deg)
        third = 4 if quality == "maj" else 3
        return [r, r + third, r + 7]

    def make_motif():
        motif = [int(rng.integers(0, 7)) for _ in range(8)]
        rhythm = [1 if rng.random() < 0.7 else 0 for _ in range(8)]
        rhythm[0] = 1
        return motif, rhythm

    # A short motif reused across the loop (A A' B A'), so the melody sounds composed.
    motif_a, rhythm_a = make_motif()
    motif_b, rhythm_b = make_motif() if cfg.get("progression_b") else (motif_a, rhythm_a)

    drums = cfg.get("drums", "rock")
    arp_style = cfg.get("arp", "up")
    bass_style = cfg.get("bass", "octave")
    half = cfg["bars"] // 2 if cfg.get("progression_b") else cfg["bars"]

    for bar in range(cfg["bars"]):
        in_b = bar >= half
        progression = cfg["progression_b"] if in_b else cfg["progression"]
        section_bars = cfg["bars"] - half if in_b else half
        bars_per_chord = max(1, section_bars // len(progression))
        local_bar = bar - half if in_b else bar
        deg, quality = progression[(local_bar // bars_per_chord) % len(progression)]
        tones = triad(deg, quality)
        bar_step = bar * steps_per_bar
        motif, rhythm = (motif_b, rhythm_b) if in_b else (motif_a, rhythm_a)

        # Bass
        if bass_style == "eighths":
            for e in range(8):
                midi = tones[0] - 24 + (12 if e % 4 == 3 else 0)
                length = beat * 0.45
                sig = triangle(midi_to_freq(midi), length) * envelope(int(length * RATE), decay=length, sustain=0.5)
                place(sig, bar_step + e * 2, 0.5)
        elif bass_style == "walk":
            walk = [tones[0], tones[1], tones[2], tones[1]]
            for b in range(4):
                midi = walk[b] - 24
                length = beat * 0.9
                sig = triangle(midi_to_freq(midi), length) * envelope(int(length * RATE), decay=length, sustain=0.6)
                place(sig, bar_step + b * 4, 0.55)
        else:
            for b in range(4):
                midi = tones[0] - 24 + (12 if b % 2 else 0)
                length = beat * 0.9
                sig = triangle(midi_to_freq(midi), length) * envelope(int(length * RATE), decay=length, sustain=0.6)
                place(sig, bar_step + b * 4, 0.55)

        # Arpeggio: fast sixteenths through the chord.
        order = {
            "up": [0, 1, 2],
            "down": [2, 1, 0],
            "updown": [0, 1, 2, 1],
            "broken": [0, 2, 1, 2],
        }[arp_style]
        for st in range(steps_per_bar):
            midi = tones[order[st % len(order)]] + 12
            length = step * 0.9
            sig = square(midi_to_freq(midi), length, cfg["arp_duty"]) * envelope(int(length * RATE), decay=length * 0.8)
            place(sig, bar_step + st, 0.12)

        # Lead: motif in eighth notes, varied per section, snapped to chord tones on strong beats.
        section = (bar // 2) % 4
        for i in range(8):
            if not rhythm[i] and section != 2:
                continue
            idx = motif[i] + (2 if section == 1 else 0) + (4 if section == 2 else 0)
            midi = scale[idx % 7] + 12 * (1 + idx // 7) + 12
            if i % 4 == 0:
                midi = min(tones, key=lambda t: abs((t + 24) - midi)) + 24
            length = step * 2 * (0.95 if i < 7 else 1.8)
            env = envelope(int(length * RATE), attack=0.004, decay=length * 0.6, sustain=0.35, release=0.02)
            sig = square(midi_to_freq(midi), length, cfg["lead_duty"]) * env
            place(sig, bar_step + i * 2, 0.22)

        # Drums
        kicks, snares = {
            "rock": ((0, 8), (4, 12)),
            "four": ((0, 4, 8, 12), (4, 12)),
            "break": ((0, 6, 10), (4, 12, 14)),
            "half": ((0, 10), (8,)),
        }[drums]
        for st in range(0, steps_per_bar, 2):
            length = 0.04
            hat = noise(length, seed=bar * 100 + st, step=1) * envelope(int(length * RATE), decay=0.035)
            place(hat, bar_step + st, 0.07)
        for b in kicks:
            length = 0.12
            kick = square_sweep(150, 45, length, 0.5) * envelope(int(length * RATE), decay=0.11)
            place(kick, bar_step + b, 0.45)
        for b in snares:
            length = 0.14
            snare = noise(length, seed=bar * 7 + b, step=2) * envelope(int(length * RATE), decay=0.12)
            place(snare, bar_step + b, 0.25)

    # Seamless loop: soften the very end so the jump back to the start does not click.
    fade = int(0.01 * RATE)
    mix[-fade:] *= np.linspace(1.0, 0.0, fade)
    mix[:fade] *= np.linspace(0.0, 1.0, fade)
    return mix


I_VI_III_VII = [(0, "min"), (5, "maj"), (2, "maj"), (6, "maj")]
I_IV_VI_V = [(0, "min"), (3, "min"), (5, "maj"), (4, "maj")]
I_VII_VI_VII = [(0, "min"), (6, "maj"), (5, "maj"), (6, "maj")]
I_III_VII_IV = [(0, "min"), (2, "maj"), (6, "maj"), (3, "min")]
VI_VII_I_I = [(5, "maj"), (6, "maj"), (0, "min"), (0, "min")]

TRACKS = {
    "menu": {"tempo": 104, "key": note("A", 3), "bars": 16, "seed": 11, "lead_duty": 0.5, "arp_duty": 0.25,
             "progression": I_VI_III_VII},
    "level_a": {"tempo": 140, "key": note("E", 3), "bars": 16, "seed": 23, "lead_duty": 0.25, "arp_duty": 0.125,
                "progression": I_VI_III_VII},
    "level_b": {"tempo": 150, "key": note("D", 3), "bars": 16, "seed": 37, "lead_duty": 0.25, "arp_duty": 0.25,
                "progression": I_IV_VI_V},
    "level_c": {"tempo": 132, "key": note("G", 3), "bars": 32, "seed": 41, "lead_duty": 0.5, "arp_duty": 0.125,
                "progression": I_VII_VI_VII, "progression_b": I_IV_VI_V,
                "drums": "four", "arp": "updown", "bass": "eighths"},
    "level_d": {"tempo": 160, "key": note("C", 3), "bars": 32, "seed": 53, "lead_duty": 0.25, "arp_duty": 0.25,
                "progression": I_III_VII_IV, "progression_b": VI_VII_I_I,
                "drums": "break", "arp": "broken", "bass": "octave"},
    "level_e": {"tempo": 118, "key": note("F", 3), "bars": 32, "seed": 61, "lead_duty": 0.125, "arp_duty": 0.5,
                "progression": I_VI_III_VII, "progression_b": I_VII_VI_VII,
                "drums": "half", "arp": "down", "bass": "walk"},
    "level_f": {"tempo": 145, "key": note("B", 2), "bars": 32, "seed": 71, "lead_duty": 0.25, "arp_duty": 0.125,
                "progression": I_IV_VI_V, "progression_b": I_III_VII_IV,
                "drums": "rock", "arp": "updown", "bass": "eighths"},
    "level_g": {"tempo": 170, "key": note("A", 3), "bars": 32, "seed": 83, "lead_duty": 0.5, "arp_duty": 0.25,
                "progression": VI_VII_I_I, "progression_b": I_VI_III_VII,
                "drums": "four", "arp": "up", "bass": "eighths"},
    "level_h": {"tempo": 126, "key": note("D#", 3), "bars": 32, "seed": 97, "lead_duty": 0.25, "arp_duty": 0.125,
                "progression": I_III_VII_IV, "progression_b": I_IV_VI_V,
                "drums": "break", "arp": "broken", "bass": "walk"},
}


def make_music():
    os.makedirs(MUSIC_DIR, exist_ok=True)
    for name, cfg in TRACKS.items():
        wav = os.path.join(MUSIC_DIR, name + ".wav")
        write_wav(wav, render_track(cfg), 0.7)
        ogg = os.path.join(MUSIC_DIR, name + ".ogg")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", ogg],
                       check=True)
        os.remove(wav)
        print("music:", ogg)


if __name__ == "__main__":
    make_sfx()
    print("sfx:", SFX_DIR)
    make_music()
