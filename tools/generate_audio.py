#!/usr/bin/env python3
"""Generate simple retro WAV assets for HOTLINE KROWODRZA."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "audio"


def clamp(value: float, low: float = -1.0, high: float = 1.0) -> float:
    return max(low, min(high, value))


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for sample in samples:
            frames += struct.pack("<h", int(clamp(sample) * 32767))
        wav_file.writeframes(frames)


def sine(freq: float, length: float, amp: float = 0.25) -> list[float]:
    count = int(SAMPLE_RATE * length)
    return [
        amp * math.sin(2.0 * math.pi * freq * (i / SAMPLE_RATE))
        for i in range(count)
    ]


def noise(length: float, amp: float = 0.2) -> list[float]:
    count = int(SAMPLE_RATE * length)
    phase = 0.0
    samples: list[float] = []
    for i in range(count):
        phase += 0.17 + (i % 7) * 0.003
        samples.append(amp * math.sin(phase * 17.0) * math.sin(phase * 3.1))
    return samples


def mix(*tracks: list[float]) -> list[float]:
    length = max(len(track) for track in tracks)
    mixed = [0.0] * length
    for track in tracks:
        for i, sample in enumerate(track):
            mixed[i] += sample
    peak = max(abs(sample) for sample in mixed) or 1.0
    if peak > 0.95:
        scale = 0.95 / peak
        mixed = [sample * scale for sample in mixed]
    return mixed


def envelope(samples: list[float], attack: float, release: float) -> list[float]:
    attack_count = int(SAMPLE_RATE * attack)
    release_count = int(SAMPLE_RATE * release)
    total = len(samples)
    result: list[float] = []
    for i, sample in enumerate(samples):
        gain = 1.0
        if i < attack_count and attack_count > 0:
            gain = i / attack_count
        elif i > total - release_count and release_count > 0:
            gain = max(0.0, (total - i) / release_count)
        result.append(sample * gain)
    return result


def loop_pad(notes: list[tuple[float, float]], bar_length: float, bars: int, amp: float) -> list[float]:
    bar_count = int(SAMPLE_RATE * bar_length)
    total = bar_count * bars
    output = [0.0] * total
    step = total // len(notes)
    for index, (freq, length) in enumerate(notes):
        tone = envelope(sine(freq, length, amp), 0.01, 0.08)
        start = index * step
        for i, sample in enumerate(tone):
            pos = start + i
            if pos < total:
                output[pos] += sample
    return output


def make_menu_music() -> list[float]:
    melody = loop_pad(
        [
            (220, 0.22),
            (261.63, 0.22),
            (329.63, 0.22),
            (392.0, 0.22),
            (329.63, 0.22),
            (261.63, 0.22),
        ],
        bar_length=1.2,
        bars=8,
        amp=0.22,
    )
    bass = loop_pad(
        [(110, 0.35), (130.81, 0.35), (164.81, 0.35), (196.0, 0.35)],
        bar_length=1.2,
        bars=8,
        amp=0.18,
    )
    return mix(melody, bass)


def make_dungeon_music() -> list[float]:
  bass = loop_pad([(55, 0.35), (49, 0.35), (65.41, 0.35), (73.42, 0.35)], 0.7, 12, 0.32)
  lead = loop_pad([(220, 0.12), (0, 0.06), (261.63, 0.12), (0, 0.06), (329.63, 0.12), (293.66, 0.12)], 0.35, 12, 0.18)
  return mix(bass, lead)


def make_boss_music() -> list[float]:
    bass = loop_pad([(41.2, 0.18), (41.2, 0.18), (36.71, 0.18), (49.0, 0.18)], 0.45, 12, 0.36)
    pulse = loop_pad([(164.81, 0.08), (196.0, 0.08), (246.94, 0.08), (293.66, 0.08)], 0.22, 12, 0.2)
    return mix(bass, pulse)


def make_ending_music() -> list[float]:
    return loop_pad(
        [(196.0, 0.5), (246.94, 0.5), (293.66, 0.5), (329.63, 0.8)],
        bar_length=2.0,
        bars=2,
        amp=0.16,
    )


def make_shoot() -> list[float]:
    return envelope(mix(sine(880, 0.04, 0.18), noise(0.04, 0.12)), 0.001, 0.03)


def make_hit() -> list[float]:
    return envelope(mix(sine(180, 0.08, 0.35), noise(0.06, 0.15)), 0.001, 0.05)


def make_enemy_death() -> list[float]:
    first = sine(220, 0.08, 0.2)
    second = sine(110, 0.14, 0.22)
    return envelope(first + second, 0.001, 0.08)


def make_door() -> list[float]:
    return envelope(mix(sine(420, 0.05, 0.2), sine(280, 0.08, 0.15)), 0.002, 0.04)


def make_pickup() -> list[float]:
    return envelope(mix(sine(660, 0.05, 0.15), sine(990, 0.08, 0.12)), 0.001, 0.05)


def make_shield() -> list[float]:
    return envelope(mix(sine(520, 0.06, 0.2), sine(780, 0.08, 0.12)), 0.001, 0.06)


def make_boss_roar() -> list[float]:
    low = sine(55, 0.45, 0.35)
    grit = noise(0.45, 0.12)
    return envelope(mix(low, grit), 0.02, 0.2)


def main() -> None:
    assets = {
        "music_menu.wav": make_menu_music(),
        "music_dungeon.wav": make_dungeon_music(),
        "music_boss.wav": make_boss_music(),
        "music_ending.wav": make_ending_music(),
        "sfx_shoot.wav": make_shoot(),
        "sfx_hit.wav": make_hit(),
        "sfx_enemy_death.wav": make_enemy_death(),
        "sfx_door.wav": make_door(),
        "sfx_pickup.wav": make_pickup(),
        "sfx_shield.wav": make_shield(),
        "sfx_boss_roar.wav": make_boss_roar(),
    }
    for name, samples in assets.items():
        write_wav(OUT_DIR / name, samples)
        print(f"wrote {OUT_DIR / name}")


if __name__ == "__main__":
    main()
