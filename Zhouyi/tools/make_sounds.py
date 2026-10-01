#!/usr/bin/env python3
"""生成铜钱音效：python3 tools/make_sounds.py
coin-rattle.wav 摇动（约 0.9s，与摇动动画同长），coin-drop.wav 落定（三钱先后落桌）。
清脆声 = 几个非谐和高频分音 + 指数衰减 + 数毫秒噪声起音；调音改下面的参数即可。"""
import pathlib, wave
import numpy as np

SR = 44100
OUT = pathlib.Path(__file__).resolve().parent.parent / "Zhouyi"
rng = np.random.default_rng(7)   # 固定种子，重跑结果一致


def clink(f0, dur=0.25, decay=18.0, amp=1.0):
    t = np.arange(int(SR * dur)) / SR
    s = sum(a * np.sin(2 * np.pi * f0 * r * t + rng.uniform(0, 6.28)) * np.exp(-decay * k * t)
            for r, a, k in [(1, 1, 1), (1.47, 0.6, 1.3), (2.09, 0.4, 1.7), (2.76, 0.25, 2.2)])
    n = int(SR * 0.004)
    s[:n] += rng.normal(0, 0.6, n) * np.linspace(1, 0, n)   # 撞击瞬间的噪声
    return amp * s


def mix(total, hits):
    buf = np.zeros(int(SR * total))
    for at, snd in hits:
        i = int(SR * at)
        seg = snd[: len(buf) - i]
        buf[i:i + len(seg)] += seg
    return buf


def save(name, buf, peak=0.5):
    buf = buf / np.abs(buf).max() * peak
    fade = int(SR * 0.02)
    buf[-fade:] *= np.linspace(1, 0, fade)
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((buf * 32767).astype("<i2").tobytes())
    print("wrote", OUT / name)


# 摇动：钱在掌中相碰，约 14 下，前密后疏，音量起伏
rattle = [(at, clink(rng.uniform(2600, 4200), 0.12, 30, rng.uniform(0.35, 1.0)))
          for at in np.sort(rng.uniform(0.0, 0.8, 14))]
save("coin-rattle.wav", mix(0.95, rattle), peak=0.45)

# 落定：三钱先后落桌，各带一次轻弹
drop = []
for at, f in [(0.0, 3300), (0.07, 2900), (0.15, 3700)]:
    drop += [(at, clink(f, 0.35, 12, 1.0)), (at + 0.06, clink(f * 1.02, 0.2, 22, 0.35))]
save("coin-drop.wav", mix(0.6, drop), peak=0.5)
