#!/usr/bin/env python3
"""生成宣纸纹理与云雾：python3 tools/make_paper.py
paper-grain：256px 四方连续，黑色 + 低 alpha 的纤维与颗粒（界面里按模板色着墨色平铺）。
mist-1 / mist-2：3:2 透明白雾，左右首尾相接，首页题图上反向缓移。
周期性全靠 FFT 卷积（天然环绕）与纤维九宫格重复绘制。"""
import json, pathlib
import numpy as np
from PIL import Image, ImageDraw

ASSETS = pathlib.Path(__file__).resolve().parent.parent / "Zhouyi" / "Assets.xcassets"
rng = np.random.default_rng(11)   # 固定种子，重跑结果一致


def lowpass(h, w, sigma_y, sigma_x):
    """周期白噪声经高斯低通，归一化到 0…1"""
    f = np.fft.fft2(rng.normal(size=(h, w)))
    ky, kx = np.fft.fftfreq(h)[:, None], np.fft.fftfreq(w)[None, :]
    n = np.real(np.fft.ifft2(f * np.exp(-2 * np.pi ** 2 * ((ky * sigma_y) ** 2 + (kx * sigma_x) ** 2))))
    return (n - n.min()) / (n.max() - n.min())


def save(name, rgba, scale=None):
    d = ASSETS / f"{name}.imageset"
    d.mkdir(exist_ok=True)
    Image.fromarray(rgba, "RGBA").save(d / f"{name}.png", optimize=True)
    img = {"filename": f"{name}.png", "idiom": "universal"}
    if scale: img["scale"] = scale
    (d / "Contents.json").write_text(json.dumps({"images": [img], "info": {"author": "xcode", "version": 1}}, indent=2))
    print("wrote", d)


def paper(size=256):
    a = 0.05 * lowpass(size, size, 1.2, 1.2) + 0.05 * lowpass(size, size, 14, 14)   # 细颗粒 + 云状深浅
    im = Image.new("L", (size, size))
    dr = ImageDraw.Draw(im)
    for _ in range(70):   # 纤维：短而微弯的细线，九宫格各画一次保证接缝连续
        x, y = rng.uniform(0, size, 2)
        ang, ln = rng.uniform(0, np.pi), rng.uniform(8, 40)
        bend = rng.uniform(-0.4, 0.4)
        t = np.linspace(0, 1, 12)
        pts = np.stack([x + np.cos(ang + bend * t) * ln * t, y + np.sin(ang + bend * t) * ln * t], 1)
        v = int(rng.uniform(25, 70))
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                dr.line([tuple(p) for p in pts + (ox, oy)], fill=v, width=1)
    a += np.asarray(im, float) / 255 * 0.5
    rgba = np.zeros((size, size, 4), np.uint8)
    rgba[..., 3] = np.clip(a * 255, 0, 255).astype(np.uint8)
    save("paper-grain", rgba, "2x")   # 2x：屏上 128pt 一块，纹理更细


def mist(name, center, w=480, h=320):
    n = lowpass(h, w, 22, 40) * 0.7 + lowpass(h, w, 8, 14) * 0.3
    y = np.linspace(0, 1, h)[:, None]
    band = np.exp(-((y - center) / 0.2) ** 2)   # 一条横向雾带，上下渐隐
    a = np.clip((n - 0.42) * 2.4, 0, 1) ** 1.5 * band * 0.75
    rgba = np.full((h, w, 4), 255, np.uint8)
    rgba[..., 3] = (a * 255).astype(np.uint8)
    save(name, rgba)


if __name__ == "__main__":
    paper()
    mist("mist-1", 0.62)
    mist("mist-2", 0.42)
    # 自检：左右（纹理还有上下）首尾相接，接缝处差异不大于内部相邻像素
    for n, both in [("paper-grain", True), ("mist-1", False), ("mist-2", False)]:
        a = np.asarray(Image.open(ASSETS / f"{n}.imageset/{n}.png"), float)[..., 3]
        inner = np.abs(np.diff(a, axis=1)).mean()
        assert np.abs(a[:, 0] - a[:, -1]).mean() < inner * 2 + 1, n
        if both: assert np.abs(a[0] - a[-1]).mean() < np.abs(np.diff(a, axis=0)).mean() * 2 + 1, n
    print("seams ok")
